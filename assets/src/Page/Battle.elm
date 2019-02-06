module Page.Battle exposing (Model, Msg, init, subscriptions, update, view)

import Browser exposing (Document)
import Browser.Dom
import Browser.Events exposing (onAnimationFrame, onKeyDown, onKeyUp, onResize)
import Channel exposing (Channel, Socket)
import Data.Session exposing (Session)
import Data.String20 as String20 exposing (String20)
import GameState exposing (Bullet, GameState, Tank)
import Html exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Set exposing (Set)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Task
import Time exposing (Posix, every)


type Msg
    = NoOp
    | FitWindowSize Window
    | KeyUp Key
    | KeyDown Key
    | GotSocket (Result Decode.Error Socket)
    | GotChannel (Result Decode.Error Channel)
    | GotChannelResponse (Result Decode.Error Channel.Response)


type Key
    = ArrowRight
    | ArrowLeft
    | ArrowUp
    | ArrowDown
    | SpaceBar


type alias Model =
    { gameState : GameState
    , window : { width : Int, height : Int }
    , battleName : String
    , session : Session
    , channel : Maybe Channel
    }


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


init : Session -> String -> ( Model, Cmd Msg )
init session battleName =
    ( { gameState = { tanks = [], bullets = [] }
      , window = { width = 1000, height = 600 }
      , battleName = battleName
      , session = session
      , channel = Nothing
      }
    , case session.playerName of
        Nothing ->
            getWindowSize

        Just name ->
            Cmd.batch
                [ Channel.connect (String20.value name)
                , getWindowSize
                ]
    )


view : Model -> Document Msg
view model =
    { title = "Battle"
    , body =
        [ svg
            [ viewBox "0 0 1000 600"
            , width <| String.fromInt (model.window.width - 10)
            , height <| String.fromInt (model.window.height - 10)
            ]
            (GameState.viewField
                :: List.map GameState.viewTank model.gameState.tanks
                ++ List.map GameState.viewBullet model.gameState.bullets
            )
        ]
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        KeyDown key ->
            ( model
            , case model.channel of
                Just channel ->
                    case key of
                        ArrowRight ->
                            Channel.moveTank channel 1

                        ArrowLeft ->
                            Channel.moveTank channel -1

                        ArrowUp ->
                            Channel.moveTurret channel 0.1

                        ArrowDown ->
                            Channel.moveTurret channel -0.1

                        SpaceBar ->
                            Channel.fire channel

                Nothing ->
                    Cmd.none
            )

        KeyUp key ->
            ( model
            , case model.channel of
                Just channel ->
                    case key of
                        ArrowRight ->
                            Channel.moveTank channel 0

                        ArrowLeft ->
                            Channel.moveTank channel 0

                        ArrowUp ->
                            Channel.moveTurret channel 0

                        ArrowDown ->
                            Channel.moveTurret channel 0

                        SpaceBar ->
                            Cmd.none

                Nothing ->
                    Cmd.none
            )

        FitWindowSize window ->
            ( { model | window = window }, Cmd.none )

        GotSocket resp ->
            case resp of
                Ok socket ->
                    ( model, Channel.join socket ("game:" ++ model.battleName) )

                _ ->
                    ( model, Cmd.none )

        GotChannel resp ->
            ( { model | channel = resp |> Result.toMaybe }, Cmd.none )

        GotChannelResponse response ->
            case response of
                Ok (Channel.Sync gameState) ->
                    ( { model | gameState = gameState }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ onKeyUp (keyDecoder KeyUp)
        , onKeyDown (keyDecoder KeyDown)
        , onResize Window
            |> Sub.map FitWindowSize
        , Channel.subscribe GotSocket GotChannel GotChannelResponse
        ]


keyDecoder : (Key -> Msg) -> Decoder Msg
keyDecoder toMsg =
    let
        toKey key =
            case key of
                "ArrowUp" ->
                    Decode.succeed ArrowUp

                "ArrowDown" ->
                    Decode.succeed ArrowDown

                "ArrowLeft" ->
                    Decode.succeed ArrowLeft

                "ArrowRight" ->
                    Decode.succeed ArrowRight

                " " ->
                    Decode.succeed SpaceBar

                _ ->
                    Decode.fail "Not a controller key"
    in
    Decode.field "key" Decode.string
        |> Decode.andThen toKey
        |> Decode.map toMsg
