module Request.Battles exposing (requestCreate, requestList)

import Data.BattleSummary as BattleSummary exposing (BattleInit, BattleSummary)
import Http
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import RemoteData exposing (WebData)
import Url.Builder


requestList : (WebData (List BattleSummary) -> msg) -> Cmd msg
requestList toMsg =
    Http.get
        { url = Url.Builder.absolute [ "api", "battles" ] []
        , expect =
            Http.expectJson
                (RemoteData.fromResult >> toMsg)
                (Decode.field "data" <| Decode.list BattleSummary.decoder)
        }


requestCreate : (WebData BattleSummary -> msg) -> BattleInit -> Cmd msg
requestCreate toMsg battleInit =
    Http.post
        { url = Url.Builder.absolute [ "api", "battles" ] []
        , body = Http.jsonBody <| Encode.object [ ( "battle", BattleSummary.encode battleInit ) ]
        , expect =
            Http.expectJson
                (RemoteData.fromResult >> toMsg)
                (Decode.field "data" BattleSummary.decoder)
        }
