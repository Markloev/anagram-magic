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
	currentClient, getClientErr := common.GetCurrentPlayerClient(currentPlayerID)
	if getClientErr != nil {
		log.Printf("Error: %v", getClientErr)
	}
	common.Clients[currentClient].Searching = false
}
