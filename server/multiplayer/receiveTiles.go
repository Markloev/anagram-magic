package multiplayer

import (
	"encoding/json"
	"log"

	"github.com/gorilla/websocket"

	"../common"
)

//HandleReceiveTiles handles notifying the opponent that tiles for the round have been selected by the opponent
func HandleReceiveTiles(paramsData []byte, clients map[*websocket.Conn]common.Client) {
	var data common.TileData
	jsonErr := json.Unmarshal(paramsData, &data)
	if jsonErr != nil {
		log.Printf("Error: %v", jsonErr)
	}
	//loop through list of clients
	for client := range clients {
		//if other client is matched against current client
		if clients[client].OpponentID == data.PlayerID {
			opponentPlayerReturnJSON := createReceiveTilesReturnMessageJSON(clients[client].PlayerID, data.Tiles)
			//update opponent client with new tiles
			err := client.WriteJSON(opponentPlayerReturnJSON)
			if err != nil {
				log.Printf("Error: %v", err)
				client.Close()
				delete(clients, client)
			}
		}
	}
}

func createReceiveTilesReturnMessageJSON(playerID string, tiles []common.Tile) common.DefaultReturnMessage {
	returnJSON := common.DefaultReturnMessage{
		EventType: "receiveTiles",
		Data: common.TileData{
			PlayerID: playerID,
			Tiles:    tiles,
		},
	}
	return returnJSON
}
