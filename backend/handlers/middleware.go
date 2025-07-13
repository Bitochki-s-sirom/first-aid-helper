package handlers

import (
	"bufio"
	"context"
	"first_aid_companion/controllers"
	"fmt"
	"log"
	"net"
	"net/http"
	"time"

	"github.com/rs/cors"
)

// CorsMiddleware enables CORS for all origins and standard HTTP methods/headers.
// This is essential for allowing cross-origin requests from frontend apps or clients.
var CorsMiddleware = cors.New(cors.Options{
	AllowedOrigins:   []string{"*"}, // Allow all origins (use specific domains in production)
	AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
	AllowedHeaders:   []string{"Content-Type", "Authorization"},
	AllowCredentials: true,
	Debug:            true, // Set to false in production to disable CORS debugging logs
})

// wrapWriter wraps http.ResponseWriter to support flushing and hijacking.
// Essential for AI reply streaming
type wrapWriter struct {
	http.ResponseWriter
}

// Flush allows manual flushing of the response (for streaming).
func (w *wrapWriter) Flush() {
	if f, ok := w.ResponseWriter.(http.Flusher); ok {
		f.Flush()
	}
}

// Hijack allows taking over the underlying connection
func (w *wrapWriter) Hijack() (net.Conn, *bufio.ReadWriter, error) {
	if h, ok := w.ResponseWriter.(http.Hijacker); ok {
		return h.Hijack()
	}
	return nil, nil, fmt.Errorf("underlying ResponseWriter does not support Hijacker")
}

// RequireUserMiddleware ensures the incoming request has a valid JWT token.
// If valid, user claims are added to the request context.
func RequireUserMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Extract JWT token from the Authorization header
		tokenStr, err := controllers.ExtractTokenFromHeader(r)
		if err != nil {
			controllers.WriteError(w, 409, "no token")
			return
		}

		// Validate and parse the JWT token
		claims, err := controllers.ParseJWT(tokenStr)
		if err != nil {
			controllers.WriteError(w, 409, "Invalid token: "+err.Error())
			return
		}

		// Add claims to the request context
		ctx := context.WithValue(r.Context(), "user", claims)

		// Use custom wrapWriter for flush/hijack support
		ww := &wrapWriter{ResponseWriter: w}

		// Call the next handler with updated context
		next.ServeHTTP(ww, r.WithContext(ctx))
	})
}

// loggingResponseWriter is a wrapper that captures the HTTP status code for logging purposes.
type loggingResponseWriter struct {
	http.ResponseWriter
	statusCode int // Captured status code
}

// WriteHeader overrides the default method to store the status code before writing the header.
func (lrw *loggingResponseWriter) WriteHeader(code int) {
	lrw.statusCode = code
	lrw.ResponseWriter.WriteHeader(code)
}

// LoggingMiddleware logs method, path, status, duration, and remote IP of each HTTP request.
func LoggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		// Initialize custom response writer with default status OK (200)
		lrw := &loggingResponseWriter{ResponseWriter: w, statusCode: http.StatusOK}

		// Call the next middleware/handler
		next.ServeHTTP(lrw, r)

		// Log all relevant request/response data
		log.Printf(
			"Request: %s %s, Status: %d, Duration: %v, RemoteAddr: %s",
			r.Method,
			r.RequestURI,
			lrw.statusCode,
			time.Since(start),
			r.RemoteAddr,
		)
	})
}
