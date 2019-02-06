module Data.Session exposing (Session, init, setPlayerName, updateSession)

import Data.String20 as String20 exposing (String20)


type alias Session =
    { playerName : Maybe String20
    }


type alias Flags =
    { playerName : Maybe String
    }


init : Flags -> Session
init { playerName } =
    { playerName = playerName |> Maybe.andThen String20.create
    }


setPlayerName : String -> Session -> Session
setPlayerName playerName session =
    { session | playerName = String20.create playerName }


updateSession : Session -> { r | session : Session } -> { r | session : Session }
updateSession session model =
    { model | session = session }
