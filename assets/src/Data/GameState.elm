module Data.GameState exposing (GameState, decoder, view)

import Data.Bullet as Bullet exposing (Bullet)
import Data.Tank as Tank exposing (Tank)
import Data.Window exposing (Window)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Svg exposing (..)
import Svg.Attributes exposing (..)


type alias GameState =
    { tanks : List Tank
    , bullets : List Bullet
    , remainingTime : Int
    }


decoder : Decoder GameState
decoder =
    Decode.succeed GameState
        |> required "tanks" (Decode.list Tank.decoder)
        |> required "bullets" (Decode.list Bullet.decoder)
        |> required "remaining_time" Decode.int


viewField : Svg msg
viewField =
    line
        [ x1 "0"
        , y1 "600"
        , x2 "1000"
        , y2 "600"
        , stroke "black"
        ]
        []


view : Window -> GameState -> Svg msg
view window gameState =
    Svg.svg
        [ Svg.Attributes.viewBox "0 0 1000 600"
        , Svg.Attributes.width <| String.fromInt window.width
        , Svg.Attributes.height <| String.fromInt window.height
        ]
        (viewField
            :: List.map Tank.view gameState.tanks
            ++ List.map Bullet.view gameState.bullets
        )
