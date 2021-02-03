package multiplayer

import (
	"encoding/json"
	"log"

	"github.com/gorilla/websocket"

	"../common"
)

//HandleSubmitTurn handles notifying the opponent that the opponent has finished their turn
func HandleSubmitTurn(paramsData []byte, clients map[*websocket.Conn]common.Client) {
	var currentPlayerID string
	jsonErr := json.Unmarshal(paramsData, &currentPlayerID)
	if jsonErr != nil {
		log.Printf("Error: %v", jsonErr)
	}
	//loop through list of clients
	for client := range clients {
		//if other client is matched against current client
		if clients[client].OpponentID == currentPlayerID {
			if clients[client].TurnSubmitted {
				if thisClient, ok := clients[client]; ok {
					thisClient.TurnSubmitted = false
					clients[client] = thisClient
				}
				returnJSON := common.CreateBasicReturnMessageJSON("changePhase")
				//update opponent client of phase change
				currentErr := client.WriteJSON(returnJSON)
				if currentErr != nil {
					log.Printf("Error: %v", currentErr)
					client.Close()
					delete(clients, client)
				}
				for searchingClient := range clients {
					if clients[searchingClient].PlayerID == currentPlayerID {
						//update current player of phase change
						err := searchingClient.WriteJSON(returnJSON)
						if err != nil {
							log.Printf("Error: %v", err)
							client.Close()
							delete(clients, client)
						}
					}
				}
			} else {
				for searchingClient := range clients {
					if clients[searchingClient].PlayerID == currentPlayerID {
						if thisClient, ok := clients[searchingClient]; ok {
							thisClient.TurnSubmitted = true
							clients[searchingClient] = thisClient
						}
					}
				}
				opponentPlayerReturnJSON := common.CreateBasicReturnMessageJSON("submitTurn")
				//update opponent client of turn submit
				err := client.WriteJSON(opponentPlayerReturnJSON)
				if err != nil {
					log.Printf("Error: %v", err)
					client.Close()
					delete(clients, client)
				}
			}
		}
	}
}
