package websocket

import (
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/websocket"

	"../common"
	"../multiplayer"
)

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
		var incData map[string]interface{}
		err := currentClient.ReadJSON(&incData)
		var msg common.Message
		if err != nil {
			_, currentMessage, errOpen := currentClient.ReadMessage()
			if errOpen != nil {
				log.Println("Error: %v", errOpen)
				delete(common.Clients, currentClient)
			}
			msg.EventType = "connected"
			msg.Data = currentMessage
		} else {
			msg.EventType = incData["eventType"].(string)
			msg.Data = incData["data"]
		}
		common.Broadcast <- msg
		var newClient common.Client
		newClient.PlayerID = fmt.Sprintf("%v", msg.Data)
		newClient.Searching = false
		common.Clients[currentClient] = newClient
	}
	defer currentClient.Close()
}

//HandleMessages handles all incoming web socket messages
func HandleMessages() {
	for {
		// Grab the next message from the broadcast channel
		params := <-common.Broadcast
		// Send it out to every client that is currently connected
		if params.EventType == "searching" {
			multiplayer.HandleSearch(params.Data, common.Clients)
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
