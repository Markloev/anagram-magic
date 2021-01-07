// pull in desired CSS/SASS files
require('../assets/scss/main.scss');

// inject bundled Elm app into div#main
const { Elm } = require('./elm/Main.elm');
const app = Elm.Main.init({
  node: document.getElementById('main')
});

app.ports.pushUrl.subscribe(url => {
  history.pushState({}, "", url);
  app.ports.onUrlChange.send(location.href);
});