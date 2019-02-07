module Data.String20 exposing (String20, create, empty, length, value)


type String20
    = String20 String


create : String -> Maybe String20
create string =
    if String.length string < 20 then
        Just (String20 string)

    else
        Nothing


empty : String20
empty =
    String20 ""


value : String20 -> String
value (String20 string) =
    string


length : String20 -> Int
length (String20 string) =
    String.length string
