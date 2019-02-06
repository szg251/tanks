module Request.Lodge exposing (requestStartBattle, requestSummaries)

import Data.BattleSummary as BattleSummary exposing (BattleSummary)
import Http
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import RemoteData exposing (WebData)
import Url.Builder


requestSummaries : (WebData (List BattleSummary) -> msg) -> Cmd msg
requestSummaries toMsg =
    Http.get
        { url = Url.Builder.absolute [ "api", "battles" ] []
        , expect =
            Http.expectJson
                (RemoteData.fromResult >> toMsg)
                (Decode.field "data" <| Decode.list BattleSummary.decoder)
        }


encodeBattle : String -> String -> Value
encodeBattle name ownerName =
    Encode.object
        [ ( "battle"
          , Encode.object
                [ ( "name", Encode.string name )
                , ( "owner_name", Encode.string ownerName )
                ]
          )
        ]


requestStartBattle : (WebData BattleSummary -> msg) -> String -> String -> Cmd msg
requestStartBattle toMsg name ownerName =
    Http.post
        { url = Url.Builder.absolute [ "api", "battles" ] []
        , body = Http.jsonBody <| encodeBattle name ownerName
        , expect =
            Http.expectJson
                (RemoteData.fromResult >> toMsg)
                (Decode.field "data" BattleSummary.decoder)
        }
