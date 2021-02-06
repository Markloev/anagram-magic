package multiplayer

import (
	"encoding/json"
	"log"

	"../common"
)

type searchingReturnData struct {
	PlayerID          string
	TileSelectionTurn bool
}

//HandleSearch handles return message to player that is searching for a game
func HandleSearch(paramsData []byte) {
	found := false
	var currentPlayerID string
	jsonErr := json.Unmarshal(paramsData, &currentPlayerID)
	if jsonErr != nil {
		log.Printf("Error: %v", jsonErr)
	}
	//loop through list of clients and look for another client that is searching
	for client := range common.Clients {
		//if it is another client and they are also searching
		if common.Clients[client].PlayerID != currentPlayerID && common.Clients[client].Searching {
			found = true
			foundPlayerReturnJSON := createSearchingReturnMessageJSON(common.Clients[client].PlayerID, true)
			currentPlayerReturnJSON := createSearchingReturnMessageJSON(currentPlayerID, false)
			//get current client and update to say they are no longer searching and also return the opposing playerID
			for client2 := range common.Clients {
				if common.Clients[client2].PlayerID == currentPlayerID {
					if thisClient, ok := common.Clients[client2]; ok {
						thisClient.Searching = false
						thisClient.OpponentID = common.Clients[client].PlayerID
						common.Clients[client2] = thisClient
						jsonErr := client2.WriteJSON(foundPlayerReturnJSON)
						if jsonErr != nil {
							log.Printf("Error: %v", jsonErr)
							client2.Close()
							delete(common.Clients, client2)
						}
					}
				}
			}
			//update opponent client to say they are no longer searching and also return the opposing playerID
			if thisClient, ok := common.Clients[client]; ok {
				thisClient.Searching = false
				thisClient.OpponentID = currentPlayerID
				common.Clients[client] = thisClient
			}
			jsonErr := client.WriteJSON(currentPlayerReturnJSON)
			if jsonErr != nil {
				log.Printf("Error: %v", jsonErr)
				client.Close()
				delete(common.Clients, client)
			}
		}
	}
	//if no other player was found when search is initiated, set the current userss searching status to true
	if !found {
		for searchingClient := range common.Clients {
			if common.Clients[searchingClient].PlayerID == currentPlayerID {
				if thisClient, ok := common.Clients[searchingClient]; ok {
					thisClient.Searching = true
					common.Clients[searchingClient] = thisClient
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
