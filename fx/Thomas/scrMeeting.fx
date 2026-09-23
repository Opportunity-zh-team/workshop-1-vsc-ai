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
        Starts: DtpDateBegin.SelectedDate +
                Time(
                    Value(DrpMeetingStartHour.Selected.Value),
                    Value(DrpMeetingStartMinutes.Selected.Value),
                    0
                ),
        Ends: DtpDateEnd.SelectedDate +
                Time(
                    Value(DrpMeetingEndHour.Selected.Value),
                    Value(DrpMeetingEndMinutes.Selected.Value),
                    0
                ),
        Location: TxtRoom.Text
    }
);

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

/* I want to delete a participant from the table INT003_Participants_List. The participant should be selected in the gallery GalParticipantsScrMeetings. The column Participant_Email should be used to identify the participant to delete based on locParticipantEmailDel. */
Remove(
    INT003_Participants_List,
    LookUp(INT003_Participants_List, Participant_Email = locParticipantEmailDel && Meeting_Id.Id = locMeetingID)
);

/* If locNewMeetingMode is set to true, the patch should create a new meeting in the table INT003_Meetings_List.
   The following input fields should be used to create the new meeting:

   Topic (string): TxtTopic
   Description (string): TxtDescription
   Starts (DateTime): DtpDateBegin.SelectedDate +
                Time(
                    Value(DrpMeetingStartHour.Selected.Value),
                    Value(DrpMeetingStartMinutes.Selected.Value),
                    0
                )
   Ends (DateTime): DtpDateEnd.SelectedDate +
                Time(
                    Value(DrpMeetingEndHour.Selected.Value),
                    Value(DrpMeetingEndMinutes.Selected.Value),
                    0
                )
   Location (string): TxtRoom
*/
Patch(
    INT003_Meetings_List,
    Defaults(INT003_Meetings_List),
    {
        Topic: TxtTopic.Text,
        Description: TxtDescription.Text,
        Starts: DtpDateBegin.SelectedDate +
                Time(
                    Value(DrpMeetingStartHour.Selected.Value),
                    Value(DrpMeetingStartMinutes.Selected.Value),
                    0
                ),
        Ends: DtpDateEnd.SelectedDate +
                Time(
                    Value(DrpMeetingEndHour.Selected.Value),
                    Value(DrpMeetingEndMinutes.Selected.Value),
                    0
                ),
        Location: TxtRoom.Text
    }
);

// Now combine the two patches into one formula. If locNewMeetingMode is true, it should create a new meeting, otherwise it should update the existing meeting.
If(
    locNewMeetingMode,
    Patch(
        INT003_Meetings_List,
        Defaults(INT003_Meetings_List),
        {
            Topic: TxtTopic.Text,
            Description: TxtDescription.Text,
            Starts: DtpDateBegin.SelectedDate +
                    Time(
                        Value(DrpMeetingStartHour.Selected.Value),
                        Value(DrpMeetingStartMinutes.Selected.Value),
                        0
                    ),
            Ends: DtpDateEnd.SelectedDate +
                    Time(
                        Value(DrpMeetingEndHour.Selected.Value),
                        Value(DrpMeetingEndMinutes.Selected.Value),
                        0
                    ),
            Location: TxtRoom.Text
        }
    ),
    Patch(
        INT003_Meetings_List,
        LookUp(INT003_Meetings_List, ID = locMeetingID),
        {
            Topic: TxtTopic.Text,
            Description: TxtDescription.Text,
            Starts: DtpDateBegin.SelectedDate +
                    Time(
                        Value(DrpMeetingStartHour.Selected.Value),
                        Value(DrpMeetingStartMinutes.Selected.Value),
                        0
                    ),
            Ends: DtpDateEnd.SelectedDate +
                    Time(
                        Value(DrpMeetingEndHour.Selected.Value),
                        Value(DrpMeetingEndMinutes.Selected.Value),
                        0
                    ),
            Location: TxtRoom.Text
        }
    )
);

/* The same needs to be done to add a new record to the collection colMainMeetings.
   If locNewMeetingMode is true, it should add a new record to the collection, otherwise it should update the existing record in the collection.

   Following is the current code for updateing the collection:
UpdateIf(
    colMainMeetings,
    meetID = locMeetingID,
    {
        meetTopic: TxtTopic.Text,
        meetDescription: TxtDescription.Text,
        meetStarts: DtpDateBegin.SelectedDate +
                Time(
                    Value(DrpMeetingStartHour.Selected.Value),
                    Value(DrpMeetingStartMinutes.Selected.Value),
                    0
                ),
        meetEnds: DtpDateEnd.SelectedDate +
                Time(
                    Value(DrpMeetingEndHour.Selected.Value),
                    Value(DrpMeetingEndMinutes.Selected.Value),
                    0
                ),
        meetLocation: TxtRoom.Text
    }
); */
If (
    locNewMeetingMode,
    Collect(
        colMainMeetings,
        {
            meetID: Max(colMainMeetings, meetID) + 1,
            meetTopic: TxtTopic.Text,
            meetDescription: TxtDescription.Text,
            meetStarts: DtpDateBegin.SelectedDate +
                    Time(
                        Value(DrpMeetingStartHour.Selected.Value),
                        Value(DrpMeetingStartMinutes.Selected.Value),
                        0
                    ),
            meetEnds: DtpDateEnd.SelectedDate +
                    Time(
                        Value(DrpMeetingEndHour.Selected.Value),
                        Value(DrpMeetingEndMinutes.Selected.Value),
                        0
                    ),
            meetLocation: TxtRoom.Text
        }
    ),
    UpdateIf(
        colMainMeetings,
        meetID = locMeetingID,
        {
            meetTopic: TxtTopic.Text,
            meetDescription: TxtDescription.Text,
            meetStarts: DtpDateBegin.SelectedDate +
                    Time(
                        Value(DrpMeetingStartHour.Selected.Value),
                        Value(DrpMeetingStartMinutes.Selected.Value),
                        0
                    ),
            meetEnds: DtpDateEnd.SelectedDate +
                    Time(
                        Value(DrpMeetingEndHour.Selected.Value),
                        Value(DrpMeetingEndMinutes.Selected.Value),
                        0
                    ),
            meetLocation: TxtRoom.Text
        }
    )
);

/* I need to update the local variable locMeetingID with the ID of the newly created meeting. How can I do that? You can update the variable locMeetingID with the ID of the newly created meeting by using the Last function to get the last item added to the collection colMainMeetings. Here's how you can do it: */
UpdateContext({locMeetingID: Last(colMainMeetings).meetID});

// Can you sort this collection colUI_MeetingsDrp by the column meetTopic?
Yes, you can sort the collection `colUI_MeetingsDrp` by the column `meetTopic` using the `Sort` function in Power Apps. Here's how you can do it:
Sort(colUI_MeetingsDrp, meetTopic)

/* If a new topic is created, it should check if the entry already exists in the collection colMainMeetings. If it does, it should not add a new entry but show a notification "Topic already exists.". Based on the topic name. */
If(
    CountRows(
        Filter(colMainMeetings, meetTopic = TxtTopic.Text)
    ) > 0,
    Notify("Thema existiert bereits.", NotificationType.Error),
);

// This additionally needs to apply trim und upper-/lowercase should not be considered. So it should check if the topic already exists in the collection colMainMeetings, ignoring leading/trailing spaces and case sensitivity. If it does, it should not add a new entry but show a notification "Topic already exists." based on the topic name.
If(
    CountRows(
        Filter(colMainMeetings, Lower(Trim(meetTopic)) = Lower(Trim(TxtTopic.Text)))
    ) > 0,
    Notify("Thema existiert bereits.", NotificationType.Error),
);

/* Can this be done with lookUp instead of filtering:
If(
    !IsBlank(DrpTopicSelection.Selected),
    With(
        { selectedTopic: DrpTopicSelection.Selected.meetTopic },
        ClearCollect(
            colSelectedMeeting,
            Filter(colMainMeetings, meetTopic = selectedTopic)
        );
        If(
            CountRows(colSelectedMeeting) > 0,
            UpdateContext({
                locNewMeetingMode: false, // Needed for correct patch.
                locMeetingID: First(colSelectedMeeting).meetID,
                locTopic: First(colSelectedMeeting).meetTopic,
                locDescription: First(colSelectedMeeting).meetDescription,
                locStarts: First(colSelectedMeeting).meetStarts,
                locEnds: First(colSelectedMeeting).meetEnds,
                locLocation: First(colSelectedMeeting).meetLocation
            })
        )
    )
); */
It is possible to use LookUp instead of Filter in this case. The LookUp function returns the first record that matches the specified condition, so you can simplify the code as follows:
If(
    !IsBlank(DrpTopicSelection.Selected),
    With(
        { selectedTopic: DrpTopicSelection.Selected.meetTopic },
        ClearCollect(
            colSelectedMeeting,
            LookUp(colMainMeetings, meetTopic = selectedTopic)
        );
        If(
            CountRows(colSelectedMeeting) > 0,
            UpdateContext({
                locNewMeetingMode: false, // Needed for correct patch.
                locMeetingID: First(colSelectedMeeting).meetID,
                locTopic: First(colSelectedMeeting).meetTopic,
                locDescription: First(colSelectedMeeting).meetDescription,
                locStarts: First(colSelectedMeeting).meetStarts,
                locEnds: First(colSelectedMeeting).meetEnds,
                locLocation: First(colSelectedMeeting).meetLocation
            })
        )
    )
);

// Is First really needed in this case? Since LookUp returns a single record, you can directly access the fields of that record without using First. Here's the modified code:
With(
    {
        varSelectedMeeting: LookUp(
            colMainMeetings,
            meetTopic = DrpTopicSelection.Selected.meetTopic
        )
    },
    If(
        !IsBlank(varSelectedMeeting),
        UpdateContext({
            locNewMeetingMode: false, // Needed for correct patch, Edit mode. Thomas 23.09.2026
            locMeetingID: varSelectedMeeting.meetID,
            locTopic: varSelectedMeeting.meetTopic,
            locDescription: varSelectedMeeting.meetDescription,
            locStarts: varSelectedMeeting.meetStarts,
            locEnds: varSelectedMeeting.meetEnds,
            locLocation: varSelectedMeeting.meetLocation
        })
    )
)
