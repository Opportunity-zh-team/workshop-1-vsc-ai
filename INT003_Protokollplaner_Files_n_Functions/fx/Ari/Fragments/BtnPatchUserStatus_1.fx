// OnSelect
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
