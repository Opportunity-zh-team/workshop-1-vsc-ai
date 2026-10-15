// OnSelect
Refresh(INT003_Concurrency_States_List);
ClearCollect(ColMain_ConcurrencyStates, INT003_Concurrency_States_List);
Set(SCS, Patch(SCS, { editPermissionUserEmail: EditPermissionUserEmail(SCS.meetingId, SCS.protocolId)}));
Switch(
    true,
    IsBlank(SCS.editPermissionUserEmail) || SCS.editPermissionUserEmail = "",
    Set(SCS, Patch(SCS, { 
        targetStatusName: "edit-permission-requested",
        targetUserEmail: glbUserEmail
    }));
    Set(glbStartCheckEditPermission, true);
    Select(BtnPatchUserStatus_1),
    SCS.editPermissionUserEmail = glbUserEmail,
    Set(SCS, Patch(SCS, { isEditable: true })),
    SCS.editPermissionUserEmail <> glbUserEmail,
    Set(SCS, Patch(SCS, { isEditable: false }))
);
Set(glbStartCheckUserIdle, true);
Set(SCS, Patch(SCS, { 
    traceMessage: 
        ScreenStatusMessage(
            "#concurrency-control-register-edit-permission-request: ", 
            If(
                SCS.isEditable, 
                "edit permission GRANTED", 
                "edit permission NOT GRANTED"
            )
        ) 
}));
