# Anagram Magic

Remake of the legendary and now removed Miniclip game of the past: Anagram Magic (in Elm/Go)

## Setup

### Server

```
1. cd server
2. go run main.go
```

### Client

```
1. cd client
2. npm install
3. npm run dev
```

## How to Play

1. Start search
2. Wait for another player to begin searching
3. Select letters to make the longest word you can think of that uses the largest letter multiplier possible (two letters will have a x2 and x3 bonus applied each round)
4. For the final round, be the first to solve the nine-letter word for 9 bonus points
5. Whoever has the most total points after the final round wins the game

- The entire game can be played from start to finish with just the "Enter", "Spacebar", "Backspace", and letter keys

![](/client/src/assets/gifs/anagram.gif)
