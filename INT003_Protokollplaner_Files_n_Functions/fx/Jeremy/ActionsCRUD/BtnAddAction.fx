/*
    This Script adds a new, empty action row to the colActualActions collection of the selected protocol.

    Process details:
    1. Looks up the selected protocol in colMainProtocols once (locProtocol)
    2. If the protocol is not found, shows an error and stops
    3. Checks colActualActions for an action with a blank actionItem (after Trim)
    4. If one exists, shows a warning and stops, so only one empty action can be open at a time
    5. Otherwise adds a new row to colActualActions:
       - actionProtocolId is set from glbSelectedProtocolId
       - actionSortOrder is the current maximum + 1 (starts at 1 for an empty collection)
       - actionProtocolText and actionMeetingTopic are copied from locProtocol
       - ID, Done date and the SharePoint metadata fields (created, modified, author, editor) stay blank until the action is saved to SharePoint

    Depending on the global variable glbSelectedProtocolId,
    the collections colActualActions and colMainProtocols

    @author Jeremy
    @tags #scr-Protocol-gal, #Actions
*/
//=============================================================================================
With(
    {
        locProtocol: LookUp(
            colMainProtocols,
            protocolID = glbSelectedProtocolId
        )
    },
    If(
        IsBlank(locProtocol),
        Notify(
            "Das gewählte Protokoll konnte nicht gefunden werden. Bitte wähle es erneut an.",
            NotificationType.Error
        ),
        !IsEmpty(
            Filter(
                colActualActions,
                IsBlank(Trim(actionItem))
            )
        ),
        Notify(
            "Bitte zuerst Aktion ausfüllen.",
            NotificationType.Warning
        ),
        Collect(
            colActualActions,
            {
                actionID: Blank(),
                actionProtocolId: glbSelectedProtocolId,
                actionProtocolTitle: Text(
                    glbSelectedProtocolId,
                    "0"
                ),
                actionItem: "",
                actionSortOrder: Coalesce(
                    Max(
                        colActualActions,
                        actionSortOrder
                    ),
                    0
                ) + 1,
                actionDoneDate: Blank(),
                actionCreated: Blank(),
                actionModified: Blank(),
                actionAuthor: Blank(),
                actionEditor: Blank(),
                actionProtocolText: locProtocol.protocolText,
                actionMeetingTopic: locProtocol.protocolMeetingTopic,
                Checked: false
            }
        )
    )
);