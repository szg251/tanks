module Data.Session exposing (Session, init, setPlayerName, updateSession)

import Data.String20 as String20 exposing (String20)


type alias Session =
    { playerName : Maybe String20
    , window : Window
    }


type alias Flags =
    { playerName : Maybe String
    , window : Window
    }


type alias Window =
    { width : Int, height : Int }


init : Flags -> Session
init { window, playerName } =
    { playerName = playerName |> Maybe.andThen String20.create
    , window = window
    }


setPlayerName : String -> Session -> Session
setPlayerName playerName session =
    { session | playerName = String20.create playerName }


updateSession : Session -> { r | session : Session } -> { r | session : Session }
updateSession session model =
    { model | session = session }
