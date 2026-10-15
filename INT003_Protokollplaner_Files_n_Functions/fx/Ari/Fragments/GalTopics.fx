// Items
Sort(
    AddColumns(
        GroupBy(
            Filter(
                colMainMeetings,
                glbStartCheckEditPermission
                ||
                !IsBlank(
                    LookUp(
                        colMainParticipants,
                        participantMeetingId = meetID &&
                        Lower(participantEmail) = Lower(glbUserEmail)
                    )
                )
            ),
            meetTopic,
            Rows
        ),
        meetID,
        First(Rows).meetID
    ),
    meetID,
    SortOrder.Ascending
)

// OnSelect
Set(glbSelectedMeetingId, ThisItem.meetID);
Set(glbSelectedProtocolId, Blank());
ClearCollect(
    colCurrentAgendaItems,
    Filter(colMainAgendaItems, agendaMeetingId = glbSelectedMeetingId)
);
ClearCollect(colCurrentActions, []);
Set(glbShowEmptyOverview, true);

// LblTabsTopics.Text
"Sitzungsthemen"
