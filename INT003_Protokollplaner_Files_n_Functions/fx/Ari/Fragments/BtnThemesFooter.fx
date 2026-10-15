// OnSelect
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
