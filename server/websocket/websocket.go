package websocket

import (
	"encoding/json"
	"log"
	"net/http"

	"github.com/gorilla/websocket"

	"../common"
	"../multiplayer"
)

type incomingMessage struct {
	eventType string `json:"eventType"`
	data      []byte `json:"data"`
}

//WS handles opening of web socket
func WS(w http.ResponseWriter, req *http.Request) {
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

	for {
		var incMessage common.Message
		err := currentClient.ReadJSON(&incMessage)
		var msg common.Message
		var currentPlayerID string
		if err != nil {
			_, currentMessage, errOpen := currentClient.ReadMessage()
			if errOpen != nil {
				log.Println("Error: %v", errOpen)
				delete(common.Clients, currentClient)
			}
			msg.EventType = "connected"
			msg.Data = currentMessage
		} else {
			msg.EventType = incMessage.EventType
			msg.Data = incMessage.Data
		}
		common.Broadcast <- msg
		// if msg.EventType == "searching" {
		var newClient common.Client
		jsonErr := json.Unmarshal(msg.Data, &currentPlayerID)
		if jsonErr != nil {
			log.Printf("Error: %v", jsonErr)
		}
		newClient.PlayerID = currentPlayerID
		newClient.OpponentID = ""
		newClient.Searching = false
		defer currentClient.Close()
		common.Clients[currentClient] = newClient
		// }
	}
}

//HandleMessages handles all incoming web socket messages
func HandleMessages() {
	for {
		// Grab the next message from the broadcast channel
		params := <-common.Broadcast
		// Send it out to every client that is currently connected
		if params.EventType == "searching" {
			multiplayer.HandleSearch(params.Data, common.Clients)
		} else if params.EventType == "changePhase" {
			multiplayer.HandleChangePhase(params.Data, common.Clients)
		} else {
			for client := range common.Clients {
				err := client.WriteJSON(params.Data)
				if err != nil {
					log.Printf("Error: %v", err)
					client.Close()
					delete(common.Clients, client)
				}
			}
		}
	}
}
