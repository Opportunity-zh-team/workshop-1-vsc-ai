/*  
    DEV-NOTES:
    App.OnStart initializes all global state, loads the four root collections
    (Meetings, Protocols, Actions, Participants) plus the selected meeting's
    agenda items, cleans up orphaned draft meetings, and seeds default
    selection for the dashboard.

    Process:
    1. Declare working variables (loc*) with typed defaults
    2. Immediately blank them → known empty state on first render
    3. Load colMainMeetings        (UI, flattened: meet* aliases)
    4. Set glbSelectedMeetingId    = First(colMainMeetings)
    5. Load colMainProtocols       (UI, depends on colMainMeetings for topic/description)
    6. Load colMainActions         (UI, depends on colMainProtocols for text/topic)
    7. Load colMainParticipants    (UI)
    8. Load colCurrentAgendaItems  (UI, filtered by glbSelectedMeetingId)
    9. Load colMainAgendaItems     (UI, full list, flattened: agenda* aliases)
    10. Cleanup orphaned drafts (Title starts with "TMP-" AND Topic is Blank):
        - Remove child agenda items and participants
        - Remove the meeting row
        - Rebuild the three collections if any orphans were found

    Globals read:   —
    Globals write:  glbSelectedMeetingId, glbCarryMeetingId, glbCarryProtocolId,
                    glbSelectedAgendaId, gblMeetingId, gblStarts, gblEnds, gblTopic,
                    gblDescription, gblLocation
    Collections out: colMainMeetings, colMainProtocols, colMainActions,
                     colMainParticipants, colCurrentAgendaItems, colMainAgendaItems

    Order: Meetings → Protocols → Actions → Participants → AgendaItems → Cleanup.
    Each later collection LooksUp into an earlier one. Cleanup runs last because
    it needs the loaded collections to find children. Don't reorder.

    Gotchas:
    - Set() always creates a GLOBAL. The loc-/gbl- prefix is convention only.
    - meetStarts/meetEnds stored as text; parsed via DateTimeValue de-DE. Locale change breaks silently.
    - Empty colMainMeetings → First(...).meetID = Blank → all downstream filters return nothing silently.
    - Source spelling "Avatr_Image" kept as-is (SharePoint column name).
    - Orphan cleanup uses StartsWith(Title, "TMP-") — marker contract with
      BtnNewThemeFooter.OnSelect. Delegation warning possible on large lists.

    @gaudenz

    Tags:
    #app-onstart
    #load-meetings-protocols-actions-participants
    #flattened-collection-architecture
    #carry-variables-screen-transit
    #sort-order-by-meet-id
    #de-DE-datetime-parsing
    #introduce-glbLoadMeetingId
    #introduce-glbSelectedMeetingId
    #introduce-glbCarryMeetingId
    #introduce-glbCarryProtocolId
    #cleanup-orphan-drafts
    #introduce-fix-meetingID-oncreate
*/

// ============================================================================
// APP.ONSTART (Optimized but keeps all your flattened architecture)
// ============================================================================

// ----------------------------------------------------------------------------
// 0) Declare working variables with typed defaults, then blank them.
//    Purpose: gives intellisense a type hint, then ensures a clean start.
//    NOTE: Set() → GLOBAL. Prefix loc* is naming convention, not scope.
// ----------------------------------------------------------------------------
Set(locMeetingID,   0);
Set(locStarts,      Now());
Set(locEnds,        Now());
Set(locTopic,       "");
Set(locDescription, "");
Set(locLocation,    "");

// #introduce-glbSelectedAgendaId
Set(glbSelectedAgendaId, 0);

// #carry-variables-screen-transit
Set(glbCarryMeetingId,  0);
Set(glbCarryProtocolId, 0);
//   -1 = "no carried protocol"

// Immediately blank them → known empty state on first screen render
Set(locMeetingID,   Blank());
Set(locStarts,      Blank());
Set(locEnds,        Blank());
Set(locTopic,       Blank());
Set(locDescription, Blank());
Set(locLocation,    Blank());

// #set-validation-form-flag-for-error-display
Set(glbShowValidationErrors, false);

// ---------------------------------------------
// 1) Load Meetings (root entity)
// ---------------------------------------------
// Source:  INT003_Meetings_List (SharePoint)
// Output:  colMainMeetings — flattened with meet* aliases
// Notes:   meetStarts/meetEnds parsed from text → datetime (de-DE)
ClearCollect(
    colMainMeetings,
    AddColumns(
        INT003_Meetings_List,
        meetID,          ID,
        meetTitle,       Topic,
        meetTopic,       Topic,
        meetDescription, Description,
        meetStarts,
        IfError(
            DateTimeValue(
                Text(Starts, "[$-de-DE]dd.mm.yyyy HH:mm"),
                "de-DE"
            ),
            Blank()
        ),
        meetEnds,        Ends,
        meetLocation,    Location,
        meetState,       State
    )
);

// Default meeting selection
// #introduce-glbSelectedMeetingId
Set(
    glbSelectedMeetingId,
    First(colMainMeetings).meetID
);

// ---------------------------------------------
// 2) Load Protocols (depends on Meetings)
// ---------------------------------------------
// Source:  INT003_Protocols_List
// Output:  colMainProtocols — enriched with meeting topic/description
// Depends: colMainMeetings must already be loaded
// FIX 11/09
ClearCollect(
    colMainProtocols,
    AddColumns(
        INT003_Protocols_List,
        protocolID,             ID,
        protocolMeetingId,      Meeting_Id.Id,
        protocolMeetingTitle,   Meeting_Id.Value,
        protocolStartedAt,
        IfError(
            DateTimeValue(
                Text(Started_At, "[$-de-DE]dd.mm.yyyy HH:mm"),
                "de-DE"
            ),
            Blank()
        ),
        protocolText,           Protocol_Text,
        protocolCreated,        Created,
        protocolMeetingTopic,
        LookUp(colMainMeetings, meetID = Meeting_Id.Id).meetTopic,
        protocolMeetingDescription,
        LookUp(colMainMeetings, meetID = Meeting_Id.Id).meetDescription
    )
);

// ---------------------------------------------
// 3) Load Actions (depends on Protocols)
// ---------------------------------------------
// Source:  INT003_Actions_List
// Output:  colMainActions — enriched with protocol text + meeting topic
// Depends: colMainProtocols must already be loaded
// Note:    "Checked" column intentionally removed for now
//          (#removing-toggle-circle-checked)
ClearCollect(
    colMainActions,
    AddColumns(
        INT003_Actions_List,
        actionID,               ID,
        actionProtocolId,       Protocol_Id.Id,
        actionProtocolTitle,    Protocol_Id.Value,
        actionItem,             Action_Item,
        actionSortOrder,        Sort_Order,
        actionDoneDate,         Done_Date,
        actionCreated,          Created,
        actionProtocolText,
        LookUp(colMainProtocols, protocolID = Protocol_Id.Id).protocolText,
        actionMeetingTopic,
        LookUp(colMainProtocols, protocolID = Protocol_Id.Id).protocolMeetingTopic
    )
);

// ---------------------------------------------
// 4) Load Participants (depends on Meetings)
// ---------------------------------------------
// Source:  INT003_Participants_List
// Output:  colMainParticipants
ClearCollect(
    colMainParticipants,
    AddColumns(
        INT003_Participants_List,
        participantID,              ID,
        participantMeetingId,       Meeting_Id.Id,
        participantMeetingTitle,    Meeting_Id.Value,
        participantEmail,           Participant_Email,
        participantIsPresent,       Is_Present,
        participantAvatarImage,     Avatr_Image,      // (sic: source spelling)
        participantCreated,         Created
    )
);

// ---------------------------------------------
// 5) Load Agenda Items for selected meeting
// ---------------------------------------------
// #introduce-glbSelectedMeetingId
// Purpose: the dashboard's current agenda view for the selected meeting
ClearCollect(
    colCurrentAgendaItems,
    Filter(
        INT003_Agenda_Items_List,
        Meeting_Id.Id = glbSelectedMeetingId
    )
);

// Full agenda items, flattened with agenda* aliases
ClearCollect(
    colMainAgendaItems,
    AddColumns(
        INT003_Agenda_Items_List,
        agendaID,           ID,
        agendaTitle,        Title,
        agendaItem,         Agenda_Item,
        agendaSortOrder,    Sort_Order,
        agendaMeetingId,    Meeting_Id.Id
    )
);

Set(
    varDebugPanelVisible,
    false
);

