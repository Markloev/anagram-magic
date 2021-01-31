package common

import (
	"github.com/gorilla/websocket"
)

//Clients stores a list of all clients connected via web socket
var Clients = make(map[*websocket.Conn]Client)

//Broadcast handles messages received through web socket
var Broadcast = make(chan Message)

//Client stores a player's information that is needed for matching player's together
type Client struct {
	PlayerID  string
	Searching bool
}

//Message stores the incoming message received from a client
type Message struct {
	EventType string
	Data      data
}

type data interface{}
