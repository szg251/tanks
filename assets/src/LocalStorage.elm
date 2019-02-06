port module LocalStorage exposing (KeyValue, getItem, setItem, subscribe)


type alias KeyValue =
    { key : String, value : String }


port setItem : KeyValue -> Cmd msg


port getItem : String -> Cmd msg


port localStorageSubscribe : (KeyValue -> msg) -> Sub msg


subscribe : (KeyValue -> msg) -> Sub msg
subscribe =
    localStorageSubscribe
