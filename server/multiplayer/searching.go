package multiplayer

import (
	"encoding/json"
	"log"

	"github.com/gorilla/websocket"

	"../common"
)

type searchingReturnData struct {
	PlayerID          string
	TileSelectionTurn bool
}

//HandleSearch handles return message to player that is searching for a game
func HandleSearch(paramsData []byte, clients map[*websocket.Conn]common.Client) {
	found := false
	var currentPlayerID string
	jsonErr := json.Unmarshal(paramsData, &currentPlayerID)
	if jsonErr != nil {
		log.Printf("Error: %v", jsonErr)
	}
	//loop through list of clients and look for another client that is searching
	for client := range clients {
		//if it is another client and they are also searching
		if clients[client].PlayerID != currentPlayerID && clients[client].Searching {
			found = true
			foundPlayerReturnJSON := createSearchingReturnMessageJSON(clients[client].PlayerID, true)
			currentPlayerReturnJSON := createSearchingReturnMessageJSON(currentPlayerID, false)
			//get current client and update to say they are no longer searching and also return the opposing playerID
			for client2 := range clients {
				if clients[client2].PlayerID == currentPlayerID {
					if thisClient, ok := clients[client2]; ok {
						thisClient.Searching = false
						thisClient.OpponentID = clients[client].PlayerID
						clients[client2] = thisClient
						jsonErr := client2.WriteJSON(foundPlayerReturnJSON)
						if jsonErr != nil {
							log.Printf("Error: %v", jsonErr)
							client2.Close()
							delete(clients, client2)
						}
					}
				}
			}
			//update opponent client to say they are no longer searching and also return the opposing playerID
			if thisClient, ok := clients[client]; ok {
				thisClient.Searching = false
				thisClient.OpponentID = currentPlayerID
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
	//if no other player was found when search is initiated, set the current userss searching status to true
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

func createSearchingReturnMessageJSON(playerID string, tileSelectionTurn bool) common.DefaultReturnMessage {
	returnJSON := common.DefaultReturnMessage{
		EventType: "playerFound",
		Data: searchingReturnData{
			PlayerID:          playerID,
			TileSelectionTurn: tileSelectionTurn,
		},
	}
	return returnJSON
}
