// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html";

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import socket from "./socket";

import { Elm } from "../src/Main.elm";

const app = Elm.Main.init({
  node: document.getElementById("elm-node"),
  flags: {
    playerName: localStorage.getItem("player_name"),
    window: { width: window.innerWidth, height: window.innerHeight }
  }
});

app.ports.channelFromElm.subscribe(({ msg, payload }) => {
  console.log(msg, payload);
  switch (msg) {
    case "connect": {
      socket.connect({ user_id: payload.playerName });
      app.ports.channelToElm.send({ msg: "got_socket", payload: { socket } });
      return;
    }

    case "join": {
      console.log("join", payload);
      const channel = payload.socket.channel(payload.topic);
      channel.join().receive("ok", _ => {
        channel.on("sync", value => {
          console.log("sync", value);
          app.ports.channelToElm.send({
            msg: "got_channel_event",
            payload: {
              event: "sync",
              value
            }
          });
        });
      });
      app.ports.channelToElm.send({ msg: "got_channel", payload: { channel } });
      return;
    }

    case "push": {
      const channel = payload.channel;
      channel.push(payload.event, payload.value);
      app.ports.channelToElm.send({ msg: "got_channel", payload: { channel } });
      return;
    }
  }
});

app.ports.setItem.subscribe(({ key, value }) => {
  localStorage.setItem(key, value);
  app.ports.localStorageSubscribe.send({ key, value });
});

app.ports.getItem.subscribe(key => {
  const value = localStorage.getItem(key);
  if (value) {
    app.ports.localStorageSubscribe.send({ key, value });
  }
});
