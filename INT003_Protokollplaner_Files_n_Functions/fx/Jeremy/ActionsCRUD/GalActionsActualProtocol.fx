/*  
    DEV-NOTES:
    Actions gallery for the CURRENT protocol. Shows colActualActions, which is
    built in ScrProtocol.OnVisible with the computed Checked flag.

    Reads:  colActualActions
    Items:  colActualActions

    Gotchas:
    - Reads pre-built collection. Writer is ScrProtocol.OnVisible (only).
      Simpler than colCurrentActions on dashboard (which has three writers).
    - Includes computed Checked column (from colActualActions AddColumns) —
      if the toggle-done feature is ever re-enabled, this is where it acts.

    @gaudenz

    Tags:
    #current-protocol-actions
    #galaction-add-action-scrprotocol, #Actions
    
    NOTES-Jeremy:

    This Script provides the rows of the actions gallery, sorted ascending by actionSortOrder.

    Depending on the collection colActualActions
*/

Sort(colActualActions, actionSortOrder)