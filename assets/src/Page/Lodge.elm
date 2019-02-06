module Page.Lodge exposing (Model, Msg, init, subscriptions, update, view)

import Browser exposing (Document)
import Data.BattleSummary as BattleSummary exposing (BattleSummary)
import Data.Session as Session exposing (Session)
import Data.String20 as String20 exposing (String20)
import Html exposing (..)
import Html.Attributes exposing (disabled, href, value)
import Html.Events exposing (..)
import Http
import LocalStorage
import RemoteData exposing (RemoteData(..), WebData)
import Request.Lodge
import Route exposing (Route(..))


type Msg
    = NoOp
    | GotSummaries (WebData (List BattleSummary))
    | GotNewBattle (WebData BattleSummary)
    | InputPlayerName String
    | InputBattleName String
    | FixName
    | RequestStartBattle String20 String20


type alias Model =
    { newPlayerName : String20
    , newBattleName : String20
    , battles : WebData (List BattleSummary)
    , session : Session
    }


init : Session -> ( Model, Cmd Msg )
init session =
    let
        playerName =
            case session.playerName of
                Just name ->
                    name

                Nothing ->
                    String20.empty
    in
    ( { newPlayerName = playerName
      , newBattleName = String20.empty
      , battles = NotAsked
      , session = session
      }
    , Cmd.batch
        [ Request.Lodge.requestSummaries GotSummaries
        ]
    )


view : Model -> Document Msg
view model =
    { title = "Lodge"
    , body =
        case model.battles of
            Success battles ->
                [ text "Lodge"
                , viewUserForm model.session model.newPlayerName
                , viewCreateBattleForm model.session model.newBattleName
                , div [] (List.map (viewBattleSummary model.session) battles)
                ]

            _ ->
                [ text "Lodge" ]
    }


viewUserForm : Session -> String20 -> Html Msg
viewUserForm session playerName =
    case session.playerName of
        Nothing ->
            form [ onSubmit FixName ]
                [ input [ onInput InputPlayerName, value (String20.value playerName) ] []
                , button [] [ text "OK" ]
                ]

        Just name ->
            div [] [ text (String20.value name) ]


viewCreateBattleForm : Session -> String20 -> Html Msg
viewCreateBattleForm session battleName =
    case session.playerName of
        Nothing ->
            span [] []

        Just ownerName ->
            form [ onSubmit (RequestStartBattle battleName ownerName) ]
                [ input
                    [ onInput InputBattleName
                    , value (String20.value battleName)
                    ]
                    []
                , button [] [ text "OK" ]
                ]


viewBattleSummary : Session -> BattleSummary -> Html Msg
viewBattleSummary session { name, playerCount } =
    div []
        [ text (name ++ " " ++ String.fromInt playerCount)
        , case session.playerName of
            Nothing ->
                span [] []

            Just _ ->
                a [ href <| Route.toPath (Battle name) ] [ text "Join" ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GotSummaries response ->
            ( { model | battles = response }, Cmd.none )

        GotNewBattle response ->
            ( { model | battles = RemoteData.map2 (::) response model.battles }, Cmd.none )

        InputPlayerName name ->
            case String20.create name of
                Just validName ->
                    ( { model | newPlayerName = validName }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        InputBattleName name ->
            case String20.create name of
                Just validName ->
                    ( { model | newBattleName = validName }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        FixName ->
            ( model, LocalStorage.setItem { key = "player_name", value = String20.value model.newPlayerName } )

        RequestStartBattle playerName battleName ->
            ( model
            , Request.Lodge.requestStartBattle
                GotNewBattle
                (String20.value playerName)
                (String20.value battleName)
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
