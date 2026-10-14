/*  
    DEV-NOTES:
    Manual orphan cleanup trigger. Deletes draft meetings that were abandoned
    when a user closed the app or refreshed the browser while a new-topic
    draft was still open.

    A draft is orphaned if:
      - Title starts with "TMP-" (marker from BtnNewThemesFooter), AND
      - Topic is Blank (user never typed/saved a topic)

    Children (agenda items, participants) are removed BEFORE the meeting row.
    Collections are rebuilt from SharePoint only if orphans were found.

    Reads:  colMainMeetings, colMainAgendaItems, colMainParticipants
    Writes: INT003_Meetings_List (Remove)
            INT003_Agenda_Items_List (Remove children)
            INT003_Participants_List (Remove children)
            colOrphanDrafts, colOrphanAgendaIDs,
            colOrphanParticipantIDs, colOrphanMeetingIDs (temp working collections)
            colMainMeetings, colMainAgendaItems, colMainParticipants (rebuilt)

    Process:
    1. Find orphans in colMainMeetings (in-memory — avoids delegation)
    2. If any found:
       Phase 1 — gather child IDs into flat in-memory collections
       Phase 2 — Remove() from SharePoint, one level deep per collection
       Phase 3 — Rebuild the three main collections from clean SharePoint
    3. Notify with counts (diagnostic — remove after verification)

    Why the three-phase structure:
    - Nested ForAll over a SharePoint datasource fails silently in Power Apps.
      A ForAll over colOrphanDrafts containing a nested Filter(SharePointList)
      does not iterate reliably — the inner Remove() may never fire.
    - The fix is to flatten first: build plain in-memory collections of IDs,
      then iterate each with a single-level ForAll + Remove().

    Why this button exists (and not App.OnStart / ScrDashboard.OnVisible):
    - App.OnStart does not run when the app closes (no close event exists).
    - ScrDashboard.OnVisible runs before App.OnStart finishes populating
      collections on first launch → filter returns 0 rows → cleanup silently
      does nothing.
    - A user-triggered button runs after everything is loaded and SharePoint
      is reachable. Reliable by construction.

    When to press:
    - After the app has been left open with a draft and then closed abruptly.
    - Any time the topic list shows suspicious blank entries.
    - Can be wired to a low-frequency gesture (double-tap on logo, hidden
      long-press) if automatic invocation is desired.

    Gotchas:
    - The diagnostic Notify blocks should be removed before production, or
      gated behind a debug flag (varDebugPanelVisible).
    - Filter uses StartsWith(meetTitle, "TMP-") — delegation is safe here
      because colMainMeetings is an in-memory collection, not a SharePoint list.
    - "TMP-" is a contract with BtnNewThemesFooter.OnSelect. If that marker
      ever changes, this filter must change too.
    - The cleanup runs synchronously. With many orphans it will block the UI
      for a few seconds. Acceptable for a manual maintenance action.
    - temp collections (colOrphanDrafts, colOrphan*IDs) remain in memory after
      the run. Harmless, but consider Clear()-ing them at the end if memory is
      a concern.

    @gaudenz

    Tags:
    #orphan-cleanup
    #cleanup-orphan-drafts
    #introduce-fix-meetingID-oncreate
    #three-phase-remove-workaround
    #manual-maintenance-action
    #delegation-safe-in-memory-filter
*/

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