module Main exposing (Model, Msg(..))

import Browser
import Browser.Events exposing (onAnimationFrame, onKeyDown, onKeyUp, onResize)
import Channel
import Html exposing (..)
import Json.Decode as Decode exposing (Decoder)
import Set exposing (Set)
import Svg exposing (..)
import Svg.Attributes exposing (..)
import Tank exposing (Bullet, Tank)
import Time exposing (Posix, every)


type Msg
    = NoOp
    | ResizeWindow Int Int
    | KeyUp String
    | KeyDown String
    | ChannelMsg Channel.Msg


type alias Model =
    { activeKeys : Set String
    , tanks : List Tank
    , window : { width : Int, height : Int }
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { activeKeys = Set.empty
      , tanks = []
      , window = { width = 1000, height = 600 }
      }
    , Channel.join "game:lobby"
    )


view : Model -> Html Msg
view model =
    div []
        [ svg
            [ viewBox "0 0 1000 600"
            , width <| String.fromInt (model.window.width - 10)
            , height <| String.fromInt (model.window.height - 10)
            ]
            (List.map Tank.view model.tanks
                ++ (List.map (.bullets >> List.map Tank.viewBullet) model.tanks
                        |> List.concat
                   )
            )
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        KeyDown key ->
            let
                activeKeys =
                    Set.insert key model.activeKeys
            in
            ( { model | activeKeys = activeKeys }
            , evalKeys activeKeys model
            )

        KeyUp key ->
            let
                activeKeys =
                    Set.remove key model.activeKeys
            in
            ( { model | activeKeys = activeKeys }
            , evalKeys activeKeys model
            )

        ResizeWindow w h ->
            ( { model | window = { width = w, height = h } }, Cmd.none )

        ChannelMsg channelMsg ->
            case channelMsg of
                Channel.NoOp ->
                    ( model, Cmd.none )

                Channel.UpdateTanks tanks ->
                    ( { model | tanks = tanks }, Cmd.none )


evalKeys : Set String -> Model -> Cmd Msg
evalKeys activeKeys model =
    let
        evalMove =
            if Set.member "ArrowRight" activeKeys then
                Channel.moveTank 1

            else if Set.member "ArrowLeft" activeKeys then
                Channel.moveTank -1

            else
                Channel.moveTank 0

        evalMoveTurret =
            if Set.member "ArrowUp" activeKeys then
                Channel.moveTurret 0.01

            else if Set.member "ArrowDown" activeKeys then
                Channel.moveTurret -0.01

            else
                Channel.moveTurret 0

        evalFire =
            if Set.member " " activeKeys then
                Channel.fire

            else
                Cmd.none
    in
    Cmd.batch [ evalMove, evalMoveTurret, evalFire ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ onKeyUp (keyDecoder KeyUp)
        , onKeyDown (keyDecoder KeyDown)
        , onResize ResizeWindow
        , Channel.receive (Channel.responseToMsg >> ChannelMsg)
        ]


keyDecoder : (String -> Msg) -> Decoder Msg
keyDecoder toMsg =
    Decode.field "key" Decode.string
        |> Decode.map toMsg


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
