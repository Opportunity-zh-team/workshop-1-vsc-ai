/* 
    Mind Power Apps limitations:

    - SharePoint is used, NOT Dataverse. Therefore, the following limitations apply:
    - SharePoint list view threshold: 5000 items
    - Delegation limit: 2000 items (Filter, Sort, LookUp, Search, CountRows, Distinct, GroupBy) 
    - Do not generate code that is not delegable, unless explicitly requested.

    - For "ascending" and "descending" sorting, use the Sort() function instead of SortByColumns(), and generate Sort.Ascending or Sort.Descending as the second parameter. Do not use "asc" or "desc" strings.
    - References to SharePoint list columns, for many function calls, may not be quoted.

    - App.Formulas functions with no generic parameters can return a record or table, but cannot be used as parameters for Set() or Patch() functions.
    - App.Formulas functions with one to many generic parameters (not records or tables) BUT cannot use Set() or Patch() etc. functions as parameters either.

    - Local variables with the prefix "var" are not accessible in other screens. Therefore, use UpdateContext() to set local variables in the current screen, 
      and use Set() to set global variables that are accessible in all screens.
*/

/*
    SharePoint lists and associated collections used in the app:
    - INT003_Meetings -> ColMain_Meetings
    - INT003_Protocols -> ColMain_Protocols

    Global variables:
    -   glbUserEmail: string, holds the current user's email address (completely lower case). Default: "".
    -   glbSelectedMeetingId: integer, holds the ID of the meeting that is currently selected. Default: -1.
    -   glbSelectedProtocolId: integer, holds the ID of the protocol that is currently selected. Default: -1.   

    Local screen variables:
        - varIsEditable: boolean, indicates whether the user has permission to edit the data or not. Default: false.
        - varMeetingId: integer, holds the ID of the meeting that is currently being edited. Default: -1.
        - varProtocolId: integer, holds the ID of the protocol that is currently being edited. Default: -1.
        - varEditPermissionRequest: edit permission request record that was set to SharePoint.
        - varTraceMessage1: string, holds the trace message for debugging purposes. Default: "".
        - varIsDevEnvironment: boolean, indicates whether the app is running in a development environment or not. Default: true.
        - varStartCheckEditPermission: boolean, indicates whether to start the edit permission check timer. Default: false.

    
*/

// -------------------------------------------------------------------------------------------------

/*
    When several users are working on the same data in the app and with SharePoint, there is a risk of overwriting each other's changes, 
    losing data and as a consequence, causing conflicts and errors.
    
    To prevent this, the app implements a concurrency control mechanism that allows only one user to edit the data at a time. 
    The app uses a SharePoint list called INT003_Concurrency_States_List to store the state of the data and the user who is 
    currently editing it. The control mechanism makes sure that two or more users cannot edit the same data at the same time, 
    and that the users' apps get accurate information to act and notify reliably.

    Precondtions:
        - INT003_Concurrency_States_List is a SharePoint list that already holds a row dedicated to the current user (User_Email = current user Email).
        - The app has the global variable glbUserEmail that holds the current user's email address (completely lower case).

        - The target screen must set its context variable varIsEditable to true or false depending on whether the user has permission to edit the data or not. OnVisible: varIsEditable = false.

    Conventions:
        - screen names: scrMeeting, scrProtocol, scrDashboard
        - if App.ActiveScreen.Name = "scrMeeting", then set varMeetingId = glbSelectedMeetingId and varProtocolId = -1 (screen.OnVisible)
        - if App.ActiveScreen.Name = "scrProtocol", then set varMeetingId = -1 and varProtocolId = glbSelectedProtocolId (screen.OnVisible)

    The control mechanism works as follows:
        Step 0: When a user opens a screen that allows editing data, refresh ColMain_ConcurrencyStates from INT003_Concurrency_States_List 
                to get the latest concurrency information in SharePoint. 
                The context variable varIsEditable is set to false by default, varMeetingId, varProtocolId are initialized according to the active screen. 
                

        Step 1: The app checks the updated ColMain_ConcurrencyStates to see 
                    if the user glbUserEmail already has the target data locked (then set varUserEditPermissionGranted to true, no further action), or 
                    if no user is currently editing the target data (then request editing rights with Step 2), or
                    if another other user is currently editing the same data (then no further action).

        Step 2: Register editing rights request for user glbUserEmail in INT003_Concurrency_States_List by setting State_Name to "edit-permission-requested", 
                    varMeetingId > 0: Meeting_Id = varMeetingId, Protocol_Id = -1 
                    varProtocolId > 0: Meeting_Id = -1, Protocol_Id = varProtocolId
                Make sure that the user glbUserEmail has only one row in INT003_Concurrency_States_List, either by updating the existing row or creating a new one.

        Step 3 (triggered by timout timer): Check if "edit-permission-requested" was registered by the current user and other users to the same meeting or protocol (scrMeeting or scrProtocol).
                    if more than one user has requested editing rights to the same data, 

                    then if the current user's id is erlier in the list 
                        then grant user glbUserEmail permission in INT003_Concurrency_States_List by setting State_Name to "edit-permission-granted". Set varIsEditable to true.
                        else deny user glbUserEmail permission in INT003_Concurrency_States_List by setting State_Name to "edit-permission-denied". Set varIsEditable to false.

                    else if only the current user has requested editing rights to the same data, 
                        then grant user glbUserEmail permission in INT003_Concurrency_States_List by setting State_Name to "edit-permission-granted". Set varIsEditable to true.

    Schema of INT003_Concurrency_States_List:
        Column | Description | Type | Required
        ID | Identifikation des Zustands | SharePoint Objekt | auto
        State_Name | Name des Zustands | Text, einzeilig | erforderlich
        Modified | Datum, wann der Datensatz geändert, aktualisiert wurde | DateTime | auto
        User_Email | Email des Users, der den Zustand zuletzt beeinflusst hat | Text, einzeilig | erforderlich
        Meeting_Id | Identifikation des betroffenen Meeting-Datensatzes | Int | optional
        Protocol_Id | Identifikation des betroffenen Protocol-Datensatzes | Int | optional
*/

App.OnStart = 
/*
    @author: Chris
    @date: 2026-09-10
    @tags: #concurrency-control-initialization

    - Set the global variable glbUserEmail to the current user's email address (completely lower case).
    - Set the global variable glbSelectedMeetingId to -1 and glbSelectedProtocolId to -1. 
    - Collect all rows from INT003_Concurrency_States_List into ColMain_ConcurrencyStates.
    - Patch the current user's row in INT003_Concurrency_States_List to set State_Name = "entered-app", Meeting_Id = -1, Protocol_Id = -1.  
*/
Set(glbUserEmail, Lower(User().Email)); 
Set(glbSelectedMeetingId, -1); 
Set(glbSelectedProtocolId, -1); 

ClearCollect(ColMain_ConcurrencyStates, INT003_Concurrency_States_List);

Patch(
    INT003_Concurrency_States_List,
    Filter(
        INT003_Concurrency_States_List,
        User_Email = glbUserEmail
    ),
    {
        State_Name: "entered-app",
        Meeting_Id: glbSelectedMeetingId,
        Protocol_Id: glbSelectedProtocolId
    }
);

// -------------------------------------------------------------------------------------------------

Screen.OnVisible =
Button.OnSelect =
/*
    @author: Chris
    @date: 2026-09-10
    @tags: #concurrency-control-register-edit-permission-request
*/
// Step 0: Refresh ColMain_ConcurrencyStates from INT003_Concurrency_States_List to get the latest concurrency information in SharePoint.
Refresh(INT003_Concurrency_States_List);
ClearCollect(ColMain_ConcurrencyStates, INT003_Concurrency_States_List);

UpdateContext({ 
    varIsEditable: false, 
    varMeetingId: If(App.ActiveScreen.Name = "scrMeeting", glbSelectedMeetingId, -1), 
    varProtocolId: If(App.ActiveScreen.Name = "scrProtocol", glbSelectedProtocolId, -1),
    varEditPermissionRequest: {},
    varTraceMessage1: "",
    varStartCheckEditPermission: false
});

// Step 1: Check if the user glbUserEmail already has the target data locked.
With(
    {
        isEditPermissionGrantedUser: 
            CountRows(
                Filter(
                    ColMain_ConcurrencyStates, 
                    User_Email = glbUserEmail && 
                    State_Name = "edit-permission-granted" && 
                    (Meeting_Id = varMeetingId && Protocol_Id = varProtocolId)
                )
            ) > 0,
        isEditPermissionRequestedUser: 
            CountRows(
                Filter(
                    ColMain_ConcurrencyStates, 
                    User_Email = glbUserEmail && 
                    State_Name = "edit-permission-requested" && 
                    (Meeting_Id = varMeetingId && Protocol_Id = varProtocolId)
                )
            ) > 0
    },
    If(
        isEditPermissionGrantedUser, 

        // Case 1: The user glbUserEmail already has the target data locked (then set varIsEditable to true, no further action).
        UpdateContext({ varIsEditable: true }), 

        // Case 2: No user is currently editing the target data (then request editing rights with Step 2).
        If(!isEditPermissionRequestedUser, 
            // Step 2: Register editing rights request for user glbUserEmail in INT003_Concurrency_States_List by setting State_Name to "edit-permission-requested".
            UpdateContext({ 
                varEditPermissionRequest: 
                Patch(
                    INT003_Concurrency_States_List,
                    Coalesce(
                        LookUp(
                            INT003_Concurrency_States_List,
                            User_Email = glbUserEmail
                        ),
                        Defaults(INT003_Concurrency_States_List)
                    ),
                    {
                        State_Name: "edit-permission-requested",
                        User_Email: glbUserEmail,
                        Meeting_Id: If(varMeetingId > 0, varMeetingId, -1),
                        Protocol_Id: If(varProtocolId > 0, varProtocolId, -1)
                    }
                )
            })
        );
        // Start timer that checks concurrent edit permission requests.
        UpdateContext({varStartCheckEditPermission:true})
    )
);

// -------------------------------------------------------------------------------------------------

Label1_1.Text = varTraceMessage1;

/*
    @author: Chris
    @date: 2026-09-10
    @tags: #concurrency-control-trace-globals

    - Set varTempText to a summary of state information, reflecting the current state of the edit permission request for the current user. 
      If varIsEditable = true: "permission granted". 
      else if varIsEditable = false and varEditPermissionRequest is not empty: "permission requested". 
      else if varIsEditable = false and varEditPermissionRequest is empty: "permission denied".
      It is not enough to IsBlank(varEditPermissionRequest), varEditPermissionRequest must also contain the expected User_Email.
      "edit-permission-granted" is registered in a later step.
    - Display a message header, indicating "#concurrency-control: " and  
      the local screen variables varIsEditable, varMeetingId, varProtocolId, varTraceMessage1 for debugging purposes.
      For each variable use "<variable name>: <value>" format (except for varTraceMessage1), separated by line breaks. 
      Separate global and local variables with an empty line.
    - This label is only visible in the development environment and should be hidden in production. Use the local variable 
      varIsDevEnvironment to control the visibility of the label.
*/
UpdateContext({
    varTempText: If(
        varIsEditable, 
        "edit permission GRANTED", 
        If(
            !varIsEditable && !IsBlank(varEditPermissionRequest) && varEditPermissionRequest.User_Email = glbUserEmail, 
            "edit permission requested", 
            "edit permission was requested already"
        )
    )
});

UpdateContext({
    varTraceMessage1:
    "#concurrency-control-register-edit-permission-request: " & varTempText & Char(10) &
    "  glbUserEmail: " & glbUserEmail & Char(10) &
    "  glbSelectedMeetingId: " & glbSelectedMeetingId & Char(10) &
    "  glbSelectedProtocolId: " & glbSelectedProtocolId & Char(10) & Char(10) &
    "  varIsEditable: " & varIsEditable & Char(10) &
    "  varMeetingId: " & varMeetingId & Char(10) &
    "  varProtocolId: " & varProtocolId & Char(10)
});

// -------------------------------------------------------------------------------------------------

TimerCheckEditPermission.Start = 
varStartCheckEditPermission;

TimerCheckEditPermission.OnTimerEnd =
/*
    @author: Chris
    @date: 2026-09-10
    @tags: #concurrency-control-check-edit-permission-requests

    Checks pending edit permission requests for the current meeting or protocol and
    determines whether the current user should receive exclusive edit access.

    The script refreshes and loads concurrency state records from
    INT003_Concurrency_States_List, filters all records with the state
    "edit-permission-requested" for the current item, and evaluates all competing
    requests.

    Edit permission is granted only when:
      - varIsEditable is currently false.
      - The current user has an active edit permission request.
      - The current user's request is the oldest request based on the Modified
        timestamp among all pending requests.

    When these conditions are met, the user's state is updated to
    "edit-permission-granted" in SharePoint and varIsEditable is set to true.

    A timer (TimerCheckEditPermission) periodically executes this logic while the
    item remains locked, enabling users to automatically obtain edit access as soon
    as their request becomes the highest-priority pending request.

    varIsEditable is intentionally not reset by this script because its initial
    value is established during Screen.OnVisible. Preserving the variable prevents
    unnecessary UI flickering caused by repeated transitions between
    DisplayMode.Edit and DisplayMode.Display.

    Trace information is written to varTraceMessage1 for debugging and monitoring
    of the permission evaluation process
*/
// Step 1: Initialize context variables
UpdateContext({
    varMeetingId: If(App.ActiveScreen.Name = "scrMeeting", glbSelectedMeetingId, -1), 
    varProtocolId: If(App.ActiveScreen.Name = "scrProtocol", glbSelectedProtocolId, -1),
    varEditPermissionRequest: {},
    varTraceMessage1: "",
    varStartCheckEditPermission: false
});

// Step 2: Refresh ColMain_ConcurrencyStates from INT003_Concurrency_States_List and get concurrency data from it, collected into ColTemp_RequestedEditPermissions.
Refresh(INT003_Concurrency_States_List);
ClearCollect(ColMain_ConcurrencyStates, INT003_Concurrency_States_List);

ClearCollect(
    ColTemp_RequestedEditPermissions, 
    Filter(
        INT003_Concurrency_States_List,  
        State_Name = "edit-permission-requested" && 
        (Meeting_Id = varMeetingId && Protocol_Id = varProtocolId)
    )
);

/*
    Step 3: Decide which user gets the exclusive edit permission.

    Rule: The user with the oldest modification DateTime value gets the permission.
*/
With(
    {
        hasPermissionRequests:
            CountRows(ColTemp_RequestedEditPermissions) > 0
    }, 
    With(
        {
            userHasPermissionRequest: 
                !varIsEditable && hasPermissionRequests &&
                CountRows(
                    Filter(
                        ColTemp_RequestedEditPermissions,  
                        User_Email = glbUserEmail
                    )
                ) > 0,

            userHasOldestPermissionRequest:
                !varIsEditable && hasPermissionRequests &&
                First(
                    Sort(
                        ColTemp_RequestedEditPermissions,
                        Modified,
                        SortOrder.Ascending
                    )
                ).User_Email = glbUserEmail
        }, 
        If(
            !varIsEditable,

            // Grant permission if the user registered the permission request first.
            If(
                userHasPermissionRequest && userHasOldestPermissionRequest, 

                // Step 4: Grant the edit permission (SharePoint and App). Meeting_Id and Protocol_Id do not need to be patched.
                Patch(
                    INT003_Concurrency_States_List,
                    Coalesce(
                        LookUp(
                            INT003_Concurrency_States_List,
                            User_Email = glbUserEmail
                        ),
                        Defaults(INT003_Concurrency_States_List)
                    ),
                    {
                        State_Name: "edit-permission-granted",
                        User_Email: glbUserEmail
                    }
                );
                UpdateContext({ varIsEditable: true }) 
            )
        );  
    )
);

// Step 5: trace message with global and local variables
UpdateContext({
    varTempText: If(
        varIsEditable, 
        "edit permission GRANTED", 
        "edit permission NOT GRANTED"
    )
});

UpdateContext({
    varTraceMessage1:
    "#concurrency-control-check-edit-permission-requests: " & varTempText & Char(10) &
    "  glbUserEmail: " & glbUserEmail & Char(10) &
    "  glbSelectedMeetingId: " & glbSelectedMeetingId & Char(10) &
    "  glbSelectedProtocolId: " & glbSelectedProtocolId & Char(10) & Char(10) &
    "  varIsEditable: " & varIsEditable & Char(10) &
    "  varMeetingId: " & varMeetingId & Char(10) &
    "  varProtocolId: " & varProtocolId & Char(10)
});

