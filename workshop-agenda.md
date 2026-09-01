# KI-gestützte Entwicklung von Power Fx Skripten in Visual Studio Code

Workshop für Power Apps Entwickler

## Begrüssung und Einleitung

Guten Tag, es freut mich ...

  1. Einführung in AI-Möglichkeiten in VSC
  2. Formulierung von Kommentaren
  3. Live: Implementieren - Diskutieren - Testen
  4. Skript-Dokumentation
  5. Fragen und Feedback

## Ziele

- Die Teilnehmer werden über die technischen Möglichkeiten informiert.
- Die Teilnehmer arbeiten praktisch und lernen an Beispielen.
- Alle Teilnehmer können einen Kommentar und einen Prompt für AI optimal vorbereiten.
- Alle Teilnehmer implementieren - diskutieren mit AI - testen - verbessern.

## Voraussetzungen prüfen

## Visual Studio Code (VSC) und AI-Möglichkeiten

- [Agents Tutorial](https://www.google.com/url?sa=i&source=web&rct=j&url=CAESXAHrOzAVPoUJuibY89Q3Hp3u46jfLVSwdIHFjxlOe3De4ADDAGAQYrDwvOFdZ45s_HVB4OKg3PWi-0L4kYxeeh50AIMJXUR68of19mG0OCx0nm9r7sVAUE06FEyH&uoh=2&ved=2ahUKEwjDkpeOv8CWAxW6hf0HHcKCMG4Qy_kOegoIAggACAAIDRAF&opi=89978449&cd&psig=AOvVaw0NT_EG0adXWReNXwMtsGBw&ust=1787909247937000)

## VSC und AI-Möglichkeiten beim Bearbeiten von .fx Dateien

### AI Code Completion

Tab | Aktuellen AI-Vorschlag akzeptieren
Esc | Aktuellen AI-Vorschlag ablehnen
Alt + ] | Nächsten Vorschlag zeigen (zyklisch) ?
Alt + [ | Vorangehenden Vorschlag zeigen (zyklisch) ?

### [Copilot Completions in VSC](https://learn.microsoft.com/en-us/visualstudio/ide/visual-studio-github-copilot-extension?view=visualstudio)

## Wie formuliert man Kommentare und Prompts für AI?

- Mentale Vorbereitung: Notizen, Sketch inkl. erste Korrekturen
- Grosse Fragen in kleine Teilprobleme zerlegen
- fx Kommentar-Template (comment-template.txt)
- Prompt-Template (prompt-template.txt)

## Wie präzisiert man Kommentare für AI?

- Screens, Tabellen, Variablen, Collections, Controls benennen, in Relationen setzen
- Schemas der verwendeten Tabellen vorgeben
- Objekt-Events benennen

## Power Apps Einschränkungen

- Neuen Chat mit Einschränkungen vorbereiten
- Fehlerbehandlung mit SharePoint-Requests deklarieren

## Implementieren - Diskutieren - Testen

1. Testvorbereitung: Temporäre Button und Label(s) anlegen, notwendige Daten bereitstellen
2. Präzisen Prompt vorbereiten und an AI schicken
3. Antwort von AI kritisch lesen
4. Rückfragen, Korrekturen an AI schicken
5. Skriptvorschläge von AI in Control(s) übernehmen
6. Syntax- und Referenz-Fehler beheben
7. Schlüsselwerte in Label(s) anzeigen lassen (mit lokalen Variablen!)
8. Testen und Schlüsselwerte prüfen
9. Korrigierte Skript-Teile in der App in .fx zurückkopieren
10. Bei Problemen, notwendigen Anpassungen: Wieder bei Schritt 2 anfangen!

## AI Halluzinationen

- Variablen erfinden
- Controls erfinden
- Collections erfinden
- Verwenden von Funktionen, die es nicht gibt
- Dataverse wird angenommen, obschon SharePoint verwendet wird
- Spalten werden angenommen, die es nicht gibt

## Zusammenfassungen hinzufügen (lassen)

- Voraussetzungen
- Tabellen
- Variables
- Collections
- Functions
- Screens
- Technical Documentation
- Release Notes

## Power Apps FX-Skripte dokumentieren

- Alle Skript-Köpfe: Doku-Template verwenden (inkl. @author)
- App.OnStart: globale Variablen, Collections
- App.Formulas: Funktionen und ihre Argumente (function-documentation-template.txt)
- Screen.OnVisible: lokale Variablen

## Fragen

- Fragen (pro Teilnehmer schriftlich in Chat)
- Feedback zum Workshop (pro Teilnehmer schriftlich in Chat)
- WS KI-gestützte Entwicklung.docx an Teilnehmer verteilen (Chat)

## Appendix: Material, Voraussetzungen

- Laptop für jeden Teilnehmer
- Visual Studio Code installiert
- Copilot Agent aktiviert, eingerichtet (mit Github Copilot, Link ...)
- https://github.com/Opportunity-zh-team/workshop-1-vsc-ai (Credentials in Bitwarden)
- DEV SharePoint Site mit fertig aufgesetzten Listen
- DEV SharePoint Site mit Beispieldaten in allen Listen
- Power App Solution 'INT003_Protokollplaner_V1' (Env-Vars für Tabellen sind definiert)
- Entwickler kennen die [Naming Conventions](https://office-apps.atlassian.net/wiki/spaces/OZHC/pages/45580290/Naming+Conventions)
- WS KI-gestützte Entwicklung.docx
