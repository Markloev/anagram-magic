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

	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	"github.com/rs/cors"
)

var addr = flag.String("addr", "localhost:8080/sockets", "http service address")

var upgrader = websocket.Upgrader{} // use default options
var clients = make(map[*websocket.Conn]Client)
var searchingIDs []string
var broadcast = make(chan Message)

type Client struct {
	playerID  string
	searching bool
}

type Message struct {
	eventType string
	data      []byte
}

type data interface{}

func main() {
	log.Println("Starting server at port 8080")
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
	var upgrader = websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
		CheckOrigin: func(r *http.Request) bool {
			return true
		},
	}
	client, err := upgrader.Upgrade(w, req, nil)
	if err != nil {
		log.Println("FAILED!!!")
	}

	// receive message
	for {
		var msg Message
		err := client.ReadJSON(&msg)
		if err != nil {
			_, message, errOpen := client.ReadMessage()
			if errOpen != nil {
				log.Println("READING FAILURE!!!")
				delete(clients, client)
			}
			msg.eventType = "connected"
			msg.data = message
		}
		broadcast <- msg
		var newClient Client
		newClient.playerID = ""
		newClient.searching = false
		clients[client] = newClient
	}
	defer client.Close()
}

type SearchingReturnMessage struct {
	event string
	data  SearchingReturnData
}

type SearchingReturnData struct {
	playerID string
}

func handleMessages() {
	log.Println("HANDLING MESSAGE")
	for {
		// Grab the next message from the broadcast channel
		params := <-broadcast
		// Send it out to every client that is currently connected
		if params.eventType == "searching" {
			var returnData SearchingReturnData
			err := json.Unmarshal(params.data, &returnData)
			if err != nil {
				log.Printf("Error parsing search...")
			} else {
				searchResult := handleSearching(returnData.playerID)
				for client := range clients {
					if !searchResult.searching {
						if clients[client].playerID == searchResult.playerID || clients[client].playerID == returnData.playerID {
							m := SearchingReturnMessage{"playerFound", SearchingReturnData{searchResult.playerID}}
							jsonData, err := json.Marshal(m)
							if err != nil {
								log.Printf("Error marshalling return data...")
							}
							jsonErr := client.WriteJSON(jsonData)
							if jsonErr != nil {
								log.Printf("error: %v", err)
								client.Close()
								delete(clients, client)
							}
						}
					} else if clients[client].playerID == returnData.playerID {
						err := client.WriteJSON("searching")
						if err != nil {
							log.Printf("error: %v", err)
							client.Close()
							delete(clients, client)
						}
					}
				}
			}
		} else {
			for client := range clients {
				log.Println("DATA:")
				log.Println(params.eventType)
				log.Println(params.data)
				err := client.WriteJSON(params.data)
				if err != nil {
					log.Printf("error: %v", err)
					client.Close()
					delete(clients, client)
				}
			}
		}
	}
}

func removeSliceElement(s []string, i int) []string {
	s[len(s)-1], s[i] = s[i], s[len(s)-1]
	return s[:len(s)-1]
}

type SearchResult struct {
	searching bool
	playerID  string
}

func handleSearching(playerID string) SearchResult {
	var searchResult SearchResult
	if len(searchingIDs) > 0 {
		searchResult.playerID = searchingIDs[0]
		searchResult.searching = false
		searchingIDs = removeSliceElement(searchingIDs, 0)
		return searchResult
	} else {
		searchingIDs = append(searchingIDs, playerID)
		searchResult.playerID = playerID
		searchResult.searching = true
		return searchResult
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
