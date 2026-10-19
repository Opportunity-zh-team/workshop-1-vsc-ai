// Items
// The gallery displays the actions already loaded for the selected protocol.
colCurrentActions

// LblOverviewTab.Text
// Creates a compact preview of the selected protocol's text for the overview tab.
// Rich text is converted to plain text, line breaks are flattened, and whitespace
// is trimmed. If the result exceeds 60 characters, it is cut at the last space
// within the first 60 characters (or exactly at 60 if there is no space) and
// suffixed with " ...". The global ID check is for non-blank, not a positive ID.
With(
    {
        txt: Trim(
            Substitute(
                Substitute(
                    PlainText(GalProtocols.Selected.protocolText),
                    Char(13),
                    " "
                ),
                Char(10),
                " "
            )
        ),
        maxCharLength: 60
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
            !IsBlank(glbSelectedProtocolId) &&
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
