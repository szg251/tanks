module Request.Players exposing (requestCreate, requestDelete, requestList, requestShow)

import Data.Player as Player exposing (Player)
import Data.String20 as String20
import Http
import Json.Decode as Decode
import Json.Encode as Encode exposing (Value)
import RemoteData exposing (WebData)
import Url.Builder exposing (string)


requestShow : (WebData Player -> msg) -> Player -> Cmd msg
requestShow toMsg player =
    Http.get
        { url = Url.Builder.absolute [ "api", "players", String20.value player.name ] []
        , expect =
            Http.expectJson
                (RemoteData.fromResult >> toMsg)
                (Decode.field "data" Player.decoder)
        }


requestList : (WebData (List Player) -> msg) -> Cmd msg
requestList toMsg =
    Http.get
        { url = Url.Builder.absolute [ "api", "players" ] []
        , expect =
            Http.expectJson
                (RemoteData.fromResult >> toMsg)
                (Decode.field "data" <| Decode.list Player.decoder)
        }


requestCreate : (WebData Player -> msg) -> Player -> Cmd msg
requestCreate toMsg player =
    Http.post
        { url = Url.Builder.absolute [ "api", "players" ] []
        , body = Http.jsonBody <| Encode.object [ ( "player", Player.encode player ) ]
        , expect =
            Http.expectJson
                (RemoteData.fromResult >> toMsg)
                (Decode.field "data" Player.decoder)
        }


requestDelete : (Result Http.Error () -> msg) -> Player -> Cmd msg
requestDelete toMsg player =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = Url.Builder.absolute [ "api", "players", String20.value player.name ] []
        , body = Http.emptyBody
        , expect = Http.expectWhatever toMsg
        , timeout = Nothing
        , tracker = Nothing
        }
