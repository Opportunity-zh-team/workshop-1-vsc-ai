BtnOverviewTopicsScrMeeting.OnSelect =
// Check if there are unsaved changes. @Thomas 28.09.2026 #scr-meeting-check-isdirty-dashboardbutton
If( Trim(locTopic) <> Trim(TxtTopic.Text) ||
    Trim(locDescription) <> Trim(TxtDescription.Text) ||
    locStarts <> DtpDateBegin.SelectedDate +
                    Time(
                        Value(DrpMeetingStartHour.Selected.Value),
                        Value(DrpMeetingStartMinutes.Selected.Value),
                        0
                    ) ||
    locEnds <> DtpDateEnd.SelectedDate +
                    Time(
                        Value(DrpMeetingEndHour.Selected.Value),
                        Value(DrpMeetingEndMinutes.Selected.Value),
                        0
                    ) ||
    Trim(locLocation) <> Trim(TxtRoom.Text),
    UpdateContext( {locIsDirtyDashboard: true}), // activates confirmation screen @Thomas 28.09.2026 #scr-meeting-check-isdirty-dashboardbutton-confirmation
    
    // If no changes pending, go to scrDashboard. @Thomas 28.09.2026 ##scr-meeting-button-dashboard
    UpdateContext({locMeetingID: Blank(), locTopic: Blank(), locLastSavedTopic: Blank(), locNewMeetingMode: false, locDescription: Blank(), locStarts: Blank(), locEnds: Blank(), locLocation: Blank()}); // Clear previous values

    Reset(TxtTopic);
    Reset(TxtDescription);
    Reset(DtpDateBegin);
    Reset(DtpDateEnd);
    Reset(TxtRoom);
    Reset(DrpMeetingStartHour);
    Reset(DrpMeetingStartMinutes);
    Reset(DrpMeetingEndHour);
    Reset(DrpMeetingEndMinutes);

    Navigate(ScrDashboard, ScreenTransition.None)
)


DrpTopicSelection.OnChange =
// Check if there are unsaved changes. @Thomas 28.09.2026 #scr-meeting-check-isdirty-changetopic
If( Trim(locTopic) <> Trim(TxtTopic.Text) ||
    Trim(locDescription) <> Trim(TxtDescription.Text) ||
    locStarts <> DtpDateBegin.SelectedDate +
                    Time(
                        Value(DrpMeetingStartHour.Selected.Value),
                        Value(DrpMeetingStartMinutes.Selected.Value),
                        0
                    ) ||
    locEnds <> DtpDateEnd.SelectedDate +
                    Time(
                        Value(DrpMeetingEndHour.Selected.Value),
                        Value(DrpMeetingEndMinutes.Selected.Value),
                        0
                    ) ||
    Trim(locLocation) <> Trim(TxtRoom.Text),
    UpdateContext( {locIsDirtyChangeTopic: true}), // activates confirmation screen @Thomas 28.09.2026 #scr-meeting-check-isdirty-changetopic-confirmation


    // Reset local variables. @Thomas #screen-meeting-topic-dropdown
    UpdateContext({
        locMeetingID: Blank(),
        locTopic: Blank(),
        locDescription: Blank(),
        locStarts: Blank(),
        locEnds: Blank(),
        locLocation: Blank()
    });

    // If a selection has been made, save it into local variables. @Thomas 23.09.2026 #screen-meeting-topic-dropdown-selected
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
                locNewMeetingMode: false, // Needed for correct patch, Edit mode. @Thomas 23.09.2026
                locMeetingID: varSelectedMeeting.meetID,
                locTopic: varSelectedMeeting.meetTopic,
                locDescription: varSelectedMeeting.meetDescription,
                locStarts: varSelectedMeeting.meetStarts,
                locEnds: varSelectedMeeting.meetEnds,
                locLocation: varSelectedMeeting.meetLocation
            })
        )
    )
)


BtnAddTopic.OnSelect =
// Check if there are unsaved changes. @Thomas 28.09.2026 #scr-meeting-check-isdirty-newtopic
If( Trim(locTopic) <> Trim(TxtTopic.Text) ||
    Trim(locDescription) <> Trim(TxtDescription.Text) ||
    locStarts <> DtpDateBegin.SelectedDate +
                    Time(
                        Value(DrpMeetingStartHour.Selected.Value),
                        Value(DrpMeetingStartMinutes.Selected.Value),
                        0
                    ) ||
    locEnds <> DtpDateEnd.SelectedDate +
                    Time(
                        Value(DrpMeetingEndHour.Selected.Value),
                        Value(DrpMeetingEndMinutes.Selected.Value),
                        0
                    ) ||
    Trim(locLocation) <> Trim(TxtRoom.Text),
    UpdateContext( {locIsDirtyNewTopic: true}), // activates confirmation screen @Thomas 28.09.2026 #scr-meeting-check-isdirty-newtopic-confirmation

    // Set variable for new topic mode and reset detail fields. @Thomas 23.09.2026 #scr-meeting-new-topic
    UpdateContext({
        locNewMeetingMode: true, // Needed for correct patch. @Thomas #scr-meeting-new-topic-variable
        // locNewMeetingModeShowAgendaItemsParticipants: false, // Hide agenda items and participants if topic is not saved yet. @Thomas #scr-meeting-new-topic-hide-variable. Not needed.
        locMeetingID: Blank(),
        locTopic: "",
        locDescription: "",
        locStarts: Today() + Time(8, 30, 0),
        locEnds: Today()+7 + Time(9, 00, 0),
        locLocation: ""
    });

    Reset(TxtTopic);
    Reset(TxtDescription);
    Reset(DtpDateBegin);
    Reset(DtpDateEnd);
    Reset(TxtRoom);
    Reset(DrpMeetingStartHour);
    Reset(DrpMeetingStartMinutes);
    Reset(DrpMeetingEndHour);
    Reset(DrpMeetingEndMinutes);

    // Reset variable "locLastSavedTopic" and reset topic dropdown. @Thomas #scr-meeting-new-topic-dropdown
    UpdateContext({ locLastSavedTopic: Blank() });
    Reset(DrpTopicSelection)
)


LblNotYetSaved.Text =
// Label that shows if there are unsaved changes. @Thomas 29.09.2026 #scr-meeting-isdirty-label
If( Trim(locTopic) <> Trim(TxtTopic.Text) ||
    Trim(locDescription) <> Trim(TxtDescription.Text) ||
    locStarts <> DtpDateBegin.SelectedDate +
                    Time(
                        Value(DrpMeetingStartHour.Selected.Value),
                        Value(DrpMeetingStartMinutes.Selected.Value),
                        0
                    ) ||
    locEnds <> DtpDateEnd.SelectedDate +
                    Time(
                        Value(DrpMeetingEndHour.Selected.Value),
                        Value(DrpMeetingEndMinutes.Selected.Value),
                        0
                    ) ||
    Trim(locLocation) <> Trim(TxtRoom.Text) ,"Änderungen noch nicht gespeichert.", "")


BtnStartMeeting.OnSelect =
// Check if there are unsaved changes. @Thomas 28.09.2026 #scr-meeting-check-isdirty-protocolbutton
If( Trim(locTopic) <> Trim(TxtTopic.Text) ||
    Trim(locDescription) <> Trim(TxtDescription.Text) ||
    locStarts <> DtpDateBegin.SelectedDate +
                    Time(
                        Value(DrpMeetingStartHour.Selected.Value),
                        Value(DrpMeetingStartMinutes.Selected.Value),
                        0
                    ) ||
    locEnds <> DtpDateEnd.SelectedDate +
                    Time(
                        Value(DrpMeetingEndHour.Selected.Value),
                        Value(DrpMeetingEndMinutes.Selected.Value),
                        0
                    ) ||
    Trim(locLocation) <> Trim(TxtRoom.Text),
    UpdateContext( {locIsDirtyProtocol: true}), // activates confirmation screen @Thomas 28.09.2026 #scr-meeting-check-isdirty-protocolbutton-confirmation
    
    Reset(TxtTopic);
    Reset(TxtDescription);
    Reset(DtpDateBegin);
    Reset(DtpDateEnd);
    Reset(TxtRoom);
    Reset(DrpMeetingStartHour);
    Reset(DrpMeetingStartMinutes);
    Reset(DrpMeetingEndHour);
    Reset(DrpMeetingEndMinutes);

    // If no changes pending, go to scrProtocol. @Thomas 28.09.2026 ##scr-meeting-button-protocol
    Navigate(ScrProtocol, ScreenTransition.None, { locMeetingIDProtocol: locMeetingID });

    UpdateContext({locMeetingID: Blank(), locTopic: Blank(), locLastSavedTopic: Blank(), locNewMeetingMode: false, locDescription: Blank(), locStarts: Blank(), locEnds: Blank(), locLocation: Blank()}); // Clear previous values. @Thomas ##scr-meeting-button-protocol

);