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
*/

// -------------------------------------------------------------------------------------------------

App.OnStart = 
/*
    @author: Chris
    @date: 2024-06-12
    
    SC-000: Define Constants and Global Variables
        Step 1: Define globals EXCLUSIVE_EDIT_PERMISSION_GRANTED_ID and DB_DATA_CHANGED_ID.
        Step 2: Initialize global variables.
*/
// SC-000: Step 1
Set(EXCLUSIVE_EDIT_PERMISSION_GRANTED_ID, 1);
Set(DB_DATA_CHANGED_ID, 2);

// SC-000: Step 2
Set(gblLastRefreshTimestamp, Now()); // Initialize the last refresh timestamp to the current date-time value (DateTime). 
Set(glbIsRefreshing, false); // Initialize the global variable to indicate whether a refresh is in progress (Boolean).
Set(gblIsExclusiveEditPermissionGranted, false); // Initialize the global variable to indicate whether the current user has exclusive edit permission (Boolean).
Set(gblIsDbDataChanged, false); // Initialize the global variable to indicate whether the database data has changed (Boolean).
Set(gblIsEditPermissionGrantedUser, false); // Initialize the global variable to indicate whether the current user has edit permission (Boolean).

// -------------------------------------------------------------------------------------------------

Screen.OnVisible =
Button.OnSelect =
/*
    @author: Chris
    @date: 2024-06-12 
    
    Initialize the local variable to indicate whether the current screen is editable (Boolean).  
*/
UpdateContext({ 
    varIsEditable: false, // Initialize the local variable to indicate whether the current user has edit permission (Boolean).
    varTraceMessage: ""
});

/*
    @author: Chris
    @date: 2024-06-12

    SC-001: Check Concurrency States
        Step 1: Get all rows from INT003_Concurrency_States_List into ColMain_ConcurrencyStates, without the columns that are not needed.
        Step 2: Set the global variable gblIsExclusiveEditPermissionGranted to true, if the row with ID = EXCLUSIVE_EDIT_PERMISSION_GRANTED_ID has Activated = 1.
        Step 3: Set the global variable gblIsDbDataChanged to true, if the row with ID = DB_DATA_CHANGED_ID has Activated = 1 AND the modification date-time value is more recent than gblLastRefreshTimestamp.
        Step 4: Update gblLastRefreshTimestamp to the current date-time value.

        Step 5: Set the global variable glbIsEditPermissionGrantedUser to true, if the current user Email matches the User_Email in the row with ID = EXCLUSIVE_EDIT_PERMISSION_GRANTED_ID.

        Step 6: Decide the consequences of the currently registered concurrency states compared with Modified date-time value, the current user Email and if the current screen contains editable fields. 
            
            - Case 1:If gblIsExclusiveEditPermissionGranted = true AND the current user Email matches the User_Email in the concurrency state, 
                then enable all edit buttons in a target screen that contains editable fields (OnVisible or on change of the local variable).

            - Case 2: If gblIsExclusiveEditPermissionGranted = true AND the current user Email does NOT match the User_Email in the concurrency state, 
                then display a tiny message to the user that they do not have permission to edit the data and disable all edit buttons in the target screen with a local variable.

            - Case 3: If gblIsExclusiveEditPermissionGranted = false 
                then grant the permission for the current user in INT003_Concurrency_States_List by setting Activated = 1 and User_Email = current user Email. 
                Then enable all edit buttons in the target screen with a local variable.

            - Case 4: [TODO] Reset the grant for the current user (gblIsExclusiveEditPermissionGranted = true) in INT003_Concurrency_States_List by setting Activated = 0 and User_Email = current user Email
            not automatically, but in the following cases:
                - The user has finished editing the data (save, patch etc.) and leaves the editable screen (button with navigation direction).
                - The user was not active in an editable screenfor a certain time period (e.g. 15 minutes) and the permission is revoked automatically (timer). 
                In order to not loose any unsaved changes, the current data could be saved automatically before blocking the edit-fields.

            - Case 5: [TODO] Users with gblIsExclusiveEditPermissionGranted = false and gblIsDbDataChanged = true should execute a refresh in the current screen (refresh-button BtnRefreshScreen in that screen) or 
                refresh the target with Screen.OnVisible (selecting the hidden BtnRefreshScreen), because the data has changed and they do not have permission to edit the data but auto-refresh on changes. 
                Consequently, a screen must be able to refresh itself completely, without depending on actions in another screen. 
                
                UI status support: A refresh of the current screen can be visualized with the spinner IcnRefreshSpinner (with short message LblRefreshSpinnerMessage, visibility depends on gblIsRefreshing). 
                The mode (display|edit) of the screen can be indicated with (locked icon|unlocked icon), depending on the value of gblIsExclusiveEditPermissionGranted.

                The user with gblIsExclusiveEditPermissionGranted = true does not need to be informed about the data change (spinner with message), because he/she is the only one who can edit the data. 

                Question: How can a screen be refreshed automatically without loosing the position of the text cursor in the editable fields?

        Step 7: Update the local variable varTraceMessage with the current values of gblIsExclusiveEditPermissionGranted, gblIsEditPermissionGrantedUser, varIsEditable and gblIsDbDataChanged for debugging purposes.
                         

    Schema of INT003_Concurrency_States_List:
        Column | Description | Type | Required
        ID | Identifikation des Zustands | SharePoint Objekt | auto
        State_Name | Name des Zustands | Text, einzeilig | erforderlich
        Activated | Angabe, ob der betroffene Zustand aktiviert ist - oder nicht | Int, 0|1 | erforderlich
        Modified | Datum, wann der Datensatz geändert, aktualisiert wurde | DateTime | auto
        User_Email | Email des Users, der den Zustand zuletzt beeinflusst hat | Text, einzeilig | erforderlich
*/
ClearCollect( // SC-001: Step 1
    ColMain_ConcurrencyStates, 
    ShowColumns(
        INT003_Concurrency_States_List, 
        ID, 
        State_Name, 
        Activated, 
        Modified, 
        User_Email
    )
);

Set( // SC-001: Step 2
    gblIsExclusiveEditPermissionGranted, 
    LookUp(
        ColMain_ConcurrencyStates, 
        ID = EXCLUSIVE_EDIT_PERMISSION_GRANTED_ID, 
        Activated
    ) = 1
);

Set( // SC-001: Step 3
    gblIsDbDataChanged, 
    LookUp(
        ColMain_ConcurrencyStates, 
        ID = DB_DATA_CHANGED_ID, 
        Activated
    ) = 1 && 
    LookUp(
        ColMain_ConcurrencyStates, 
        ID = DB_DATA_CHANGED_ID, 
        Modified
    ) > gblLastRefreshTimestamp
);

Set( // SC-001: Step 4
    gblLastRefreshTimestamp, 
    Now()
);

Set( // SC-001: Step 5
    gblIsEditPermissionGrantedUser,
    LookUp(
        ColMain_ConcurrencyStates, 
        ID = EXCLUSIVE_EDIT_PERMISSION_GRANTED_ID, 
        Lower(User_Email)
    ) = Lower(User().Email)
);

If( // SC-001: Step 6
    gblIsExclusiveEditPermissionGranted && gblIsEditPermissionGrantedUser,
    // Case 1: [TODO] Enable all edit buttons in the target screen with a local variable.
    // Case 1: [TODO] In the target screen displays (unlocked|locked)-icon depending on varIsEditable.
    UpdateContext({ varIsEditable: true }),
    
    gblIsExclusiveEditPermissionGranted && !gblIsEditPermissionGrantedUser,
    // Case 2: [TODO] Disable all edit buttons in the target screen depending on varIsEditable.
    // Case 2: [TODO] In the target screen displays (unlocked|locked)-icon depending on varIsEditable.
    UpdateContext({ varIsEditable: false }),
    
    !gblIsExclusiveEditPermissionGranted,
    // Case 3: Grant permission for the current user in INT003_Concurrency_States_List.
    // Case 3: Update varIsEditable and gblIsExclusiveEditPermissionGranted accordingly.
    Patch(
        INT003_Concurrency_States_List,
        LookUp(INT003_Concurrency_States_List, ID = EXCLUSIVE_EDIT_PERMISSION_GRANTED_ID),
        {
            Activated: 1,
            User_Email: User().Email
        }
    );
    UpdateContext({ varIsEditable: true });
    Set(gblIsExclusiveEditPermissionGranted, true)
);

UpdateContext({ // SC-001: Step 7
    varTraceMessage: 
    "gblIsExclusiveEditPermissionGranted = " & gblIsExclusiveEditPermissionGranted & 
    ", gblIsEditPermissionGrantedUser = " & gblIsEditPermissionGrantedUser & Char(13) &
    "varIsEditable = " & varIsEditable & 
    ", gblIsDbDataChanged = " & gblIsDbDataChanged
});

// -------------------------------------------------------------------------------------------------
