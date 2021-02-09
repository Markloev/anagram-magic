package multiplayer

import (
	"encoding/json"
	"log"

	"../common"
)

//HandleStopSearch handles stopping the search for the current client
func HandleStopSearch(paramsData []byte) {
	var currentPlayerID string
	jsonErr := json.Unmarshal(paramsData, &currentPlayerID)
	if jsonErr != nil {
		log.Printf("Error: %v", jsonErr)
	}
	//loop through list of clients to find current client
	for client := range common.Clients {
		if common.Clients[client].PlayerID == currentPlayerID {
			//update current client to say they are no longer searching
			if thisClient, ok := common.Clients[client]; ok {
				thisClient.Searching = false
				common.Clients[client] = thisClient
			}
		}
	}
}
