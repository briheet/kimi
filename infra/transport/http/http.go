package http

import (
	"context"
	"net"
	"net/http"
	"time"
)

type Options func(*http.Server)

func NewAddrString(addr string) func(*http.Server) {
	return func(srv *http.Server) {
		srv.Addr = addr
	}
}

func NewReadTimeout(readTimeout time.Duration) func(*http.Server) {
	return func(srv *http.Server) {
		srv.ReadTimeout = readTimeout
	}
}

func NewWriteTimeout(writeTimeout time.Duration) func(*http.Server) {
	return func(srv *http.Server) {
		srv.WriteTimeout = writeTimeout
	}
}

func NewBaseContext(ctx context.Context) func(*http.Server) {
	return func(srv *http.Server) {
		srv.BaseContext = func(_ net.Listener) context.Context { return ctx }
	}
}

func NewHandler(handler http.Handler) func(*http.Server) {
	return func(srv *http.Server) {
		srv.Handler = handler
	}
}

func NewHttpServer(opts ...Options) *http.Server {

	httpServer := &http.Server{}

	for _, option := range opts {
		option(httpServer)
	}

	return httpServer
}
