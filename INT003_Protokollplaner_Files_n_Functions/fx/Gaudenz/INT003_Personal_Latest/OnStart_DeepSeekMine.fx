// ============================================================================
// APP.ONSTART
// ============================================================================

// ----------------------------------------------------------------------------
// 0) Global Sentinels & UI State
// ----------------------------------------------------------------------------
Set(glbUserEmail, Lower(User().Email));

// -1 = "no protocol selected"
Set(glbSelectedProtocolId, -1);      
// Right panel starts in empty state
Set(glbShowEmptyOverview, true);     
// Validation labels hidden
Set(glbShowValidationErrors, false); 

// Selected agenda item sentinel
Set(glbSelectedAgendaId, 0);

// Carry variables (Blank, never 0, for transit logic)
Set(glbCarryMeetingId,  Blank());
Set(glbCarryProtocolId, Blank());

// ----------------------------------------------------------------------------
// 1) Declare working variables with typed defaults, then blank them.
// ----------------------------------------------------------------------------
Set(locMeetingID,   0);
Set(locStarts,      Now());
Set(locEnds,        Now());
Set(locTopic,       "");
Set(locDescription, "");
Set(locLocation,    "");

Set(locMeetingID,   Blank());
Set(locStarts,      Blank());
Set(locEnds,        Blank());
Set(locTopic,       Blank());
Set(locDescription, Blank());
Set(locLocation,    Blank());

// ----------------------------------------------------------------------------
// 2) Load Meetings (Root Entity)
// ----------------------------------------------------------------------------
ClearCollect(
    colMainMeetings,
    AddColumns(
        INT003_DEV_Meetings,
        meetID,          ID,
        meetTitle,       Title,
        meetTopic,       Topic,
        meetDescription, Description,
        meetStarts,      Starts,
        meetEnds,        Ends,
        meetLocation,    Location
    )
);

// Set default selected meeting
If(
    CountRows(colMainMeetings) > 0,
    Set(glbSelectedMeetingId, First(colMainMeetings).meetID),
    Set(glbSelectedMeetingId, Blank())
);

// ----------------------------------------------------------------------------
// 3) Load Protocols
// ----------------------------------------------------------------------------
ClearCollect(
    colMainProtocols,
    AddColumns(
        INT003_DEV_Protocols,
        protocolID,             ID,
        protocolMeetingId,      Meeting_Id.Id,
        protocolMeetingTitle,   Meeting_Id.Value,
        protocolStartedAt,      Started_At,
        protocolText,           Protocol_Text,
        protocolCreated,        Created,
        // Enrich with meeting data for quick access
        protocolMeetingTopic,
            LookUp(colMainMeetings, meetID = Meeting_Id.Id).meetTopic,
        protocolMeetingDescription,
            LookUp(colMainMeetings, meetID = Meeting_Id.Id).meetDescription
    )
);

// ----------------------------------------------------------------------------
// 4) Load Actions
// ----------------------------------------------------------------------------
ClearCollect(
    colMainActions,
    AddColumns(
        INT003_DEV_Actions,
        actionID,               ID,
        actionProtocolId,       Protocol_Id.Id,
        actionProtocolTitle,    Protocol_Id.Value,
        actionItem,             Action_Item,
        actionSortOrder,        Sort_Order,
        actionDoneDate,         Done_Date,
        actionCreated,          Created,
        // Enrich with protocol/meeting info
        actionProtocolText,
            LookUp(colMainProtocols, protocolID = Protocol_Id.Id).protocolText,
        actionMeetingTopic,
            LookUp(colMainProtocols, protocolID = Protocol_Id.Id).protocolMeetingTopic
    )
);

// ----------------------------------------------------------------------------
// 5) Load Participants
// ----------------------------------------------------------------------------
ClearCollect(
    colMainParticipants,
    AddColumns(
        INT003_DEV_Participants,
        participantID,              ID,
        participantMeetingId,       Meeting_Id.Id,
        participantMeetingTitle,    Meeting_Id.Value,
        participantEmail,           Participant_Email,
        participantIsPresent,       Is_Present,
        participantCreated,         Created
    )
);

// ----------------------------------------------------------------------------
// 6) Load Agenda Items (Both for selected meeting & full list)
// ----------------------------------------------------------------------------
// Agenda items just for the currently selected meeting
ClearCollect(
    colCurrentAgendaItems,
    Filter(
        INT003_DEV_Agenda_Items,
        Meeting_Id.Id = glbSelectedMeetingId
    )
);

// All agenda items, flattened for local filtering
ClearCollect(
    colMainAgendaItems,
    AddColumns(
        INT003_DEV_Agenda_Items,
        agendaID,           ID,
        agendaTitle,        Title,
        agendaItem,         Agenda_Item,
        agendaSortOrder,    Sort_Order,
        agendaMeetingId,    Meeting_Id.Id
    )
);

// ----------------------------------------------------------------------------
// 7) Debug Panel Default
// ----------------------------------------------------------------------------
Set(varDebugPanelVisible, false);