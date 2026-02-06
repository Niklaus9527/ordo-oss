.PHONY: test e2e demo

test:
	go test ./...

demo:
	cd examples/mock-server && docker compose up --build -d
	@echo "Mock server started."
	@echo "Start Ordo: ordo server --config configs/ordo.example.yaml"

e2e:
	@echo "E2E placeholder for v0.1. Add tests/e2e later."
