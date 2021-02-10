package multiplayer

import (
	"encoding/base64"
	"log"

	"../common"
)

//HandleChangeTiles handles sending the updated list of selected tiles to the opponent
func HandleChangeTiles(paramsData []byte) {
	var data common.TileData
	common.DataToJSON(&data, paramsData)
	opponentClient, getClientErr := common.GetOpponentClient(data.PlayerID)
	if getClientErr != nil {
		log.Printf("Error: %v", getClientErr)
	}
	opponentJSON := createChangeTilesJSON(common.Clients[opponentClient].PlayerID, data.Tiles)
	//update opponent client of newly selected tiles by other player
	common.WriteJSON(opponentClient, opponentJSON)
}

type returnChangeTilesData struct {
	PlayerID     string `json:"playerId"`
	SelectedWord string `json:"selectedWord"`
}

func createChangeTilesJSON(playerID string, tiles []common.Tile) common.DefaultReturnMessage {
	var word string
	for tile := range tiles {
		word = word + string(tiles[tile].Letter)
	}
	returnJSON := common.DefaultReturnMessage{
		EventType: "changeTiles",
		Data: returnChangeTilesData{
			PlayerID:     playerID,
			SelectedWord: base64.StdEncoding.EncodeToString([]byte(word)),
		},
	}
	return returnJSON
}
