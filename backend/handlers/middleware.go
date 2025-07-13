package handlers

import (
	"bufio"
	"context"
	"first_aid_companion/controllers"
	"fmt"
	"net"
	"net/http"
)

type wrapWriter struct {
	http.ResponseWriter
}

func (w *wrapWriter) Flush() {
	if f, ok := w.ResponseWriter.(http.Flusher); ok {
		f.Flush()
	}
}

// You may also want to forward Hijacker and CloseNotifier if needed:
func (w *wrapWriter) Hijack() (net.Conn, *bufio.ReadWriter, error) {
	if h, ok := w.ResponseWriter.(http.Hijacker); ok {
		return h.Hijack()
	}
	return nil, nil, fmt.Errorf("underlying ResponseWriter does not support Hijacker")
}

func RequireUserMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		tokenStr, err := controllers.ExtractTokenFromHeader(r)
		if err != nil {
			controllers.WriteError(w, 409, "no token")
			return
		}

		claims, err := controllers.ParseJWT(tokenStr)
		if err != nil {
			controllers.WriteError(w, 409, "Invalid token: "+err.Error())
			return
		}

		ctx := context.WithValue(r.Context(), "user", claims)
		ww := &wrapWriter{ResponseWriter: w}
		next.ServeHTTP(ww, r.WithContext(ctx))
	})
}
