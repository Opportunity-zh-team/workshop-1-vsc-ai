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

/* For colMainMeetings I would like to add an item "Bitte auswählen..." by .OnVisible of the screen scrMeeting.
   The item should be added at the top of the collection. The item should have the following values:
    .ID = 0, .Topic = "Bitte auswählen...", .Description = "", .Starts = Blank(), .Ends = Blank(), .Location = "" */
ClearCollect(
    colMainMeetings,
    {ID: 0, Topic: "Bitte auswählen...", Description: "", Starts: Blank(), Ends: Blank(), Location: ""}
);

// Now it does not work because the collection is cleared and only the new item is added.
// Please modify the code so that the existing items of colMainMeetings are kept and the new item is added at the top of the collection.
AddColumns(
    colMainMeetings,
    {ID: 0, Topic: "Bitte auswählen...", Description: "", Starts: Blank(), Ends: Blank(), Location: ""}
)

// Error: The above code will not work as expected because AddColumns does not modify the existing collection but creates a new table with additional columns. Instead, you can use the following approach to add the new item at the top of the collection while keeping the existing items:
ClearCollect(
    colMainMeetings,
    {ID: 0, Topic: "Bitte auswählen...", Description: "", Starts: Blank(), Ends: Blank(), Location: ""},
    colMainMeetings
);

// It stil doesn't work. The content of colMainMeetings is missing. Please modify the code so that the existing items of colMainMeetings are kept and the new item is added at the top of the collection.
ClearCollect(
    colMainMeetings,
    {ID: 0, Topic: "Bitte auswählen...", Description: "", Starts: Blank(), Ends: Blank(), Location: ""},
    colMainMeetings
);

// No, still doesn't work. The content of colMainMeetings is missing. Please modify the code so that the existing items of colMainMeetings are kept and the new item is added at the top of the collection.
ClearCollect(
    colMainMeetings,
    {ID: 0, Topic: "Bitte auswählen...", Description: "", Starts: Blank(), Ends: Blank(), Location: ""},
    Filter(colMainMeetings, ID <> 0) // Keep existing items except the one with ID = 0
);

// OK, that works. How do I set it so it defaults to "Bitte auswählen..." in the dropdown DrpTopicSelection? You can set the Default property of the dropdown DrpTopicSelection to the item with ID = 0. Here's how you can do it:
Set the Default property of DrpTopicSelection to:
    Filter(colMainMeetings, ID = 0)

// I only want the hours of DateTime locStarts
You can extract the hours from the DateTime variable `locStarts` using the `Hour` function in Power Apps. Here's how you can do it:
Hour(locStarts)

/* I want to save (patch) participants into the table INT003_Participants_List.
   The following local variables should be saved into the mentioned columns:

   Meeting_Id (int): locMeetingID
   Participant_Email (string): locParticipantEmail
   */
Patch(
    INT003_DEV_Participants,
    Defaults(INT003_DEV_Participants),
    {
        Meeting_Id: {
            Id: locMeetingID,
            Value: locMeetingID
        },
        Participant_Email: locParticipantEmail
    }
);

// It should check additionally if the participant already exists for the meeting. If it does, it should not add a new entry but show a notification "Participant already exists for this meeting.". Based on the email.
If(
    CountRows(
        Filter(INT003_DEV_Participants, Meeting_Id.Id = locMeetingID && Participant_Email = locParticipantEmail)
    ) > 0,
    Notify("Teilnehmer existiert bereits für dieses Thema.", NotificationType.Error),
    Patch(
        INT003_DEV_Participants,
        Defaults(INT003_DEV_Participants),
        {
            Meeting_Id: {
                Id: locMeetingID,
                Value: locMeetingID
            },
            Participant_Email: locParticipantEmail
        }
    )
);