//SVG image
"data:image/svg+xml; utf-8, " & EncodeUrl($"<svg width='51' height='51' viewBox='0 0 51 51' fill='none' xmlns='http://www.w3.org/2000/svg'><path d='M25.1573 0.786133C11.6942 0.786133 0.786133 11.6942 0.786133 25.1573C0.786133 38.6205 11.6942 49.5285 25.1573 49.5285C38.6205 49.5285 49.5285 38.6205 49.5285 25.1573C49.5285 11.6942 38.6205 0.786133 25.1573 0.786133ZM25.1573 44.8115C14.2984 44.8115 5.50314 36.0163 5.50314 25.1573C5.50314 14.2984 14.2984 5.50314 25.1573 5.50314C36.0163 5.50314 44.8115 14.2984 44.8115 25.1573C44.8115 36.0163 36.0163 44.8115 25.1573 44.8115Z' fill='green'/></svg>")

//OnSelect
/*
    This Script toggles the done state of the selected action by writing or clearing Done_Date in SharePoint and then syncing the local collections.

    Process details:
    1. If the action has no actionID (not yet saved), shows a warning and stops
    2. Sets newDoneDate to Blank() if the action is currently checked, otherwise to Today()
    3. Patches Done_Date of the matching item (ID = actionID) in INT003_Actions_List
    4. If Errors(INT003_Actions_List) is not empty, shows the first error message and stops, leaving the collections unchanged
    5. Otherwise updates both collections with the new date:
       - colMainActions (matched by actionID): actionDoneDate
       - colActualActions (matched by actionSortOrder): actionDoneDate and Checked (toggled)

    Depending on the data source INT003_Actions_List,
    the collections colMainActions and colActualActions

    @author Jeremy
    @tags #scr-Protocol-gal, #Action, #Actions
*/
If(
    IsBlank(ThisItem.actionID),
    Notify(
        "Diese Aktion wurde noch nicht gespeichert und kann daher nicht abgehakt werden.",
        NotificationType.Warning
    ),
    With(
        {newDoneDate: If(ThisItem.Checked, Blank(), Today())},
        Patch(
            INT003_Actions_List,
            LookUp(INT003_Actions_List, ID = ThisItem.actionID),
            {Done_Date: newDoneDate}
        );
        If(
            !IsEmpty(Errors(INT003_Actions_List)),
            Notify(
                "Fehler beim Speichern des Erledigt-Datums: " & First(Errors(INT003_Actions_List)).Message,
                NotificationType.Error
            ),
            UpdateIf(
                colMainActions,
                actionID = ThisItem.actionID,
                {actionDoneDate: newDoneDate}
            );
            UpdateIf(
                colActualActions,
                actionSortOrder = ThisItem.actionSortOrder,
                {actionDoneDate: newDoneDate, Checked: !ThisItem.Checked}
            )
        )
    )
);

//DisplayMode
If(
    IsBlank(TxtActionItem.Text),
    DisplayMode.Disabled,
    DisplayMode.Edit
)
