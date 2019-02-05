module Page.ErrorPage exposing (Error(..), view)

import Browser exposing (Document)
import Html exposing (div, text)


type Error
    = NotFound


view : Error -> Document msg
view error =
    case error of
        NotFound ->
            { title = "Tanks - not found"
            , body = [ div [] [ text "page not found" ] ]
            }
