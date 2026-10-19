// OnSelect
// Opens ScrMeeting for the currently selected dashboard meeting. If no meeting is
// selected, it shows a warning and does not navigate. Otherwise it passes the
// meeting ID through glbLoadMeetingId, clears the add-agenda/add-participant mode
// flags so the form opens in its normal editing mode, and navigates with a fade.
If(
    IsBlank(glbSelectedMeetingId),
    Notify("Bitte zuerst ein Thema auswählen.", NotificationType.Warning),
    Set(glbLoadMeetingId, glbSelectedMeetingId);
    Set(glbAddAgendaItem,  false);
    Set(glbAddParticipant, false);
    Navigate(ScrMeeting, ScreenTransition.Fade)
)
