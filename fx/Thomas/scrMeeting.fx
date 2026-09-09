/* If I select a topic in the dropdown DrpTopicSelection, the matching entries based on the table
    INT003_Meetings_List should be loaded into local variables. The Dropdown shows columns
    .Topic. The following columns should be loaded into local variables:
    .ID, .Topic, .Description, .Starts, .Ends, .Location.
    The variable names should be: locID, locTopic, locDescription, locStarts, locEnds, locLocation. */

// Code for onChange event of DrpTopicSelection
UpdateContext({locID: Blank(), locTopic: Blank(), locDescription: Blank(), locStarts: Blank(), locEnds: Blank(), locLocation: Blank()}); // Clear previous values
If( !IsBlank(DrpTopicSelection.Selected), 
    With(
        {selectedTopic: DrpTopicSelection.Selected.Topic},
        ClearCollect(
            colSelectedMeeting,
            Filter(INT003_Meetings_List, Topic = selectedTopic)
        );
        If(CountRows(colSelectedMeeting) > 0,
            UpdateContext({
                locID: First(colSelectedMeeting).ID,
                locTopic: First(colSelectedMeeting).Topic,
                locDescription: First(colSelectedMeeting).Description,
                locStarts: First(colSelectedMeeting).Starts,
                locEnds: First(colSelectedMeeting).Ends,
                locLocation: First(colSelectedMeeting).Location
            })
        )
    )
)

