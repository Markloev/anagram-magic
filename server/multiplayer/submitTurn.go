package multiplayer

import (
	"bufio"
	"encoding/json"
	"log"
	"os"
	"strings"

	"github.com/gorilla/websocket"

	"../common"
)

//HandleSubmitTurn handles notifying the opponent that the opponent has finished their turn
func HandleSubmitTurn(paramsData []byte, clients map[*websocket.Conn]common.Client) {
	var data common.TileData
	jsonErr := json.Unmarshal(paramsData, &data)
	if jsonErr != nil {
		log.Printf("Error: %v", jsonErr)
	}
	//loop through list of clients
	for client := range clients {
		if clients[client].OpponentID == data.PlayerID {
			if clients[client].TurnSubmitted {
				opponentReturnJSON := createchangePhaseReturnMessageJSON("submitTurnComplete", checkWordValidity(clients[client].Tiles), checkWordValidity(data.Tiles))
				//update opponent client of phase change
				currentErr := client.WriteJSON(opponentReturnJSON)
				if currentErr != nil {
					log.Printf("Error: %v", currentErr)
					client.Close()
					delete(clients, client)
				}
				for searchingClient := range clients {
					if clients[searchingClient].PlayerID == data.PlayerID {
						//update current player of phase change
						currentPlayerReturnJSON := createchangePhaseReturnMessageJSON("submitTurnComplete", checkWordValidity(data.Tiles), checkWordValidity(clients[client].Tiles))
						err := searchingClient.WriteJSON(currentPlayerReturnJSON)
						if err != nil {
							log.Printf("Error: %v", err)
							searchingClient.Close()
							delete(clients, searchingClient)
						}
					}
				}
				if thisClient, ok := clients[client]; ok {
					thisClient.TurnSubmitted = false
					thisClient.Tiles = nil
					clients[client] = thisClient
				}
			} else {
				//if opponent hasn't submitted yet, set the current user's TurnSubmitted status to true and Tiles to their list of selected tiles
				for searchingClient := range clients {
					if clients[searchingClient].PlayerID == data.PlayerID {
						if thisClient, ok := clients[searchingClient]; ok {
							thisClient.TurnSubmitted = true
							thisClient.Tiles = data.Tiles
							clients[searchingClient] = thisClient
						}
					}
				}
				currentPlayerReturnJSON := common.CreateBasicReturnMessageJSON("submitTurn")
				//update opponent client of turn submit
				err := client.WriteJSON(currentPlayerReturnJSON)
				if err != nil {
					log.Printf("Error: %v", err)
					client.Close()
					delete(clients, client)
				}
			}
		}
	}
}

func checkWordValidity(tiles []common.Tile) bool {
	var word string
	for tile := range tiles {
		word = word + string(tiles[tile].Letter)
	}
	word = strings.ToLower(word)
	file, err := os.Open("words.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		if word == scanner.Text() {
			return true
		}
	}

	return false
}

type returnData struct {
	PlayerID          string `json:"playerId"`
	PlayerValidWord   bool   `json:"playerValidWord"`
	OpponentValidWord bool   `json:"opponentValidWord"`
}

func createchangePhaseReturnMessageJSON(eventType string, playerValidWord bool, opponentValidWord bool) common.DefaultReturnMessage {
	returnJSON := common.DefaultReturnMessage{
		EventType: eventType,
		Data: returnData{
			PlayerValidWord:   playerValidWord,
			OpponentValidWord: opponentValidWord,
		},
	}
	return returnJSON
}
