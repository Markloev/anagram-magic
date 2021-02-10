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
		log.Printf("Error: %v", err)
	}

	defer currentClient.Close()

	playerID, ok := req.URL.Query()["playerId"]
	if !ok || len(playerID[0]) < 1 {
		log.Printf("Url Param 'playerId' is missing")
		return
	}
	common.Clients[currentClient] = common.CreateNewClient(playerID[0])

	for {
		var incMessage common.Message
		err := currentClient.ReadJSON(&incMessage)
		if err != nil {
			log.Printf("Error HERE: %v", err)
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

		if params.EventType == "startSearch" {
			multiplayer.HandleSearch(params.Data)
		} else if params.EventType == "stopSearch" {
			multiplayer.HandleStopSearch(params.Data)
		} else if params.EventType == "receiveTiles" {
			multiplayer.HandleReceiveTiles(params.Data)
		} else if params.EventType == "submitTurn" {
			multiplayer.HandleSubmitTurn(params.Data)
		} else if params.EventType == "changeTiles" {
			multiplayer.HandleChangeTiles(params.Data)
		} else if params.EventType == "roundComplete" {
			multiplayer.HandleRoundComplete(params.Data)
		} else if params.EventType == "endGame" {
			multiplayer.HandleEndGame(params.Data)
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
