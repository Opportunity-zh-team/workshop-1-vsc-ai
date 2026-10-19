// OnVisible
// Runs whenever the dashboard becomes active. The order is significant: selected IDs
// are established before the dependent agenda/action collections are rebuilt.
//
// Flow:
// 1. Reset the overview state and clear its screen-local content.
// 2. Restore glbCarryMeetingId when supplied; otherwise select the first meeting
//    by topic. Consume the carried meeting ID after using it.
// 3. If glbCarryProtocolId is supplied, select that protocol, load its overview
//    fields from colMainProtocols, and consume the carried protocol ID.
// 4. Rebuild the selected meeting's agenda collection and the selected protocol's
//    actions collection. With no protocol (sentinel -1), actions are empty.
// 5. Refresh the debug-variable snapshot, initialize concurrency settings and
//    timer flags, mark the user idle, then trigger the concurrency check.
//
// Reads:  glbCarryMeetingId, glbCarryProtocolId, colMainMeetings,
//         colMainProtocols, colMainAgendaItems, colMainActions
// Writes: selected IDs, overview context, current collections, debug snapshot,
//         SCS, concurrency timer flags, glbIsUserIdle
// Notes:  An empty colMainMeetings collection makes the fallback meeting ID Blank.
//         A carried protocol ID is trusted to exist in colMainProtocols.
Set(glbShowEmptyOverview, true);
Set(glbSelectedProtocolId, -1);
Set(glbSelectedAgendaId, 0);
UpdateContext({
    locOverviewTitle:       "",
    locOverviewDescription: "",
    locOverviewHtml:        ""
});
If(
    !IsBlank(glbCarryMeetingId),
    Set(glbSelectedMeetingId, glbCarryMeetingId);
    Set(glbCarryMeetingId, Blank()),
    Set(
        glbSelectedMeetingId,
        First(Sort(colMainMeetings, meetTopic, SortOrder.Ascending)).meetID
    )
);
If(
    !IsBlank(glbCarryProtocolId),
    Set(glbSelectedProtocolId, glbCarryProtocolId);
    Set(glbShowEmptyOverview, false);
    With(
        { p: LookUp(colMainProtocols, protocolID = glbCarryProtocolId) },
        UpdateContext({
            locOverviewTitle:       p.protocolMeetingTopic,
            locOverviewDescription: p.protocolMeetingDescription,
            locOverviewHtml:        p.protocolText
        })
    );
    Set(glbCarryProtocolId, Blank())
);
ClearCollect(
    colCurrentAgendaItems,
    Filter(colMainAgendaItems, agendaMeetingId = glbSelectedMeetingId)
);
If(
    glbSelectedProtocolId <> -1,
    ClearCollect(
        colCurrentActions,
        Filter(colMainActions, actionProtocolId = glbSelectedProtocolId)
    ),
    ClearCollect(colCurrentActions, [])
);
ClearCollect(
    colDebugVars,
    { Name: "glbSelectedProtocolId", Value: Text(glbSelectedProtocolId) },
    { Name: "glbSelectedMeetingId", Value: Text(glbSelectedMeetingId) },
    { Name: "locSelectedTab", Value: Text(locSelectedTab) },
    { Name: "varDebugPanelVisible", Value: Text(varDebugPanelVisible) },
    { Name: "colMainMeetings.Count", Value: Text(CountRows(colMainMeetings)) },
    { Name: "colMainProtocols.Count", Value: Text(CountRows(colMainProtocols)) },
    { Name: "colMainParticipants.Count", Value: Text(CountRows(colMainParticipants)) },
    { Name: "colMainActions.Count", Value: Text(CountRows(colMainActions)) },
    { Name: "colCurrentAgendaItems.Count", Value: Text(CountRows(colCurrentAgendaItems)) }
);
Set(SCS, ConcurrencyControlSettings);
Set(glbStartCheckEditPermission, false);
Set(glbStartCheckEditPermissionUser, false);
Set(glbStartCheckUserIdle, false);
Set(glbIsUserIdle, true);
Select(BtnCheckConcurrencyState_1);
