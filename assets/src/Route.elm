module Route exposing (Route(..), parseUrl, toPath)

import Data.String20 as String20 exposing (String20)
import Url exposing (Url)
import Url.Builder exposing (absolute)
import Url.Parser as Url exposing ((</>), Parser, map, oneOf, s, string, top)


type Route
    = Lodge
    | Battle String20


string20 : Parser (String20 -> a) a
string20 =
    Url.custom "STRING20" String20.create


parseUrl : Url -> Maybe Route
parseUrl url =
    Url.parse
        (oneOf
            [ map Lodge top
            , map Battle (s "battle" </> string20)
            ]
        )
        url


toPath : Route -> String
toPath route =
    case route of
        Lodge ->
            absolute [] []

        Battle battleName ->
            absolute [ "battle", String20.value battleName ] []
