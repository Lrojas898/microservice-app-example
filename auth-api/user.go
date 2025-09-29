package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"time"

	jwt "github.com/dgrijalva/jwt-go"
)

var allowedUserHashes = map[string]interface{}{
	"admin_admin": nil,
	"johnd_foo":   nil,
	"janed_ddd":   nil,
}

type User struct {
	Username  string `json:"username"`
	FirstName string `json:"firstname"`
	LastName  string `json:"lastname"`
	Role      string `json:"role"`
}

type HTTPDoer interface {
	Do(req *http.Request) (*http.Response, error)
}

type UserService struct {
	Client            HTTPDoer
	UserAPIAddress    string
	AllowedUserHashes map[string]interface{}
}

func (h *UserService) Login(ctx context.Context, username, password string) (User, error) {
	user, err := h.getUser(ctx, username)
	if err != nil {
		return user, err
	}

	userKey := fmt.Sprintf("%s_%s", username, password)

	if _, ok := h.AllowedUserHashes[userKey]; !ok {
		return user, ErrWrongCredentials // this is BAD, business logic layer must not return HTTP-specific errors
	}

	return user, nil
}

func (h *UserService) getUser(ctx context.Context, username string) (User, error) {
	var user User

	log.Printf("DEBUG: Getting user %s, UserAPIAddress: %s", username, h.UserAPIAddress)

	token, err := h.getUserAPIToken(username)
	if err != nil {
		log.Printf("DEBUG: Token generation failed: %v", err)
		return user, err
	}

	url := fmt.Sprintf("%s/users/%s", h.UserAPIAddress, username)
	log.Printf("DEBUG: Making request to URL: %s", url)

	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		log.Printf("DEBUG: NewRequest failed: %v", err)
		return user, err
	}
	req.Header.Add("Authorization", "Bearer "+token)

	req = req.WithContext(ctx)

	log.Printf("DEBUG: About to make HTTP request...")
	resp, err := h.Client.Do(req)
	if err != nil {
		log.Printf("DEBUG: HTTP request failed: %v", err)
		return user, err
	}
	log.Printf("DEBUG: HTTP request successful, status: %s", resp.Status)

	defer resp.Body.Close()
	bodyBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return user, err
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		log.Printf("DEBUG: HTTP %d response body: %s", resp.StatusCode, string(bodyBytes))
		return user, fmt.Errorf("could not get user data: %s", string(bodyBytes))
	}

	err = json.Unmarshal(bodyBytes, &user)

	return user, err
}

func (h *UserService) getUserAPIToken(username string) (string, error) {
	token := jwt.New(jwt.SigningMethodHS256)
	claims := token.Claims.(jwt.MapClaims)
	claims["username"] = username
	claims["scope"] = "read"
	claims["exp"] = time.Now().Add(time.Hour).Unix() // Expira en 1 hora
	return token.SignedString([]byte(jwtSecret))
}
