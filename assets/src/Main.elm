module Main exposing (main)

import Browser exposing (Document, UrlRequest(..))
import Browser.Navigation as Nav
import Data.Player as Player exposing (Authenticated, Player)
import Data.Session as Session exposing (Session)
import Data.String20 as String20 exposing (String20)
import Document
import Html exposing (Html)
import LocalStorage
import Page.Battle as Battle
import Page.ErrorPage as ErrorPage
import Page.Loading as Loading
import Page.Lodge as Lodge
import RemoteData exposing (RemoteData(..), WebData)
import Request.Players
import Route exposing (Route)
import Url exposing (Url)


type Msg
    = UrlChanged Url
    | UrlRequested UrlRequest
    | GotLocalStorageValue LocalStorage.KeyValue
    | GotPlayerVerification (WebData Player)
    | LodgeMsg Lodge.Msg
    | BattleMsg Battle.Msg


type alias Model =
    { page : Page
    , navKey : Nav.Key
    , session : Session
    }


type Page
    = ErrorPage ErrorPage.Error
    | Lodge Lodge.Model
    | Battle Battle.Model
    | Loading Route


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url navKey =
    let
        session =
            Session.init navKey Nothing
    in
    case initPageAtUrl session url of
        Just ( page, cmd ) ->
            ( { page = page
              , navKey = navKey
              , session = session
              }
            , cmd
            )

        Nothing ->
            ( { page = ErrorPage ErrorPage.NotFound
              , navKey = navKey
              , session = session
              }
            , Cmd.none
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

        Loading route ->
            Loading.view


routeToPageCmd : Session -> Route -> ( Page, Cmd Msg )
routeToPageCmd session route =
    let
        loadRoute =
            ( Loading route, LocalStorage.getItem "player_name" )
    in
    case ( route, session.player ) of
        ( _, Player.NotAsked ) ->
            loadRoute

        ( Route.Lodge, _ ) ->
            Lodge.init session
                |> Tuple.mapBoth
                    Lodge
                    (Cmd.map LodgeMsg)

        ( Route.Battle battleName, Player.Authenticated player ) ->
            Battle.init session player battleName
                |> Tuple.mapBoth
                    Battle
                    (Cmd.map BattleMsg)

        ( Route.Battle _, Player.NoPlayer ) ->
            Lodge.init session
                |> Tuple.mapBoth
                    Lodge
                    (Cmd.map LodgeMsg)


initPageAtUrl : Session -> Url -> Maybe ( Page, Cmd Msg )
initPageAtUrl session url =
    Maybe.map (routeToPageCmd session) (Route.parseUrl url)


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
            let
                unloadCmd =
                    case model.page of
                        Battle subModel ->
                            Battle.unload subModel

                        _ ->
                            Cmd.none
            in
            case initPageAtUrl model.session url of
                Just ( page, initCmd ) ->
                    ( { model | page = page }, Cmd.batch [ unloadCmd, initCmd ] )

                Nothing ->
                    ( model, Cmd.none )

        GotLocalStorageValue { key, value } ->
            case key of
                "player_name" ->
                    case Maybe.andThen String20.create value of
                        Just validName ->
                            ( model, Request.Players.requestShow GotPlayerVerification { name = validName } )

                        Nothing ->
                            updateSession (Session.setPlayer Player.NoPlayer model.session) model

                _ ->
                    ( model, Cmd.none )

        GotPlayerVerification remotePlayer ->
            let
                authenticatedPlayer =
                    case remotePlayer of
                        Success player ->
                            Player.Authenticated player

                        Failure _ ->
                            Player.NoPlayer

                        _ ->
                            Player.NotAsked

                newSession =
                    Session.setPlayer authenticatedPlayer model.session
            in
            updateSession newSession model

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
        ( page, cmd ) =
            case model.page of
                Battle subModel ->
                    ( Battle <| Session.updateSession session subModel, Cmd.none )

                Lodge subModel ->
                    ( Lodge <| Session.updateSession session subModel, Cmd.none )

                ErrorPage _ ->
                    ( model.page, Cmd.none )

                Loading route ->
                    routeToPageCmd model.session route
    in
    ( { model | page = page, session = session }
    , cmd
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

                Loading _ ->
                    Sub.none
    in
    Sub.batch
        [ LocalStorage.subscribe GotLocalStorageValue
        , pageSub
        ]


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = UrlRequested
        , onUrlChange = UrlChanged
        }
