module Page.Loading exposing (view)

import Browser exposing (Document)
import Element exposing (..)


view : Document msg
view =
    { title = "Tanks - Loading..."
    , body =
        [ Element.layout [ width fill, height fill ]
            (el [ centerX, centerY ] (text "Loading..."))
        ]
    }
