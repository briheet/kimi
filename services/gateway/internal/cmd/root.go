package cmd

import (
	"context"
	"errors"

	"github.com/briheet/kimi/infra/otel/otelgo"
	"github.com/joho/godotenv"
)

func Execute(ctx context.Context) error {

	_ = godotenv.Load()

	otelShutdown, err := otelgo.SetupOtelSDK(ctx)
	if err != nil {
		return err
	}

	defer func() {
		err = errors.Join(err, otelShutdown(ctx))
	}()

	return nil
}
