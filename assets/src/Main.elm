module Main exposing (main)

import Browser exposing (Document, UrlRequest(..))
import Browser.Navigation as Nav
import Data.Session as Session exposing (Session)
import Data.String20 as String20 exposing (String20)
import Document
import Html exposing (Html)
import LocalStorage
import Page.Battle as Battle
import Page.ErrorPage as ErrorPage
import Page.Lodge as Lodge
import Route
import Url exposing (Url)


type Msg
    = UrlChanged Url
    | UrlRequested UrlRequest
    | GotLocalStorageValue LocalStorage.KeyValue
    | LodgeMsg Lodge.Msg
    | BattleMsg Battle.Msg


type alias Model =
    { page : Page
    , navKey : Nav.Key
    , session : Session
    }


type alias Flags =
    { playerName : Maybe String
    , window : Window
    }


type alias Window =
    { width : Int, height : Int }


type Page
    = ErrorPage ErrorPage.Error
    | Lodge Lodge.Model
    | Battle Battle.Model


init : Flags -> Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url navKey =
    let
        session =
            Session.init flags
    in
    case initPageAtUrl session url of
        Just ( page, cmd ) ->
            ( { page = page
              , navKey = navKey
              , session = session
              }
            , Cmd.batch [ cmd, LocalStorage.getItem "player_name" ]
            )

        Nothing ->
            ( { page = ErrorPage ErrorPage.NotFound
              , navKey = navKey
              , session = session
              }
            , LocalStorage.getItem "player_name"
            )


view : Model -> Document Msg
view model =
    case model.page of
        Lodge subModel ->
            Lodge.view subModel
                |> Document.map LodgeMsg

        Battle subModel ->
            Battle.view subModel
                |> Document.map BattleMsg

        ErrorPage error ->
            ErrorPage.view error


initPageAtUrl : Session -> Url -> Maybe ( Page, Cmd Msg )
initPageAtUrl session url =
    let
        routeToPageCmd route =
            case route of
                Route.Lodge ->
                    Lodge.init session
                        |> Tuple.mapBoth
                            Lodge
                            (Cmd.map LodgeMsg)

                Route.Battle battleName ->
                    Battle.init session battleName
                        |> Tuple.mapBoth
                            Battle
                            (Cmd.map BattleMsg)
    in
    Maybe.map routeToPageCmd (Route.parseUrl url)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlRequested urlRequest ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.navKey (Url.toString url)
                    )

                External url ->
                    ( model, Nav.load url )

        UrlChanged url ->
            case initPageAtUrl model.session url of
                Just ( page, cmd ) ->
                    ( { model | page = page }, cmd )

                Nothing ->
                    ( model, Cmd.none )

        GotLocalStorageValue { key, value } ->
            case key of
                "player_name" ->
                    updateSession (Session.setPlayerName value model.session) model

                _ ->
                    ( model, Cmd.none )

        LodgeMsg subMsg ->
            case model.page of
                Lodge subModel ->
                    let
                        ( newSubModel, cmd ) =
                            Lodge.update subMsg subModel
                    in
                    ( { model | page = Lodge newSubModel }, cmd |> Cmd.map LodgeMsg )

                _ ->
                    ( model, Cmd.none )

        BattleMsg subMsg ->
            case model.page of
                Battle subModel ->
                    let
                        ( newSubModel, cmd ) =
                            Battle.update subMsg subModel
                    in
                    ( { model | page = Battle newSubModel }, cmd |> Cmd.map BattleMsg )

                _ ->
                    ( model, Cmd.none )


updateSession : Session -> Model -> ( Model, Cmd Msg )
updateSession session model =
    let
        page =
            case model.page of
                Battle subModel ->
                    Battle <| Session.updateSession session subModel

                Lodge subModel ->
                    Lodge <| Session.updateSession session subModel

                ErrorPage _ ->
                    model.page
    in
    ( { model | page = page, session = session }
    , Cmd.none
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        pageSub =
            case model.page of
                Lodge subModel ->
                    Lodge.subscriptions subModel
                        |> Sub.map LodgeMsg

                Battle subModel ->
                    Battle.subscriptions subModel
                        |> Sub.map BattleMsg

                ErrorPage _ ->
                    Sub.none
    in
    Sub.batch
        [ LocalStorage.subscribe GotLocalStorageValue
        , pageSub
        ]


main : Program Flags Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }
