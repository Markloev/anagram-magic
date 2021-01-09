module View.Style exposing (style)

import Element exposing (Attribute, Color)
import Html.Attributes


style : String -> String -> Attribute msg
style k v =
    Html.Attributes.style k v
        |> Element.htmlAttribute