/*
    Prerequisites:
    - SharePoint lists INT003_Meetings, INT003_Protocols, INT003_Actions, INT003_Participants exist and are accessible by the app, including Env-Variables for each table.
    - The app has the following global variables defined:
        - glbSelectedMeetingId (int)
        - glbSelectedProtocolId (int)
    - The app has the following collections defined:
        - ColMain_Meetings
        - ColMain_Protocols
        - ColMain_Actions
        - ColMain_Participants
    - The app has the following screens defined:
        - scrDashboard
        - scrProtocol
        - scrMeeting
    - The app has the following controls defined:
        - DrpMeetingTopics (dropdown)
        - GalMeetingProtocols (gallery)
        - LblProtocolText (multiline text label)
        - GalProtocolActions (gallery)
        - GalMeetingParticipants (horizontal gallery)
*/

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


/*
    Error handling:
    - If a SharePoint list is not accessible, the app must display an error message to the user and not crash.
    - If a SharePoint list is empty, the app must display an appropriate message to the user and not crash.
    - If a SharePoint list is not delegable, the app must display an appropriate message to the user and not crash.
    - If the requested item is not found in the SharePoint list, the app must display an appropriate message to the user and not crash.
*/


/* C-0
    In Screen scrDashboard.onVisible, load all meetings from the SharePoint list INT003_Meetings into ColMain_Meetings. Sort by Topic, ascending.

    Schema of INT003_Meetings:
        Column | Description | Type | Required
        ID | Identifikation des Meetings | SharePoint Objekt | auto
        Topic | Thema des Meetings oder der Meeting-Serie | Text, einzeilig	erforderlich
        Description | Kurzbeschreibung des Themas | Text, mehrzeilig | optional
        Starts | Geplanter Starttermin | DateTime | erforderlich
        Ends | Geplanter Endtermin | DateTime | erforderlich
        Location | Austragungsort des Meetings | Text, einzeilig | erforderlich

    If glbSelectedMeetingId is blank: Set glbSelectedMeetingId to the ID.Id of the first item in ColMain_Meetings. 

*/
ClearCollect(ColMain_Meetings, Sort(INT003_Meetings, Topic, Sort.Ascending));
If(IsBlank(glbSelectedMeetingId), Set(glbSelectedMeetingId, First(ColMain_Meetings).ID.Id));


/* C-1
    In Screen scrDashboard.onVisible, load all protocols from the SharePoint list INT003_Protocols into ColMain_Protocols. Sort by Started_At, descending (most recent first).

    Schema of ColMain_Protocols:
        ID | Identifikation des Protokolls | SharePoint Objekt | auto
        Meeting_Id | Identifikation des Meetings zudem das Protokoll gehört | int, SharePoint Object | erforderlich
        Started_At | Datum und Uhrzeit, wann das Meeting reell gestartet wurde | DateTime | erforderlich
        Protocol_Text | Text des Protokolls | Text, mehrzeilig | erforderlich

    If glbSelectedProtocolId is blank: Set glbSelectedProtocolId to the ID.Id of the first item in ColMain_Protocols.

*/


/* C-2
    In the same screen, use a classic dropdown control (DrpMeetingTopics) to display all meeting topics from ColMain_Meetings. 

    When the dropdown is displayed, the selected item should be the one corresponding to glbSelectedMeetingId.
    When the dropdown selection changes, update the dropdown and glbSelectedMeetingId accordingly.
*/


/* C-3
    In the same screen, use a gallery control (GalMeetingProtocols) to display all protocols from ColMain_Protocols where Meeting_Id = glbSelectedMeetingId, sorted by Started_At, descending. 

    When glbSelectedMeetingId changes, the control should update accordingly. 
    When a row of the gallery is selected, update glbSelectedProtocolId accordingly.
*/


/* C-4
    In the same screen, use a text area (LblProtocolText) to display the Protocol_Text of the protocol corresponding to glbSelectedProtocolId.  
    When glbSelectedProtocolId changes, the text area should update accordingly.
*/


/* C-5
    In the same screen, use a gallery control (GalProtocolActions) to display all action items from the SharePoint list INT003_Actions where Protocol_Id = glbSelectedProtocolId, sorted by Sort_Order, ascending. 
    GalProtocolActions lists the Action_Item (Text) and a checkbox control, indicating whether the action is done (Done_Date is not blank).

    When glbSelectedProtocolId changes, the control should update accordingly.

    Schema of INT003_Actions:
        Column | Description | Type | Required
        ID | Identifikation der Action | SharePoint Objekt | auto
        Protocol_Id | Identifikation des Protokolls zu dem die Action gehört | int, SharePoint Object | erforderlich
        Action_Item | Text der Aktion | Text, einzeilig | erforderlich
        Sort_Order | Sortierreihenfolge der Aktion | int | erforderlich
        Done_Date | Datum, wann die Aktion abgeschlossen wurde | Date | optional

    
*/


/* C-6
    In the same screen, use the horizontal gallery control (GalMeetingParticipants) to display the meeting participants where Meeting_Id = glbSelectedMeetingId AND Is_Present = 1, 
    represented by their profile pictures.

    When glbSelectedMeetingId changes, the control should update accordingly.

    Schema of INT003_Participants:
        Column | Description | Type | Required
        ID | Identifikation der Teilnehmer-Person | SharePoint Objekt | auto
        Meeting_Id | Identifikation des Meetings zudem die Teilnehmer-Person gehört	int, SharePoint Object	erforderlich
        Participant_Email | Email der Teilnehmer-Person | Text, einzeilig | erforderlich
        Is_Present | Flag gibt an, ob die Teilnehmer-Person anwesend ist | int, 0 für false, 1 für true | erforderlich
*/


/* C-7
    For App.Formulas, create the function GetSelectedMeeting() that returns the record of the meeting corresponding to glbSelectedMeetingId.

    If glbSelectedMeetingId is blank, return the first record of ColMain_Meetings. If ColMain_Meetings is empty, return blank.
*/


/* C-8
    For App.Formulas, create the function GetSelectedProtocol() that returns the record of the protocol corresponding to glbSelectedProtocolId.

    If glbSelectedProtocolId is blank, return the first record of ColMain_Protocols. If ColMain_Protocols is empty, return blank.
*/