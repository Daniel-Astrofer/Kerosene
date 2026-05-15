package main

import (
	"log"
	"net"

	"google.golang.org/grpc"
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

	s := grpc.NewServer()
	pb.RegisterMpcServiceServer(s, &service.MpcService{})
	reflection.Register(s)

	log.Printf("MPC Sidecar listening on %v", lis.Addr())
	if err := s.Serve(lis); err != nil {
		log.Fatalf("failed to serve: %v", err)
	}
}
