package multiplayer

import (
	"encoding/json"
	"log"

	"github.com/gorilla/websocket"

	"../common"
)

type changePhaseData struct {
	PlayerID       string `json:"playerId"`
	AvailableTiles []Tile `json:"tiles"`
}

type Tile struct {
	Letter        int  `json:"letter"`
	Value         int  `json:"value"`
	OriginalIndex int  `json:"originalIndex"`
	Hidden        bool `json:"hidden"`
}

//HandleChangePhase handles notifying the opponent that a phase change is happening
func HandleChangePhase(paramsData []byte, clients map[*websocket.Conn]common.Client) {
	var data changePhaseData
	jsonErr := json.Unmarshal(paramsData, &data)
	// log.Println(paramsData)
	// log.Println(data)
	if jsonErr != nil {
		log.Printf("Error: %v", jsonErr)
	}
	log.Println(data.PlayerID)
	//loop through list of clients
	for client := range clients {
		log.Println(clients[client].OpponentID)
		//if other client is matched against current client
		if clients[client].OpponentID == data.PlayerID {
			opponentPlayerReturnJSON := createChangePhaseReturnMessageJSON(clients[client].PlayerID, data.AvailableTiles)
			log.Println(opponentPlayerReturnJSON)
			//update opponent client of phase change
			err := client.WriteJSON(opponentPlayerReturnJSON)
			if err != nil {
				log.Printf("Error: %v", err)
				client.Close()
				delete(clients, client)
			}
		}
	}
}

func createChangePhaseReturnMessageJSON(playerID string, tiles []Tile) common.DefaultReturnMessage {
	returnJSON := common.DefaultReturnMessage{
		EventType: "changePhase",
		Data: changePhaseData{
			PlayerID:       playerID,
			AvailableTiles: tiles,
		},
	}
	return returnJSON
}
