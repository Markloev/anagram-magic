'use strict';

import "./styles/tailwind.css";
require('./styles/anagram.scss');

const { Elm } = require('./elm/Main.elm');
const app = Elm.Main.init({
    node: document.getElementById('main'),
    flags: randomPlayerId(32, '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')
});
bind(app);

function randomPlayerId(length, chars) {
    var result = '';
    for (var i = length; i > 0; --i) result += chars[Math.floor(Math.random() * chars.length)];
    return result;
}

const maxConsonantOrVowel = 6;
const tileListMax = 9;

var consonants = [66, 67, 68, 70, 71, 72, 74, 75, 76, 77, 78, 80, 81, 82, 83, 84, 86, 87, 88, 89, 90, 91];
var vowels = [65, 69, 73, 79, 85];
var tiles = [];

function getRandomTiles() {
    var consonantOrVowel = Math.round(Math.random());
    if (consonantOrVowel < 0.5) {
        if (hasMaxConsonants(tiles)) {
            getRandomVowel(tiles);
        }
        else
            getRandomConsonant(tiles);
    }
    else {
        if (hasMaxVowels(tiles)) {
            getRandomConsonant(tiles);
        }
        else {
            getRandomVowel(tiles);
        }
    }
    if (tiles.length < tileListMax) {
        getRandomTiles();
    }
}

function getRandomConsonant(tiles) {
    var randomConsonant = Math.floor(Math.random() * 20);
    var tile = { letter: consonants[randomConsonant], value: 1, originalIndex: tiles.length, hidden: false };
    tiles.push(tile);
}

function getRandomVowel(tiles) {
    var randomVowel = Math.floor(Math.random() * 5);
    var tile = { letter: vowels[randomVowel], value: 1, originalIndex: tiles.length, hidden: false };
    tiles.push(tile);
}

function hasMaxConsonants(tiles) {
    var consonantsCount = 0;
    tiles.forEach(function (tile) {
        if (consonants.includes(tile.letter)) {
            consonantsCount++;
        }
    });
    if (consonantsCount >= maxConsonantOrVowel) {
        return true;
    }
    else {
        return false;
    }
}

function hasMaxVowels(tiles) {
    var vowelsCount = 0;
    tiles.forEach(function (tile) {
        if (vowels.includes(tile.letter)) {
            vowelsCount++;
        }
    });
    if (vowelsCount >= maxConsonantOrVowel) {
        return true;
    }
    else {
        return false;
    }
}

function setMultipliers(tiles) {
    var threeTimesIndex = Math.floor(Math.random() * tileListMax);
    var twoTimesIndex = Math.floor(Math.random() * tileListMax);
    while (twoTimesIndex === threeTimesIndex) {
        twoTimesIndex = Math.floor(Math.random() * tileListMax);
    }
    var threeTimesTile = tiles[threeTimesIndex];
    threeTimesTile.value = 3;
    var twoTimesTile = tiles[twoTimesIndex];
    twoTimesTile.value = 2;
}

function shuffle(array) {
    var currentIndex = array.length, temporaryValue, randomIndex;

    // While there remain elements to shuffle...
    while (0 !== currentIndex) {

        // Pick a remaining element...
        randomIndex = Math.floor(Math.random() * currentIndex);
        currentIndex -= 1;

        // And swap it with the current element.
        temporaryValue = array[currentIndex];
        array[currentIndex] = array[randomIndex];
        array[randomIndex] = temporaryValue;
    }

    return array;
}

app.ports.getRandomTiles.subscribe(function () {
    getRandomTiles();
    setMultipliers(tiles);
    console.log(tiles);
    app.ports.receiveRandomTiles.send(tiles);
});

app.ports.getRandomConsonant.subscribe(function (tiles) {
    if (tiles.length < tileListMax && !hasMaxConsonants(tiles)) {
        getRandomConsonant(tiles);
    }
    if (tiles.length == tileListMax) {
        setMultipliers(tiles);
    }
    app.ports.receiveRandomTiles.send(tiles);
});

app.ports.getRandomVowel.subscribe(function (tiles) {
    if (tiles.length < tileListMax && !hasMaxVowels(tiles)) {
        getRandomVowel(tiles);
    }
    if (tiles.length == tileListMax) {
        setMultipliers(tiles);
    }
    app.ports.receiveRandomTiles.send(tiles);
});

app.ports.shuffleTiles.subscribe(function (tiles) {
    console.log(tiles);
    shuffle(tiles);
    app.ports.receiveShuffledTiles.send(tiles);
});


function bind(app) {
    if (!app.ports || !(app.ports.toSocket && app.ports.fromSocket)) {
        return;
    }

    let sockets = {};

    app.ports.toSocket.subscribe(message => {
        console.log("MESSAGE TYPE: " + message.msgType);
        switch (message.msgType) {
            case "connect":
                openWebSocket(message.msg);
                break;
            case "disconnect":
                closeWebSocket(message.msg);
                break;
            case "sendJSON":
                sendJSON(message.msg);
                break;
        }
    });

    function openWebSocket(request) {
        if (sockets[request.url]) {
            return;
        }

        let toElm = app.ports.fromSocket;
        console.log(request.url);
        console.log(request.protocols);
        let socket = new WebSocket(request.url, request.protocols);

        socket.onopen = openHandler.bind(null, toElm, socket, request.url);
        socket.onmessage = messageHandler.bind(null, toElm, socket, request.url);
        socket.onerror = errorHandler.bind(null, toElm, socket, request.url);
        socket.onclose = closeHandler.bind(null, toElm, sockets, request.url);

        sockets[request.url] = socket;
    }

    function closeWebSocket(request) {
        console.log("CLOSING");
        let socket = sockets[request.url];
        if (!socket) {
            return;
        }

        socket.close();

        sockets[request.url] = undefined;
    }

    function sendJSON(request) {
        console.log("Yo: " + request.message);
        let socket = sockets[request.url];
        if (socket) {
            socket.send(request.message);
        }
        else {
            console.log(`No open socket for: ${request.url}. Cannot send ${request.message}`);
        }
    }
}


function openHandler(toElm, socket, url, event) {
    console.log("Opened");

    toElm.send({
        msgType: "connected",
        msg: {
            url: url,
            binaryType: socket.binaryType,
            extensions: socket.extensions,
            protocol: socket.protocol
        }
    });
}

function messageHandler(toElm, socket, url, event) {
    if (typeof event.data === "string") {
        toElm.send({
            msgType: "stringMessage",
            msg: {
                url: url,
                binaryType: socket.binaryType,
                extensions: socket.extensions,
                protocol: socket.protocol,
                data: event.data
            }
        });
    }
    else {
        console.log(`Binary message handling not supported.`);
    }
}

function errorHandler(toElm, socket, url, event) {
    toElm.send({
        msgType: "error",
        msg: {
            url: url,
            binaryType: socket.binaryType,
            extensions: socket.extensions,
            protocol: socket.protocol
        }
    });
}

function closeHandler(toElm, sockets, url, event) {
    let socket = sockets[url];
    sockets[url] = undefined;

    toElm.send({
        msgType: "closed",
        msg: {
            url: url,
            binaryType: socket.binaryType,
            extensions: socket.extensions,
            protocol: socket.protocol,
            unsentBytes: socket.bufferedAmount,
            reason: event.reason
        }
    });
}