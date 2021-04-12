package multiplayer

import (
	"bufio"
	"encoding/base64"
	"log"
	"math/rand"
	"os"
	"time"

	"github.com/markloev/anagram-magic/common"
)

type roundCompleteData struct {
	PlayerID string `json:"playerId"`
	Phase    string `json:"phase"`
}

//HandleRoundComplete sends message to both clients to begin "Round Complete" phase
func HandleRoundComplete(paramsData []byte) {
	var data roundCompleteData
	common.DataToJSON(&data, paramsData)
	opponentClient, getClientErr := common.GetOpponentClient(data.PlayerID)
	if getClientErr != nil {
		log.Printf("Error: %v", getClientErr)
	}
	currentClient, getClientErr := common.GetCurrentPlayerClient(data.PlayerID)
	if getClientErr != nil {
		log.Printf("Error: %v", getClientErr)
	}
	if common.Clients[opponentClient].NextRound {
		var returnJSON common.DefaultReturnMessage
		var randomWord string
		//if changing phase to final round, fetch a random nine-letter word to scramble
		if data.Phase == "finalRound" {
			randomWord = getRandomWord()
			encodedRandomWord := base64.StdEncoding.EncodeToString([]byte(randomWord))
			returnJSON = createRoundCompleteJSON(roundCompleteReturnData{RandomWord: encodedRandomWord})
		} else {
			returnJSON = createRoundCompleteJSON(nil)
		}
		common.Clients[opponentClient].NextRound = false
		common.Clients[opponentClient].FinalRoundWord = randomWord
		common.Clients[currentClient].FinalRoundWord = randomWord
		//update current client in order to begin "Round Complete" phase
		common.WriteJSON(currentClient, returnJSON)

		//update opponent client in order to begin "Round Complete" phase
		common.WriteJSON(opponentClient, returnJSON)
	} else { //if opponent hasn't selected "Next Round" yet, set the current user's NextRound status to true
		common.Clients[currentClient].NextRound = true
	}
}

type roundCompleteReturnData struct {
	RandomWord string `json:"randomWord"`
}

func createRoundCompleteJSON(data interface{}) common.DefaultReturnMessage {
	returnJSON := common.DefaultReturnMessage{
		EventType: "roundComplete",
		Data:      data,
	}
	return returnJSON
}

func getRandomWord() string {
	const nineLetterWords = 57288
	rand.Seed(time.Now().UnixNano())
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
