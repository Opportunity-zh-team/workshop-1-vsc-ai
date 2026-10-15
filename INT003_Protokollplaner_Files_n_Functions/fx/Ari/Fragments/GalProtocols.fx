// Items
SortByColumns(
    Filter(
        colMainProtocols,
        !IsBlank(glbSelectedMeetingId) && protocolMeetingId = glbSelectedMeetingId
    ),
    "protocolStartedAt",
    SortOrder.Ascending
)

// OnSelect
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
