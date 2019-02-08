module Page.Lodge exposing (Model, Msg, init, subscriptions, update, view)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Data.BattleSummary as BattleSummary exposing (BattleInit, BattleSummary)
import Data.Player exposing (Player)
import Data.Session as Session exposing (Session)
import Data.String20 as String20 exposing (String20)
import Element exposing (..)
import Element.Input as Input
import Http
import LocalStorage
import RemoteData exposing (RemoteData(..), WebData)
import Request.Battles
import Request.Players
import Route exposing (Route(..))
import Validated exposing (Validated(..))


type Msg
    = NoOp
    | GotSummaries (WebData (List BattleSummary))
    | GotNewBattle (WebData BattleSummary)
    | InputPlayerName String
    | InputBattleName String
    | SaveName
    | PlayerSaved (WebData Player)
    | EditName
    | PlayerDeleted (Result Http.Error ())
    | RequestStartBattle BattleInit


type alias Model =
    { newPlayerName : Validated String20
    , newBattleName : Validated String20
    , battles : WebData (List BattleSummary)
    , session : Session
    }


init : Session -> ( Model, Cmd Msg )
init session =
    let
        playerName =
            case session.player of
                Just { name } ->
                    Valid name

                Nothing ->
                    Valid String20.empty
    in
    ( { newPlayerName = playerName
      , newBattleName = Valid String20.empty
      , battles = NotAsked
      , session = session
      }
    , Cmd.batch
        [ Request.Battles.requestList GotSummaries
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


viewUserForm : Session -> Validated String20 -> Element Msg
viewUserForm session playerName =
    case session.player of
        Nothing ->
            column []
                [ row [ paddingEach { left = 150, top = 0, right = 0, bottom = 0 } ]
                    [ text <| Validated.error playerName ]
                , row [ width fill, spacing 10 ]
                    [ Input.text [ centerX ]
                        { onChange = InputPlayerName
                        , text = (String20.value << Validated.value) playerName
                        , placeholder = Nothing
                        , label = Input.labelLeft [ width (px 150), centerY ] (text "Player name:")
                        }
                    , Input.button [ alignRight ]
                        { onPress =
                            case playerName of
                                Valid _ ->
                                    Just SaveName

                                Invalid _ _ ->
                                    Nothing
                        , label = text "OK"
                        }
                    ]
                ]

        Just { name } ->
            row [ width fill, spacing 10 ]
                [ el [ width (px 150), centerY ] (text "Player name:")
                , el [] (text <| String20.value name)
                , Input.button [ alignRight ]
                    { onPress = Just EditName, label = text "Edit" }
                ]


viewCreateBattleForm : Session -> Validated String20 -> Element Msg
viewCreateBattleForm session battleName =
    case session.player of
        Nothing ->
            Element.none

        Just player ->
            column []
                [ row [ paddingEach { left = 150, top = 0, right = 0, bottom = 0 } ]
                    [ text <| Validated.error battleName ]
                , row [ width fill, spacing 10 ]
                    [ Input.text []
                        { onChange = InputBattleName
                        , text = (String20.value << Validated.value) battleName
                        , placeholder = Nothing
                        , label = Input.labelLeft [ width (px 150), centerY ] (text "Battle name:")
                        }
                    , Input.button [ alignRight ]
                        { onPress =
                            case battleName of
                                Valid validName ->
                                    Just (RequestStartBattle { name = validName, ownerName = player.name })

                                Invalid _ _ ->
                                    Nothing
                        , label = text "OK"
                        }
                    ]
                ]


viewBattles : Session -> List BattleSummary -> Element Msg
viewBattles session battles =
    let
        columns =
            [ { header = text "Name"
              , width = fill
              , view = .name >> String20.value >> text
              }
            , { header = text "Players"
              , width = shrink
              , view = .playerCount >> String.fromInt >> text
              }
            , { header = Element.none
              , width = shrink
              , view =
                    \{ name } ->
                        case session.player of
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
            case response of
                Success newBattle ->
                    ( model
                    , Nav.pushUrl model.session.navKey (Route.toPath (Route.Battle newBattle.name))
                    )

                Failure (Http.BadStatus 409) ->
                    ( { model
                        | newBattleName =
                            Validated.invalidate
                                "This name is already used."
                                model.newBattleName
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        InputPlayerName name ->
            let
                playerName =
                    Validated.map String20.createTrim (Validated.min 1 "Please insert a name" name)
            in
            ( { model | newPlayerName = playerName }, Cmd.none )

        InputBattleName name ->
            let
                battleName =
                    Validated.map String20.createTrim (Validated.min 1 "Please insert a name" name)
            in
            ( { model | newBattleName = battleName }, Cmd.none )

        SaveName ->
            ( model
            , Request.Players.requestCreate PlayerSaved (Player (Validated.value model.newPlayerName))
            )

        PlayerSaved remotePlayer ->
            case remotePlayer of
                Success player ->
                    ( model
                    , LocalStorage.setItem
                        { key = "player_name"
                        , value = Just (String20.value player.name)
                        }
                    )

                Failure (Http.BadStatus 409) ->
                    ( { model
                        | newPlayerName =
                            Validated.invalidate
                                "This name is already used."
                                model.newPlayerName
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        EditName ->
            case model.session.player of
                Just player ->
                    ( model, Request.Players.requestDelete PlayerDeleted player )

                Nothing ->
                    ( model, Cmd.none )

        PlayerDeleted response ->
            case response of
                Ok () ->
                    ( model, LocalStorage.removeItem "player_name" )

                Err _ ->
                    ( model, Cmd.none )

        RequestStartBattle battleInit ->
            ( model, Request.Battles.requestCreate GotNewBattle battleInit )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
