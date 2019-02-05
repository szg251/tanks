module Route exposing (Route(..), parseUrl)

import Url exposing (Url)
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
