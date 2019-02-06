module Data.Session exposing (Session, init, setPlayerName, updateSession)

import Browser.Navigation as Nav
import Data.String20 as String20 exposing (String20)


type alias Session =
    { playerName : Maybe String20
    , navKey : Nav.Key
    }


init : Nav.Key -> Maybe String -> Session
init navKey playerName =
    { playerName = playerName |> Maybe.andThen String20.create
    , navKey = navKey
    }


setPlayerName : Maybe String -> Session -> Session
setPlayerName playerName session =
    { session | playerName = playerName |> Maybe.andThen String20.create }


updateSession : Session -> { r | session : Session } -> { r | session : Session }
updateSession session model =
    { model | session = session }
