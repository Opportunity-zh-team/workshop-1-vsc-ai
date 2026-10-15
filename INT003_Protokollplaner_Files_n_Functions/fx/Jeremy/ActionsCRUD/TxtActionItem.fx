//Default
ThisItem.actionItem
//DisplayMode #concurrency-control-display-mode
If(
    SCS.isEditable, 
    DisplayMode.Edit, 
    DisplayMode.Disabled
)

//OnChange
/*
    This Script saves the text of an action to SharePoint (creating a new item or updating the existing one) and syncs the local collections.

    Process details:
    1. Determines isNew (actionID is blank) and cleanText (Trim of TxtActionItem.Text)
    2. If cleanText is empty, shows a warning, resets TxtActionItem and stops
    3. Patches INT003_Actions_List with Protocol_Id, Action_Item and Sort_Order:
       - new action: creates the item via Defaults(INT003_Actions_List)
       - existing action: updates the item matching ID = actionID
    4. If the Patch fails, IfError shows the error message and stops, leaving the collections unchanged
    5. Otherwise syncs the collections with the saved record:
       - colMainActions: new action is added with Collect, existing action gets actionItem updated (matched by actionID)
       - colActualActions: actionID and actionItem are updated (matched by actionSortOrder, as a new row has no actionID yet)

    Depending on the global variable glbSelectedProtocolId,
    the data source INT003_Actions_List,
    the collections colMainActions and colActualActions

    @author Jeremy
    @tags #scr-Protocol-gal
          #Action-ActionItem
*/
//========================================================================================================

With(
    {
        isNew: IsBlank(ThisItem.actionID),
        cleanText: Trim(TxtActionItem.Text)
    },
    If(
        IsBlank(cleanText),
        Notify("Aktion-Text darf nicht leer sein.", NotificationType.Warning);
        Reset(TxtActionItem),
        IfError(
            With(
                {
                    saved: Patch(
                        INT003_Actions_List,
                        If(
                            isNew,
                            Defaults(INT003_Actions_List),
                            LookUp(INT003_Actions_List, ID = ThisItem.actionID)
                        ),
                        {
                            Protocol_Id: {
                                Id: glbSelectedProtocolId,
                                Value: Text(glbSelectedProtocolId, "0")
                            },
                            Action_Item: cleanText,
                            Sort_Order: ThisItem.actionSortOrder
                        }
                    )
                },
                If(
                    isNew,
                    Collect(
                        colMainActions,
                        {
                            actionID: saved.ID,
                            actionProtocolId: saved.Protocol_Id.Id,
                            actionProtocolTitle: saved.Protocol_Id.Value,
                            actionItem: saved.Action_Item,
                            actionSortOrder: saved.Sort_Order
                        }
                    ),
                    UpdateIf(
                        colMainActions,
                        actionID = saved.ID,
                        {actionItem: saved.Action_Item}
                    )
                );
                UpdateIf(
                    colActualActions,
                    actionSortOrder = ThisItem.actionSortOrder,
                    {actionID: saved.ID, actionItem: saved.Action_Item}
                );
                true
            ),
            Notify("Aktion konnte nicht gespeichert werden: " & FirstError.Message, NotificationType.Error)
        )
    )
)
