package websocket

import (
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
		log.Fatal("Error: %v", err)
	}
	defer currentClient.Close()
	playerID, ok := req.URL.Query()["playerId"]
	if !ok || len(playerID[0]) < 1 {
		log.Printf("Url Param 'playerId' is missing")
		return
	}
	var newClient common.Client
	newClient.PlayerID = playerID[0]
	newClient.OpponentID = ""
	newClient.Searching = false
	newClient.TurnSubmitted = false
	newClient.Tiles = nil
	common.Clients[currentClient] = newClient

	for {
		var incMessage common.Message
		err := currentClient.ReadJSON(&incMessage)
		if err != nil {
			log.Printf("Error: %v", err)
			delete(common.Clients, currentClient)
			break
		}
		var msg common.Message
		msg.EventType = incMessage.EventType
		msg.Data = incMessage.Data
		common.Broadcast <- msg
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
		} else if params.EventType == "receiveTiles" {
			multiplayer.HandleReceiveTiles(params.Data, common.Clients)
		} else if params.EventType == "submitTurn" {
			multiplayer.HandleSubmitTurn(params.Data, common.Clients)
		} else if params.EventType == "changeTiles" {
			multiplayer.HandleChangeTiles(params.Data, common.Clients)
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
