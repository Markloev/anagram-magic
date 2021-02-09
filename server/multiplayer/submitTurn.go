package multiplayer

import (
	"bufio"
	// "encoding/json"
	"log"
	"os"
	"strings"

	"../common"
)

type submitTurnData struct {
	PlayerID string        `json:"playerId"`
	Tiles    []common.Tile `json:"tiles"`
	Phase    string        `json:"phase"`
}

//HandleSubmitTurn handles notifying the opponent that the opponent has finished their turn
func HandleSubmitTurn(paramsData []byte) {
	// var data submitTurnData
	// jsonErr := json.Unmarshal(paramsData, &data)
	// if jsonErr != nil {
	// 	log.Printf("Error: %v", jsonErr)
	// }
	// //loop through list of clients
	// for client := range common.Clients {
	// 	if common.Clients[client].OpponentID == data.PlayerID {
	// 		if common.Clients[client].TurnSubmitted {
	// 			if data.Phase == "finalRound" {
	// 				var playerValidWord bool
	// 				var opponentValidWord bool
	// 				if common.Clients[client].FinalRoundWord != "" {
	// 					playerValidWord = checkFinalRoundWordValidity(common.Clients[client].Tiles, common.Clients[client])
	// 					opponentValidWord = checkFinalRoundWordValidity(data.Tiles, common.Clients[client])
	// 				} else {
	// 					for searchingClient := range common.Clients {
	// 						if common.Clients[searchingClient].PlayerID == data.PlayerID {
	// 							playerValidWord = checkFinalRoundWordValidity(common.Clients[searchingClient].Tiles, common.Clients[searchingClient])
	// 							opponentValidWord = checkFinalRoundWordValidity(data.Tiles, common.Clients[searchingClient])
	// 						}
	// 					}
	// 				}
	// 				opponentReturnJSON := createchangePhaseReturnMessageJSON("submitTurnComplete", playerValidWord, opponentValidWord)
	// 				//update opponent client of phase change
	// 				currentErr := client.WriteJSON(opponentReturnJSON)
	// 				if currentErr != nil {
	// 					log.Printf("Error: %v", currentErr)
	// 					client.Close()
	// 					delete(common.Clients, client)
	// 				}
	// 				for searchingClient := range common.Clients {
	// 					if common.Clients[searchingClient].PlayerID == data.PlayerID {
	// 						//update current player of phase change
	// 						currentPlayerReturnJSON := createchangePhaseReturnMessageJSON("submitTurnComplete", opponentValidWord, playerValidWord)
	// 						err := searchingClient.WriteJSON(currentPlayerReturnJSON)
	// 						if err != nil {
	// 							log.Printf("Error: %v", err)
	// 							searchingClient.Close()
	// 							delete(common.Clients, searchingClient)
	// 						}
	// 					}
	// 				}
	// 				if thisClient, ok := common.Clients[client]; ok {
	// 					thisClient.TurnSubmitted = false
	// 					thisClient.Tiles = nil
	// 					common.Clients[client] = thisClient
	// 				}
	// 			} else {
	// 				opponentReturnJSON := createchangePhaseReturnMessageJSON("submitTurnComplete", checkWordValidity(common.Clients[client].Tiles), checkWordValidity(data.Tiles))
	// 				//update opponent client of phase change
	// 				currentErr := client.WriteJSON(opponentReturnJSON)
	// 				if currentErr != nil {
	// 					log.Printf("Error: %v", currentErr)
	// 					client.Close()
	// 					delete(common.Clients, client)
	// 				}
	// 				for searchingClient := range common.Clients {
	// 					if common.Clients[searchingClient].PlayerID == data.PlayerID {
	// 						//update current player of phase change
	// 						currentPlayerReturnJSON := createchangePhaseReturnMessageJSON("submitTurnComplete", checkWordValidity(data.Tiles), checkWordValidity(common.Clients[client].Tiles))
	// 						err := searchingClient.WriteJSON(currentPlayerReturnJSON)
	// 						if err != nil {
	// 							log.Printf("Error: %v", err)
	// 							searchingClient.Close()
	// 							delete(common.Clients, searchingClient)
	// 						}
	// 					}
	// 				}
	// 				if thisClient, ok := common.Clients[client]; ok {
	// 					thisClient.TurnSubmitted = false
	// 					thisClient.Tiles = nil
	// 					common.Clients[client] = thisClient
	// 				}
	// 			}
	// 		} else {
	// 			//if opponent hasn't submitted yet, set the current user's TurnSubmitted status to true and Tiles to their list of selected tiles
	// 			for searchingClient := range common.Clients {
	// 				if common.Clients[searchingClient].PlayerID == data.PlayerID {
	// 					if thisClient, ok := common.Clients[searchingClient]; ok {
	// 						thisClient.TurnSubmitted = true
	// 						thisClient.Tiles = data.Tiles
	// 						common.Clients[searchingClient] = thisClient
	// 					}
	// 				}
	// 			}
	// 		}
	// 	}
	// }
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

func checkFinalRoundWordValidity(tiles []common.Tile, client common.Client) bool {
	var word string
	for tile := range tiles {
		word = word + string(tiles[tile].Letter)
	}
	word = strings.ToLower(word)
	return word == client.FinalRoundWord
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
