module Page.Lodge exposing (Model, Msg, init, subscriptions, update, view)

import Browser exposing (Document)
import Data.BattleSummary as BattleSummary exposing (BattleSummary)
import Data.Session as Session exposing (Session)
import Data.String20 as String20 exposing (String20)
import Element exposing (..)
import Element.Input as Input
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
        [ Element.layout []
            (case model.battles of
                Success battles ->
                    Element.column [ width (px 500), centerX, spacing 20 ]
                        [ viewHeader
                        , viewUserForm model.session model.newPlayerName
                        , viewCreateBattleForm model.session model.newBattleName
                        , viewBattles model.session battles
                        ]

                _ ->
                    viewHeader
            )
        ]
    }


viewHeader : Element Msg
viewHeader =
    row [ width fill, height (px 50) ] [ el [ centerX, centerY ] (text "Lodge") ]


viewUserForm : Session -> String20 -> Element Msg
viewUserForm session playerName =
    case session.playerName of
        Nothing ->
            row []
                [ Input.text [ centerX ]
                    { onChange = InputPlayerName
                    , text = String20.value playerName
                    , placeholder = Nothing
                    , label = Input.labelLeft [ width (px 150) ] (text "Player name:")
                    }
                , Input.button [] { onPress = Just FixName, label = text "OK" }
                ]

        Just name ->
            row [] [ el [ width (px 150) ] (text "Player name:"), el [] (text <| String20.value name) ]


viewCreateBattleForm : Session -> String20 -> Element Msg
viewCreateBattleForm session battleName =
    case session.playerName of
        Nothing ->
            Element.none

        Just ownerName ->
            row [ spacing 10 ]
                [ Input.text []
                    { onChange = InputBattleName
                    , text = String20.value battleName
                    , placeholder = Nothing
                    , label = Input.labelLeft [ width (px 150) ] (text "Battle name:")
                    }
                , Input.button []
                    { onPress = Just (RequestStartBattle battleName ownerName)
                    , label = text "OK"
                    }
                ]


viewBattles : Session -> List BattleSummary -> Element Msg
viewBattles session battles =
    let
        columns =
            [ { header = text "Name"
              , width = fill
              , view = .name >> text
              }
            , { header = text "Players"
              , width = shrink
              , view = .playerCount >> String.fromInt >> text
              }
            , { header = Element.none
              , width = shrink
              , view =
                    \{ name } ->
                        case session.playerName of
                            Nothing ->
                                Element.none

                            Just _ ->
                                link [ alignRight ] { url = Route.toPath (Battle name), label = text "Join" }
              }
            ]
    in
    column [ width fill ]
        [ el [ centerX ] (text "Battles")
        , table [ spacing 10 ] { data = battles, columns = columns }
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
