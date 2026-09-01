/*
    In screen scrDashboard.OnVisible: Load all meetings from SharePoint INT003_Meetings into the 
    collection ColMain_Meetings. Sort the collection by Topic in ascending order. 

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
ClearCollect(ColMain_Meetings, Sort(INT003_Meetings_List, Topic, SortOrder.Ascending));
If(IsBlank(glbSelectedMeetingId), Set(glbSelectedMeetingId, First(ColMain_Meetings).ID));

// Set the local variable locMeetingTopicsCount to the number of rows in ColMain_Meetings.
UpdateContext(
    { locMeetingsTopicCount: CountRows(colMain_Meetings) }
);

// For Label1 the text shoud indicate the number of meeting topics in ColMain_Meetings. 
Label1.Text = "Number of meeting topics: " & Text(locMeetingTopicsCount);
