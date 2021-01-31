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

//Clients stores a list of all clients connected via web socket
var Clients = make(map[*websocket.Conn]client)

//Broadcast handles messages received through web socket
var Broadcast = make(chan message)

type client struct {
	playerID  string
	searching bool
}

type message struct {
	eventType string
	data      data
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
	currentClient, err := upgrader.Upgrade(w, req, nil)
	if err != nil {
		log.Println("Error: %v", err)
	}

	// receive message
	for {
		var incData map[string]interface{}
		err := currentClient.ReadJSON(&incData)
		var msg message
		if err != nil {
			_, currentMessage, errOpen := currentClient.ReadMessage()
			if errOpen != nil {
				log.Println("Error: %v", errOpen)
				delete(Clients, currentClient)
			}
			msg.eventType = "connected"
			msg.data = currentMessage
		} else {
			msg.eventType = incData["eventType"].(string)
			msg.data = incData["data"]
		}
		Broadcast <- msg
		var newClient client
		newClient.playerID = fmt.Sprintf("%v", msg.data)
		newClient.searching = false
		Clients[currentClient] = newClient
	}
	defer currentClient.Close()
}

//SearchingDefaultMessage returns that the user is still searching
type SearchingDefaultMessage struct {
	EventType string
}

//SearchingReturnMessage returns the opponent a player will match
type SearchingReturnMessage struct {
	EventType string
	Data      SearchingReturnData
}

//SearchingReturnData stores the opponent PlayerID
type SearchingReturnData struct {
	PlayerID string
}

func handleMessages() {
	for {
		// Grab the next message from the broadcast channel
		params := <-Broadcast
		// Send it out to every client that is currently connected
		found := false
		if params.eventType == "searching" {
			playerID := fmt.Sprintf("%v", params.data)
			for client := range Clients {
				log.Println(playerID)
				log.Println(Clients[client].playerID)
				if Clients[client].playerID != playerID && Clients[client].searching {
					found = true
					currentPlayerReturnJSON := SearchingReturnMessage{
						EventType: "playerFound",
						Data: SearchingReturnData{
							PlayerID: playerID,
						},
					}
					foundPlayerReturnJSON := SearchingReturnMessage{
						EventType: "playerFound",
						Data: SearchingReturnData{
							PlayerID: Clients[client].playerID,
						},
					}
					if thisClient, ok := Clients[client]; ok {
						thisClient.searching = false
						Clients[client] = thisClient
					}
					for client := range Clients {
						if Clients[client].playerID == playerID {
							if thisClient, ok := Clients[client]; ok {
								thisClient.searching = false
								Clients[client] = thisClient
								jsonErr := client.WriteJSON(currentPlayerReturnJSON)
								if jsonErr != nil {
									log.Printf("Error: %v", jsonErr)
									client.Close()
									delete(Clients, client)
								}
							}
						}
					}
					log.Println("Wow, we are here")
					jsonErr := client.WriteJSON(foundPlayerReturnJSON)
					if jsonErr != nil {
						log.Printf("Error: %v", jsonErr)
						client.Close()
						delete(Clients, client)
					}
				}
			}
			if !found {
				for searchingClient := range Clients {
					if Clients[searchingClient].playerID == playerID {
						if thisClient, ok := Clients[searchingClient]; ok {
							thisClient.searching = true
							Clients[searchingClient] = thisClient
						}
						searchingJSON := SearchingDefaultMessage{
							EventType: "searching",
						}
						err := searchingClient.WriteJSON(searchingJSON)
						if err != nil {
							log.Printf("Error: %v", err)
							searchingClient.Close()
							delete(Clients, searchingClient)
						}
					}
				}
			}
		} else {
			for client := range Clients {
				err := client.WriteJSON(params.data)
				if err != nil {
					log.Printf("Error: %v", err)
					client.Close()
					delete(Clients, client)
				}
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
