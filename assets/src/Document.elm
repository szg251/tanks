module Document exposing (map)

import Browser exposing (Document)
import Html


map : (msgA -> msgB) -> Document msgA -> Document msgB
map fn document =
    { title = document.title
    , body = document.body |> List.map (Html.map fn)
    }
