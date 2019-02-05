module Page.Battle exposing (Model, Msg, init, subscriptions, update, view)

import Browser exposing (Document)
import Browser.Events exposing (onAnimationFrame, onKeyDown, onKeyUp, onResize)
import Channel
import GameState exposing (Bullet, GameState, Tank)
import Html exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Set exposing (Set)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Time exposing (Posix, every)


type Msg
    = NoOp
    | ResizeWindow Int Int
    | KeyUp Key
    | KeyDown Key
    | ChannelMsg Channel.Msg


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
    }


type alias Flags =
    { window : { width : Int, height : Int } }


init : String -> ( Model, Cmd Msg )
init battleName =
    ( { gameState = { tanks = [], bullets = [] }
      , window = { width = 1000, height = 600 }
      , battleName = battleName
      }
    , Channel.join ("game:" ++ battleName)
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
            , case key of
                ArrowRight ->
                    Channel.moveTank 1

                ArrowLeft ->
                    Channel.moveTank -1

                ArrowUp ->
                    Channel.moveTurret 0.1

                ArrowDown ->
                    Channel.moveTurret -0.1

                SpaceBar ->
                    Channel.fire
            )

        KeyUp key ->
            ( model
            , case key of
                ArrowRight ->
                    Channel.moveTank 0

                ArrowLeft ->
                    Channel.moveTank 0

                ArrowUp ->
                    Channel.moveTurret 0

                ArrowDown ->
                    Channel.moveTurret 0

                SpaceBar ->
                    Cmd.none
            )

        ResizeWindow w h ->
            ( { model | window = { width = w, height = h } }, Cmd.none )

        ChannelMsg channelMsg ->
            case channelMsg of
                Channel.NoOp ->
                    ( model, Cmd.none )

                Channel.Sync gameState ->
                    ( { model | gameState = gameState }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ onKeyUp (keyDecoder KeyUp)
        , onKeyDown (keyDecoder KeyDown)
        , onResize ResizeWindow
        , Channel.receive (Channel.responseToMsg >> ChannelMsg)
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
