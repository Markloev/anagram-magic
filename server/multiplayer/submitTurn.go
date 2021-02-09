package multiplayer

import (
	"bufio"
	"encoding/json"
	"log"
	"os"

	"../common"
)

type submitTurnData struct {
	PlayerID string        `json:"playerId"`
	Tiles    []common.Tile `json:"tiles"`
	Phase    string        `json:"phase"`
}

//HandleSubmitTurn handles notifying the opponent that the opponent has finished their turn
func HandleSubmitTurn(paramsData []byte) {
	var data submitTurnData
	jsonErr := json.Unmarshal(paramsData, &data)
	if jsonErr != nil {
		log.Printf("Error: %v", jsonErr)
	}
	currentClient, getClientErr := common.GetCurrentPlayerClient(data.PlayerID)
	if getClientErr != nil {
		log.Printf("Error: %v", getClientErr)
	}
	opponentClient, getClientErr := common.GetOpponentClient(data.PlayerID)
	if getClientErr != nil {
		log.Printf("Error: %v", getClientErr)
	} else {
		if common.Clients[opponentClient].TurnSubmitted {
			if data.Phase == "finalRound" {
				playerValidWord := checkFinalRoundWordValidity(data.Tiles, common.Clients[currentClient])
				opponentJSON := createchangePhaseJSON("submitTurnComplete", playerValidWord, false)
				//update opponent client of phase change
				opponentWriteErr := opponentClient.WriteJSON(opponentJSON)
				if opponentWriteErr != nil {
					common.CloseClient(opponentWriteErr, opponentClient)
				}
				//update current player of phase change
				currentPlayerJSON := createchangePhaseJSON("submitTurnComplete", false, playerValidWord)
				currentWriteErr := currentClient.WriteJSON(currentPlayerJSON)
				if currentWriteErr != nil {
					common.CloseClient(currentWriteErr, opponentClient)
				}
				common.Clients[opponentClient].TurnSubmitted = false
				common.Clients[opponentClient].Tiles = nil
			} else {
				opponentJSON := createchangePhaseJSON("submitTurnComplete", checkWordValidity(common.Clients[opponentClient].Tiles), checkWordValidity(data.Tiles))
				//update opponent client of phase change
				opponentWriteErr := opponentClient.WriteJSON(opponentJSON)
				if opponentWriteErr != nil {
					common.CloseClient(opponentWriteErr, opponentClient)
				}
				//update current player of phase change
				currentPlayerJSON := createchangePhaseJSON("submitTurnComplete", checkWordValidity(data.Tiles), checkWordValidity(common.Clients[opponentClient].Tiles))
				currentWriteErr := currentClient.WriteJSON(currentPlayerJSON)
				if currentWriteErr != nil {
					common.CloseClient(currentWriteErr, currentClient)
				}
				common.Clients[opponentClient].TurnSubmitted = false
				common.Clients[opponentClient].Tiles = nil
			}
		} else {
			if data.Phase == "finalRound" {
				playerValidWord := checkFinalRoundWordValidity(data.Tiles, common.Clients[currentClient])
				if playerValidWord {
					currentPlayerJSON := createchangePhaseJSON("submitTurnComplete", playerValidWord, false)
					currentWriteErr := currentClient.WriteJSON(currentPlayerJSON)
					if currentWriteErr != nil {
						common.CloseClient(currentWriteErr, currentClient)
					}
					opponentJSON := createchangePhaseJSON("submitTurnComplete", false, playerValidWord)
					opponentWriteErr := opponentClient.WriteJSON(opponentJSON)
					if opponentWriteErr != nil {
						common.CloseClient(opponentWriteErr, opponentClient)
					}
				}
			}
			//if opponent hasn't submitted yet, set the current user's TurnSubmitted status to 'true' and Tiles to their list of selected tiles
			common.Clients[currentClient].TurnSubmitted = true
			common.Clients[currentClient].Tiles = data.Tiles
		}
	}
}

func checkWordValidity(tiles []common.Tile) bool {
	var word string
	for tile := range tiles {
		word = word + string(tiles[tile].Letter)
	}
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

func checkFinalRoundWordValidity(tiles []common.Tile, client *common.Client) bool {
	var word string
	for tile := range tiles {
		word = word + string(tiles[tile].Letter)
	}
	return word == client.FinalRoundWord
}

type returnData struct {
	PlayerID          string `json:"playerId"`
	PlayerValidWord   bool   `json:"playerValidWord"`
	OpponentValidWord bool   `json:"opponentValidWord"`
}

func createchangePhaseJSON(eventType string, playerValidWord bool, opponentValidWord bool) common.DefaultReturnMessage {
	returnJSON := common.DefaultReturnMessage{
		EventType: eventType,
		Data: returnData{
			PlayerValidWord:   playerValidWord,
			OpponentValidWord: opponentValidWord,
		},
	}
	return returnJSON
}
