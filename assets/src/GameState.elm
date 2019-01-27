module GameState exposing
    ( Bullet
    , GameState
    , Tank
    , decoder
    , viewBullet
    , viewField
    , viewTank
    )

import Json.Decode as Decode exposing (Decoder)
import Svg exposing (..)
import Svg.Attributes exposing (..)


type alias GameState =
    { tanks : List Tank
    , bullets : List Bullet
    }


type alias Position =
    { x : Int, y : Int }


type alias Bullet =
    { x : Int, y : Int }


type Direction
    = Left
    | Right


type alias Tank =
    { x : Int
    , y : Int
    , load : Int
    , turretAngle : Float
    , direction : Direction
    , life : Int
    }


wheel : Position -> Svg msg
wheel { x, y } =
    circle
        [ cx <| String.fromInt x
        , cy <| String.fromInt y
        , r "5"
        , fill "white"
        , stroke "black"
        ]
        []


track : Position -> Position -> Svg msg
track p1 p2 =
    line
        [ x1 <| String.fromInt p1.x
        , y1 <| String.fromInt p1.y
        , x2 <| String.fromInt p2.x
        , y2 <| String.fromInt p2.y
        , stroke "black"
        ]
        []


body : Svg msg
body =
    polygon
        [ points "10,25 10,20 20,15 50,15 60,20 60,25"
        , fill "white"
        , stroke "black"
        ]
        []


turretBase : Direction -> Svg msg
turretBase direction =
    polygon
        [ case direction of
            Right ->
                points "30,15 30,10 45,10 50,15"

            Left ->
                points "20,15 25,10, 40,10 40,15"
        , fill "white"
        , stroke "black"
        ]
        []


turret : Direction -> Float -> Svg msg
turret direction angle =
    let
        pointToString p =
            String.fromInt p.x ++ "," ++ String.fromInt p.y

        pointList =
            case direction of
                Left ->
                    [ { x = 22, y = 13 }
                    , { x = 20 - round (20 * cos (angle + 0.05))
                      , y = 14 - round (20 * sin (angle + 0.05))
                      }
                    , { x = 20 - round (20 * cos (angle - 0.05))
                      , y = 14 - round (20 * sin (angle - 0.05))
                      }
                    , { x = 20, y = 15 }
                    ]

                Right ->
                    [ { x = 48, y = 13 }
                    , { x = 50 + round (20 * cos (angle + 0.05))
                      , y = 14 - round (20 * sin (angle + 0.05))
                      }
                    , { x = 50 + round (20 * cos (angle - 0.05))
                      , y = 14 - round (20 * sin (angle - 0.05))
                      }
                    , { x = 50, y = 15 }
                    ]
    in
    polygon
        [ points (pointList |> List.map pointToString |> String.join " ")
        , fill "white"
        , stroke "black"
        ]
        []


loadIndicator : Direction -> Int -> Svg msg
loadIndicator direction load =
    let
        ( p1, p2 ) =
            case direction of
                Left ->
                    ( Position (40 - load // 5) 13, Position 40 13 )

                Right ->
                    ( Position 30 13, Position (30 + load // 5) 13 )
    in
    line
        [ x1 <| String.fromInt p1.x
        , y1 <| String.fromInt p1.y
        , x2 <| String.fromInt p2.x
        , y2 <| String.fromInt p2.y
        , stroke "green"
        , strokeWidth "2"
        ]
        []


lifeIndicator : Direction -> Int -> Svg msg
lifeIndicator direction life =
    let
        ( p1, p2 ) =
            case direction of
                Left ->
                    ( Position (40 - life // 5) 14, Position 40 14 )

                Right ->
                    ( Position 30 14, Position (30 + life // 5) 14 )
    in
    line
        [ x1 <| String.fromInt p1.x
        , y1 <| String.fromInt p1.y
        , x2 <| String.fromInt p2.x
        , y2 <| String.fromInt p2.y
        , stroke "blue"
        , strokeWidth "2"
        ]
        []


viewTank : Tank -> Svg msg
viewTank tank =
    svg
        [ x <| String.fromInt tank.x
        , y <| String.fromInt tank.y
        ]
        [ body
        , turretBase tank.direction
        , loadIndicator tank.direction tank.load
        , lifeIndicator tank.direction tank.life
        , turret tank.direction tank.turretAngle
        , wheel { x = 10, y = 30 }
        , wheel { x = 20, y = 35 }
        , wheel { x = 30, y = 35 }
        , wheel { x = 40, y = 35 }
        , wheel { x = 50, y = 35 }
        , wheel { x = 60, y = 30 }
        , track { x = 9, y = 35 } { x = 19, y = 40 }
        , track { x = 51, y = 40 } { x = 61, y = 35 }
        , track { x = 20, y = 40 } { x = 50, y = 40 }
        ]


viewField : Svg msg
viewField =
    line
        [ x1 "0"
        , y1 "600"
        , x2 "1000"
        , y2 "600"
        , stroke "black"
        ]
        []



-- Bullet


viewBullet : Bullet -> Svg msg
viewBullet p =
    circle
        [ cx <| String.fromInt p.x
        , cy <| String.fromInt p.y
        , r "1"
        , fill "black"
        , stroke "black"
        ]
        []



-- Decoders


decoder : Decoder GameState
decoder =
    Decode.map2 GameState
        (Decode.field "tanks" (Decode.list tankDecoder))
        (Decode.field "bullets" (Decode.list bulletDecoder))


tankDecoder : Decoder Tank
tankDecoder =
    Decode.map6 Tank
        (Decode.field "x" Decode.int)
        (Decode.field "y" Decode.int)
        (Decode.field "load" Decode.int)
        (Decode.field "turret_angle" Decode.float)
        (Decode.field "direction" directionDecoder)
        (Decode.field "health" Decode.int)


bulletDecoder : Decoder Bullet
bulletDecoder =
    Decode.map2 Bullet
        (Decode.field "x" Decode.int)
        (Decode.field "y" Decode.int)


directionDecoder : Decoder Direction
directionDecoder =
    Decode.string
        |> Decode.andThen
            (\direction ->
                case direction of
                    "left" ->
                        Decode.succeed Left

                    "right" ->
                        Decode.succeed Right

                    _ ->
                        Decode.fail "invalid direction"
            )
