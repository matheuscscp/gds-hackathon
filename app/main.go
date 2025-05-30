package main

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"os"
	"os/signal"
	"regexp"
	"strings"
	"syscall"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/sirupsen/logrus"
	"google.golang.org/api/idtoken"
)

const keyPattern = `^[a-z0-9-]+$`

var keyRegex = regexp.MustCompile(keyPattern)

func main() {
	logrus.SetFormatter(&logrus.JSONFormatter{
		TimestampFormat: time.RFC3339,
	})

	bucketName := os.Getenv("BUCKET_NAME")

	var conf aws.Config
	{
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		var err error
		conf, err = config.LoadDefaultConfig(ctx)
		if err != nil {
			panic(err)
		}
	}

	s3Client := s3.NewFromConfig(conf)

	s := &http.Server{
		Addr: ":8080",
		Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authz := r.Header.Get("Authorization")
			authz = strings.TrimPrefix(authz, "Bearer ")
			if authz == "" {
				http.Error(w, "Authorization header missing or invalid", http.StatusUnauthorized)
				return
			}
			payload, err := idtoken.Validate(r.Context(), authz, "32555940559.apps.googleusercontent.com")
			if err != nil {
				logrus.WithError(err).Error("Failed to validate ID token")
				http.Error(w, "Invalid ID token", http.StatusUnauthorized)
				return
			}
			if payload.Claims["email"] != "matheuscscp@gmail.com" {
				http.Error(w, "Unauthorized email", http.StatusForbidden)
				return
			}

			key := r.URL.Path
			key = strings.TrimPrefix(key, "/")
			if !keyRegex.MatchString(key) {
				http.Error(w, "Invalid key format, must match "+keyPattern, http.StatusBadRequest)
				return
			}

			switch r.Method {
			case http.MethodPut:
				const maxBodySize = 100 * 1024 // 100 KiB
				r.Body = http.MaxBytesReader(w, r.Body, maxBodySize)
				defer r.Body.Close()
				data, err := io.ReadAll(r.Body)
				if err != nil {
					http.Error(w, "Request body too large", http.StatusRequestEntityTooLarge)
					return
				}
				var obj any
				if err := json.Unmarshal(data, &obj); err != nil {
					http.Error(w, "Invalid JSON payload", http.StatusBadRequest)
					return
				}
				data, err = json.Marshal(obj)
				if err != nil {
					http.Error(w, "Failed to marshal JSON", http.StatusInternalServerError)
					return
				}
				_, err = s3Client.PutObject(r.Context(), &s3.PutObjectInput{
					Bucket:        &bucketName,
					Key:           &key,
					Body:          io.NopCloser(strings.NewReader(string(data))),
					ContentLength: aws.Int64(int64(len(data))),
				})
				if err != nil {
					logrus.WithError(err).Error("Failed to put object in S3")
					http.Error(w, "Failed to store data", http.StatusInternalServerError)
					return
				}

			case http.MethodGet:
				resp, err := s3Client.GetObject(r.Context(), &s3.GetObjectInput{
					Bucket: &bucketName,
					Key:    &key,
				})
				if err != nil {
					if strings.Contains(err.Error(), "NoSuchKey") {
						http.NotFound(w, r)
					} else {
						logrus.WithError(err).Error("Failed to get object from S3")
						http.Error(w, "Failed to retrieve data", http.StatusInternalServerError)
					}
					return
				}
				defer resp.Body.Close()
				w.Header().Set("Content-Type", "application/json")
				if _, err := io.Copy(w, resp.Body); err != nil {
					logrus.WithError(err).Error("Failed to copy response body")
					http.Error(w, "Failed to read data", http.StatusInternalServerError)
					return
				}

			case http.MethodDelete:
				_, err := s3Client.DeleteObject(r.Context(), &s3.DeleteObjectInput{
					Bucket: &bucketName,
					Key:    &key,
				})
				if err != nil {
					if strings.Contains(err.Error(), "NoSuchKey") {
						http.NotFound(w, r)
					} else {
						logrus.WithError(err).Error("Failed to delete object from S3")
						http.Error(w, "Failed to delete data", http.StatusInternalServerError)
					}
					return
				}
				w.WriteHeader(http.StatusNoContent)

			default:
				http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
				return
			}
		}),
	}

	go func() {
		if err := s.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			panic(err)
		}
	}()

	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, os.Interrupt, syscall.SIGTERM)
	<-sigCh

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := s.Shutdown(ctx); err != nil {
		panic(err)
	}
}
