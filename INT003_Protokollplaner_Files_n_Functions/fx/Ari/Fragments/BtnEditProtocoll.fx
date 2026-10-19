// OnSelect
// Opens ScrProtocol for the protocol selected in GalProtocols. A blank
// glbSelectedProtocolId produces a warning and stops navigation. Otherwise, the
// selected gallery row supplies both the parent meeting ID and protocol ID before
// the screen transition. This guard checks Blank() only; it does not reject the
// numeric sentinel -1.
If(
    IsBlank(glbSelectedProtocolId),
    Notify("Bitte ein Thema oder Protokoll auswählen.", NotificationType.Warning),
    Set(glbSelectedMeetingId, GalProtocols.Selected.protocolMeetingId);
    Set(glbSelectedProtocolId, GalProtocols.Selected.protocolID);
    Navigate(ScrProtocol, ScreenTransition.Fade)
)
