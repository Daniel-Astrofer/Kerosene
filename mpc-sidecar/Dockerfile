# Build Stage
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Install git, gcc (for tss-lib), and protobuf tools
RUN apk add --no-cache git build-base protoc protobuf-dev

# Install protoc generators
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

COPY go.mod go.sum* ./
RUN go mod download

COPY . .

# Generate gRPC Go files from the protobuf definition
RUN export PATH=$PATH:$(go env GOPATH)/bin && \
    protoc --go_out=. --go_opt=paths=source_relative \
           --go-grpc_out=. --go-grpc_opt=paths=source_relative \
           proto/mpc.proto

RUN go mod tidy

# Build the enclave sidecar (CGO enabled because of tss-lib math)
RUN CGO_ENABLED=1 GOOS=linux go build -o mpc_enclave main.go

# Production Run Stage
FROM alpine:latest

# Installs ca-certificates if calls to external APIs are needed and libc for CGO
RUN apk --no-cache add ca-certificates tzdata libc6-compat

WORKDIR /app
COPY --from=builder /app/mpc_enclave .

EXPOSE 50051

# Executa o binario de Go com zero dependencias
ENTRYPOINT ["/app/mpc_enclave"]
