module View exposing (view)

import Char
import Color exposing (rgb)
import Html exposing (..)
import Html.Attributes exposing (class, href, id, placeholder, src, title, type_, value)
import Html.Events exposing (onBlur, onClick, onFocus, onInput, onSubmit)
import Http exposing (Error(BadStatus))
import Json.Decode as Decode
import RemoteData exposing (RemoteData(Failure, Loading, NotAsked, Success), WebData)
import Time exposing (Time)
import Action exposing (..)
import App.Model exposing (App)
import App.View exposing (viewAppItem, viewAppsTable)
import Container
import Error
import Formo exposing (Form, elementErrors, elementIsFocused, elementIsValid, elementValue, formIsValidated)
import Loader
import Member.Model exposing (Member)
import Model exposing (Model, isLoggedIn)
import Route
import Rule.Model exposing (Rule)
import Rule.View exposing (viewRule, viewRuleItem, viewRuleTable)
import User.Model exposing (User)
import User.View exposing (viewUser, viewUserItem, viewUserTable)


view : Model -> Html Msg
view model =
    div [ class "content" ]
        ([ viewHeader model ] ++ [ getPage model ] ++ [ viewFooter model ])


getPage : Model -> Html Msg
getPage model =
    if isLoggedIn model then
        case model.route of
            Nothing ->
                pageNotFound

            Just (Route.App _) ->
                pageApp model

            Just Route.Apps ->
                pageApps model

            Just Route.Dashboard ->
                pageDashboard model

            Just Route.Login ->
                pageLogin model

            Just Route.Members ->
                pageNotFound

            Just (Route.OAuthCallback _ _) ->
                pageNotFound

            Just (Route.Rule _ _) ->
                pageRule model

            Just (Route.Rules _) ->
                pageRules model

            Just (Route.User _ _) ->
                pageUser model

            Just (Route.Users _) ->
                pageUsers model
    else if model.route == (Just Route.Login) then
        pageLogin model
    else
        pageGuard model


pageApp : Model -> Html Msg
pageApp { app, startTime, time } =
    let
        viewEntities data =
            case data of
                Success app ->
                    ul []
                        (List.map viewEntity
                            [ ( app.counts.comments, "Comments", "ui-2_chat-content", (Navigate Route.Members) )
                            , ( app.counts.connections, "Connections", "arrows-2_conversion", (Navigate Route.Members) )
                            , ( app.counts.devices, "Devices", "tech_mobile-button", (Navigate Route.Members) )
                            , ( app.counts.posts, "Posts", "files_single-content-02", (Navigate (Route.Rules app.id)) )
                            , ( app.counts.rules, "Rules", "education_book-39", (Navigate (Route.Rules app.id)) )
                            , ( app.counts.users, "Users", "users_multiple-11", (Navigate (Route.Users app.id)) )
                            ]
                        )

                _ ->
                    div [] []

        viewApp app =
            div []
                [ h3 []
                    [ text app.name
                    ]
                , p [] [ text app.description ]
                ]
    in
        main_ []
            [ viewContextApps app
            , Container.view (section [ class "highlight" ])
                [ viewWebData viewApp startTime time app ]
            , Container.view (section [ class "actions" ])
                [ viewEntities app
                ]
            ]


pageApps : Model -> Html Msg
pageApps { app, apps, appForm, newApp, startTime, time } =
    let
        viewItem =
            (\app -> viewAppItem (Navigate (Route.App app.id)) app)

        viewApps apps =
            if List.length apps == 0 then
                div []
                    [ h3 [] [ text "Looks like you haven't created an App yet." ]
                    , formApp newApp appForm startTime time
                    ]
            else
                div []
                    [ viewAppsTable viewItem apps
                    , formApp newApp appForm startTime time
                    ]
    in
        main_ []
            [ viewContextApps app
            , Container.view (section [ class "highlight" ])
                [ viewWebData viewApps startTime time apps ]
            ]


pageDashboard : Model -> Html Msg
pageDashboard { member, zone } =
    let
        name =
            case member of
                Success member ->
                    member.name

                _ ->
                    ""
    in
        Container.view (section [ id "dashboard" ])
            [ h2 []
                [ text ("Hej " ++ name ++ ", welcome to your installation in")
                , span [ class "zone" ] [ text zone ]
                , text "start of by looking into"
                , a [ onClick (Navigate Route.Apps), title "Apps" ]
                    [ span [ class "icon nc-icon-glyph ui-2_layers" ] []
                    , text "Apps"
                    ]
                , text "or"
                , a [ onClick (Navigate Route.Members), title "Members" ]
                    [ span [ class "icon nc-icon-glyph users_multiple-11" ] []
                    , text "Members"
                    ]
                ]
            ]


pageGuard : Model -> Html Msg
pageGuard model =
    let
        content =
            case model.member of
                Failure err ->
                    h3 [] [ text ("Error: " ++ toString err) ]

                _ ->
                    Loader.view 64 (rgb 63 91 96) (Loader.nextStep model.startTime model.time)
    in
        Container.view (section [])
            [ content ]


pageLogin : Model -> Html Msg
pageLogin model =
    Container.view (section [ class "highlight" ])
        [ h3 []
            [ text "Welcome, in order to continue you need to login with "
            , a [ href model.loginUrl, title "Google login" ]
                [ span [ class "icon nc-icon-glyph social-1_logo-google-plus" ] []
                , text "Google"
                ]
            ]
        ]


pageNotFound : Html Msg
pageNotFound =
    Container.view (section [ class "highlight" ])
        [ h3 [] [ text "Looks like we couldn't find the page you were looking for." ]
        ]


pageRule : Model -> Html Msg
pageRule { app, appId, rule, startTime, time } =
    let
        actions =
            case rule of
                Success rule ->
                    viewActions
                        [ ( (RuleDeleteAsk rule.id), "ui-1_edit-76", Nothing, "edit" )
                        , ( (RuleDeleteAsk rule.id), "ui-1_trash", Nothing, "delete" )
                        ]

                _ ->
                    ul [] []

        --viewActiveAction rule =
        --    if rule.active then
        --        li []
        --            [ a [ onClick (RuleDeactivateAsk rule.id) ]
        --                [ span [ class "icon nc-icon-glyph ui-1_circle-remove" ] []
        --                , span [] [ text "deactivate" ]
        --                ]
        --            ]
        --    else
        --        li []
        --            [ a [ onClick (RuleActivateAsk rule.id) ]
        --                [ span [ class "icon nc-icon-glyph ui-1_check-circle-08" ] []
        --                , span [] [ text "activate" ]
        --                ]
        --            ]
        --viewActions rule =
        --    case rule of
        --        Success rule ->
        --            ul []
        --                [ viewActiveAction rule
        --                , li []
        --                    [ a []
        --                        [ div [ class "icon nc-icon-glyph ui-1_edit-76" ] []
        --                        , div [ class "name" ] [ text "edit" ]
        --                        ]
        --                    ]
        --                , li []
        --                    [ a [ onClick (RuleDeleteAsk rule.id) ]
        --                        [ div [ class "icon nc-icon-glyph ui-1_trash" ] []
        --                        , div [ class "name" ] [ text "delete" ]
        --                        ]
        --                    ]
        --                ]
        --        _ ->
        --            ul [] []
    in
        div []
            [ viewContextApps app
            , viewContextRules appId rule
            , actions

            --, Container.view (section [ class "actions" ]) [ (viewActions rule) ]
            , Container.view (section [ class "highlight" ]) [ (viewWebData viewRule startTime time rule) ]
            ]


pageRules : Model -> Html Msg
pageRules { app, appId, rule, rules, startTime, time } =
    let
        viewItem =
            (\rule -> viewRuleItem (Navigate (Route.Rule appId rule.id)) rule)

        content =
            viewWebData (viewRuleTable viewItem) startTime time rules
    in
        div []
            [ viewContextApps app
            , viewContextRules appId rule
            , Container.view (section [ class "highlight" ]) [ content ]
            ]


pageUser : Model -> Html Msg
pageUser { app, appId, userUpdateForm, startTime, time, user } =
    div []
        [ viewContextApps app
        , viewContextUsers appId user
        , Container.view (section [ class "highlight" ])
            [ (viewWebData viewUser startTime time user)
            , formUser user userUpdateForm startTime time
            ]
        ]


pageUsers : Model -> Html Msg
pageUsers { app, appId, startTime, time, user, users, userSearchForm } =
    let
        viewItem =
            (\user -> viewUserItem (Navigate (Route.User appId user.id)) user)
    in
        div []
            [ viewContextApps app
            , viewContextUsers appId user
            , Container.view (section [ class "highlight" ])
                [ form [ onSubmit UserSearchFormSubmit ]
                    [ formGroup
                        [ formElementText UserSearchFormBlur UserSearchFormFocus UserSearchFormUpdate userSearchForm "query"
                        , div [ class "action-group" ]
                            [ formButtonSubmit UserSearchFormSubmit "Search"
                            ]
                        ]
                    ]
                , viewWebData (viewUserTable viewItem) startTime time users
                ]
            ]


viewAction : ( Msg, String, Maybe Int, String ) -> Html Msg
viewAction ( msg, icon, _, name ) =
    li []
        [ a [ onClick msg ]
            [ div [ class ("icon nc-icon-glyph " ++ icon) ] []
            , div [ class "name" ] [ text name ]
            ]
        ]


viewActions : List ( Msg, String, Maybe Int, String ) -> Html Msg
viewActions actions =
    Container.view (section [ class "actions" ])
        [ ul [] (List.map viewAction actions)
        ]


viewContext : String -> Msg -> Html Msg -> Bool -> String -> Html Msg
viewContext entities listMsg view selected icon =
    let
        sectionClass =
            case selected of
                True ->
                    "selected"

                False ->
                    ""
    in
        Container.view (section [ class ("context " ++ sectionClass) ])
            [ h2 []
                [ a [ onClick listMsg ]
                    [ span [ class ("icon nc-icon-glyph " ++ icon) ] []
                    , span [] [ text entities ]
                    ]
                ]
            , view
            ]


viewContextApps : WebData App -> Html Msg
viewContextApps app =
    let
        viewApp =
            case app of
                Success app ->
                    viewSelected (Navigate (Route.App app.id)) app.name

                _ ->
                    span [] []
    in
        viewContext "Apps" (Navigate Route.Apps) viewApp True "ui-2_layers"


viewContextRules : String -> WebData Rule -> Html Msg
viewContextRules appId rule =
    let
        ( _, viewRule ) =
            case rule of
                Success rule ->
                    ( True, viewSelected (Navigate (Route.Rule appId rule.id)) rule.name )

                _ ->
                    ( False, span [] [] )
    in
        viewContext "Rules" (Navigate (Route.Rules appId)) viewRule False "education_book-39"


viewContextUsers : String -> WebData User -> Html Msg
viewContextUsers appId user =
    let
        ( selected, viewUser ) =
            case user of
                Success user ->
                    ( True, viewSelected (Navigate (Route.User appId user.id)) user.username )

                _ ->
                    ( False, span [] [] )
    in
        viewContext "Users" (Navigate (Route.Users appId)) viewUser selected "users_multiple-11"


viewDebug : Model -> Html Msg
viewDebug model =
    div [ class "debug" ]
        [ text (toString model)
        ]


viewEntity : ( Int, String, String, Msg ) -> Html Msg
viewEntity ( count, entity, icon, msg ) =
    li []
        [ a [ onClick msg, title entity ]
            [ div [ class "icon" ]
                [ span [ class ("icon nc-icon-glyph " ++ icon) ] [] ]
            , div [ class "info" ]
                [ div [ class "count" ] [ text (toString count) ]
                , div [ class "name" ] [ text entity ]
                ]
            ]
        ]


viewHeader : Model -> Html Msg
viewHeader { member, zone } =
    header []
        [ Container.view (section [ class "profile" ])
            [ viewProfile member
            ]
        , Container.view (section [])
            [ h1 []
                [ a [ onClick (Navigate Route.Dashboard), title "Home" ]
                    [ strong [] [ text "SocialPath" ]
                    , span [] [ text "Console" ]
                    ]
                ]
            , nav [] [ span [] [ text zone ] ]
            ]
        ]


viewFooter : Model -> Html Msg
viewFooter model =
    Container.view (footer [])
        --[ viewDebug model ]
        []


viewProfile : WebData Member -> Html Msg
viewProfile member =
    case member of
        Success member ->
            h4 []
                [ img [ class "profile", src member.picture ] []
                , span [] [ text member.name ]
                ]

        _ ->
            h3 [] []


viewSelected : Msg -> String -> Html Msg
viewSelected msg name =
    nav []
        [ a [ onClick msg ]
            [ span [] [ text name ]
            , span [ class "icon nc-icon-outline arrows-2_skew-down" ] []
            ]
        ]


viewWebData : (a -> Html Msg) -> Time -> Time -> WebData a -> Html Msg
viewWebData view startTime time data =
    case data of
        NotAsked ->
            div [] []

        Loading ->
            Loader.view 64 (rgb 63 91 96) (Loader.nextStep startTime time)

        Failure err ->
            case err of
                BadStatus response ->
                    let
                        errors =
                            Decode.decodeString Error.decodeList response.body
                    in
                        case errors of
                            Ok errors ->
                                let
                                    viewError err =
                                        li []
                                            [ text err.message
                                            , span []
                                                [ text " ("
                                                , text (toString err.code)
                                                , text ")"
                                                ]
                                            ]
                                in
                                    ul [ class "errors api" ] (List.map viewError errors)

                            Err err ->
                                span [ class "errors parse" ] [ text err ]

                _ ->
                    span [ class "errors network" ] [ text ("Error: " ++ toString err) ]

        Success data ->
            view data



-- FORM


formUser : WebData User -> Form -> Time -> Time -> Html Msg
formUser user userUpdateForm startTime time =
    form [ onSubmit UserUpdateFormSubmit ]
        [ formGroup
            [ formElementText UserUpdateFormBlur UserUpdateFormFocus UserUpdateFormUpdate userUpdateForm "username"
            ]
        , div [ class "action-group" ]
            [ formButtonReset UserUpdateFormClear "Clear"
            , formButtonSubmit UserUpdateFormSubmit "Update"
            ]
        ]


formApp : WebData App -> Form -> Time -> Time -> Html Msg
formApp new appForm startTime time =
    let
        elementText =
            formElementText AppFormBlur AppFormFocus AppFormUpdate

        createForm =
            form [ onSubmit AppFormSubmit ]
                [ formGroup
                    [ elementText appForm "name"
                    , elementText appForm "description"
                    ]
                , div [ class "action-group" ]
                    [ formButtonReset AppFormClear "Clear"
                    , formButtonSubmit AppFormSubmit "Create"
                    ]
                ]
    in
        case new of
            NotAsked ->
                createForm

            Loading ->
                Loader.view 48 (rgb 63 91 96) (Loader.nextStep startTime time)

            Failure err ->
                text ("Failed: " ++ toString err)

            Success _ ->
                createForm


formButtonReset : Msg -> String -> Html Msg
formButtonReset msg name =
    button [ onClick msg, type_ "reset" ] [ text name ]


formButtonSubmit : Msg -> String -> Html Msg
formButtonSubmit msg name =
    button [] [ text name ]


formElementContext : Form -> String -> Html Msg
formElementContext form field =
    let
        isFocused =
            elementIsFocused form field

        isValidated =
            formIsValidated form

        error =
            if isFocused || isValidated then
                case List.head (elementErrors form field) of
                    Nothing ->
                        ""

                    Just err ->
                        err
            else
                ""
    in
        div [ class "error" ] [ text error ]


formElementText : (String -> Msg) -> (String -> Msg) -> (String -> String -> Msg) -> Form -> String -> Html Msg
formElementText blurMsg focusMsg inputMsg form field =
    let
        isFocused =
            elementIsFocused form field

        isValidated =
            formIsValidated form

        validationClass =
            if isFocused || isValidated then
                case elementIsValid form field of
                    False ->
                        "invalid"

                    True ->
                        "valid"
            else
                ""
    in
        div [ class ("element " ++ field) ]
            [ input
                [ class (field ++ " " ++ validationClass)
                , onBlur (blurMsg field)
                , onFocus (focusMsg field)
                , onInput (inputMsg field)
                , placeholder (capitalise field)
                , type_ "text"
                , value (elementValue form field)
                ]
                []
            , formElementContext form field
            ]


formGroup : List (Html Msg) -> Html Msg
formGroup elements =
    div [ class "form-group" ] elements



-- HELPER


capitalise : String -> String
capitalise s =
    case String.uncons s of
        Nothing ->
            ""

        Just ( head, tail ) ->
            String.cons (Char.toUpper head) tail
