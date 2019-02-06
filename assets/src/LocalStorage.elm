port module LocalStorage exposing (KeyValue, getItem, removeItem, setItem, subscribe)


type alias KeyValue =
    { key : String, value : Maybe String }


port setItem : KeyValue -> Cmd msg


port getItem : String -> Cmd msg


port removeItem : String -> Cmd msg


port localStorageSubscribe : (KeyValue -> msg) -> Sub msg


subscribe : (KeyValue -> msg) -> Sub msg
subscribe =
    localStorageSubscribe
