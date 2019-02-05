module Data.BattleSummary exposing (BattleSummary, decoder, responseDecoder)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)


type alias BattleSummary =
    { name : String
    , ownerName : String
    , playerCount : Int
    }


decoder : Decoder BattleSummary
decoder =
    Decode.succeed BattleSummary
        |> required "name" Decode.string
        |> required "owner_name" Decode.string
        |> required "player_count" Decode.int


responseDecoder : Decoder (List BattleSummary)
responseDecoder =
    Decode.field "data" (Decode.list decoder)