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
	currentClient, getClientErr := common.GetCurrentPlayerClient(currentPlayerID)
	if getClientErr != nil {
		log.Printf("Error: %v", getClientErr)
	} else {
		var newClient common.Client
		newClient.PlayerID = common.Clients[currentClient].PlayerID
		newClient.OpponentID = ""
		newClient.Searching = false
		newClient.TurnSubmitted = false
		newClient.NextRound = false
		newClient.Tiles = nil
		newClient.FinalRoundWord = ""
		common.Clients[currentClient] = &newClient
	}
}
