package common

import (
	"encoding/json"

	"github.com/gorilla/websocket"
)

//Clients stores a list of all clients connected via web socket
var Clients = make(map[*websocket.Conn]Client)

//Broadcast handles messages received through web socket
var Broadcast = make(chan Message)

//Client stores a player's information that is needed for matching player's together
type Client struct {
	PlayerID   string
	OpponentID string
	Searching  bool
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
