module Page.Lodge exposing (Model, Msg, init, subscriptions, update, view)

import Browser exposing (Document)
import Data.BattleSummary as BattleSummary exposing (BattleSummary)
import Html exposing (..)
import Http
import RemoteData exposing (RemoteData(..), WebData)
import Url.Builder


type Msg
    = NoOp
    | GotSummaries (WebData (List BattleSummary))


type alias Model =
    { battles : WebData (List BattleSummary) }


init : ( Model, Cmd Msg )
init =
    ( { battles = NotAsked }, requestSummaries )


view : Model -> Document Msg
view model =
    { title = "Lodge"
    , body =
        case model.battles of
            Success battles ->
                [ text "Lodge"
                , div [] (List.map viewBattleSummary battles)
                ]

            _ ->
                [ text "Lodge" ]
    }


viewBattleSummary : BattleSummary -> Html Msg
viewBattleSummary { name, playerCount } =
    div [] [ text (name ++ " " ++ String.fromInt playerCount) ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GotSummaries response ->
            ( { model | battles = response }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


requestSummaries : Cmd Msg
requestSummaries =
    Http.get
        { url = Url.Builder.absolute [ "api", "battles" ] []
        , expect = Http.expectJson (RemoteData.fromResult >> GotSummaries) BattleSummary.responseDecoder
        }
