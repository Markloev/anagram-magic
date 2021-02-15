package main

import (
	"log"
	"net/http"

	"github.com/gorilla/mux"
	"github.com/rs/cors"

	"github.com/markloev/anagram-magic/websocket"
)

func main() {
	log.Println("Starting server at port 8080")

	router := mux.NewRouter()

	router.HandleFunc("/ws", http.HandlerFunc(websocket.WS)).Methods("GET")
	go websocket.HandleMessages()

	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"http://localhost:3000"},
		AllowCredentials: true,
	})

	handler := c.Handler(router)

	log.Fatal(http.ListenAndServe(":8080", handler))
}
