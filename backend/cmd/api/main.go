package main

import (
	"context"
	"log"
	"net/http"
	"os/signal"
	"syscall"
	"time"

	"cursorubcar/backend/internal/api"
	"cursorubcar/backend/internal/config"
	"cursorubcar/backend/internal/repository"
	"cursorubcar/backend/internal/service"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatal(err)
	}

	postgresRepo, err := repository.NewPostgresRepository(cfg.PostgresDSN)
	if err != nil {
		log.Fatal(err)
	}
	defer postgresRepo.Close()

	mongoRepo, err := repository.NewMongoRepository(cfg.MongoURI, cfg.MongoDatabase)
	if err != nil {
		log.Fatal(err)
	}
	defer mongoRepo.Close(context.Background())

	cacheRepo, err := repository.NewCacheRepository(cfg.RedisAddr, cfg.RedisPassword, cfg.RedisDB)
	if err != nil {
		log.Fatal(err)
	}
	defer cacheRepo.Close()

	authService := service.NewAuthService(cfg.JWTSecret, cacheRepo, postgresRepo)
	server := api.NewServer(postgresRepo, mongoRepo, cacheRepo, authService)

	httpServer := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           server.Routes(),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      15 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	go func() {
		log.Printf("backend listening on http://localhost:%s", cfg.Port)
		if err := httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatal(err)
		}
	}()

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()
	<-ctx.Done()

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := httpServer.Shutdown(shutdownCtx); err != nil {
		log.Printf("shutdown error: %v", err)
	}
}
