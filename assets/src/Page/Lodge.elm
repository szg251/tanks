module Page.Lodge exposing (Model, Msg, init, subscriptions, update, view)

import Browser exposing (Document)
import Data.BattleSummary as BattleSummary exposing (BattleSummary)
import Data.String20 as String20 exposing (String20)
import Html exposing (..)
import Html.Attributes exposing (disabled, href, value)
import Html.Events exposing (..)
import Http
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
    { playerName : PlayerName
    , newBattleName : String20
    , battles : WebData (List BattleSummary)
    }


type PlayerName
    = EditablePlayerName String20
    | FixedPlayerName String20


isFixed : PlayerName -> Bool
isFixed playerName =
    case playerName of
        FixedPlayerName _ ->
            True

        _ ->
            False


init : ( Model, Cmd Msg )
init =
    ( { playerName = EditablePlayerName String20.empty
      , newBattleName = String20.empty
      , battles = NotAsked
      }
    , Request.Lodge.requestSummaries GotSummaries
    )


view : Model -> Document Msg
view model =
    { title = "Lodge"
    , body =
        case model.battles of
            Success battles ->
                [ text "Lodge"
                , viewUserForm model.playerName
                , viewCreateBattleForm model.playerName model.newBattleName
                , div [] (List.map (viewBattleSummary model.playerName) battles)
                ]

            _ ->
                [ text "Lodge" ]
    }


viewUserForm : PlayerName -> Html Msg
viewUserForm playerName =
    case playerName of
        EditablePlayerName name ->
            form [ onSubmit FixName ]
                [ input [ onInput InputPlayerName, value (String20.value name) ] []
                , button [] [ text "OK" ]
                ]

        FixedPlayerName name ->
            div [] [ text (String20.value name) ]


viewCreateBattleForm : PlayerName -> String20 -> Html Msg
viewCreateBattleForm playerName battleName =
    case playerName of
        EditablePlayerName _ ->
            span [] []

        FixedPlayerName ownerName ->
            form [ onSubmit (RequestStartBattle battleName ownerName) ]
                [ input
                    [ onInput InputBattleName
                    , value (String20.value battleName)
                    ]
                    []
                , button [] [ text "OK" ]
                ]


viewBattleSummary : PlayerName -> BattleSummary -> Html Msg
viewBattleSummary playerName { name, playerCount } =
    div []
        [ text (name ++ " " ++ String.fromInt playerCount)
        , if isFixed playerName then
            a [ href <| Route.toPath (Battle name) ] [ text "Join" ]

          else
            span [] []
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
            case ( model.playerName, String20.create name ) of
                ( EditablePlayerName _, Just validName ) ->
                    ( { model | playerName = EditablePlayerName validName }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        InputBattleName name ->
            case String20.create name of
                Just validName ->
                    ( { model | newBattleName = validName }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        FixName ->
            case model.playerName of
                EditablePlayerName name ->
                    ( { model | playerName = FixedPlayerName name }, Cmd.none )

                FixedPlayerName _ ->
                    ( model, Cmd.none )

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
