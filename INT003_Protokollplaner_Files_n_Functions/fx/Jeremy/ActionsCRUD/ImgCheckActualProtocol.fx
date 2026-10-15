
//SVG image
"data:image/svg+xml; utf-8, " & EncodeUrl($"<svg width='51' height='51' viewBox='0 0 51 51' fill='none' xmlns='http://www.w3.org/2000/svg'><path d='M42.8312 8.19913L16.9816 34.0487L7.48354 24.5506C7.02305 24.0901 6.27638 24.0901 5.81579 24.5506L3.03629 27.3301C2.57579 27.7906 2.57579 28.5373 3.03629 28.9979L16.1477 42.1093C16.6082 42.5698 17.3549 42.5698 17.8155 42.1093L47.2784 12.6464C47.7389 12.1859 47.7389 11.4392 47.2784 10.9786L44.4989 8.19913C44.0384 7.73864 43.2917 7.73864 42.8312 8.19913Z' fill='green'/></svg>")


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
    @tags #scr-Protocol-gal
*/
//===============================================================================================

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
                "Fehler beim Speichern des Datums: " & First(Errors(INT003_Actions_List)).Message,
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
)

//DisplayMode
If(
    IsBlank(TxtActionItem.Text),
    DisplayMode.Disabled,
    DisplayMode.Edit
)