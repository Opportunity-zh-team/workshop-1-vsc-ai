ClearCollect(
    colOrphanDrafts,
    Filter(
        colMainMeetings,
        StartsWith(meetTitle, "TMP-") && IsBlank(meetTopic)
    )
);

If(
    CountRows(colOrphanDrafts) > 0,
    // Phase 1 — flat ID lists
    ClearCollect(colOrphanAgendaIDs, []);
    ClearCollect(colOrphanParticipantIDs, []);
    ClearCollect(colOrphanMeetingIDs, []);

    ForAll(
        colOrphanDrafts As d,
        Collect(
            colOrphanAgendaIDs,
            ForAll(
                Filter(colMainAgendaItems, agendaMeetingId = d.meetID),
                { ID: agendaID }
            )
        )
    );

    ForAll(
        colOrphanDrafts As d,
        Collect(
            colOrphanParticipantIDs,
            ForAll(
                Filter(colMainParticipants, participantMeetingId = d.meetID),
                { ID: participantID }
            )
        )
    );

    ForAll(
        colOrphanDrafts As d,
        Collect(colOrphanMeetingIDs, { ID: d.meetID })
    );

    // Diagnostics — remove after verification
    Notify(
        "Orphans=" & CountRows(colOrphanDrafts) &
        " | agendaIDs=" & CountRows(colOrphanAgendaIDs) &
        " | participantIDs=" & CountRows(colOrphanParticipantIDs) &
        " | meetingIDs=" & CountRows(colOrphanMeetingIDs),
        NotificationType.Information
    );

    // Phase 2 — Remove from SharePoint, one level deep
    ForAll(
        colOrphanAgendaIDs As a,
        Remove(
            INT003_Agenda_Items_List,
            LookUp(INT003_Agenda_Items_List, ID = a.ID)
        )
    );

    ForAll(
        colOrphanParticipantIDs As p,
        Remove(
            INT003_Participants_List,
            LookUp(INT003_Participants_List, ID = p.ID)
        )
    );

    ForAll(
        colOrphanMeetingIDs As m,
        Remove(
            INT003_Meetings_List,
            LookUp(INT003_Meetings_List, ID = m.ID)
        )
    );

    // Diagnostics — remove after verification
    Notify(
        "After delete — Meetings=" & CountRows(INT003_Meetings_List) &
        " | Agenda=" & CountRows(INT003_Agenda_Items_List) &
        " | Participants=" & CountRows(INT003_Participants_List),
        NotificationType.Information
    );

    // Phase 3 — Rebuild collections from clean SharePoint
    ClearCollect(
        colMainMeetings,
        AddColumns(
            INT003_Meetings_List,
            meetID, ID, meetTitle, Topic, meetTopic, Topic,
            meetDescription, Description,
            meetStarts,
            IfError(
                DateTimeValue(
                    Text(Starts, "[$-de-DE]dd.mm.yyyy HH:mm"),
                    "de-DE"
                ),
                Blank()
            ),
            meetEnds, Ends, meetLocation, Location, meetState, State
        )
    );

    ClearCollect(
        colMainAgendaItems,
        AddColumns(
            INT003_Agenda_Items_List,
            agendaID, ID, agendaTitle, Title, agendaItem, Agenda_Item,
            agendaSortOrder, Sort_Order, agendaMeetingId, Meeting_Id.Id
        )
    );

    ClearCollect(
        colMainParticipants,
        AddColumns(
            INT003_Participants_List,
            participantID, ID, participantMeetingId, Meeting_Id.Id,
            participantMeetingTitle, Meeting_Id.Value,
            participantEmail, Participant_Email,
            participantIsPresent, Is_Present,
            participantAvatarImage, Avatr_Image,
            participantCreated, Created
        )
    )
);