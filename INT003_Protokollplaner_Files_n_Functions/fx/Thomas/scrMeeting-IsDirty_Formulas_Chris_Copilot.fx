// **************************************************************************************************************************************

// Define in App.Formulas to make the local variables available in the entire app.
App.Formulas =

/*
    Define local variables to store the last saved values of the meeting details.
    These variables are used to determine whether the meeting form contains unsaved changes.
    The variables are initialized with blank values and will be updated when a meeting is loaded or saved.
*/
MeetingFormDefaultLocals =
{
    // Local variables to store the last saved values of the meeting details.
    locMeetingID: Blank(),
    locTopic: Blank(),
    locLastSavedTopic: Blank(),
    locNewMeetingMode: false, // Needed for correct patch. @Thomas #scr-meeting-new-topic-variable
    locResetControls: false, // Needed to reset controls when switching topics.
    locDescription: Blank(),
    locStarts: Blank(),
    locEnds: Blank(),
    locLocation: Blank()
}; 

/*
    Provide centralized, reusable calculations for the current meeting start/end
    timestamps and determine whether the meeting form contains unsaved changes.

    CurrentMeetingStart
        Combines the selected meeting start date, hour and minute controls into a
        single DateTime value representing the meeting start timestamp currently
        entered by the user.

    CurrentMeetingEnd
        Combines the selected meeting end date, hour and minute controls into a
        single DateTime value representing the meeting end timestamp currently
        entered by the user.

    MeetingIsDirty
        Compares the values currently displayed in the meeting form with the last
        loaded or last saved meeting values stored in local variables.

    A meeting is considered "dirty" when at least one of the following differs:
        - Topic
        - Description
        - Start date/time
        - End date/time
        - Location

    The formula returns:
        - true  = unsaved changes exist
        - false = form content matches the stored meeting values

    Usage:
        Use MeetingIsDirty whenever navigation, topic changes, meeting creation,
        protocol generation or visual indicators must react to unsaved changes.

    Dependencies:

    Context Variables:
        - locTopic
        - locDescription
        - locStarts
        - locEnds
        - locLocation

    Controls:
        - TxtTopic
        - TxtDescription
        - TxtRoom
        - DtpDateBegin
        - DtpDateEnd
        - DrpMeetingStartHour
        - DrpMeetingStartMinutes
        - DrpMeetingEndHour
        - DrpMeetingEndMinutes
*/
CurrentMeetingStart =
    DtpDateBegin.SelectedDate +
    Time(
        Value(DrpMeetingStartHour.Selected.Value),
        Value(DrpMeetingStartMinutes.Selected.Value),
        0
    );

CurrentMeetingEnd =
    DtpDateEnd.SelectedDate +
    Time(
        Value(DrpMeetingEndHour.Selected.Value),
        Value(DrpMeetingEndMinutes.Selected.Value),
        0
    );

MeetingIsDirty =
    Trim(locTopic) <> Trim(TxtTopic.Text) ||
    Trim(locDescription) <> Trim(TxtDescription.Text) ||
    locStarts <> CurrentMeetingStart ||
    locEnds <> CurrentMeetingEnd ||
    Trim(locLocation) <> Trim(TxtRoom.Text);

// **************************************************************************************************************************************

/*
    Before calling BtnCheckMeetingIsDirty in a navigation button, define the name of the target 
    action to allow to branch and execute as expected.

    Possible actions: "navigate-to-Dashboard", "change-topic", "new-topic", "start-protocol"
*/
BtnNavigateToDashboard.OnSelect = 
UpdateContext({ locTargetAction: "navigate-to-Dashboard" });

/*
Checks whether the currently displayed meeting contains unsaved changes and, depending on the requested target action, either prompts the user for confirmation or continues the requested action without saving.

Step 1: Compare all editable meeting fields against their last saved values stored in local variables:
- Topic
- Description
- Start date/time
- End date/time
- Location

Step 2: If differences are detected, the meeting is considered "dirty" (contains unsaved changes).
Depending on the value of locTargetAction, activate the corresponding confirmation dialog by setting a dedicated dirty-state context variable:
- locIsDirtyDashboard
- locIsDirtyChangeTopic
- locIsDirtyNewTopic
- locIsDirtyProtocol

Step 3: If no changes are detected, reset all meeting-related local variables using MeetingFormDefaultLocals to ensure no stale values remain from a previous operation.

Step 4:Execute the requested target action:
- navigate-to-Dashboard: Prepare the screen for navigation and reset form controls.
- change-topic: Load the selected meeting from colMainMeetings and store its values in local meeting variables.
- new-topic: Enable new-meeting mode, initialize default start/end values and reset selection controls.
- start-protocol: Prepare navigation to the protocol screen.

Step 5: If control reset has been requested through locResetControls, reset all meeting input controls and clear the temporary reset flag.

Step 6: Perform final navigation when applicable:
- ScrDashboard
- ScrProtocol

Prerequisites: The variable locTargetAction must be set before this button is executed. Typical values are:
- "navigate-to-Dashboard"
- "change-topic"
- "new-topic"
- "start-protocol"

Dependencies

App Formulas:
- MeetingFormDefaultLocals

Context Variables:
- locTargetAction
- locMeetingID
- locTopic
- locDescription
- locStarts
- locEnds
- locLocation
- locNewMeetingMode
- locResetControls
- locIsDirtyDashboard
- locIsDirtyChangeTopic
- locIsDirtyNewTopic
- locIsDirtyProtocol

Collections:
- colMainMeetings

Controls:
- TxtTopic
- TxtDescription
- TxtRoom
- DtpDateBegin
- DtpDateEnd
- DrpMeetingStartHour
- DrpMeetingStartMinutes
- DrpMeetingEndHour
- DrpMeetingEndMinutes
- DrpTopicSelection

Screens:
- ScrDashboard
- ScrProtocol

Temporary Record Variables:
- varSelectedMeeting (used within With())

Outputs / Side Effects:
- Updates multiple context variables.
- Resets form controls.
- Loads selected meeting data.
- Initiates navigation to other screens.
- Triggers dirty-state confirmation dialogs when unsaved changes are detected.
*/
BtnCheckMeetingIsDirty.OnSelect =
If(
    MeetingIsDirty, 

    // Is dirty, HAS CHANGES: Trigger prompt popup to decide how to continue ----------------------------------------------------------
    Switch(
        locTargetAction,
        "navigate-to-Dashboard", UpdateContext({locIsDirtyDashboard: true}), // activates confirmation screen @Thomas 28.09.2026 #scr-meeting-check-isdirty-dashboardbutton-confirmation
        "change-topic", UpdateContext({locIsDirtyChangeTopic: true}), // activates confirmation screen @Thomas 28.09.2026 #scr-meeting-check-isdirty-changetopic-confirmation
        "new-topic", UpdateContext({locIsDirtyNewTopic: true}), // activates confirmation screen @Thomas 28.09.2026 #scr-meeting-check-isdirty-newtopic-confirmation
        "start-protocol", UpdateContext({locIsDirtyProtocol: true}) // activates confirmation screen @Thomas 28.09.2026 #scr-meeting-check-isdirty-protocolbutton-confirmation
    ),

    // NO CHANGES: No saving required, continue as expected (navigate, create new meeting) --------------------------------------------
    UpdateContext(MeetingFormDefaultLocals); // For all target actions, first clear previous values.

    Switch(
        locTargetAction,
        "navigate-to-Dashboard", 
            UpdateContext({locResetControls: true}), // Reset controls when switching topics.
        
        "change-topic",
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
                        locMeetingID: varSelectedMeeting.meetID,
                        locTopic: varSelectedMeeting.meetTopic,
                        locDescription: varSelectedMeeting.meetDescription,
                        locStarts: varSelectedMeeting.meetStarts,
                        locEnds: varSelectedMeeting.meetEnds,
                        locLocation: varSelectedMeeting.meetLocation
                    })
                )
            ),

        "new-topic",
            UpdateContext({
                locNewMeetingMode: true, // Needed for correct patch. @Thomas #scr-meeting-new-topic-variable
                locStarts: Today() + Time(8, 30, 0),
                locEnds: Today()+7 + Time(9, 00, 0)
            });

            UpdateContext({locResetControls: true}); // Reset controls when switching topics.
            Reset(DrpTopicSelection), // Reset topic dropdown. @Thomas #scr-meeting-new-topic-dropdown

        "start-protocol",
            UpdateContext({locResetControls: true}) // Reset controls when switching topics.
    );

    // Reset the reset variable and the controls.
    If(
        locResetControls, 

        UpdateContext({locResetControls: false});
        Reset(TxtTopic);
        Reset(TxtDescription);
        Reset(DtpDateBegin);
        Reset(DtpDateEnd);
        Reset(TxtRoom);
        Reset(DrpMeetingStartHour);
        Reset(DrpMeetingStartMinutes);
        Reset(DrpMeetingEndHour);
        Reset(DrpMeetingEndMinutes);    
    ); 

    // Navigate to the target screen if no changes are pending.
    Switch(
        locTargetAction,
        "navigate-to-Dashboard", Navigate(ScrDashboard, ScreenTransition.None),
        "start-protocol", Navigate(ScrProtocol, ScreenTransition.None, { locMeetingIDProtocol: locMeetingID })
    )
);

// **************************************************************************************************************************************

// Label that shows if there are unsaved changes. @Thomas 29.09.2026 #scr-meeting-isdirty-label
LblNotYetSaved.Text =
If(MeetingIsDirty, "Änderungen noch nicht gespeichert.", "")