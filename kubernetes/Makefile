.PHONY: bootstrap
bootstrap:
	helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
		--namespace flux-system \
		--create-namespace
	kubectl apply -f clusters/gds-hackathon/flux-system/sync/fluxinstance.yaml
