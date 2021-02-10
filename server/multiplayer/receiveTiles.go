package multiplayer

import (
	"encoding/json"
	"log"

	"../common"
)

//HandleReceiveTiles handles notifying the opponent that tiles for the round have been selected by the current player
func HandleReceiveTiles(paramsData []byte) {
	var data common.TileData
	jsonErr := json.Unmarshal(paramsData, &data)
	if jsonErr != nil {
		log.Printf("Error: %v", jsonErr)
	}
	opponentClient, getClientErr := common.GetOpponentClient(data.PlayerID)
	if getClientErr != nil {
		log.Printf("Error: %v", getClientErr)
	}
	opponentPlayerReturnJSON := createReceiveTilesJSON(common.Clients[opponentClient].PlayerID, data.Tiles)
	//update opponent client with new tiles
	common.WriteJSON(opponentClient, opponentPlayerReturnJSON)
}

func createReceiveTilesJSON(playerID string, tiles []common.Tile) common.DefaultReturnMessage {
	returnJSON := common.DefaultReturnMessage{
		EventType: "receiveTiles",
		Data: common.TileData{
			PlayerID: playerID,
			Tiles:    tiles,
		},
	}
	return returnJSON
}
