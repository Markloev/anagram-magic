package multiplayer

import (
	"log"

	"github.com/markloev/anagram-magic/common"
)

//HandleEndGame removes the client from the list of clients searching/playing
func HandleEndGame(paramsData []byte) {
	var currentPlayerID string
	common.DataToJSON(&currentPlayerID, paramsData)
	currentClient, getClientErr := common.GetCurrentPlayerClient(currentPlayerID)
	if getClientErr != nil {
		log.Printf("Error: %v", getClientErr)
	} else {
		common.Clients[currentClient] = common.CreateNewClient(common.Clients[currentClient].PlayerID)
	}
}
