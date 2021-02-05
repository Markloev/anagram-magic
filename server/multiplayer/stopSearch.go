package multiplayer

import (
	"encoding/json"
	"log"

	"github.com/gorilla/websocket"

	"../common"
)

//HandleStopSearch handles stopping the search for the current client
func HandleStopSearch(paramsData []byte, clients map[*websocket.Conn]common.Client) {
	var currentPlayerID string
	jsonErr := json.Unmarshal(paramsData, &currentPlayerID)
	if jsonErr != nil {
		log.Printf("Error: %v", jsonErr)
	}
	//loop through list of clients to find current client
	for client := range clients {
		if clients[client].PlayerID == currentPlayerID {
			//update current client to say they are no longer searching
			if thisClient, ok := clients[client]; ok {
				thisClient.Searching = false
				clients[client] = thisClient
			}
		}
	}
}
