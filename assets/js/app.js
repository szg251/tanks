// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import socket from "./socket"

import { Elm } from "../src/Main.elm"

const app = Elm.Main.init({
  node: document.getElementById("elm-node")
})

app.ports.join.subscribe(topic => {
  const channel = socket.channel(topic, {})
  channel
    .join()
    .receive("ok", resp => {
      console.log("Joined successfully", resp)
      app.ports.push.subscribe(({ event, payload }) => {
        channel.push(event, payload)
      })
      channel.on("sync", payload => {
        app.ports.receive.send({
          event: "sync",
          payload
        })
      })
    })
    .receive("error", resp => {
      console.log("Unable to join", resp)
    })
})
