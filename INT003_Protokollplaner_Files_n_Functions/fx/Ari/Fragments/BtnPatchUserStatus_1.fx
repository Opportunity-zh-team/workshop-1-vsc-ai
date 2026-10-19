// OnSelect
// Persists the current user's requested concurrency status to
// INT003_Concurrency_States_List. The guarded block runs only when a target status
// and the current user's email are present. It looks up the current user's row,
// normalizes non-positive meeting/protocol IDs to -1, and patches only when the
// row is absent or one of the compared status/ID fields differs; Heartbeat is then
// set to Now(). A failed Patch displays an error notification.
//
// After the guarded block, regardless of whether it ran or the Patch succeeded,
// targetStatusName and targetUserEmail are cleared and the user-permission timer
// is started. targetUserEmail is not used to select the row; glbUserEmail is.
If(
    SCS.targetStatusName <> "" && glbUserEmail <> "" && !IsBlank(glbUserEmail),
    With(
        {
            mId: SCS.meetingId,
            pId: SCS.protocolId,
            tsn: If(
                SCS.meetingId > 0 || SCS.protocolId > 0, 
                SCS.targetStatusName, 
                "edit-permission-ignored"
            ),
            rec: LookUp(
                INT003_Concurrency_States_List,
                User_Email = glbUserEmail
            )
        },
        If( 
            IsBlank(rec) ||
            rec.State_Name <> tsn ||
            rec.Meeting_Id <> If(mId > 0, mId, -1) ||
            rec.Protocol_Id <> If(pId > 0, pId, -1),
            IfError(
                Patch(
                    INT003_Concurrency_States_List, 
                    Coalesce(
                        rec,
                        Defaults(INT003_Concurrency_States_List)
                    ),
                    {
                        State_Name: tsn,
                        User_Email: glbUserEmail,
                        Meeting_Id: If(mId > 0, mId, -1),
                        Protocol_Id: If(pId > 0, pId, -1),
                        Heartbeat: Now()
                    }
                ),
                Notify(
                    "Error while patching user status: " & FirstError.Message,
                    NotificationType.Error
                );
                Blank()
            ); 
        )
    )
);
Set(SCS, Patch(SCS, {
        targetStatusName: "",
        targetUserEmail: ""
}));
Set(glbStartCheckEditPermissionUser, true);
