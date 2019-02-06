module Route exposing (Route(..), parseUrl, toPath)

import Url exposing (Url)
import Url.Builder exposing (absolute)
import Url.Parser as Url exposing ((</>), map, oneOf, s, string, top)


type Route
    = Lodge
    | Battle String


parseUrl : Url -> Maybe Route
parseUrl url =
    Url.parse
        (oneOf
            [ map Lodge top
            , map Battle (s "battle" </> string)
            ]
        )
        url


toPath : Route -> String
toPath route =
    case route of
        Lodge ->
            absolute [] []

        Battle battleName ->
            absolute [ "battle", battleName ] []
