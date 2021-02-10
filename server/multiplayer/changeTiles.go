package multiplayer

import (
	"encoding/json"
	"log"

	"../common"
)

//HandleChangeTiles handles sending the updated list of selected tiles to the opponent
func HandleChangeTiles(paramsData []byte) {
	var data common.TileData
	parseErr := json.Unmarshal(paramsData, &data)
	if parseErr != nil {
		log.Printf("Error: %v", parseErr)
	}
	opponentClient, getClientErr := common.GetOpponentClient(data.PlayerID)
	if getClientErr != nil {
		log.Printf("Error: %v", getClientErr)
	}
	opponentJSON := createChangeTilesJSON(common.Clients[opponentClient].PlayerID, data.Tiles)
	//update opponent client of newly selected tiles by other player
	common.WriteJSON(opponentClient, opponentJSON)
}

func createChangeTilesJSON(playerID string, tiles []common.Tile) common.DefaultReturnMessage {
	returnJSON := common.DefaultReturnMessage{
		EventType: "changeTiles",
		Data: common.TileData{
			PlayerID: playerID,
			Tiles:    tiles,
		},
	}
	return returnJSON
}
