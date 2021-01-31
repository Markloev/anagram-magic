package multiplayer

import (
	"fmt"
	"log"

	"github.com/gorilla/websocket"

	"../common"
)

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

//HandleSearch handles return message to player that is searching for a game
func HandleSearch(paramsData interface{}, clients map[*websocket.Conn]common.Client) {
	found := false
	playerID := fmt.Sprintf("%v", paramsData)
	for client := range clients {
		if clients[client].PlayerID != playerID && clients[client].Searching {
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
					PlayerID: clients[client].PlayerID,
				},
			}
			if thisClient, ok := clients[client]; ok {
				thisClient.Searching = false
				clients[client] = thisClient
			}
			for client := range clients {
				if clients[client].PlayerID == playerID {
					if thisClient, ok := clients[client]; ok {
						thisClient.Searching = false
						clients[client] = thisClient
						jsonErr := client.WriteJSON(currentPlayerReturnJSON)
						if jsonErr != nil {
							log.Printf("Error: %v", jsonErr)
							client.Close()
							delete(clients, client)
						}
					}
				}
			}
			jsonErr := client.WriteJSON(foundPlayerReturnJSON)
			if jsonErr != nil {
				log.Printf("Error: %v", jsonErr)
				client.Close()
				delete(clients, client)
			}
		}
	}
	if !found {
		for searchingClient := range clients {
			if clients[searchingClient].PlayerID == playerID {
				if thisClient, ok := clients[searchingClient]; ok {
					thisClient.Searching = true
					clients[searchingClient] = thisClient
				}
				searchingJSON := SearchingDefaultMessage{
					EventType: "searching",
				}
				err := searchingClient.WriteJSON(searchingJSON)
				if err != nil {
					log.Printf("Error: %v", err)
					searchingClient.Close()
					delete(clients, searchingClient)
				}
			}
		}
	}
}
