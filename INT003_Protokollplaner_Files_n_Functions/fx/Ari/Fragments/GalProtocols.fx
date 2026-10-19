// Items
// Shows only protocols linked to the selected meeting. A blank meeting selection
// produces no rows; matching protocols are ordered by their start timestamp.
SortByColumns(
    Filter(
        colMainProtocols,
        !IsBlank(glbSelectedMeetingId) && protocolMeetingId = glbSelectedMeetingId
    ),
    "protocolStartedAt",
    SortOrder.Ascending
)

// OnSelect
// Selects this protocol and its parent meeting, clears any agenda-item selection,
// and displays the protocol overview. It refreshes agenda items and protocol actions
// from the in-memory collections, then copies the selected protocol's topic,
// description, and formatted text into the dashboard's overview context.
Set(glbSelectedProtocolId, ThisItem.protocolID);
Set(glbSelectedMeetingId, ThisItem.protocolMeetingId);
Set(glbSelectedAgendaId, Blank());
Set(glbShowEmptyOverview, false);
ClearCollect(
    colCurrentAgendaItems,
    Filter(colMainAgendaItems, agendaMeetingId = glbSelectedMeetingId)
);
ClearCollect(
    colCurrentActions,
    Filter(colMainActions, actionProtocolId = glbSelectedProtocolId)
);
With(
    {
        p: LookUp(colMainProtocols, protocolID = ThisItem.protocolID)
    },
    UpdateContext({
        locOverviewTitle:       p.protocolMeetingTopic,
        locOverviewDescription: p.protocolMeetingDescription,
        locOverviewHtml:        p.protocolText
    })
)

// LblProtocolsTab.Text
// Builds the tab caption from the selected meeting topic. Rich text is reduced to
// plain text, line breaks become spaces, and surrounding whitespace is trimmed.
// Captions longer than 27 characters are cut at the last available word boundary
// within that limit (or at character 27 when there is no space), then suffixed
// with " ...". Shorter captions are shown in full.
With(
    {
        txt: Trim(
            Substitute(
                Substitute(
                    PlainText(GalTopics.Selected.meetTopic),
                    Char(13),
                    " "
                ),
                Char(10),
                " "
            )
        ),
        maxCharLength: 27
    },
    With(
        {
            cutText: Left(txt, maxCharLength),
            spaceCount:
                Len(Left(txt, maxCharLength))
                - Len(
                    Substitute(
                        Left(txt, maxCharLength),
                        " ",
                        ""
                    )
                )
        },
        If(
            !IsBlank(glbSelectedMeetingId) &&
            Len(txt) > maxCharLength,
            If(
                spaceCount > 0,
                Left(
                    cutText,
                    Find(
                        "♦",
                        Substitute(
                            cutText,
                            " ",
                            "♦",
                            spaceCount
                        )
                    ) - 1
                ),
                cutText
            ) & " ...",
            txt
        )
    )
)
