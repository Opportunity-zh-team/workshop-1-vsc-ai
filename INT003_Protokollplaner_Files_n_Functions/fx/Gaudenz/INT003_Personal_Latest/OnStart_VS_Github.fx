/*
    App.OnStart starter for the five INT003_DEV SharePoint lists.

    Confirm that the SharePoint data-source names in this file match the
    connected data sources in the app before pasting it into App.OnStart.
    The collections are startup snapshots; CRUD operations should Patch the
    SharePoint data sources and then refresh/reload the affected collection.

    SharePoint lookup fields are records. The aliases below expose their
    numeric lookup IDs and display values for filtering and form logic.
    Is_Present is a Number column; use the app's agreed numeric values
    (for example, 0 and 1) rather than treating it as a Boolean.

    ClearCollect can load only up to the app's non-delegation row limit
    (500 by default, configurable up to 2,000). For larger lists, use
    delegable SharePoint queries instead of relying on a full local copy.
*/

// SharePoint item IDs are numeric; 0 means no item is selected.
Set(glbSelectedMeetingId, 0);
Set(glbSelectedProtocolId, 0);
Set(glbSelectedAgendaId, 0);
Set(glbSelectedActionId, 0);
Set(glbSelectedParticipantId, 0);

// Meeting form working values (text fields and date/time fields).
Set(locMeetingTitle, "");
Set(locMeetingTopic, "");
Set(locMeetingDescription, "");
Set(locMeetingStarts, Now());
Set(locMeetingEnds, Now());
Set(locMeetingStarts, Blank());
Set(locMeetingEnds, Blank());
Set(locMeetingLocation, "");

// Protocol and action form working values.
Set(locProtocolText, "");
Set(locActionItem, "");
Set(locActionSortOrder, 0);
Set(locActionDoneDate, Now());
Set(locActionDoneDate, Blank());

// Participant form working values (Is_Present is a SharePoint Number).
Set(locParticipantEmail, "");
Set(locParticipantIsPresent, 0);

// Meetings: Title/Topic/Description/Location are text; Starts/Ends are date/time.
ClearCollect(
    colMainMeetings,
    AddColumns(
        INT003_DEV_Meetings,
        meetID, ID,
        meetTitle, Title,
        meetTopic, Topic,
        meetDescription, Description,
        meetStarts, Starts,
        meetEnds, Ends,
        meetLocation, Location
    )
);

// Select the first meeting when available; otherwise retain the 0 sentinel.
Set(
    glbSelectedMeetingId,
    If(
        IsEmpty(colMainMeetings),
        0,
        First(colMainMeetings).meetID
    )
);
// Test

// Agenda items: Title/Agenda_Item are text; Meeting_Id is lookup; Sort_Order is number.
ClearCollect(
    colMainAgendaItems,
    AddColumns(
        INT003_DEV_Agenda_Items,
        agendaID, ID,
        agendaTitle, Title,
        agendaMeetingId, Meeting_Id.Id,
        agendaMeetingTitle, Meeting_Id.Value,
        agendaItem, Agenda_Item,
        agendaSortOrder, Sort_Order
    )
);

// Protocols: Title is text; Meeting_Id is lookup; Started_At is date/time;
// Protocol_Text is multiple lines of text.
ClearCollect(
    colMainProtocols,
    AddColumns(
        INT003_DEV_Protocols,
        protocolID, ID,
        protocolTitle, Title,
        protocolMeetingId, Meeting_Id.Id,
        protocolMeetingTitle, Meeting_Id.Value,
        protocolStartedAt, Started_At,
        protocolText, Protocol_Text,
        protocolMeetingTopic,
        LookUp(
            colMainMeetings,
            meetID = Meeting_Id.Id
        ).meetTopic
    )
);

// Actions: Title is text; Protocol_Id is lookup; Action_Item is multiple lines;
// Sort_Order is number; Done_Date is date/time.
ClearCollect(
    colMainActions,
    AddColumns(
        INT003_DEV_Actions,
        actionID, ID,
        actionTitle, Title,
        actionProtocolId, Protocol_Id.Id,
        actionProtocolTitle, Protocol_Id.Value,
        actionItem, Action_Item,
        actionSortOrder, Sort_Order,
        actionDoneDate, Done_Date,
        actionMeetingId,
        LookUp(
            colMainProtocols,
            protocolID = Protocol_Id.Id
        ).protocolMeetingId,
        actionProtocolText,
        LookUp(
            colMainProtocols,
            protocolID = Protocol_Id.Id
        ).protocolText
    )
);

// Participants: Title/Participant_Email are text; Meeting_Id is lookup;
// Is_Present is number.
ClearCollect(
    colMainParticipants,
    AddColumns(
        INT003_DEV_Participants,
        participantID, ID,
        participantTitle, Title,
        participantMeetingId, Meeting_Id.Id,
        participantMeetingTitle, Meeting_Id.Value,
        participantEmail, Participant_Email,
        participantIsPresent, Is_Present
    )
);

// Convenience collection for the currently selected meeting's agenda.
ClearCollect(
    colCurrentAgendaItems,
    Filter(
        colMainAgendaItems,
        agendaMeetingId = glbSelectedMeetingId
    )
);
