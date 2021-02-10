package multiplayer

import (
	"errors"
	"log"

	"../common"
	"github.com/gorilla/websocket"
)

type searchingReturnData struct {
	PlayerID          string
	TileSelectionTurn bool
}

//HandleSearch handles return message to player that is searching for a game
func HandleSearch(paramsData []byte) {
	var currentPlayerID string
	common.DataToJSON(&currentPlayerID, paramsData)
	currentClient, getClientErr := common.GetCurrentPlayerClient(currentPlayerID)
	if getClientErr != nil {
		log.Printf("Error: %v", getClientErr)
	}
	searchingClient, getClientErr := findSearchingClient(currentPlayerID)
	//if another searching client is not found, set the current client Searching attribute to 'true'
	if getClientErr != nil {
		common.Clients[currentClient].Searching = true
	} else { //Set the OpponentID attributes on both clients, the Searching attribute to 'false' on the searching client, and notify players of the created match
		searchingPlayerJSON := createSearchingJSON(common.Clients[searchingClient].PlayerID, true)
		currentPlayerJSON := createSearchingJSON(currentPlayerID, false)
		common.Clients[currentClient].OpponentID = common.Clients[searchingClient].PlayerID
		common.WriteJSON(currentClient, searchingPlayerJSON)
		common.Clients[searchingClient].Searching = false
		common.Clients[searchingClient].OpponentID = currentPlayerID
		common.WriteJSON(searchingClient, currentPlayerJSON)
	}
}

func findSearchingClient(playerID string) (*websocket.Conn, error) {
	for client := range common.Clients {
		if common.Clients[client].PlayerID != playerID && common.Clients[client].Searching {
			return client, nil
		}
	}
	return nil, errors.New("No searching client found")
}

func createSearchingJSON(playerID string, tileSelectionTurn bool) common.DefaultReturnMessage {
	returnJSON := common.DefaultReturnMessage{
		EventType: "playerFound",
		Data: searchingReturnData{
			PlayerID:          playerID,
			TileSelectionTurn: tileSelectionTurn,
		},
	}
	return returnJSON
}
