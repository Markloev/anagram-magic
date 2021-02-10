package multiplayer

import (
	"log"

	"../common"
)

//HandleStopSearch handles stopping the search for the current client
func HandleStopSearch(paramsData []byte) {
	var currentPlayerID string
	common.DataToJSON(&paramsData, paramsData)
	currentClient, getClientErr := common.GetCurrentPlayerClient(currentPlayerID)
	if getClientErr != nil {
		log.Printf("Error: %v", getClientErr)
	}
	common.Clients[currentClient].Searching = false
}
