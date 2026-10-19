// Items
// Returns one row per distinct meeting topic. The list includes every meeting
// while the edit-permission check is running; otherwise it includes only meetings
// where the current user's email matches a participant email (case-insensitively).
// Each group is represented by the first row's meetID and the resulting topics are
// sorted by that ID, not alphabetically by topic.
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
// Selects the meeting represented by this topic. The previous protocol selection
// is cleared, agenda items are reloaded for the chosen meeting, actions are emptied
// because they belong to a protocol, and the dashboard switches to its empty
// overview state. The overview context fields themselves are not cleared here.
Set(glbSelectedMeetingId, ThisItem.meetID);
Set(glbSelectedProtocolId, Blank());
ClearCollect(
    colCurrentAgendaItems,
    Filter(colMainAgendaItems, agendaMeetingId = glbSelectedMeetingId)
);
ClearCollect(colCurrentActions, []);
Set(glbShowEmptyOverview, true);

// LblTabsTopics.Text
// Static German title for the gallery of meeting topics.
"Sitzungsthemen"
