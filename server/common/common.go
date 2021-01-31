package common

import (
	"github.com/gorilla/websocket"
)

//Clients stores a list of all clients connected via web socket
var Clients = make(map[*websocket.Conn]Client)

//Client stores a player's information that is needed for matching player's together
type Client struct {
	PlayerID  string
	Searching bool
}
