export function randomPlayerId(length, chars) {
    var result = '';
    for (var i = length; i > 0; --i) result += chars[Math.floor(Math.random() * chars.length)];
    return result;
}

export function bindRandomizers(app) {
    app.ports.getRandomTiles.subscribe(function () {
        tiles = [];
        getRandomTiles();
        setMultipliers(tiles);
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
        shuffle(tiles);
        app.ports.receiveShuffledTiles.send(tiles);
    });
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