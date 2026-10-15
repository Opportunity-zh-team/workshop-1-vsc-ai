// OnSelect
If(
    IsBlank(glbSelectedMeetingId),
    Notify("Bitte zuerst ein Thema auswählen.", NotificationType.Warning),
    Set(glbLoadMeetingId, glbSelectedMeetingId);
    Set(glbAddAgendaItem,  false);
    Set(glbAddParticipant, false);
    Navigate(ScrMeeting, ScreenTransition.Fade)
)
