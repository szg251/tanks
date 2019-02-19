module Page.Battle exposing (Model, Msg, init, subscriptions, unload, update, view)

import Browser exposing (Document)
import Browser.Dom
import Browser.Events exposing (onAnimationFrame, onKeyDown, onKeyUp, onResize, onVisibilityChange)
import Channel exposing (Channel, Socket)
import Data.GameState as GameState exposing (GameState)
import Data.Player exposing (Player)
import Data.Session exposing (Session)
import Data.String20 as String20 exposing (String20)
import Data.Tank exposing (Tank)
import Data.Window exposing (Window)
import Element exposing (..)
import Html
import Json.Decode as Decode exposing (Decoder)
import KeyRegister exposing (Key, KeyRegister, KeyState(..))
import Set exposing (Set)
import Svg
import Svg.Attributes
import Task
import Time exposing (Posix, every)


type Msg
    = NoOp
    | FitWindowSize Window
    | KeyRegisterMsg KeyRegister.Msg
    | GotSocket (Result Decode.Error Socket)
    | GotChannel (Result Decode.Error Channel)
    | GotChannelResponse (Result Decode.Error Channel.Response)


type alias Model =
    { gameState : GameState
    , window : { width : Int, height : Int }
    , battleName : String20
    , session : Session
    , channel : Maybe Channel
    , keyRegister : KeyRegister
    , modal : Modal
    }


type Modal
    = NoModal
    | EndBattle (List Tank)


getWindowSize : Cmd Msg
getWindowSize =
    let
        fromViewport { viewport } =
            Window (round viewport.width) (round viewport.height)
    in
    Browser.Dom.getViewport
        |> Task.perform (fromViewport >> FitWindowSize)


init : Session -> Player -> String20 -> ( Model, Cmd Msg )
init session player battleName =
    ( { gameState = { tanks = [], bullets = [], remainingTime = 0 }
      , window = { width = 1000, height = 600 }
      , battleName = battleName
      , session = session
      , channel = Nothing
      , keyRegister = KeyRegister.init
      , modal = NoModal
      }
    , Cmd.batch
        [ Channel.connect (String20.value player.name)
        , getWindowSize
        ]
    )


view : Model -> Document Msg
view model =
    { title = "Tanks - Battle: " ++ String20.value model.battleName
    , body =
        [ Element.layout
            [ inFront
                (case model.modal of
                    NoModal ->
                        Element.none

                    EndBattle tanks ->
                        column
                            [ width (px 500), centerX, centerY ]
                            [ el [ centerX ] (text "Battle Ended")
                            , viewResults tanks
                            , link [ centerX ] { label = text "back to top", url = "/" }
                            ]
                )
            ]
            (column []
                [ row [ height (px 10), spacing 10 ]
                    [ el [ height (px 10) ] (text "Remaining time:")
                    , el [ height (px 10) ] (text <| toTime model.gameState.remainingTime)
                    ]
                , Element.html <|
                    GameState.view
                        { width = model.window.width - 10
                        , height = model.window.height - 20
                        }
                        model.gameState
                ]
            )
        ]
    }


toTime : Int -> String
toTime seconds =
    let
        mins =
            String.fromInt (seconds // 60)

        secs =
            String.fromInt (modBy 60 seconds)
    in
    mins
        ++ ":"
        ++ (if String.length secs == 1 then
                "0" ++ secs

            else
                secs
           )


viewResults : List Tank -> Element Msg
viewResults tanks =
    let
        columns =
            [ { header = text "Name"
              , width = fill
              , view = .playerName >> text
              }
            , { header = text "Alive time"
              , width = shrink
              , view = .aliveTime >> String.fromInt >> text
              }
            , { header = text "HP"
              , width = shrink
              , view = .health >> String.fromInt >> text
              }
            ]

        tanksSorted =
            tanks
                |> List.sortBy .aliveTime
                |> List.sortBy .health
                |> List.reverse
    in
    column [ width fill ]
        [ el [ centerX ] (text "Players")
        , table [ spacing 10 ] { data = tanksSorted, columns = columns }
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        FitWindowSize window ->
            ( { model | window = window }, Cmd.none )

        GotSocket resp ->
            case resp of
                Ok socket ->
                    ( model, Channel.join socket ("game:" ++ String20.value model.battleName) )

                _ ->
                    ( model, Cmd.none )

        GotChannel resp ->
            ( { model | channel = resp |> Result.toMaybe }, Cmd.none )

        GotChannelResponse response ->
            case response of
                Ok (Channel.Sync gameState) ->
                    ( { model | gameState = gameState }, Cmd.none )

                Ok (Channel.EndBattle tanks) ->
                    ( { model | modal = EndBattle tanks }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        KeyRegisterMsg subMsg ->
            let
                ( keyRegister, keyChanges ) =
                    KeyRegister.update subMsg model.keyRegister
            in
            case model.channel of
                Nothing ->
                    ( { model | keyRegister = keyRegister }, Cmd.none )

                Just channel ->
                    ( { model | keyRegister = keyRegister }, handleKeys channel keyChanges )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ onKeyUp KeyRegister.onKeyUp |> Sub.map KeyRegisterMsg
        , onKeyDown KeyRegister.onKeyDown |> Sub.map KeyRegisterMsg
        , onVisibilityChange KeyRegister.onVisibilityChange |> Sub.map KeyRegisterMsg
        , onResize Window |> Sub.map FitWindowSize
        , Channel.subscribe GotSocket GotChannel GotChannelResponse
        ]


handleKeys : Channel -> List Key -> Cmd Msg
handleKeys channel keys =
    let
        toCmd { id, state } =
            case id of
                "ArrowLeft" ->
                    if state == KeyDown then
                        Channel.moveTank channel -1

                    else
                        Channel.moveTank channel 0

                "ArrowRight" ->
                    if state == KeyDown then
                        Channel.moveTank channel 1

                    else
                        Channel.moveTank channel 0

                "ArrowUp" ->
                    if state == KeyDown then
                        Channel.moveTurret channel 0.1

                    else
                        Channel.moveTurret channel 0

                "ArrowDown" ->
                    if state == KeyDown then
                        Channel.moveTurret channel -0.1

                    else
                        Channel.moveTurret channel 0

                " " ->
                    if state == KeyDown then
                        Channel.fire channel

                    else
                        Cmd.none

                _ ->
                    Cmd.none
    in
    keys
        |> List.map toCmd
        |> Cmd.batch


unload : Model -> Cmd msg
unload model =
    case model.channel of
        Just channel ->
            Channel.leave channel

        Nothing ->
            Cmd.none
