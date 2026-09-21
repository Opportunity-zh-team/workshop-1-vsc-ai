/* If I select a topic in the dropdown DrpTopicSelection, the matching entries based on the table
    INT003_Meetings_List should be loaded into local variables. The Dropdown shows columns
    .Topic. The following columns should be loaded into local variables:
    .ID (int), .Topic (string), .Description (string), .Starts (DateTime), .Ends (DateTime), .Location (string).
    The variable names should be: locID, locTopic, locDescription, locStarts, locEnds, locLocation. */

// Code for onChange event of DrpTopicSelection
UpdateContext({locMeetingID: Blank(), locTopic: Blank(), locDescription: Blank(), locStarts: Blank(), locEnds: Blank(), locLocation: Blank()}); // Clear previous values
If( !IsBlank(DrpTopicSelection.Selected), 
    With(
        {selectedTopic: DrpTopicSelection.Selected.Topic},
        ClearCollect(
            colSelectedMeeting,
            Filter(INT003_Meetings_List, Topic = selectedTopic)
        );
        If(CountRows(colSelectedMeeting) > 0,
            UpdateContext({
                locMeetingID: First(colSelectedMeeting).ID,
                locTopic: First(colSelectedMeeting).Topic,
                locDescription: First(colSelectedMeeting).Description,
                locStarts: First(colSelectedMeeting).Starts,
                locEnds: First(colSelectedMeeting).Ends,
                locLocation: First(colSelectedMeeting).Location
            })
        )
    )
)

/* Filter items of gallery GalAgendaItems based on locMeetingID. The table for the gallery is INT003_Agenda_Items_List.
   The filter should be based on the column .Meeting_Id matching locMeetingID. */
Filter(INT003_Agenda_Items_List, Meeting_Id.Id = locMeetingID)

/* Filter items of gallery GalParticipants based on locMeetingID. The table for the gallery is INT003_Participants_List.
   The filter should be based on the column .Meeting_Id matching locMeetingID. */
Filter(INT003_Participants_List, Meeting_Id.Id = locMeetingID)

/* Write a patch which updates INT003_Meetings_List with the values of TxtTopic (.Topic), TxtDescription (.Description),
 DatBegin (.Begin), DatEnd (.End), TxtRoom (.Location). The patch should be based on the column .ID matching locMeetingID. */
Patch(
    INT003_Meetings_List,
    LookUp(INT003_Meetings_List, ID = locMeetingID),
    {
        Topic: TxtTopic.Text,
        Description: TxtDescription.Text,
        Starts: DatBegin.SelectedDate,
        Ends: DatEnd.SelectedDate,
        Location: TxtRoom.Text
    }
)

// Please reset all the input fields after the patch is executed. The input fields are:
// TxtTopic, TxtDescription, DatBegin, DatEnd, TxtRoom.
Reset(TxtTopic);
Reset(TxtDescription);
Reset(DatBegin);
Reset(DatEnd);
Reset(TxtRoom);

// Create a formula that shows the weekday based on DatBegin.SelectedDate.
Text(Weekday(DatBegin.SelectedDate), "dddd")

// Please create a formula that translates these days into German.
Switch(
    Weekday(DatBegin.SelectedDate),
    1, "Sonntag",
    2, "Montag",
    3, "Dienstag",
    4, "Mittwoch",
    5, "Donnerstag",
    6, "Freitag",
    7, "Samstag"
)

