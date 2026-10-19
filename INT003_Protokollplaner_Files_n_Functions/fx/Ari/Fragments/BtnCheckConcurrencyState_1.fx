// OnSelect
// Re-evaluates the current user's edit permission for the meeting/protocol in SCS.
// It refreshes the SharePoint concurrency list and its local cache, then asks
// EditPermissionUserEmail() for the current permission owner.
//
// Decision:
// - No owner: mark an edit-permission request for this user, start the request
//   timer, and invoke BtnPatchUserStatus_1 to persist the request.
// - Current user owns permission: set SCS.isEditable to true.
// - Another user owns permission: set SCS.isEditable to false.
//
// In every case, the idle-check timer is started and SCS.traceMessage is updated
// with a diagnostic message. This formula registers a request when no owner is
// found; it does not itself grant permission.
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
