package main

import (
	mrand "math/rand"

	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	"github.com/rs/cors"
)

var addr = flag.String("addr", "localhost:8080/sockets", "http service address")

var upgrader = websocket.Upgrader{} // use default options
var clients = make(map[*websocket.Conn]bool)
var broadcast = make(chan Message)

type Message struct {
	messageType int
	message     []byte
}

func main() {
	log.Println("Starting server at port 8080\n")
	flag.Parse()
	log.SetFlags(0)

	router := mux.NewRouter()

	// Only log requests to our admin dashboard to stdout
	router.HandleFunc("/sockets", http.HandlerFunc(sockets)).Methods("GET")
	router.HandleFunc("/word", http.HandlerFunc(wordHandler)).Methods("POST")
	router.HandleFunc("/randomWord", http.HandlerFunc(randomWordHandler)).Methods("GET")
	go handleMessages()

	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"http://localhost:3000"},
		AllowCredentials: true,
	})

	handler := c.Handler(router)

	// Wrap our server with our gzip handler to gzip compress all responses.
	log.Fatal(http.ListenAndServe(":8080", handler))
}

var count = 0

func sockets(w http.ResponseWriter, req *http.Request) {
	log.Println(strconv.Itoa(count) + "\n")
	count++

	var upgrader = websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
		CheckOrigin: func(r *http.Request) bool {
			return true
		},
	}
	client, err := upgrader.Upgrade(w, req, nil)
	if err != nil {
		log.Println("FAILED!!!\n")
	}

	// receive message
	for {
		messageType, message, err := client.ReadMessage()
		if err != nil {
			delete(clients, client)
			log.Println("READING FAILURE!!!\n")
		}
		var msg Message
		msg.messageType = messageType
		msg.message = message
		broadcast <- msg
		clients[client] = true
	}

	defer client.Close()
}

func handleMessages() {
	log.Println("HANDLING MESSAGE\n")
	for {
		// Grab the next message from the broadcast channel
		params := <-broadcast
		// Send it out to every client that is currently connected
		for client := range clients {
			err := client.WriteMessage(params.messageType, params.message)
			if err != nil {
				log.Println("WRITING FAILURE!!!\n")
				log.Printf("error: %v", err)
				client.Close()
				delete(clients, client)
			}
		}
	}
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
	randomLine := mrand.Intn(nineLetterWords)
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
