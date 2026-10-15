// Items
colCurrentActions

// LblOverviewTab.Text
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
