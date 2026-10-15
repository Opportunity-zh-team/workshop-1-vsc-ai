// OnSelect
If(
    IsBlank(glbSelectedProtocolId),
    Notify("Bitte ein Thema oder Protokoll auswählen.", NotificationType.Warning),
    Set(glbSelectedMeetingId, GalProtocols.Selected.protocolMeetingId);
    Set(glbSelectedProtocolId, GalProtocols.Selected.protocolID);
    Navigate(ScrProtocol, ScreenTransition.Fade)
)
