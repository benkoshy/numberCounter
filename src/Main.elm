module Main exposing (..)

import Browser
import Browser.Events exposing (onAnimationFrameDelta)
import Html exposing (Html, button, div, h1, hr, p, text)
import Html.Attributes exposing (class, src)
import Html.Events exposing (onClick)
import List exposing (head, map, range)
import Random
import Random.List exposing (shuffle)
import List.Extra exposing (groupsOf)
import List exposing (..)
import Time


{-
   To do:
       
       (2) Master piping operations. |> and <| till you are completely comfortable with it.
       (3) Fix the problem of splitting lists into rows and displaying them:
       	   https://stackoverflow.com/questions/37361229/elm-split-list-into-multiple-lists
       (4) Fix the layout: we'd like everything a little more square
           Understanding bootstrap: https://medium.com/wdstack/bootstrap-equal-height-columns-d07bc934eb27
           also see here: https://stackoverflow.com/questions/19695784/how-can-i-make-bootstrap-columns-all-the-same-height#comment56504018_19695851
           https://stackoverflow.com/questions/20456694/grid-of-responsive-squares
           https://stackoverflow.com/a/49692667/4880924
           Adding a display flex will change the height stretchability of the item: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Flexible_Box_Layout/Basic_Concepts_of_Flexbox i.e.  If some items are taller than others, all items will stretch along the cross axis to fill its full size.
       (5) do testing in elm
       (6) fix the styling  
       (7) fix the timer     
       (8) Fix bug: timer should only start when the correct number is pressed.	   
-}
---- MODEL ----


type alias Model =
    { timer : Float
    , gameState : GameState
    , currentNumber : Int
    , numbers : List Int
    }


initialModel : Model
initialModel =
    { timer = 0, gameState = NotStarted, currentNumber = 0, numbers = [] }


init : ( Model, Cmd Msg )
init =
    ( initialModel, Random.generate RandomizeNumbers (Random.List.shuffle (range startingNumber endingNumber) ) )

---- Configuration ----

startingNumber : Int
startingNumber = 1

endingNumber : Int
endingNumber = 36

---- UPDATE ----


type Msg
    = NoOp
    | Tick Time.Posix
    | ResetGame
    | NumberPress Int
    | RandomizeNumbers (List Int)


type GameState 
    = NotStarted
    | Running
    | End

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Tick newTime ->
            ( { model | timer = model.timer + 1.0 }, Cmd.none )

        ResetGame ->
            init

        NumberPress number ->
            let
                newNumber =
                    if number == (model.currentNumber + 1) then
                        model.currentNumber + 1

                    else
                        model.currentNumber

                newSubs =
                    if model.gameState == NotStarted then
                        Running
                    else if number == endingNumber && model.currentNumber == (endingNumber - 1 )then 
                        End
                    else
                        model.gameState
            in
            ( { model | currentNumber = newNumber, gameState = newSubs }, Cmd.none )

        RandomizeNumbers numbers ->
            ({model | numbers = numbers}, Cmd.none )



---- SUBSCRIPTIONS ----


subscriptions model =
    if model.gameState == Running then
        Time.every 100 Tick
    else
        Sub.none

---- VIEW ----


view : Model -> Html Msg
view model =
    let
        timerString = String.fromFloat (model.timer / 10)      
        formattedTimerString =  if not (String.contains "." timerString) then
                                   timerString ++ ".0"
                                else
                                    timerString
    in
        
    div []
        (instructions
            ++ [showButtons model]
            ++ [ h1 [] [ text ("Timer: " ++ formattedTimerString) ]
               , hr [] []
               , if model.gameState /= NotStarted then
                    button [ class "btn btn-primary", onClick ResetGame ] [ text "Reset Game" ]
                 else
                    text ""
               ]
        )


instructions : List (Html Msg)
instructions =
    [ h1 [] [ text "The Number Game:" ]
    , p [] [ text ("Click from 1 through to " ++ String.fromInt(endingNumber) ++ " as fast as you can!") ]
    , hr [] []
    ]

split : Int -> List a -> List (List a)
split i list =
  case take i list of
    [] -> []
    listHead -> listHead :: split i (drop i list)

showButtons : Model -> Html Msg
showButtons model =
    div [class "container"] ( (split 6  <| model.numbers)  |> List.map (\x -> showButtonRow model x))


showButtonRow : Model -> List Int -> Html Msg
showButtonRow model list =
    div [class "row no-gutters"] (List.map (\x -> showButton x model.currentNumber) list )  

showButton : Int -> Int -> Html Msg
showButton buttonNumber currentNumber =
    let
        highlightCurrentButton =
            if buttonNumber == currentNumber then
                "btn-outline-dark btn-block btn btn-danger "
            else if buttonNumber == startingNumber && currentNumber == 0 then
                "btn-outline-dark btn-block btn btn-success"
            else if buttonNumber < currentNumber then
                "btn-outline-dark btn-block btn btn-link"
            else
                "btn-outline-dark btn-block btn btn-light"
    in    
        div [class "col-2 d-flex justify-content-center align-items-center"] 
            [button [ class highlightCurrentButton, onClick (NumberPress buttonNumber) ] [ text (String.fromInt buttonNumber) ]]
        

---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = subscriptions
        }
