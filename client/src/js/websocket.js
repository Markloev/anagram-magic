export function bindWebSocket(app) {
    if (!app.ports || !(app.ports.toSocket && app.ports.fromSocket)) {
        return;
    }

    let sockets = {};

    app.ports.toSocket.subscribe(message => {
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
        let socket = new WebSocket(request.url, request.protocols);

        socket.onopen = openHandler.bind(null, toElm, socket, request.url);
        socket.onmessage = messageHandler.bind(null, toElm, socket, request.url);
        socket.onerror = errorHandler.bind(null, toElm, socket, request.url);
        socket.onclose = closeHandler.bind(null, toElm, sockets, request.url);

        sockets[request.url] = socket;
    }

    function closeWebSocket(request) {
        let socket = sockets[request.url];
        if (!socket) {
            return;
        }

        socket.close();

        sockets[request.url] = undefined;
    }

    function sendJSON(request) {
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
        console.log("Binary message handling not supported");
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