package multiplayer

import (
	"fmt"
	"log"

	"github.com/gorilla/websocket"

	"../common"
)

type changePhaseReturnData struct {
	PlayerID string
}

//HandleChangePhase handles notifying the opponent that a phase change is happening
func HandleChangePhase(paramsData interface{}, clients map[*websocket.Conn]common.Client) {
	currentPlayerID := fmt.Sprintf("%v", paramsData)
	//loop through list of clients
	for client := range clients {
		//if other client is matched against current client
		if clients[client].OpponentID == currentPlayerID {
			opponentPlayerReturnJSON := createChangePhaseReturnMessageJSON(clients[client].PlayerID)
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

func createChangePhaseReturnMessageJSON(playerID string) common.DefaultReturnMessage {
	returnJSON := common.DefaultReturnMessage{
		EventType: "changePhase",
		Data:      "",
	}
	return returnJSON
}
