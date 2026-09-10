# INT003_Protokollplaner_Main
Int003_Protocollplanning_Files using Github Copilot for PowerApps App
---
## Test 1st Commit stage and push!

## Check YAML naming

Run the naming validator against the dashboard YAML file from the project folder:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\check-naming.ps1 -Path .\ScrDashboard.yaml
```

This checks the control and screen names in the YAML file and prints any naming violations. If no issues are found, it reports that the naming check passed.