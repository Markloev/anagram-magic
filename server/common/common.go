package common

import (
	"encoding/json"
	"errors"
	"log"

	"github.com/gorilla/websocket"
)

//Clients stores a list of all clients connected via web socket
var Clients = make(map[*websocket.Conn]*Client)

//Broadcast handles messages received through web socket
var Broadcast = make(chan Message)

//Client stores a player's information that is needed for matching player's together
type Client struct {
	PlayerID       string
	OpponentID     string
	Searching      bool
	TurnSubmitted  bool
	NextRound      bool
	FinalRoundWord string
	Tiles          []Tile
}

//Message stores the incoming message received from a client
type Message struct {
	EventType string          `json:"eventType"`
	Data      json.RawMessage `json:"data"`
}

//DefaultReturnMessage holds the JSON object that will be returned to the user via web sockets
type DefaultReturnMessage struct {
	EventType string
	Data      interface{}
}

//TileData holds the player ID and list of selected tiles
type TileData struct {
	PlayerID string `json:"playerId"`
	Tiles    []Tile `json:"tiles"`
}

//Tile hold the tile object
type Tile struct {
	Letter        int  `json:"letter"`
	Value         int  `json:"value"`
	OriginalIndex int  `json:"originalIndex"`
	Hidden        bool `json:"hidden"`
}

//CreateBasicReturnMessageJSON creates a simple JSON object with an event type that is returned to the user
func CreateBasicReturnMessageJSON(eventType string) DefaultReturnMessage {
	returnJSON := DefaultReturnMessage{
		EventType: eventType,
		Data:      nil,
	}
	return returnJSON
}

//GetCurrentPlayerClient gets the current player client from a given playerID
func GetCurrentPlayerClient(playerID string) (*websocket.Conn, error) {
	for client := range Clients {
		if Clients[client].PlayerID == playerID {
			return client, nil
		}
	}
	return nil, errors.New("No current player client found")
}

//GetOpponentClient gets the current opponent client from a given playerID
func GetOpponentClient(playerID string) (*websocket.Conn, error) {
	for client := range Clients {
		if Clients[client].OpponentID == playerID {
			return client, nil
		}
	}
	return nil, errors.New("No opponent client found")
}

//ForceEndGame ends the current game session if an error has occurred
func ForceEndGame(err error, client *websocket.Conn) {
	log.Printf("Error1: %v", err)
	opponentClient, getClientErr := GetOpponentClient(Clients[client].PlayerID)
	if getClientErr != nil {
		log.Printf("Error2: %v", getClientErr)
	}
	WriteJSON(opponentClient, CreateBasicReturnMessageJSON("forceEndGame"))
	client.Close()
}

//WriteJSON sends JSON to the client
func WriteJSON(client *websocket.Conn, jsonMsg DefaultReturnMessage) {
	currentWriteErr := client.WriteJSON(jsonMsg)
	if currentWriteErr != nil {
		client.Close()
	}
}

//DataToJSON converts incoming data to JSON format or returns error
func DataToJSON(incData interface{}, paramsData []byte) {
	parseErr := json.Unmarshal(paramsData, &incData)
	if parseErr != nil {
		log.Printf("Error: %v", parseErr)
	}
}

//CreateNewClient creates a new client with default values
func CreateNewClient(playerID string) *Client {
	var newClient Client
	newClient.PlayerID = playerID
	newClient.OpponentID = ""
	newClient.Searching = false
	newClient.TurnSubmitted = false
	newClient.NextRound = false
	newClient.Tiles = nil
	newClient.FinalRoundWord = ""
	return &newClient
}
