package main

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"log"
	"net"
	"os"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/reflection"

	pb "mpc-sidecar/proto"
	"mpc-sidecar/service"
)

func main() {
	// Secure Boot / Enclave initialization (tmpfs shard loading)
	err := service.InitSecureEnclave()
	if err != nil {
		log.Fatalf("Secure Enclave initialization failed: %v", err)
	}

	lis, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatalf("failed to listen: %v", err)
	}

	s, err := newGrpcServer()
	if err != nil {
		log.Fatalf("failed to configure gRPC server: %v", err)
	}
	pb.RegisterMpcServiceServer(s, &service.MpcService{})
	if os.Getenv("MPC_ENABLE_REFLECTION") == "true" || os.Getenv("MPC_ALLOW_INSECURE_GRPC") == "true" {
		reflection.Register(s)
	}

	log.Printf("MPC Sidecar listening on %v", lis.Addr())
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}

func newGrpcServer() (*grpc.Server, error) {
	if os.Getenv("MPC_ALLOW_INSECURE_GRPC") == "true" {
		log.Println("[MPC] WARNING: plaintext gRPC enabled by MPC_ALLOW_INSECURE_GRPC=true")
		return grpc.NewServer(), nil
	}

	certFile := os.Getenv("MPC_TLS_CERT_FILE")
	keyFile := os.Getenv("MPC_TLS_KEY_FILE")
	caFile := os.Getenv("MPC_TLS_CA_FILE")
	if certFile == "" || keyFile == "" || caFile == "" {
		return nil, fmt.Errorf("mTLS is required; set MPC_TLS_CERT_FILE, MPC_TLS_KEY_FILE and MPC_TLS_CA_FILE")
	}

	cert, err := tls.LoadX509KeyPair(certFile, keyFile)
	if err != nil {
		return nil, fmt.Errorf("failed to load server certificate/key: %w", err)
	}

	caPEM, err := os.ReadFile(caFile)
	if err != nil {
		return nil, fmt.Errorf("failed to read client CA file: %w", err)
	}

	clientCAs := x509.NewCertPool()
	if !clientCAs.AppendCertsFromPEM(caPEM) {
		return nil, fmt.Errorf("failed to parse client CA file")
	}

	tlsConfig := &tls.Config{
		Certificates: []tls.Certificate{cert},
		ClientCAs:    clientCAs,
		ClientAuth:   tls.RequireAndVerifyClientCert,
		MinVersion:   tls.VersionTLS13,
	}

	return grpc.NewServer(grpc.Creds(credentials.NewTLS(tlsConfig))), nil
}
