// Clear existing collections to avoid duplicates
ClearCollect(MeetingCollection, INT003_DEV_Meetings);
ClearCollect(AgendaItemCollection, INT003_DEV_Agenda_Items);
ClearCollect(ProtocolCollection, INT003_DEV_Protocols);
ClearCollect(ActionCollection, INT003_DEV_Actions);
ClearCollect(ParticipantCollection, INT003_DEV_Participants);

// Optional: Set global variables for default selections
Set(varSelectedMeeting, Default(INT003_DEV_Meetings));
Set(varSelectedAgendaItem, Default(INT003_DEV_Agenda_Items));
Set(varSelectedProtocol, Default(INT003_DEV_Protocols));
Set(varSelectedAction, Default(INT003_DEV_Actions));
Set(varSelectedParticipant, Default(INT003_DEV_Participants));

// For tracking new records (optional)
Set(varIsNewRecord, false);