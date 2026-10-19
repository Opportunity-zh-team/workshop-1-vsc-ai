// OnSelect
// Creates a temporary, empty meeting row in INT003_Meetings_List. A GUID-based
// marker in Titel is used to look up the new SharePoint ID, which becomes
// glbLoadMeetingId. The local meetings collection is then rebuilt with the app's
// meet* aliases, glbResetForm is set for the meeting form, and the app navigates
// to ScrMeeting. The SharePoint Patch and subsequent lookup are not guarded here
// with IfError or a missing-record check.
Set(
    varMarker,
    "TMP-" & GUID()
);
Patch(
    INT003_Meetings_List,
    Defaults(INT003_Meetings_List),
    {
        Titel: varMarker,
        Topic: ""
    }
);
Set(
    glbLoadMeetingId,
    LookUp(
        INT003_Meetings_List,
        Titel = varMarker
    ).ID
);
ClearCollect(
    colMainMeetings,
    AddColumns(
        INT003_Meetings_List,
        meetID, ID,
        meetTitle, Titel,
        meetTopic, Topic,
        meetDescription, Description,
        meetStarts, Starts,
        meetEnds, Ends,
        meetLocation, Location
    )
);
Set(
    glbResetForm,
    true
);
Navigate(
    ScrMeeting,
    ScreenTransition.Fade
)
