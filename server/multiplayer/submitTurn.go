package multiplayer

import (
	"bufio"
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
	common.DataToJSON(&data, paramsData)
	currentClient, getClientErr := common.GetCurrentPlayerClient(data.PlayerID)
	if getClientErr != nil {
		log.Printf("Error: %v", getClientErr)
	}
	playerValidWord := checkFinalRoundWordValidity(data.Tiles, common.Clients[currentClient])
	opponentClient, getClientErr := common.GetOpponentClient(data.PlayerID)
	if getClientErr != nil {
		log.Printf("Error: %v", getClientErr)
	} else {
		if common.Clients[opponentClient].TurnSubmitted {
			if data.Phase == "finalRound" {
				opponentJSON := createSubmitTurnJSON(false, playerValidWord)
				common.WriteJSON(opponentClient, opponentJSON)
				currentPlayerJSON := createSubmitTurnJSON(playerValidWord, false)
				common.WriteJSON(currentClient, currentPlayerJSON)
				common.Clients[opponentClient].TurnSubmitted = false
				common.Clients[opponentClient].Tiles = nil
			} else {
				opponentJSON := createSubmitTurnJSON(checkWordValidity(common.Clients[opponentClient].Tiles), checkWordValidity(data.Tiles))
				common.WriteJSON(opponentClient, opponentJSON)
				currentPlayerJSON := createSubmitTurnJSON(checkWordValidity(data.Tiles), checkWordValidity(common.Clients[opponentClient].Tiles))
				common.WriteJSON(currentClient, currentPlayerJSON)
				common.Clients[opponentClient].TurnSubmitted = false
				common.Clients[opponentClient].Tiles = nil
			}
		} else {
			if data.Phase == "finalRound" {
				if playerValidWord {
					currentPlayerJSON := createSubmitTurnJSON(playerValidWord, false)
					common.WriteJSON(currentClient, currentPlayerJSON)
					opponentJSON := createSubmitTurnJSON(false, playerValidWord)
					common.WriteJSON(opponentClient, opponentJSON)
				}
			}
			//if opponent hasn't submitted yet, set the current user's TurnSubmitted status to 'true' and Tiles to their list of selected tiles
			common.Clients[currentClient].TurnSubmitted = true
			common.Clients[currentClient].Tiles = data.Tiles
			currentPlayerJSON := common.CreateBasicReturnMessageJSON("submitTurn")
			common.WriteJSON(opponentClient, currentPlayerJSON)
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

type returnSubmitTurnData struct {
	PlayerID          string `json:"playerId"`
	PlayerValidWord   bool   `json:"playerValidWord"`
	OpponentValidWord bool   `json:"opponentValidWord"`
}

func createSubmitTurnJSON(playerValidWord bool, opponentValidWord bool) common.DefaultReturnMessage {
	returnJSON := common.DefaultReturnMessage{
		EventType: "submitTurnComplete",
		Data: returnSubmitTurnData{
			PlayerValidWord:   playerValidWord,
			OpponentValidWord: opponentValidWord,
		},
	}
	return returnJSON
}
