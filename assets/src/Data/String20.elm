module Data.String20 exposing (String20, create, empty, value)


type String20
    = String20 String


create : String -> Maybe String20
create string =
    if String.length string < 20 then
        Just (String20 string)

    else
        Nothing


value : String20 -> String
value (String20 string) =
    string


empty : String20
empty =
    String20 ""
