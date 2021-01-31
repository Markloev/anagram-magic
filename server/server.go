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
	// "reflect"

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
	client, err := upgrader.Upgrade(w, req, nil)
	if err != nil {
		log.Println("FAILED!!!")
	}

	// receive message
	for {
		var incData map[string]interface{}
		err := client.ReadJSON(&incData)
		var msg Message
		if err != nil {
			_, message, errOpen := client.ReadMessage()
			if errOpen != nil {
				log.Println("READING FAILURE!!!")
				delete(clients, client)
			}
			msg.eventType = "connected"
			msg.data = message
		} else {
			msg.eventType = incData["eventType"].(string)
			msg.data = incData["data"]
		}
		broadcast <- msg
		var newClient Client
		newClient.playerID = fmt.Sprintf("%v", msg.data)
		newClient.searching = false
		clients[client] = newClient

		// var incData map[string]interface{}
		// err := client.ReadJSON(&incData)
		// var msg Message
		// if err != nil {
		// 	_, message, errOpen := client.ReadMessage()
		// 	if errOpen != nil {
		// 		log.Println("READING FAILURE!!!")
		// 		delete(clients, client)
		// 	}
		// 	msg.eventType = "connected"
		// 	msg.data = message
		// } else {
		// 	msg.eventType = incData["eventType"].(string)
		// 	msg.data = incData["data"]
		// }
		// broadcast <- msg
		// var newClient Client
		// newClient.playerID = ""
		// newClient.searching = false
		// clients[client] = newClient
	}
	defer client.Close()
}

type SearchingDefaultMessage struct {
	EventType string
}

type SearchingReturnMessage struct {
	EventType string
	Data      SearchingReturnData
}

type SearchingReturnData struct {
	PlayerID string
}

func handleMessages() {
	log.Println("HANDLING MESSAGE")
	for {
		// Grab the next message from the broadcast channel
		params := <-broadcast
		// Send it out to every client that is currently connected
		found := false
		if params.eventType == "searching" {
			playerID := fmt.Sprintf("%v", params.data)
			for client := range clients {
				log.Println(playerID)
				log.Println(clients[client].playerID)
				if clients[client].playerID != playerID && clients[client].searching {
					found = true
					currentPlayerReturnJSONPrep := SearchingReturnMessage{
						EventType: "playerFound",
						Data: SearchingReturnData{
							PlayerID: playerID,
						},
					}
					// currentPlayerJSONData, err := json.Marshal(currentPlayerReturnJSONPrep)
					// log.Printf(string(currentPlayerJSONData))

					// if err != nil {
					// 	log.Printf("Error marshalling return data...")
					// }
					foundPlayerReturnJSONPrep := SearchingReturnMessage{
						EventType: "playerFound",
						Data: SearchingReturnData{
							PlayerID: clients[client].playerID,
						},
					}
					// foundPlayerJSONData, err := json.Marshal(foundPlayerReturnJSONPrep)
					// if err != nil {
					// 	log.Printf("Error marshalling return data...")
					// }
					if thisClient, ok := clients[client]; ok {
						thisClient.searching = false
						clients[client] = thisClient
					}
					for client := range clients {
						if clients[client].playerID == playerID {
							if thisClient, ok := clients[client]; ok {
								thisClient.searching = false
								clients[client] = thisClient
								jsonErr := client.WriteJSON(currentPlayerReturnJSONPrep)
								if jsonErr != nil {
									log.Printf("error: %v", jsonErr)
									client.Close()
									delete(clients, client)
								}
							}
						}
					}
					log.Println("Wow, we are here")
					jsonErr := client.WriteJSON(foundPlayerReturnJSONPrep)
					if jsonErr != nil {
						log.Printf("error: %v", jsonErr)
						client.Close()
						delete(clients, client)
					}
				}
			}
			if !found {
				for searchingClient := range clients {
					if clients[searchingClient].playerID == playerID {
						if thisClient, ok := clients[searchingClient]; ok {
							thisClient.searching = true
							clients[searchingClient] = thisClient
						}
						searchingJSON := SearchingDefaultMessage{
							EventType: "searching",
						}
						err := searchingClient.WriteJSON(searchingJSON)
						if err != nil {
							log.Printf("error: %v", err)
							searchingClient.Close()
							delete(clients, searchingClient)
						}
					}
				}
			}
		} else {
			for client := range clients {
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
