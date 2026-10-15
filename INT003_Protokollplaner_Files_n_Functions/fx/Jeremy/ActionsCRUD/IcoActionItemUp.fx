// Correction Upload
/*
    This Script swaps the Sort_Order of the selected action with its upper neighbor, 
    updating the local collections immediately and SharePoint in one batched call.

    1. Find the neighbor (next lower actionSortOrder) in colActualActions
    2. Swap actionSortOrder in colMainActions and colActualActions (UI updates instantly)
    3. Patch both items to INT003_Actions_List in a single call
    4. On error, revert the collections and notify the user

    Depending on colActualActions, colMainActions, INT003_Actions_List

    @author Jeremy
    @tags #scr-Protocol-gal
*/
With(
    {
        neighbor: First(
            Sort(
                Filter(
                    colActualActions,
                    actionSortOrder < ThisItem.actionSortOrder
                ),
                actionSortOrder,
                SortOrder.Descending
            )
        )
    },
    With(
        {
            neighborID: Value(neighbor.actionID),
            neighborOrder: neighbor.actionSortOrder,
            currentID: Value(ThisItem.actionID),
            currentOrder: ThisItem.actionSortOrder
        },
        If(
            !IsBlank(currentID) && !IsBlank(neighborID),
            // 1. Local update first: gallery reflects the swap immediately
            UpdateIf(
                colMainActions,
                actionID = neighborID || actionID = currentID,
                {actionSortOrder: If(actionID = currentID, neighborOrder, currentOrder)}
            );
            UpdateIf(
                colActualActions,
                actionID = neighborID || actionID = currentID,
                {actionSortOrder: If(actionID = currentID, neighborOrder, currentOrder)}
            );
            // 2. One batched call to SharePoint
            Patch(
                INT003_Actions_List,
                Table(
                    {ID: neighborID, Sort_Order: currentOrder},
                    {ID: currentID, Sort_Order: neighborOrder}
                )
            );
            // 3. Revert local state if SharePoint rejected the change
            If(
                !IsEmpty(Errors(INT003_Actions_List)),
                UpdateIf(
                    colMainActions,
                    actionID = neighborID || actionID = currentID,
                    {actionSortOrder: If(actionID = currentID, currentOrder, neighborOrder)}
                );
                UpdateIf(
                    colActualActions,
                    actionID = neighborID || actionID = currentID,
                    {actionSortOrder: If(actionID = currentID, currentOrder, neighborOrder)}
                );
                Notify(
                    "Reordering failed: " & First(Errors(INT003_Actions_List)).Message,
                    NotificationType.Error
                )
            )
        )
    )
)

/*
MENTAL MODEL of the process UP (swap with upper neighbor):
tap up on C (order 3)
   ↓
find nearest saved row above → B (order 2)
   ↓
grab both IDs and both orders
   ↓
swap the two order values locally (B↔C)  → gallery re-sorts, feels instant
   ↓
swap the two order values in SharePoint (batch patch)
   ↓
if error → swap back locally AND in SharePoint, notify  DisplayMode of the button is disabled if the action is the first in the list (no upper neighbor)

// -------

Mental model of the process DOWN (swap with lower neighbor):
tap down on B (order 2)
   ↓
find nearest saved row below → C (order 3)
   ↓
grab both IDs and both orders
   ↓
swap the two order values locally (B↔C)  → gallery re-sorts, feels instant
   ↓
swap the two order values in SharePoint (batch patch)
   ↓
if error → swap back locally AND in SharePoint, notify

// -------

One-Line-Essence: Swap the Sort_Order of the selected action with its nearest neighbor (up or down) in both local collections and SharePoint, with instant UI feedback and error handling.

pick neighbor (above for ↑, below for ↓)
   ↓
swap orders locally  → instant visual
   ↓
swap orders in SharePoint
   ↓
on error → undo both, notify
*/