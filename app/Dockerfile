FROM golang:1.24.3-alpine3.21 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY main.go ./

# CGO_ENABLED=0 to build a statically-linked binary
# -ldflags '-w -s' to strip debugging information for smaller size
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o gds-hackathon \
    github.com/matheuscscp/gds-hackathon

FROM alpine:3.21

COPY --from=builder /app/gds-hackathon .

ENTRYPOINT ["./gds-hackathon"]
