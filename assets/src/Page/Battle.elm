module Page.Battle exposing (Model, Msg, init, subscriptions, update, view)

import Browser exposing (Document)
import Browser.Dom
import Browser.Events exposing (onAnimationFrame, onKeyDown, onKeyUp, onResize, onVisibilityChange)
import Channel exposing (Channel, Socket)
import Data.Session exposing (Session)
import Data.String20 as String20 exposing (String20)
import Element exposing (..)
import GameState exposing (Bullet, GameState, Tank)
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


type alias Window =
    { width : Int, height : Int }


getWindowSize : Cmd Msg
getWindowSize =
    let
        fromViewport { viewport } =
            Window (round viewport.width) (round viewport.height)
    in
    Browser.Dom.getViewport
        |> Task.perform (fromViewport >> FitWindowSize)


init : Session -> String20 -> ( Model, Cmd Msg )
init session battleName =
    ( { gameState = { tanks = [], bullets = [] }
      , window = { width = 1000, height = 600 }
      , battleName = battleName
      , session = session
      , channel = Nothing
      , keyRegister = KeyRegister.init
      , modal = NoModal
      }
    , case session.player of
        Nothing ->
            getWindowSize

        Just { name } ->
            Cmd.batch
                [ Channel.connect (String20.value name)
                , getWindowSize
                ]
    )


view : Model -> Document Msg
view model =
    { title = "Battle"
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
                [ Element.html <|
                    Svg.svg
                        [ Svg.Attributes.viewBox "0 0 1000 600"
                        , Svg.Attributes.width <| String.fromInt (model.window.width - 10)
                        , Svg.Attributes.height <| String.fromInt (model.window.height - 10)
                        ]
                        (GameState.viewField
                            :: List.map GameState.viewTank model.gameState.tanks
                            ++ List.map GameState.viewBullet model.gameState.bullets
                        )
                ]
            )
        ]
    }


viewResults : List Tank -> Element Msg
viewResults tanks =
    let
        columns =
            [ { header = text "Name"
              , width = fill
              , view = .playerName >> text
              }
            , { header = text "HP"
              , width = shrink
              , view = .health >> String.fromInt >> text
              }
            ]

        tanksByHealth =
            tanks
                |> List.sortBy .health
                |> List.reverse
    in
    column [ width fill ]
        [ el [ centerX ] (text "Players")
        , table [ spacing 10 ] { data = tanksByHealth, columns = columns }
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
