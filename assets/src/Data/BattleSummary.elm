module Data.BattleSummary exposing (BattleInit, BattleSummary, decoder, encode)

import Data.String20 as String20 exposing (String20)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode exposing (Value)


type alias BattleSummary =
    { name : String20
    , ownerName : String20
    , playerCount : Int
    }


type alias BattleInit =
    { name : String20, ownerName : String20 }


decoder : Decoder BattleSummary
decoder =
    Decode.succeed BattleSummary
        |> required "name" String20.decoder
        |> required "owner_name" String20.decoder
        |> required "player_count" Decode.int


encode : BattleInit -> Value
encode { name, ownerName } =
    Encode.object
        [ ( "name", String20.encode name )
        , ( "owner_name", String20.encode ownerName )
        ]
