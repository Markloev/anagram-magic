package multiplayer

import (
	"encoding/json"
	"log"

	"../common"
)

//HandleEndGame removes the client from the list of clients searching/playing
func HandleEndGame(paramsData []byte) {
	var currentPlayerID string
	jsonErr := json.Unmarshal(paramsData, &currentPlayerID)
	if jsonErr != nil {
		log.Printf("Error: %v", jsonErr)
	}
	//loop through list of clients to find current client
	for client := range common.Clients {
		if common.Clients[client].PlayerID == currentPlayerID {
			if thisClient, ok := common.Clients[client]; ok {
				thisClient.OpponentID = ""
				thisClient.Searching = false
				thisClient.TurnSubmitted = false
				thisClient.NextRound = false
				thisClient.Tiles = nil
				thisClient.FinalRoundWord = ""
				common.Clients[client] = thisClient
			}
		}
	}
}
