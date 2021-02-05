package multiplayer

import (
	"encoding/json"
	"log"

	"github.com/gorilla/websocket"

	"../common"
)

//HandleRoundComplete sends message to both clients to start timers for "Round Complete" phase
func HandleRoundComplete(paramsData []byte, clients map[*websocket.Conn]common.Client) {
	var currentPlayerID string
	jsonErr := json.Unmarshal(paramsData, &currentPlayerID)
	if jsonErr != nil {
		log.Printf("Error: %v", jsonErr)
	}
	//loop through list of clients to find current client and opponent client
	for client := range clients {
		if clients[client].OpponentID == currentPlayerID {
			if clients[client].NextRound {
				returnJSON := common.CreateBasicReturnMessageJSON("roundComplete")
				if thisClient, ok := clients[client]; ok {
					thisClient.NextRound = false
					clients[client] = thisClient
				}
				//get current client and update in order to start timer for "Round Complete" phase
				for client2 := range clients {
					if clients[client2].PlayerID == currentPlayerID {
						jsonErr := client2.WriteJSON(returnJSON)
						if jsonErr != nil {
							log.Printf("Error: %v", jsonErr)
							client2.Close()
							delete(clients, client2)
						}
					}
				}

				//get opponent client and update in order to start timer for "Round Complete" phase
				jsonErr := client.WriteJSON(returnJSON)
				if jsonErr != nil {
					log.Printf("Error: %v", jsonErr)
					client.Close()
					delete(clients, client)
				}
			} else {
				//if opponent hasn't selected "Next Round" yet, set the current user's NextRound status to true
				for searchingClient := range clients {
					if clients[searchingClient].PlayerID == currentPlayerID {
						if thisClient, ok := clients[searchingClient]; ok {
							thisClient.NextRound = true
							clients[searchingClient] = thisClient
						}
					}
				}
			}
		}
	}
}
