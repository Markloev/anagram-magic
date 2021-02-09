package multiplayer

import (
	"bufio"
	"encoding/json"
	"log"
	"math/rand"
	"os"

	"../common"
)

type roundCompleteData struct {
	PlayerID string `json:"playerId"`
	Phase    string `json:"phase"`
}

//HandleRoundComplete sends message to both clients to start timers for "Round Complete" phase
func HandleRoundComplete(paramsData []byte) {
	var data roundCompleteData
	jsonErr := json.Unmarshal(paramsData, &data)
	if jsonErr != nil {
		log.Printf("Error: %v", jsonErr)
	}
	//loop through list of clients to find current client and opponent client
	for client := range common.Clients {
		if common.Clients[client].OpponentID == data.PlayerID {
			if common.Clients[client].NextRound {
				var returnJSON common.DefaultReturnMessage
				var randomWord string
				//if changing phase to final round, fetch a random nine-letter word to scramble
				if data.Phase == "finalRound" {
					randomWord = getRandomWord()
					returnJSON = createRoundCompleteReturnMessageJSON(roundCompleteReturnData{RandomWord: randomWord})
				} else {
					returnJSON = createRoundCompleteReturnMessageJSON(nil)
				}
				if thisClient, ok := common.Clients[client]; ok {
					thisClient.NextRound = false
					thisClient.FinalRoundWord = randomWord
					common.Clients[client] = thisClient
				}
				//get current client and update in order to start timer for "Round Complete" phase
				for client2 := range common.Clients {
					if common.Clients[client2].PlayerID == data.PlayerID {
						jsonErr := client2.WriteJSON(returnJSON)
						if jsonErr != nil {
							log.Printf("Error: %v", jsonErr)
							client2.Close()
							delete(common.Clients, client2)
						}
					}
				}

				//get opponent client and update in order to start timer for "Round Complete" phase
				jsonErr := client.WriteJSON(returnJSON)
				if jsonErr != nil {
					log.Printf("Error: %v", jsonErr)
					client.Close()
					delete(common.Clients, client)
				}
			} else {
				//if opponent hasn't selected "Next Round" yet, set the current user's NextRound status to true
				for searchingClient := range common.Clients {
					if common.Clients[searchingClient].PlayerID == data.PlayerID {
						if thisClient, ok := common.Clients[searchingClient]; ok {
							thisClient.NextRound = true
							common.Clients[searchingClient] = thisClient
						}
					}
				}
			}
		}
	}
}

type roundCompleteReturnData struct {
	RandomWord string `json:"randomWord"`
}

func createRoundCompleteReturnMessageJSON(data interface{}) common.DefaultReturnMessage {
	returnJSON := common.DefaultReturnMessage{
		EventType: "roundComplete",
		Data:      data,
	}
	return returnJSON
}

func getRandomWord() string {
	const nineLetterWords = 57288
	randomLine := rand.Intn(nineLetterWords)
	file, err := os.Open("nine_letter_words.txt")
	if err != nil {
		log.Fatal(err)
	}
	defer file.Close()

	word := ""
	count := 0
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		if randomLine == count {
			word = scanner.Text()
			break
		}
		count++
	}

	return word
}
