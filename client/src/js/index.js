'use strict';

import "../styles/tailwind.css";
require('../styles/anagram.scss');
import { bindWebSocket } from "./websocket.js";
import { randomPlayerId, bindRandomizers } from "./random.js";

const { Elm } = require('../elm/Main.elm');
const app = Elm.Main.init({
    node: document.getElementById('main'),
    flags: randomPlayerId(32, '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')
});
bindWebSocket(app);
bindRandomizers(app);