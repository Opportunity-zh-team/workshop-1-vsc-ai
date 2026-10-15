//OnSelect
/*
    This Script deletes the selected action, removing it from SharePoint if it was already saved, and syncs the local collections.

    Process details:
    1. If the action has no actionID (not yet saved), removes it from colActualActions (matched by actionSortOrder) and stops
    2. Otherwise removes the item with ID = actionID from INT003_Actions_List
    3. If the Remove fails, shows an error notification and stops, leaving the collections unchanged
    4. Otherwise removes the action from both collections (matched by actionID):
       - colMainActions
       - colActualActions

    Depending on the data source INT003_Actions_List,
    the collections colMainActions and colActualActions

    @author Jeremy
    @tags #scr-Protocol-gal, #Actions #Action
*/
//=======================================================================================

If(
    IsBlank(ThisItem.actionID),
    RemoveIf(
        colActualActions,
        actionSortOrder = ThisItem.actionSortOrder
    ),
    If(
        IsError(
            Remove(
                INT003_Actions_List,
                {ID: ThisItem.actionID}
            )
        ),
        Notify(
            "Aktion konnte nicht gelöscht werden",
            NotificationType.Error
        ),
        RemoveIf(
            colMainActions,
            actionID = ThisItem.actionID
        );
        RemoveIf(
            colActualActions,
            actionID = ThisItem.actionID
        )
    )
)