package multiplayer

import (
	"fmt"
	"log"

	"github.com/gorilla/websocket"

	"../common"
)

type searchingReturnData struct {
	PlayerID string
}

//HandleSearch handles return message to player that is searching for a game
func HandleSearch(paramsData interface{}, clients map[*websocket.Conn]common.Client) {
	found := false
	currentPlayerID := fmt.Sprintf("%v", paramsData)
	//loop through list of clients and look for another client that is searching
	for client := range clients {
		//if it is another client and they are also searching
		if clients[client].PlayerID != currentPlayerID && clients[client].Searching {
			found = true
			foundPlayerReturnJSON := createSearchingReturnMessageJSON(clients[client].PlayerID)
			currentPlayerReturnJSON := createSearchingReturnMessageJSON(currentPlayerID)
			//get current client and update to say they are no longer searching and also return the opposing playerID
			for client := range clients {
				if clients[client].PlayerID == currentPlayerID {
					if thisClient, ok := clients[client]; ok {
						thisClient.Searching = false
						clients[client] = thisClient
						jsonErr := client.WriteJSON(foundPlayerReturnJSON)
						if jsonErr != nil {
							log.Printf("Error: %v", jsonErr)
							client.Close()
							delete(clients, client)
						}
					}
				}
			}
			//update opponent client to say they are no longer searching and also return the opposing playerID
			if thisClient, ok := clients[client]; ok {
				thisClient.Searching = false
				clients[client] = thisClient
			}
			jsonErr := client.WriteJSON(currentPlayerReturnJSON)
			if jsonErr != nil {
				log.Printf("Error: %v", jsonErr)
				client.Close()
				delete(clients, client)
			}
		}
	}
	//if no other player was found when search is initiated, set the current users searching status to true
	if !found {
		for searchingClient := range clients {
			if clients[searchingClient].PlayerID == currentPlayerID {
				if thisClient, ok := clients[searchingClient]; ok {
					thisClient.Searching = true
					clients[searchingClient] = thisClient
				}
			}
		}
	}
}

func createSearchingReturnMessageJSON(playerID string) common.DefaultReturnMessage {
	returnJSON := common.DefaultReturnMessage{
		EventType: "playerFound",
		Data: searchingReturnData{
			PlayerID: playerID,
		},
	}
	return returnJSON
}
