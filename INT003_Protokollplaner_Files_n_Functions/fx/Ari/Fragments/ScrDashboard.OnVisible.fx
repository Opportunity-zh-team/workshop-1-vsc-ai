// OnVisible
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
