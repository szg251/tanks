module Main exposing (main)

import Browser exposing (Document, UrlRequest(..))
import Browser.Navigation as Nav
import Document
import Html exposing (Html)
import Page.Battle as Battle
import Page.ErrorPage as ErrorPage
import Page.Lodge as Lodge
import Route
import Url exposing (Url)


type Msg
    = UrlChanged Url
    | UrlRequested UrlRequest
    | LodgeMsg Lodge.Msg
    | BattleMsg Battle.Msg


type alias Model =
    { page : Page
    , navKey : Nav.Key
    }


type Page
    = ErrorPage ErrorPage.Error
    | Lodge Lodge.Model
    | Battle Battle.Model


init : () -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url navKey =
    case urlToPage url of
        Just ( page, cmd ) ->
            ( { page = page, navKey = navKey }, cmd )

        Nothing ->
            ( { page = ErrorPage ErrorPage.NotFound, navKey = navKey }, Cmd.none )


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


urlToPage : Url -> Maybe ( Page, Cmd Msg )
urlToPage url =
    let
        routeToPageCmd route =
            case route of
                Route.Lodge ->
                    Lodge.init
                        |> Tuple.mapBoth
                            Lodge
                            (Cmd.map LodgeMsg)

                Route.Battle battleName ->
                    Battle.init battleName
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
            case urlToPage url of
                Just ( page, cmd ) ->
                    ( { model | page = page }, cmd )

                Nothing ->
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


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        Lodge subModel ->
            Lodge.subscriptions subModel
                |> Sub.map LodgeMsg

        Battle subModel ->
            Battle.subscriptions subModel
                |> Sub.map BattleMsg

        ErrorPage _ ->
            Sub.none


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
