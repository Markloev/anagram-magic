package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"

	"github.com/gorilla/mux"
	"github.com/rs/cors"

	"./websocket"
)

func main() {
	log.Println("Starting server at port 8080")

	router := mux.NewRouter()

	// Only log requests to our admin dashboard to stdout
	router.HandleFunc("/ws", http.HandlerFunc(websocket.WS)).Methods("GET")
	router.HandleFunc("/word", http.HandlerFunc(wordHandler)).Methods("POST")
	router.HandleFunc("/randomWord", http.HandlerFunc(randomWordHandler)).Methods("GET")
	go websocket.HandleMessages()

	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"http://localhost:3000"},
		AllowCredentials: true,
	})

	handler := c.Handler(router)

	// Wrap our server with our gzip handler to gzip compress all responses.
	log.Fatal(http.ListenAndServe(":8080", handler))
}

func wordHandler(w http.ResponseWriter, req *http.Request) {
	if err := req.ParseForm(); err != nil {
		fmt.Fprintf(w, "Error parsing request: %v", err)
		return
	}

	var word string
	err := json.NewDecoder(req.Body).Decode(&word)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	file, err := os.Open("words.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	validity := "invalid"
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		if word == scanner.Text() {
			validity = "valid"
			break
		}
	}

	fmt.Fprintf(w, validity)
}

func randomWordHandler(w http.ResponseWriter, req *http.Request) {
	if err := req.ParseForm(); err != nil {
		fmt.Fprintf(w, "Error parsing request: %v", err)
		return
	}

	const nineLetterWords = 57288
	randomLine := rand.Intn(nineLetterWords)
	file, err := os.Open("nine_letter_words.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	word := ""
	count := 0
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		if randomLine == count {
			word = scanner.Text()
			break
		}
		count++
	}

	// Do something with the Person struct...
	fmt.Fprintf(w, word)
}
