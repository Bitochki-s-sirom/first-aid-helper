package handlers

import (
	"context"
	"first_aid_companion/controllers"
	"net/http"
)

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
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}
