Screens:
  ScrDashboard:
    Properties:
      Fill: =RGBA(244, 245, 247, 1)
      Height: =App.Height
      OnVisible: |
        =/*  
            DEV-NOTES:
            Resets the right overview panel, resolves which meeting and protocol to
            display (carried in from other screens, or defaults), and rebuilds the
            agenda + actions collections for the current selection.

            Process:
            1. Reset flags/IDs: glbShowEmptyOverview=true, glbSelectedProtocolId=-1, glbSelectedAgendaId=0
            2. Clear overview context: locOverviewTitle / Description / Html = ""
            3. Resolve meeting: glbCarryMeetingId → use it, else first topic alphabetically
            4. Resolve protocol: glbCarryProtocolId → use it + load overview, else leave -1
            5. Rebuild colCurrentAgendaItems filtered by glbSelectedMeetingId
            6. Rebuild colCurrentActions filtered by glbSelectedProtocolId (or empty if -1)

            Globals read:   glbCarryMeetingId, glbCarryProtocolId
            Globals write:  glbSelectedMeetingId, glbSelectedProtocolId, glbSelectedAgendaId, glbShowEmptyOverview
            Collections in: colMainMeetings, colMainProtocols, colMainAgendaItems, colMainActions
            Collections out: colCurrentAgendaItems, colCurrentActions
            Context out:    locOverviewTitle, locOverviewDescription, locOverviewHtml

            Order: reset → meeting → protocol → collections. Don't reorder; filters read the IDs set in steps 3–4.

            Gotchas:
            - glbSelectedProtocolId = -1 is a sentinel (no protocol). Test with "<> -1", not IsBlank.
            - glbCarryProtocolId is consumed after use; glbCarryMeetingId likewise. If not blanked, stale load on next visit.
            - Empty colMainMeetings → First(Sort(...)).meetID = Blank, silently.
            - Stray comment "...ScrDashboardly" in source — remove.

            @gaudenz

            Tags:
            #scrdashboard-onvisible
            #reset-overview-right-panel
            #pass-selected-topic-on-navigate-scrmeeting-to-scrdashboard
            #pass-selected-protocol-on-navigate-scrprotocol-to-scrdashboard
            #introduce-glbSelectedProtocolId
            #consume-glbCarryMeetingId
            #consume-glbCarryProtocolId
            #sentinel-minus-one-no-protocol
            #introduce-glbShowEmptyOverview
        */

        // ============================================================================
        // SCREEN: ScrDashboard.OnVisible
        // ============================================================================

        // Reset right panel
        // #introduce-glbSelectedProtocolId
        // #introduce-glbShowEmptyOverview
        Set(glbShowEmptyOverview, true);
        Set(glbSelectedProtocolId, -1);
        Set(glbSelectedAgendaId, 0);

        // Reset overview vars so the right panel is well-defined
        UpdateContext({
            locOverviewTitle:       "",
            locOverviewDescription: "",
            locOverviewHtml:        ""
        });

        // Prefer a meeting carried over from ScrMeeting; else first topic alphabetically
        // #pass-selected-topic-on-navigate-scrmeeting-to-scrdashboard
        If(
            !IsBlank(glbCarryMeetingId),
            Set(glbSelectedMeetingId, glbCarryMeetingId);
            Set(glbCarryMeetingId, Blank()),
            Set(
                glbSelectedMeetingId,
                First(Sort(colMainMeetings, meetTopic, SortOrder.Ascending)).meetID
            )
        );

        // Prefer a protocol carried over from ScrProtocol to ScrDashboard
        // #pass-selected-protocol-on-navigate-scrprotocol-to-scrdashboard
        If(
            !IsBlank(glbCarryProtocolId),
            Set(glbSelectedProtocolId, glbCarryProtocolId);
            Set(glbShowEmptyOverview, false);
            With(
                { p: LookUp(colMainProtocols, protocolID = glbCarryProtocolId) },
                UpdateContext({
                    locOverviewTitle:       p.protocolMeetingTopic,
                    locOverviewDescription: p.protocolMeetingDescription,
                    locOverviewHtml:        p.protocolText
                })
            );
            Set(glbCarryProtocolId, Blank())
        );

        // Load agenda items for the selected meeting
        ClearCollect(
            colCurrentAgendaItems,
            Filter(colMainAgendaItems, agendaMeetingId = glbSelectedMeetingId)
        );

        // No actions until a protocol is chosen
        If(
            glbSelectedProtocolId <> -1,
            ClearCollect(
                colCurrentActions,
                Filter(colMainActions, actionProtocolId = glbSelectedProtocolId)
            ),
            ClearCollect(colCurrentActions, [])
        );

        // ---------------------------------------------
        // ---------------------------------------------
        // Debug panel ScrDashboard
        // ---------------------------------------------
        // ---------------------------------------------

        // 3) Debug variable viewer (script + collection counts)
        ClearCollect(
            colDebugVars,
            { Name: "glbSelectedProtocolId", Value: Text(glbSelectedProtocolId) },
            { Name: "glbSelectedMeetingId", Value: Text(glbSelectedMeetingId) },
            { Name: "locSelectedTab", Value: Text(locSelectedTab) },
            { Name: "varDebugPanelVisible", Value: Text(varDebugPanelVisible) },

            // Collection counts
            { Name: "colMainMeetings.Count", Value: Text(CountRows(colMainMeetings)) },
            { Name: "colMainProtocols.Count", Value: Text(CountRows(colMainProtocols)) },
            { Name: "colMainParticipants.Count", Value: Text(CountRows(colMainParticipants)) },
            { Name: "colMainActions.Count", Value: Text(CountRows(colMainActions)) },

            // Current Agenda Items count (replaces slow colMainAllItems)
            { Name: "colCurrentAgendaItems.Count", Value: Text(CountRows(colCurrentAgendaItems)) }
        );

        /******************************************************************************************************
            @author: Chris
            @date: 2026-09-23
            @tags: #concurrency-control-scr-onvisible

            Check the concurrency state of the current user and decide if the screen is editable or not.
        */ 

        // Update screen's concurrency settings, especially to set SCS.isEditable = false. 
        Set(SCS, ConcurrencyControlSettings);

        // Update timers' activity
        Set(glbStartCheckEditPermission, false);
        Set(glbStartCheckEditPermissionUser, false);
        Set(glbStartCheckUserIdle, false);

        // Mark user to be idle
        Set(glbIsUserIdle, true);

        // Check Concurrency State
        Select(BtnCheckConcurrencyState_1);
        // ********************************************************************************************************/
      Width: =App.Width
    Children:
      - ConPage:
          Control: GroupContainer@1.5.0
          Variant: AutoLayout
          Properties:
            Fill: =RGBA(244, 245, 247, 1)
            Height: =Parent.Height
            LayoutDirection: =LayoutDirection.Vertical
            Width: =Parent.Width
          Children:
            - ConHeader:
                Control: GroupContainer@1.5.0
                Variant: ManualLayout
                Properties:
                  AlignInContainer: =AlignInContainer.Center
                  BorderColor: =RGBA(0, 0, 0, 0)
                  BorderThickness: =1
                  DropShadow: =DropShadow.None
                  Fill: =RGBA(255, 255, 255, 1)
                  FillPortions: =0
                  Height: =70
                  RadiusBottomLeft: =0
                  RadiusBottomRight: =0
                  RadiusTopLeft: =0
                  RadiusTopRight: =0
                  Width: =Parent.Width
                Children:
                  - ConHeaderMain:
                      Control: GroupContainer@1.5.0
                      Variant: AutoLayout
                      Properties:
                        DropShadow: =DropShadow.None
                        Height: =70
                        LayoutAlignItems: =LayoutAlignItems.Center
                        LayoutDirection: =LayoutDirection.Horizontal
                        LayoutJustifyContent: =LayoutJustifyContent.Center
                        PaddingBottom: =8
                        PaddingLeft: =8
                        PaddingRight: =8
                        PaddingTop: =8
                        RadiusBottomLeft: =0
                        RadiusBottomRight: =0
                        RadiusTopLeft: =0
                        RadiusTopRight: =0
                        Width: =App.Width
                      Children:
                        - ConHeaderLeft:
                            Control: GroupContainer@1.5.0
                            Variant: ManualLayout
                            Properties:
                              AlignInContainer: =AlignInContainer.Center
                              DropShadow: =DropShadow.None
                              Height: =54
                              Visible: =false
                              X: =40
                              Y: =40
                        - ConLogoScrDB:
                            Control: GroupContainer@1.5.0
                            Variant: AutoLayout
                            Properties:
                              DropShadow: =DropShadow.None
                              Height: =54
                              LayoutDirection: =LayoutDirection.Vertical
                              LayoutMaxHeight: =54
                              LayoutMinHeight: =0
                              Width: =450
                            Children:
                              - LblHeaderTitleMainScrDB:
                                  Control: Label@2.5.1
                                  Properties:
                                    Color: =RGBA(32, 32, 32, 1)
                                    Height: =30
                                    Size: =18
                                    Text: ="Protokollplaner "
                                    Width: =400
                                    X: =(Parent.Width / 2) - 200
                              - ConLogoPlusLogofontFontScrDB:
                                  Control: GroupContainer@1.5.0
                                  Variant: AutoLayout
                                  Properties:
                                    AlignInContainer: =AlignInContainer.SetByContainer
                                    DropShadow: =DropShadow.None
                                    LayoutAlignItems: =LayoutAlignItems.Center
                                    LayoutDirection: =LayoutDirection.Horizontal
                                    LayoutMinHeight: =16
                                    LayoutMinWidth: =16
                                    PaddingBottom: =8
                                    PaddingLeft: =8
                                    PaddingRight: =8
                                    PaddingTop: =8
                                  Children:
                                    - ImgLogoOfficeAppsScrDB:
                                        Control: Image@2.2.3
                                        Properties:
                                          AlignInContainer: =AlignInContainer.Center
                                          BorderColor: =RGBA(0, 18, 107, 1)
                                          Height: =20
                                          Image: ="data:image/svg+xml; utf-8, " & EncodeUrl("<svg width='453' height='209' viewBox='0 0 453 209' fill='none' xmlns='http://www.w3.org/2000/svg'><g clip-path='url(#paint0_angular_2019_12_clip_path)' data-figma-skip-parse='true'><g transform='matrix(0 0.1044 -0.10433 0 104.33 104.4)'><foreignObject x='-1009.58' y='-1009.58' width='2019.17' height='2019.17'><div xmlns='http://www.w3.org/1999/xhtml' style='background:conic-gradient(from 90deg,rgba(96, 173, 246, 1) 0deg,rgba(255, 255, 255, 1) 360deg);height:100%;width:100%;opacity:1'></div></foreignObject></g></g><path d='M104.33 208.8C161.95 208.8 208.66 162.058 208.66 104.4C208.66 46.7414 161.95 0 104.33 0C46.7101 0 0 46.7414 0 104.4C0 162.058 46.7101 208.8 104.33 208.8Z' data-figma-gradient-fill='{&#34;type&#34;:&#34;GRADIENT_ANGULAR&#34;,&#34;stops&#34;:[{&#34;color&#34;:{&#34;r&#34;:0.37647059559822083,&#34;g&#34;:0.67843139171600342,&#34;b&#34;:0.96470588445663452,&#34;a&#34;:1.0},&#34;position&#34;:0.0},{&#34;color&#34;:{&#34;r&#34;:1.0,&#34;g&#34;:1.0,&#34;b&#34;:1.0,&#34;a&#34;:1.0},&#34;position&#34;:1.0}],&#34;transform&#34;:{&#34;m00&#34;:1.2776725444513855e-14,&#34;m01&#34;:-208.65977478027344,&#34;m02&#34;:208.65977478027344,&#34;m10&#34;:208.79965209960938,&#34;m11&#34;:1.2785290641676491e-14,&#34;m12&#34;:1.3817201929969116e-21},&#34;opacity&#34;:1.0,&#34;blendMode&#34;:&#34;NORMAL&#34;,&#34;stopsVar&#34;:[{&#34;color&#34;:{&#34;r&#34;:0.37647059559822083,&#34;g&#34;:0.67843139171600342,&#34;b&#34;:0.96470588445663452,&#34;a&#34;:1.0},&#34;position&#34;:0.0},{&#34;color&#34;:{&#34;r&#34;:1.0,&#34;g&#34;:1.0,&#34;b&#34;:1.0,&#34;a&#34;:1.0},&#34;position&#34;:1.0}],&#34;visible&#34;:true}'/><g clip-path='url(#paint1_angular_2019_12_clip_path)' data-figma-skip-parse='true'><g transform='matrix(0 0.1044 -0.122088 0 330.748 104.4)'><foreignObject x='-1009.58' y='-1009.58' width='2019.16' height='2019.16'><div xmlns='http://www.w3.org/1999/xhtml' style='background:conic-gradient(from 90deg,rgba(96, 173, 246, 1) 0deg,rgba(255, 255, 255, 1) 360deg);height:100%;width:100%;opacity:1'></div></foreignObject></g></g><path d='M330.748 0L452.836 208.8H208.66L330.748 0Z' data-figma-gradient-fill='{&#34;type&#34;:&#34;GRADIENT_ANGULAR&#34;,&#34;stops&#34;:[{&#34;color&#34;:{&#34;r&#34;:0.37647059559822083,&#34;g&#34;:0.67843139171600342,&#34;b&#34;:0.96470588445663452,&#34;a&#34;:1.0},&#34;position&#34;:0.0},{&#34;color&#34;:{&#34;r&#34;:1.0,&#34;g&#34;:1.0,&#34;b&#34;:1.0,&#34;a&#34;:1.0},&#34;position&#34;:1.0}],&#34;transform&#34;:{&#34;m00&#34;:1.4951490159885797e-14,&#34;m01&#34;:-244.17634582519531,&#34;m02&#34;:452.83615112304688,&#34;m10&#34;:208.79965209960938,&#34;m11&#34;:1.2785290641676491e-14,&#34;m12&#34;:-4.2721571377988289e-22},&#34;opacity&#34;:1.0,&#34;blendMode&#34;:&#34;NORMAL&#34;,&#34;stopsVar&#34;:[{&#34;color&#34;:{&#34;r&#34;:0.37647059559822083,&#34;g&#34;:0.67843139171600342,&#34;b&#34;:0.96470588445663452,&#34;a&#34;:1.0},&#34;position&#34;:0.0},{&#34;color&#34;:{&#34;r&#34;:1.0,&#34;g&#34;:1.0,&#34;b&#34;:1.0,&#34;a&#34;:1.0},&#34;position&#34;:1.0}],&#34;visible&#34;:true}'/><defs><clipPath id='paint0_angular_2019_12_clip_path'><path d='M104.33 208.8C161.95 208.8 208.66 162.058 208.66 104.4C208.66 46.7414 161.95 0 104.33 0C46.7101 0 0 46.7414 0 104.4C0 162.058 46.7101 208.8 104.33 208.8Z'/></clipPath><clipPath id='paint1_angular_2019_12_clip_path'><path d='M330.748 0L452.836 208.8H208.66L330.748 0Z'/></clipPath></defs></svg>")
                                          LayoutMinHeight: =16
                                          LayoutMinWidth: =16
                                          Width: =40
                                    - LblHeaderTitleMainLogofontScrDB:
                                        Control: Label@2.5.1
                                        Properties:
                                          AlignInContainer: =AlignInContainer.Center
                                          Color: =RGBA(32, 32, 32, 1)
                                          Height: =20
                                          Size: =11
                                          Text: ="Office Apps"
                                          Width: =400
                                          X: =(Parent.Width / 2) - 200
                        - ConHeadeCenter:
                            Control: GroupContainer@1.5.0
                            Variant: ManualLayout
                            Properties:
                              DropShadow: =DropShadow.None
                              LayoutMinHeight: =16
                              LayoutMinWidth: =16
                            Children:
                              - LblHeaderTitleMain:
                                  Control: Label@2.5.1
                                  Properties:
                                    Align: =Align.Center
                                    Color: =RGBA(32, 32, 32, 1)
                                    FontWeight: =FontWeight.Semibold
                                    Height: =39
                                    Size: =18
                                    Text: ="Sitzungsthemen und Protokolle"
                                    Width: =400
                                    X: =(Parent.Width / 2) - 200
                                    Y: =(Parent.Height - Self.Height) / 2
                        - ConHeaderRight:
                            Control: GroupContainer@1.5.0
                            Variant: ManualLayout
                            Properties:
                              AlignInContainer: =AlignInContainer.Center
                              DropShadow: =DropShadow.None
                              Height: =54
                              X: =40
                              Y: =40
                            Children:
                              - IcoToggleDebugPanelIn:
                                  Control: Classic/Icon@2.5.0
                                  Properties:
                                    BorderColor: =RGBA(0, 18, 107, 1)
                                    Color: =RGBA(149, 149, 149, 1)
                                    Height: =30
                                    Icon: =Icon.BackArrow
                                    OnSelect: |
                                      =Set(varDebugPanelVisible, !varDebugPanelVisible)
                                    Width: =30
                                    X: =413
                                    Y: =11
                              - CircleIcoRefresh:
                                  Control: Circle@2.3.0
                                  Properties:
                                    BorderColor: =RGBA(0, 18, 107, 1)
                                    Fill: =RGBA(149, 149, 149, 1)
                                    Height: =52
                                    Visible: =false
                                    Width: =52
                              - IcoRefresh:
                                  Control: Classic/Icon@2.5.0
                                  Properties:
                                    BorderColor: =RGBA(0, 18, 107, 1)
                                    Color: =RGBA(255, 255, 255, 1)
                                    Height: =50
                                    Icon: =Icon.Reload
                                    OnSelect: |-
                                      =/*
                                          DEV-BUTTON ONLY

                                      //  NOTE: a legacy "reload dashboard state" button was removed here 2026-10.
                                      //  It reset overview flags and filled colCurrentAgendaItems with ALL items.
                                      //  See DEV_NOTES / Known Issues.

                                      // 1) Empty overview at start
                                      Set(glbShowEmptyOverview, true);

                                      // 2) No protocol or theme selected yet
                                      // #introduce-glbSelectedProtocolId

                                      Set(glbSelectedProtocolId, Blank());
                                      Set(glbSelectedMeetingId, Blank());
                                      Set(glbSelectedAgendaId, Blank());

                                      // 3) Show ALL agenda items at start
                                      ClearCollect(colCurrentAgendaItems, colMainAgendaItems);

                                      // 4) No actions at start
                                      ClearCollect(colCurrentActions, []);

                                      */
                                    PaddingBottom: =8
                                    PaddingLeft: =8
                                    PaddingRight: =8
                                    PaddingTop: =8
                                    Visible: =false
                                    Width: =50
                                    X: =2
                                    Y: =(Parent.Height - Self.Height) / 2
            - ConTabsMain:
                Control: GroupContainer@1.5.0
                Variant: AutoLayout
                Properties:
                  DropShadow: =DropShadow.None
                  Fill: =RGBA(245, 244, 239, 1)
                  FillPortions: =0
                  Height: =60
                  LayoutAlignItems: =LayoutAlignItems.Center
                  LayoutDirection: =LayoutDirection.Horizontal
                  LayoutMinHeight: =16
                  LayoutMinWidth: =16
                  PaddingBottom: =16
                  PaddingLeft: =16
                  PaddingRight: =16
                  PaddingTop: =16
                  RadiusBottomLeft: =0
                  RadiusBottomRight: =0
                  RadiusTopLeft: =0
                  RadiusTopRight: =0
                Children:
                  - ConTabsThemesAndArchives:
                      Control: GroupContainer@1.5.0
                      Variant: AutoLayout
                      Properties:
                        DropShadow: =DropShadow.None
                        FillPortions: =0.5
                        Height: =48
                        LayoutDirection: =LayoutDirection.Horizontal
                        LayoutMinWidth: =262
                        PaddingBottom: '=0   '
                        Width: =Parent.Width
                      Children:
                        - BtnTabsTopics:
                            Control: Classic/Button@2.2.0
                            Properties:
                              Align: =Align.Left
                              BorderColor: |-
                                =// RGBA(72, 95, 146, 1)
                                varTabBorderColor
                              Color: |-
                                =// RGBA(22, 45, 92, 1)
                                varTabTextColor
                              Fill: =If(locSelectedTab = "Archiv", RGBA(255,255,255,1), RGBA(239,239,239,1))
                              FontWeight: =FontWeight.Normal
                              Height: =45
                              HoverBorderColor: =varTabHoverFill
                              HoverFill: =varTabHoverFill
                              OnSelect: =Set(locSelectedTab, "Archiv")
                              PaddingLeft: =16
                              RadiusBottomLeft: =0
                              RadiusBottomRight: =0
                              RadiusTopLeft: =6
                              RadiusTopRight: =6
                              Size: =varTabFontSize
                              Text: ="Sitzungsthemen"
                              Visible: =false
                              Width: =200
                        - LblTabsTopics:
                            Control: Label@2.5.1
                            Properties:
                              BorderColor: =varTabBorderColor
                              BorderThickness: =2
                              Color: =varTabTextColor
                              Fill: =If(locSelectedTab = "Protokolle", RGBA(255,255,255,1), RGBA(239,239,239,1))
                              Font: =Font.'Open Sans'
                              Height: =45
                              LayoutMinHeight: =16
                              LayoutMinWidth: =16
                              PaddingLeft: =16
                              PressedBorderColor: =App.Theme.Colors.Darker40
                              PressedFill: =App.Theme.Colors.Darker40
                              Size: =16
                              Text: ="Sitzungsthemen"
                              Width: =200
                  - ConTabsProtocolls:
                      Control: GroupContainer@1.5.0
                      Variant: AutoLayout
                      Properties:
                        DropShadow: =DropShadow.None
                        Height: =48
                        LayoutDirection: =LayoutDirection.Horizontal
                        LayoutGap: =10
                        Width: =Parent.Width
                      Children:
                        - BtnProtocollsTab:
                            Control: Classic/Button@2.2.0
                            Properties:
                              Align: =Align.Left
                              BorderColor: |-
                                =// RGBA(72, 95, 146, 1)
                                varTabBorderColor
                              Color: |-
                                =// RGBA(22, 45, 92, 1)
                                varTabTextColor
                              Fill: =If(locSelectedTab = "Protokolle", RGBA(255,255,255,1), RGBA(239,239,239,1))
                              FontWeight: |-
                                =// FontWeight.Semibold
                                varTabFontWeight
                              Height: =45
                              HoverBorderColor: =varTabHoverFill
                              HoverFill: =varTabHoverFill
                              OnSelect: =Set(locSelectedTab, "Protokolle")
                              PaddingLeft: =16
                              RadiusBottomLeft: =0
                              RadiusBottomRight: =0
                              RadiusTopLeft: =6
                              RadiusTopRight: =6
                              Size: =varTabFontSize
                              Text: ="Protokolle"
                              Visible: =false
                              Width: =130
                        - LblTabsProtocols:
                            Control: Label@2.5.1
                            Properties:
                              BorderColor: =varTabBorderColor
                              BorderThickness: =2
                              Color: =varTabTextColor
                              Fill: =If(locSelectedTab = "Protokolle", RGBA(255,255,255,1), RGBA(239,239,239,1))
                              Font: =Font.'Open Sans'
                              Height: =45
                              LayoutMinHeight: =16
                              LayoutMinWidth: =16
                              PaddingLeft: =16
                              PressedBorderColor: =App.Theme.Colors.Darker40
                              PressedFill: =App.Theme.Colors.Darker40
                              Size: =16
                              Text: ="Protokolle"
                              Width: =130
                        - LblProtocolsTab:
                            Control: Label@2.5.1
                            Properties:
                              AlignInContainer: =AlignInContainer.Start
                              BorderColor: =RGBA(0, 18, 107, 1)
                              Font: =Font.'Open Sans'
                              FontWeight: =FontWeight.Semibold
                              Height: =45
                              OnSelect: |-
                                =// #removing-toggle-circle-checked
                                /*Patch(
                                    colMainActions,
                                    ThisItem,
                                    {Checked: !ThisItem.Checked}
                                )*/
                              PaddingTop: =14
                              Size: =10
                              Strikethrough: |-
                                =// #removing-toggle-circle-checked
                                // ThisItem.Checked
                              Text: |-
                                =/*
                                Set it to selected Item in Gallery of Topics called "Sitzungsthemen" in German
                                */
                                // GalTopics.Selected.meetTopic


                                With(
                                    {
                                        txt: Trim(
                                            Substitute(
                                                Substitute(
                                                    PlainText(GalTopics.Selected.meetTopic),
                                                    Char(13),
                                                    " "
                                                ),
                                                Char(10),
                                                " "
                                            )
                                        ),
                                        maxCharLength: 27
                                    },
                                    With(
                                        {
                                            cutText: Left(txt, maxCharLength),
                                            spaceCount:
                                                Len(Left(txt, maxCharLength))
                                                - Len(
                                                    Substitute(
                                                        Left(txt, maxCharLength),
                                                        " ",
                                                        ""
                                                    )
                                                )
                                        },
                                        If(
                                            !IsBlank(glbSelectedMeetingId) &&
                                            Len(txt) > maxCharLength,

                                            If(
                                                spaceCount > 0,
                                                Left(
                                                    cutText,
                                                    Find(
                                                        "♦",
                                                        Substitute(
                                                            cutText,
                                                            " ",
                                                            "♦",
                                                            spaceCount
                                                        )
                                                    ) - 1
                                                ),
                                                cutText
                                            ) & " ...",

                                            txt
                                        )
                                    )
                                )
                              Width: =210
                              X: =50
                              Y: =4
                  - ConTabsOverview:
                      Control: GroupContainer@1.5.0
                      Variant: AutoLayout
                      Properties:
                        DropShadow: =DropShadow.None
                        FillPortions: =0
                        Height: =48
                        LayoutDirection: =LayoutDirection.Horizontal
                        LayoutGap: =10
                        Width: =ConRightPanel.Width
                      Children:
                        - BtnOverviewTab:
                            Control: Classic/Button@2.2.0
                            Properties:
                              Align: =Align.Left
                              BorderColor: |-
                                =// RGBA(72, 95, 146, 1)
                                varTabBorderColor
                              Color: |-
                                =// RGBA(22, 45, 92, 1)
                                varTabTextColor
                              Fill: =If(locSelectedTab = "Uebersicht", RGBA(255,255,255,1), RGBA(239,239,239,1))
                              FontWeight: |-
                                =// FontWeight.Semibold
                                varTabFontWeight
                              Height: =45
                              HoverBorderColor: =varTabHoverFill
                              HoverFill: =varTabHoverFill
                              OnSelect: =Set(locSelectedTab, "Uebersicht")
                              PaddingLeft: =16
                              RadiusBottomLeft: =0
                              RadiusBottomRight: =0
                              RadiusTopLeft: =6
                              RadiusTopRight: =6
                              Size: =varTabFontSize
                              Text: ="Protokoll"
                              Visible: =false
                              Width: =120
                        - LblProtocolsOverview:
                            Control: Label@2.5.1
                            Properties:
                              BorderColor: =varTabBorderColor
                              BorderThickness: =2
                              Color: =varTabTextColor
                              Fill: =If(locSelectedTab = "Protokolle", RGBA(255,255,255,1), RGBA(239,239,239,1))
                              Font: =Font.'Open Sans'
                              Height: =45
                              LayoutMinHeight: =16
                              LayoutMinWidth: =16
                              PaddingLeft: =16
                              PressedBorderColor: =App.Theme.Colors.Darker40
                              PressedFill: =App.Theme.Colors.Darker40
                              Size: =16
                              Text: ="Protokoll"
                              Width: =130
                        - LblOverviewTab:
                            Control: Label@2.5.1
                            Properties:
                              AlignInContainer: =AlignInContainer.Start
                              BorderColor: =RGBA(0, 18, 107, 1)
                              DisplayMode: =DisplayMode.View
                              Font: =Font.'Open Sans'
                              FontWeight: =FontWeight.Semibold
                              Height: =45
                              OnSelect: |-
                                =// #removing-toggle-circle-checked
                                /*Patch(
                                    colMainActions,
                                    ThisItem,
                                    {Checked: !ThisItem.Checked}
                                )*/
                              PaddingTop: =14
                              Size: =10
                              Strikethrough: |-
                                =// #removing-toggle-circle-checked
                                // ThisItem.Checked
                              Text: |
                                =/*
                                 Setted to the selected Protokoll of GalProtocols with its description up to 60 chars
                                */

                                With(
                                    {
                                        txt: Trim(
                                            Substitute(
                                                Substitute(
                                                    PlainText(GalProtocols.Selected.protocolText),
                                                    Char(13),
                                                    " "
                                                ),
                                                Char(10),
                                                " "
                                            )
                                        ),
                                        maxCharLength: 60
                                    },
                                    With(
                                        {
                                            cutText: Left(txt, maxCharLength),
                                            spaceCount:
                                                Len(Left(txt, maxCharLength))
                                                - Len(
                                                    Substitute(
                                                        Left(txt, maxCharLength),
                                                        " ",
                                                        ""
                                                    )
                                                )
                                        },
                                        If(
                                            !IsBlank(glbSelectedProtocolId) &&
                                            Len(txt) > maxCharLength,

                                            If(
                                                spaceCount > 0,
                                                Left(
                                                    cutText,
                                                    Find(
                                                        "♦",
                                                        Substitute(
                                                            cutText,
                                                            " ",
                                                            "♦",
                                                            spaceCount
                                                        )
                                                    ) - 1
                                                ),
                                                cutText
                                            ) & " ...",

                                            txt
                                        )
                                    )
                                )
                              Visible: |-
                                =/*
                                Button Disabled as long as there exists no Protocol_id
                                */

                                If(
                                    IsBlank(glbSelectedProtocolId),
                                    false,
                                    true
                                )
                              Width: =560
                              X: =50
                              Y: =4
            - ConMainRow:
                Control: GroupContainer@1.5.0
                Variant: AutoLayout
                Properties:
                  DropShadow: =DropShadow.None
                  Fill: =RGBA(245, 244, 239, 1)
                  Height: =Parent.Height - ConHeader.Height
                  LayoutDirection: =LayoutDirection.Horizontal
                  LayoutGap: =12
                  PaddingBottom: =10
                  PaddingLeft: =16
                  PaddingRight: =16
                  Width: =Parent.Width
                Children:
                  - ConLeftPanel:
                      Control: GroupContainer@1.5.0
                      Variant: AutoLayout
                      Properties:
                        BorderColor: =RGBA(169, 169, 169, 1)
                        FillPortions: =0.5
                        LayoutAlignItems: =LayoutAlignItems.Center
                        LayoutDirection: =LayoutDirection.Vertical
                        LayoutGap: =12
                        PaddingLeft: =12
                        PaddingRight: =12
                        RadiusBottomLeft: =0
                        RadiusBottomRight: =0
                        RadiusTopLeft: =0
                        RadiusTopRight: =0
                        Width: =Parent.Width * 0.30
                      Children:
                        - ConThemeButtons:
                            Control: GroupContainer@1.5.0
                            Variant: AutoLayout
                            Properties:
                              AlignInContainer: =AlignInContainer.SetByContainer
                              Fill: '=RGBA(255, 255, 255, 1)  '
                              Height: =Parent.Height - ConTabsThemesAndArchives.Height - 32
                              LayoutAlignItems: =LayoutAlignItems.Center
                              LayoutDirection: =LayoutDirection.Vertical
                              LayoutGap: =12
                              PaddingLeft: =5
                              RadiusBottomLeft: =8
                              RadiusBottomRight: =8
                              RadiusTopLeft: =8
                              RadiusTopRight: =8
                              Width: =Parent.Width
                            Children:
                              - GalTopics:
                                  Control: Gallery@2.15.0
                                  Variant: BrowseLayout_Vertical_TwoTextOneImageVariant_ver5.0
                                  Properties:
                                    BorderColor: =RGBA(0, 18, 107, 1)
                                    Fill: =RGBA(255, 255, 255, 1)
                                    Items: "=/*  \n    DEV-NOTES:\n    Topics gallery on ScrDashboard. Groups meetings by meetTopic so each topic\n    appears once, then sorts by the group's first meetID.\n\n    Reads:  colMainMeetings\n    \n    @gaudenz\n\n    #topics-Not-agendaitems\n    #sort-order-by-meet-id\n*/\n\nSort(\n    AddColumns(\n        GroupBy(\n            Filter(\n                colMainMeetings,\n                glbStartCheckEditPermission\n                ||\n                !IsBlank(\n                    LookUp(\n                        colMainParticipants,\n                        participantMeetingId = meetID &&\n                        Lower(participantEmail) = Lower(glbUserEmail)\n                    )\n                )\n            ),\n            meetTopic,\n            Rows\n        ),\n        meetID,\n        First(Rows).meetID\n    ),\n    meetID,\n    SortOrder.Ascending\n)\n"
                                    LayoutMaxWidth: =250
                                    LayoutMinHeight: =16
                                    LayoutMinWidth: =16
                                    OnSelect: |-
                                      =/*  
                                          DEV-NOTES:
                                          Selects a topic on ScrDashboard. Sets the meeting, clears protocol selection,
                                          reloads agenda items, empties actions, and shows the empty overview state.

                                          Reads:  ThisItem.meetID
                                          Writes: glbSelectedMeetingId, glbSelectedProtocolId, glbShowEmptyOverview,
                                                  colCurrentAgendaItems, colCurrentActions

                                          Process:
                                          1. glbSelectedMeetingId = ThisItem.meetID
                                          2. glbSelectedProtocolId = Blank()   ← clears protocol
                                          3. Rebuild colCurrentAgendaItems filtered by meeting
                                          4. Empty colCurrentActions
                                          5. glbShowEmptyOverview = true

                                          @gaudenz

                                          #introduce-glbSelectedProtocolId
                                          #protocoll-themes-vice-versa-gsal-onselect-protocol
                                      */

                                      // 1) Selected meeting drives the middle gallery
                                      Set(glbSelectedMeetingId, ThisItem.meetID);

                                      // 2) Clear previously selected protocol
                                      // #introduce-glbSelectedProtocolId

                                      Set(glbSelectedProtocolId, Blank());

                                      // 3) Load agenda items for the selected meeting (if used elsewhere on Dashboard)
                                      ClearCollect(
                                          colCurrentAgendaItems,
                                          Filter(colMainAgendaItems, agendaMeetingId = glbSelectedMeetingId)
                                      );

                                      // 4) Actions belong to a protocol — clear until one is picked
                                      ClearCollect(colCurrentActions, []);

                                      // 5) Show empty state in the right panel
                                      Set(glbShowEmptyOverview, true);
                                    TemplatePadding: =12
                                    TemplateSize: =60
                                    Transition: =Transition.Push
                                  Children:
                                    - ConGalThemes:
                                        Control: GroupContainer@1.5.0
                                        Variant: ManualLayout
                                        Properties:
                                          BorderColor: =RGBA(39, 113, 194, 1)
                                          BorderThickness: =2
                                          Fill: |-
                                            =// ORIGINAL
                                            // RGBA(255, 255, 255, 1)
                                            // Fill.Selected

                                            //@gaudenz
                                            // 24/09/2026
                                            // #improve-gallery-performance
                                            If(
                                                ThisItem.meetID = glbSelectedMeetingId,
                                                varSelectedRowFill,   // named formula
                                                varRowFill            // named formula
                                            )
                                            /*
                                            If(
                                                ThisItem.meetID = glbSelectedMeetingId,
                                                RGBA(230, 240, 255, 1),
                                                RGBA(255, 255, 255, 1)
                                            )
                                            */


                                            /*
                                            If(
                                                ThisItem.meetTopic = "Arbeit und Gesundheit test",
                                                RGBA(230, 240, 255, 1), 
                                                RGBA(255, 255, 255, 1)
                                            )
                                            */
                                          Height: =Parent.TemplateHeight
                                          RadiusBottomLeft: =8
                                          RadiusBottomRight: =8
                                          RadiusTopLeft: =8
                                          RadiusTopRight: =8
                                          Width: =Parent.TemplateWidth - 10
                                    - LblThemes:
                                        Control: Label@2.5.1
                                        Properties:
                                          BorderColor: =RGBA(0, 0, 0, 1)
                                          Color: =RGBA(39, 113, 194, 1)
                                          Font: =Font.'Open Sans'
                                          FontWeight: =If(ThisItem.IsSelected, FontWeight.Semibold, FontWeight.Normal)
                                          Height: =Parent.TemplateHeight
                                          OnSelect: =Select(Parent)
                                          PaddingBottom: =10
                                          PaddingLeft: =8
                                          PaddingRight: =8
                                          Size: =11
                                          Text: |-
                                            =// ThisItem.meetTopic
                                            /*
                                            With(
                                                { _plainText: PlainText(ThisItem.meetTopic) },
                                                If(
                                                    Len(_plainText) > 30, 
                                                    Left(_plainText, 30) & "...", 
                                                    _plainText
                                                )
                                            )
                                            */

                                            With(
                                                {
                                                    txt: Trim(
                                                        Substitute(
                                                            Substitute(
                                                                PlainText(ThisItem.meetTopic),
                                                                Char(13),
                                                                " "
                                                            ),
                                                            Char(10),
                                                            " "
                                                        )
                                                    ),
                                                    maxCharLength: 50
                                                },
                                                With(
                                                    {
                                                        cutText: Left(txt, maxCharLength),
                                                        spaceCount:
                                                            Len(Left(txt, maxCharLength))
                                                            - Len(
                                                                Substitute(
                                                                    Left(txt, maxCharLength),
                                                                    " ",
                                                                    ""
                                                                )
                                                            )
                                                    },
                                                    If(
                                                        !IsBlank(glbSelectedMeetingId) &&
                                                        Len(txt) > maxCharLength,

                                                        If(
                                                            spaceCount > 0,
                                                            Left(
                                                                cutText,
                                                                Find(
                                                                    "♦",
                                                                    Substitute(
                                                                        cutText,
                                                                        " ",
                                                                        "♦",
                                                                        spaceCount
                                                                    )
                                                                ) - 1
                                                            ),
                                                            cutText
                                                        ) & " ...",

                                                        txt
                                                    )
                                                )
                                            )
                                          VerticalAlign: =VerticalAlign.Top
                                          Width: '=Parent.TemplateWidth - 10 '
                                    - IcoNextArrow2:
                                        Control: Classic/Icon@2.5.0
                                        Properties:
                                          AccessibleLabel: =Self.Tooltip
                                          BorderColor: =RGBA(0, 0, 0, 1)
                                          Color: =RGBA(166, 166, 166, 1)
                                          DisabledBorderColor: =RGBA(56, 56, 56, 1)
                                          DisabledColor: =RGBA(119, 119, 119, 1)
                                          Height: =50
                                          Icon: =Icon.ChevronRight
                                          OnSelect: =Select(Parent)
                                          PaddingBottom: =16
                                          PaddingLeft: =16
                                          PaddingRight: =16
                                          PaddingTop: =16
                                          Tooltip: ="View item details"
                                          Visible: =false
                                          Width: =50
                                          X: =146
                                          Y: =(Parent.TemplateHeight / 2) - (Self.Height / 2)
                                    - BtnHoverOverlay_Topics:
                                        Control: Classic/Button@2.2.0
                                        Properties:
                                          BorderColor: =ColorFade(Self.Fill, -15%)
                                          Color: =RGBA(255, 255, 255, 1)
                                          DisabledBorderColor: =RGBA(166, 166, 166, 1)
                                          Fill: =RGBA(0, 0, 0, 0)
                                          Font: =Font.'Open Sans'
                                          Height: =60
                                          HoverBorderColor: =ColorFade(Self.BorderColor, 20%)
                                          HoverColor: =RGBA(255, 255, 255, 1)
                                          HoverFill: =RGBA(0, 0, 0, 0.03)
                                          OnSelect: =Select(Parent)
                                          PressedBorderColor: =Self.Fill
                                          PressedColor: =Self.Fill
                                          PressedFill: =RGBA(0, 0, 0, 0)
                                          Text: =
                                          Width: =211
                                          X: =10
                  - ConCenterPanel:
                      Control: GroupContainer@1.5.0
                      Variant: AutoLayout
                      Properties:
                        BorderColor: =RGBA(180,180,180,1)
                        BorderThickness: =1
                        Fill: =RGBA(250,250,250,1)
                        LayoutDirection: =LayoutDirection.Vertical
                        LayoutGap: =12
                        RadiusBottomLeft: =8
                        RadiusBottomRight: =8
                        RadiusTopLeft: =8
                        RadiusTopRight: =8
                        Width: =Parent.Width * 0.42
                      Children:
                        - LblNoChoiceOverview_1:
                            Control: Label@2.5.1
                            Properties:
                              Align: =Align.Center
                              AlignInContainer: =AlignInContainer.Center
                              BorderColor: =RGBA(0, 18, 107, 1)
                              Font: =Font.'Open Sans'
                              FontWeight: =FontWeight.Semibold
                              Height: =Parent.Height
                              LayoutMinHeight: =16
                              LayoutMinWidth: =16
                              Text: ="Für dieses Thema wurde noch kein Protokoll erstellt."
                              Visible: |-
                                =// Visible property of the label
                                CountRows(
                                    Filter(colMainProtocols, protocolMeetingId = glbSelectedMeetingId)
                                ) = 0
                              Width: =ConCenterPanel.Width
                        - ConProtocolList:
                            Control: GroupContainer@1.5.0
                            Variant: AutoLayout
                            Properties:
                              DropShadow: =DropShadow.None
                              Height: =ConCenterPanel.Height
                              LayoutDirection: =LayoutDirection.Vertical
                              LayoutGap: =10
                              Width: =Parent.Width
                            Children:
                              - GalProtocols:
                                  Control: Gallery@2.15.0
                                  Variant: BrowseLayout_Vertical_TwoTextOneImageVariant_ver5.0
                                  Properties:
                                    AlignInContainer: =AlignInContainer.Start
                                    BorderColor: =RGBA(0, 18, 107, 1)
                                    FillPortions: =2
                                    Height: =Parent.Height
                                    Items: |+
                                      =/*  
                                          DEV-NOTES:
                                          Protocols gallery on ScrDashboard. Shows protocols belonging to the currently
                                          selected meeting, sorted by start time ascending.

                                          Reads:  colMainProtocols, glbSelectedMeetingId
                                          Sort:   protocolStartedAt ascending

                                          @gaudenz

                                      */

                                      SortByColumns(
                                          Filter(
                                              colMainProtocols,
                                              !IsBlank(glbSelectedMeetingId) && protocolMeetingId = glbSelectedMeetingId
                                          ),
                                          "protocolStartedAt",
                                          SortOrder.Ascending
                                      )
                                    LayoutMinHeight: =16
                                    LayoutMinWidth: =16
                                    OnSelect: |
                                      =/*  
                                          DEV-NOTES:
                                          Selects a protocol on ScrDashboard. Sets protocol + meeting, clears agenda
                                          selection, hides the empty overview, rebuilds agenda + actions for the
                                          selected protocol, and loads its content into the right panel.

                                          Reads:  ThisItem.protocolID, ThisItem.protocolMeetingId
                                          Writes: glbSelectedProtocolId, glbSelectedMeetingId, glbSelectedAgendaId,
                                                  glbShowEmptyOverview, colCurrentAgendaItems, colCurrentActions,
                                                  locOverviewTitle, locOverviewDescription, locOverviewHtml

                                          Process:
                                          1. Set protocol + meeting + clear agenda + hide empty state
                                          2. Rebuild colCurrentAgendaItems for the (possibly new) meeting
                                          3. Rebuild colCurrentActions for the selected protocol
                                          4. Load protocol content into overview context vars

                                          @gaudemnz

                                          Tags:
                                          #protocoll-themes-vice-versa-gsal-onselect-protocol
                                          #introduce-glbSelectedProtocolId
                                          #improve-gallery-performance
                                          #introduce-glbSelectedProtocolId
                                      */

                                      Set(glbSelectedProtocolId, ThisItem.protocolID);
                                      Set(glbSelectedMeetingId, ThisItem.protocolMeetingId);
                                      Set(glbSelectedAgendaId, Blank());
                                      Set(glbShowEmptyOverview, false);

                                      ClearCollect(
                                          colCurrentAgendaItems,
                                          Filter(colMainAgendaItems, agendaMeetingId = glbSelectedMeetingId)
                                      );

                                      ClearCollect(
                                          colCurrentActions,
                                          Filter(colMainActions, actionProtocolId = glbSelectedProtocolId)
                                      );

                                      With(
                                          {
                                              p: LookUp(colMainProtocols, protocolID = ThisItem.protocolID)
                                          },
                                          UpdateContext({
                                              locOverviewTitle:       p.protocolMeetingTopic,
                                              locOverviewDescription: p.protocolMeetingDescription,
                                              locOverviewHtml:        p.protocolText
                                          })
                                      )
                                    TemplateFill: |
                                      =// RGBA(0, 0, 0, 0)
                                      // #vice-versa-theme-protocol-function-onselect
                                      If(
                                          ThisItem.protocolID = glbSelectedProtocolId,
                                          RGBA(230, 240, 255, 1),   // light blue highlight
                                          RGBA(255, 255, 255, 1)    // normal white
                                      )
                                    TemplatePadding: =12
                                    TemplateSize: =70
                                    Transition: =Transition.Push
                                    Width: =ConCenterPanel.Width
                                  Children:
                                    - ConCoverGalProtocols:
                                        Control: GroupContainer@1.5.0
                                        Variant: ManualLayout
                                        Properties:
                                          BorderColor: |-
                                            =// RGBA(50, 86, 160, 1)
                                            varTabBorderColor
                                          BorderThickness: =1
                                          Fill: |
                                            =// ORIGINAL
                                            // RGBA(255, 255, 255, 1)
                                            // Fill.Selected
                                            //@gaudenz
                                            // 24/09/2026
                                            // #improve-gallery-performance
                                            If(
                                                ThisItem.protocolID = glbSelectedProtocolId,
                                                varSelectedRowFill,   // named formula
                                                varRowFill            // named formula
                                            )
                                          Height: =Parent.TemplateHeight
                                          RadiusBottomLeft: =8
                                          RadiusBottomRight: =8
                                          RadiusTopLeft: =8
                                          RadiusTopRight: =8
                                          Width: =320
                                    - GalParticipants:
                                        Control: Gallery@2.15.0
                                        Variant: BrowseLayout_Horizontal_TwoTextOneImageVariant_ver5.0
                                        Properties:
                                          BorderColor: =RGBA(0, 18, 107, 1)
                                          Height: =70
                                          Items: |-
                                            =Filter(
                                                colMainParticipants,
                                                participantMeetingId = ThisItem.protocolMeetingId
                                                && participantCreated <= ThisItem.protocolStartedAt
                                            )
                                            /*
                                            Filter(
                                                colMainParticipants,
                                                participantMeetingId = ThisItem.protocolMeetingId
                                            )
                                            */
                                          TemplateSize: =24
                                          Width: '=118 '
                                          X: =211
                                        Children:
                                          - imgCircle:
                                              Control: Circle@2.3.0
                                              Properties:
                                                BorderColor: =RGBA(255, 255, 255, 1)
                                                BorderThickness: =1
                                                Fill: =RGBA(56, 96, 178, 1)
                                                Height: =30
                                                OnSelect: =Select(Parent)
                                                Visible: |+
                                                  =LblAvatar.Visible







                                                Width: =30
                                                X: =2
                                                Y: '=(Parent.TemplateHeight - Self.Height) / 2   '
                                          - LblAvatar:
                                              Control: Label@2.5.1
                                              Properties:
                                                Align: =Align.Center
                                                BorderColor: =RGBA(0, 18, 107, 1)
                                                Color: =RGBA(255, 255, 255, 1)
                                                Font: =Font.'Open Sans'
                                                FontWeight: =FontWeight.Semibold
                                                Height: =30
                                                LineHeight: =1
                                                OnSelect: =Select(Parent)
                                                Text: |-
                                                  =Upper(Left(ThisItem.participantEmail, 1))

                                                  // Left(ThisItem.participantEmail, 1)
                                                Visible: |+
                                                  =IsError(Office365Users.UserPhotoMetadata(ThisItem.participantEmail))






                                                Width: =30
                                                X: =2
                                                Y: '=(Parent.TemplateHeight - Self.Height) / 2  '
                                          - ImgAvatar:
                                              Control: Image@2.2.3
                                              Properties:
                                                BorderColor: =RGBA(255, 255, 255, 1)
                                                BorderThickness: =1
                                                Height: =30
                                                Image: |+
                                                  =IfError(
                                                      Office365Users.UserPhotoV2(ThisItem.participantEmail),
                                                      Blank()
                                                  )

                                                ImagePosition: =ImagePosition.Fill
                                                OnSelect: =Select(Parent)
                                                RadiusBottomLeft: =15
                                                RadiusBottomRight: =15
                                                RadiusTopLeft: =15
                                                RadiusTopRight: =15
                                                Visible: =!IsError(Office365Users.UserPhotoMetadata(ThisItem.participantEmail))
                                                Width: =30
                                                X: =2
                                                Y: =(Parent.TemplateHeight - Self.Height ) / 2
                                    - IcoNextArrowGalProtocols:
                                        Control: Classic/Icon@2.5.0
                                        Properties:
                                          AccessibleLabel: =Self.Tooltip
                                          BorderColor: =RGBA(0, 0, 0, 1)
                                          Color: =RGBA(166, 166, 166, 1)
                                          DisabledBorderColor: =RGBA(56, 56, 56, 1)
                                          DisabledColor: =RGBA(119, 119, 119, 1)
                                          Height: =40
                                          Icon: =Icon.ChevronRight
                                          OnSelect: =Select(Parent)
                                          PaddingBottom: =16
                                          PaddingLeft: =16
                                          PaddingRight: =16
                                          PaddingTop: =16
                                          Tooltip: ="View item details"
                                          Visible: =false
                                          Width: =1
                                          Y: =15
                                    - LblDateProtocols:
                                        Control: Label@2.5.1
                                        Properties:
                                          BorderColor: =RGBA(0, 0, 0, 1)
                                          Font: =Font.'Open Sans'
                                          FontWeight: =If(ThisItem.IsSelected, FontWeight.Semibold, FontWeight.Normal)
                                          Height: =20
                                          OnSelect: =Select(Parent)
                                          PaddingBottom: =0
                                          PaddingLeft: =0
                                          PaddingRight: =0
                                          PaddingTop: =2
                                          Size: =11
                                          Text: |
                                            =Text(ThisItem.protocolStartedAt, "dd.mm.yyyy, HH:mm")
                                            // varSelectedProtocolID
                                          VerticalAlign: =VerticalAlign.Top
                                          Width: =140
                                          X: =8
                                          Y: =46
                                    - LblProtocols:
                                        Control: Label@2.5.1
                                        Properties:
                                          BorderColor: =RGBA(0, 0, 0, 1)
                                          Color: =RGBA(50, 49, 48, 1)
                                          Font: =Font.'Open Sans'
                                          FontWeight: =If(ThisItem.IsSelected, FontWeight.Semibold, FontWeight.Normal)
                                          Height: =36
                                          OnSelect: =Select(Parent)
                                          PaddingBottom: =0
                                          PaddingLeft: =0
                                          PaddingRight: =0
                                          PaddingTop: =0
                                          Size: =12
                                          Text: |-
                                            = /*
                                             Setted to the selected Protokoll with its description up to 40 chars
                                            */
                                            // einfache form
                                            // Left(ThisItem.protocolText, 40)

                                            With(
                                                {
                                                    txt: Trim(
                                                        Substitute(
                                                            Substitute(
                                                                PlainText(ThisItem.protocolText),
                                                                Char(13),
                                                                " "
                                                            ),
                                                            Char(10),
                                                            " "
                                                        )
                                                    ),
                                                    maxCharLength: 40
                                                },
                                                With(
                                                    {
                                                        cutText: Left(txt, maxCharLength),
                                                        spaceCount:
                                                            Len(Left(txt, maxCharLength))
                                                            - Len(
                                                                Substitute(
                                                                    Left(txt, maxCharLength),
                                                                    " ",
                                                                    ""
                                                                )
                                                            )
                                                    },
                                                    If(
                                                        !IsBlank(glbSelectedProtocolId) &&
                                                        Len(txt) > maxCharLength,

                                                        If(
                                                            spaceCount > 0,
                                                            Left(
                                                                cutText,
                                                                Find(
                                                                    "♦",
                                                                    Substitute(
                                                                        cutText,
                                                                        " ",
                                                                        "♦",
                                                                        spaceCount
                                                                    )
                                                                ) - 1
                                                            ),
                                                            cutText
                                                        ) & " ...",

                                                        txt
                                                    )
                                                )
                                            )
                                          VerticalAlign: =VerticalAlign.Top
                                          Width: =203
                                          X: =8
                                          Y: =6
                                    - BtnHoverOverlay_protocols:
                                        Control: Classic/Button@2.2.0
                                        Properties:
                                          BorderColor: =ColorFade(Self.Fill, -15%)
                                          Color: =RGBA(255, 255, 255, 1)
                                          DisabledBorderColor: =RGBA(166, 166, 166, 1)
                                          Fill: =RGBA(0, 0, 0, 0)
                                          Font: =Font.'Open Sans'
                                          Height: =70
                                          HoverBorderColor: =ColorFade(Self.BorderColor, 20%)
                                          HoverColor: =RGBA(255, 255, 255, 1)
                                          HoverFill: =RGBA(0, 0, 0, 0.03)
                                          OnSelect: =Select(Parent)
                                          PressedBorderColor: =Self.Fill
                                          PressedColor: =Self.Fill
                                          PressedFill: =RGBA(0, 0, 0, 0)
                                          Text: =
                                          Width: =319
                                          X: =10
                  - ConRightPanel:
                      Control: GroupContainer@1.5.0
                      Variant: AutoLayout
                      Properties:
                        BorderColor: =RGBA(180,180,180,1)
                        BorderThickness: =1
                        Fill: =RGBA(255, 255, 255, 1)
                        FillPortions: =2
                        LayoutDirection: =LayoutDirection.Horizontal
                        LayoutGap: =12
                        LayoutJustifyContent: =LayoutJustifyContent.Center
                        PaddingBottom: =12
                        PaddingRight: =18
                        RadiusBottomLeft: =8
                        RadiusBottomRight: =8
                        RadiusTopLeft: =8
                        RadiusTopRight: =8
                        Width: =Parent.Width * 0.28
                      Children:
                        - LblNoChoiceOverview:
                            Control: Label@2.5.1
                            Properties:
                              Align: =Align.Center
                              AlignInContainer: =AlignInContainer.Center
                              BorderColor: =RGBA(0, 18, 107, 1)
                              Font: =Font.'Open Sans'
                              FontWeight: =FontWeight.Semibold
                              LayoutMinHeight: =16
                              LayoutMinWidth: =16
                              Text: ="Wähle ein Protokoll oder ein Sitzungshema."
                              Visible: =glbShowEmptyOverview
                              Width: =ConRightPanel.Width
                        - ConOverviewOuter:
                            Control: GroupContainer@1.5.0
                            Variant: AutoLayout
                            Properties:
                              DropShadow: =DropShadow.None
                              FillPortions: =2
                              LayoutAlignItems: =LayoutAlignItems.Center
                              LayoutDirection: =LayoutDirection.Horizontal
                              LayoutMinHeight: =16
                              LayoutMinWidth: =16
                              PaddingLeft: =8
                              PaddingRight: =8
                              Visible: =!glbShowEmptyOverview
                            Children:
                              - ContOverviewInner:
                                  Control: GroupContainer@1.5.0
                                  Variant: AutoLayout
                                  Properties:
                                    DropShadow: =DropShadow.None
                                    Height: =Parent.Height
                                    LayoutDirection: =LayoutDirection.Vertical
                                    LayoutGap: =5
                                    LayoutMaxHeight: =Parent.Height
                                    LayoutMinHeight: =16
                                    LayoutMinWidth: =16
                                    PaddingBottom: =8
                                    PaddingLeft: =4
                                    PaddingRight: =8
                                    PaddingTop: =8
                                  Children:
                                    - TxtInputTitle:
                                        Control: Classic/TextInput@2.3.2
                                        Properties:
                                          BorderColor: =RGBA(0, 18, 107, 1)
                                          BorderThickness: =0
                                          Default: |+
                                            =//@gaudenz
                                            // #improve-gallery-performance
                                            // TxtInputTitle.Default
                                            locOverviewTitle
                                          DisplayMode: =DisplayMode.View
                                          Font: =Font.'Open Sans'
                                          FontWeight: =FontWeight.Semibold
                                          Height: =70
                                          HoverBorderColor: =RGBA(0, 18, 107, 1)
                                          HoverFill: =RGBA(186, 202, 226, 1)
                                          LayoutMinHeight: =16
                                          LayoutMinWidth: =16
                                          Mode: =TextMode.MultiLine
                                          PaddingLeft: =5
                                          PaddingTop: =10
                                          Size: =15
                                          Width: =Parent.Width - 12
                                    - TxtInputDescription:
                                        Control: Classic/TextInput@2.3.2
                                        Properties:
                                          AlignInContainer: =AlignInContainer.Start
                                          BorderColor: =RGBA(0, 18, 107, 1)
                                          BorderThickness: =0
                                          Default: |-
                                            =//@gaudenz
                                            // #improve-gallery-performance
                                            // TxtInputDescription.Default
                                            locOverviewDescription
                                          DisplayMode: =DisplayMode.View
                                          Font: =Font.'Open Sans'
                                          HoverBorderColor: =RGBA(0, 18, 107, 1)
                                          HoverFill: =RGBA(186, 202, 226, 1)
                                          LayoutMinHeight: =16
                                          LayoutMinWidth: =16
                                          Mode: =TextMode.MultiLine
                                          PaddingBottom: =0
                                          PaddingTop: =0
                                          Size: =12
                                          Width: =Parent.Width - 12
                                    - Rectangle1:
                                        Control: Rectangle@2.3.0
                                        Properties:
                                          BorderColor: =RGBA(0, 18, 107, 1)
                                          Fill: =RGBA(149, 149, 149, 1)
                                          Height: =1
                                          LayoutMinHeight: =16
                                          LayoutMinWidth: =16
                                          Width: '=Parent.Width - 20   '
                                    - HtmlText1:
                                        Control: HtmlViewer@2.1.0
                                        Properties:
                                          Font: =Font.'Open Sans'
                                          Height: =Parent.Height - TxtInputDescription.Height - TxtInputTitle.Height
                                          HtmlText: |-
                                            =/*  
                                                DEV-NOTES:
                                                Renders the protocol body (HTML) in the overview panel.

                                                HtmlText: locOverviewHtml

                                                Gotchas:
                                                - Height depends on TxtInputTitle + TxtInputDescription heights. If those
                                                  change dynamically (wrap, font size), the HTML region shrinks or grows
                                                  and may clip or leave whitespace.
                                                - No sanitization on locOverviewHtml — the source is protocolText from
                                                  SharePoint. RTE output is trusted here. If protocolText ever accepts
                                                  user HTML from untrusted input, XSS-style rendering is possible.
                                                - HtmlViewer control is deprecated in newer Power Apps versions; consider
                                                  migrating to the newer "HTML text" control if the app is ever rebuilt.

                                                @gaudenz  

                                                #improve-gallery-performance
                                            */
                                            locOverviewHtml
                                          LayoutMinHeight: =16
                                          LayoutMinWidth: =16
                                          Width: =Parent.Width - 12
                        - ConOverviewBox:
                            Control: GroupContainer@1.5.0
                            Variant: ManualLayout
                            Properties:
                              AlignInContainer: =AlignInContainer.End
                              BorderColor: =RGBA(200,200,200,1)
                              BorderThickness: =2
                              DropShadow: =DropShadow.None
                              Fill: =RGBA(245,245,245,1)
                              Height: =Parent.Height - 80
                              RadiusBottomLeft: =8
                              RadiusBottomRight: =8
                              RadiusTopLeft: =8
                              RadiusTopRight: =8
                              Visible: |-
                                =//!glbShowEmptyOverview


                                // Set that there are action in conOverviewBox to show or hide it
                                CountRows(colCurrentActions) > 0
                              Width: =Parent.Width - 36
                            Children:
                              - GalActions:
                                  Control: Gallery@2.15.0
                                  Variant: BrowseLayout_Vertical_TwoTextOneImageVariant_ver5.0
                                  Properties:
                                    BorderColor: =RGBA(0, 18, 107, 1)
                                    Height: =488
                                    Items: |+
                                      =/*  
                                          DEV-NOTES:
                                          Actions gallery inside the right overview panel. Shows the actions belonging
                                          to the currently selected protocol.

                                          Reads:  colCurrentActions
                                          Items:  colCurrentActions

                                          #removing-toggle-circle-checked
                                      */
                                      colCurrentActions

                                    TemplateSize: =64
                                    Width: =250
                                  Children:
                                    - ImgCircle:
                                        Control: Image@2.2.3
                                        Properties:
                                          BorderColor: =RGBA(0, 18, 107, 1)
                                          Height: =26
                                          Image: |-
                                            =// #removing-toggle-circle-checked
                                            /*
                                            "data:image/svg+xml; utf-8, " & EncodeUrl($"<svg width='51' height='51' viewBox='0 0 51 51' fill='none' xmlns='http://www.w3.org/2000/svg'><path d='M25.1573 0.786133C11.6942 0.786133 0.786133 11.6942 0.786133 25.1573C0.786133 38.6205 11.6942 49.5285 25.1573 49.5285C38.6205 49.5285 49.5285 38.6205 49.5285 25.1573C49.5285 11.6942 38.6205 0.786133 25.1573 0.786133ZM25.1573 44.8115C14.2984 44.8115 5.50314 36.0163 5.50314 25.1573C5.50314 14.2984 14.2984 5.50314 25.1573 5.50314C36.0163 5.50314 44.8115 14.2984 44.8115 25.1573C44.8115 36.0163 36.0163 44.8115 25.1573 44.8115Z' fill='green'/></svg>")
                                            */
                                          OnSelect: |-
                                            =// #removing-toggle-circle-checked
                                            /*Patch(
                                                colMainActions,
                                                ThisItem,
                                                {Checked: !ThisItem.Checked}
                                            )*/
                                          Visible: |-
                                            =// #removing-toggle-circle-checked
                                            // !ThisItem.Checked
                                          Width: =26
                                          X: =10
                                          Y: =11
                                    - ImgCheck:
                                        Control: Image@2.2.3
                                        Properties:
                                          BorderColor: =RGBA(0, 18, 107, 1)
                                          Height: =24
                                          Image: ="data:image/svg+xml; utf-8, " & EncodeUrl($"<svg width='51' height='51' viewBox='0 0 51 51' fill='none' xmlns='http://www.w3.org/2000/svg'><path d='M42.8312 8.19913L16.9816 34.0487L7.48354 24.5506C7.02305 24.0901 6.27638 24.0901 5.81579 24.5506L3.03629 27.3301C2.57579 27.7906 2.57579 28.5373 3.03629 28.9979L16.1477 42.1093C16.6082 42.5698 17.3549 42.5698 17.8155 42.1093L47.2784 12.6464C47.7389 12.1859 47.7389 11.4392 47.2784 10.9786L44.4989 8.19913C44.0384 7.73864 43.2917 7.73864 42.8312 8.19913Z' fill='green'/></svg>")
                                          OnSelect: |-
                                            =// #removing-toggle-circle-checked
                                            /*Patch(
                                                colMainActions,
                                                ThisItem,
                                                {Checked: !ThisItem.Checked}
                                            )*/
                                          Visible: |-
                                            =true
                                            // !ThisItem.Checked
                                          Width: =24
                                          X: =5
                                          Y: =10
                                    - ConActionsTaskNDoneAt:
                                        Control: GroupContainer@1.5.0
                                        Variant: AutoLayout
                                        Properties:
                                          DropShadow: =DropShadow.None
                                          Height: =64
                                          LayoutAlignItems: =LayoutAlignItems.Center
                                          LayoutDirection: =LayoutDirection.Vertical
                                          PaddingBottom: =8
                                          PaddingLeft: =5
                                          PaddingTop: =8
                                          Width: =221
                                          X: =29
                                        Children:
                                          - LblTask:
                                              Control: Label@2.5.1
                                              Properties:
                                                AlignInContainer: =AlignInContainer.Start
                                                BorderColor: =RGBA(0, 18, 107, 1)
                                                Font: =Font.'Open Sans'
                                                Height: =30
                                                OnSelect: |-
                                                  =// #removing-toggle-circle-checked
                                                  /*Patch(
                                                      colMainActions,
                                                      ThisItem,
                                                      {Checked: !ThisItem.Checked}
                                                  )*/
                                                PaddingLeft: =0
                                                PaddingTop: =0
                                                Size: =10
                                                Strikethrough: |-
                                                  =// #removing-toggle-circle-checked
                                                  // ThisItem.Checked
                                                Text: |-
                                                  =// ThisItem.Action_Item
                                                  // ThisItem.actionItem


                                                  With(
                                                      {
                                                          txt: Trim(
                                                              Substitute(
                                                                  Substitute(
                                                                      PlainText(ThisItem.actionItem),
                                                                      Char(13),
                                                                      " "
                                                                  ),
                                                                  Char(10),
                                                                  " "
                                                              )
                                                          ),
                                                          maxCharLength: 50
                                                      },
                                                      With(
                                                          {
                                                              cutText: Left(txt, maxCharLength),
                                                              spaceCount:
                                                                  Len(Left(txt, maxCharLength))
                                                                  - Len(
                                                                      Substitute(
                                                                          Left(txt, maxCharLength),
                                                                          " ",
                                                                          ""
                                                                      )
                                                                  )
                                                          },
                                                          If(
                                                              !IsBlank(glbSelectedMeetingId) &&
                                                              Len(txt) > maxCharLength,

                                                              If(
                                                                  spaceCount > 0,
                                                                  Left(
                                                                      cutText,
                                                                      Find(
                                                                          "♦",
                                                                          Substitute(
                                                                              cutText,
                                                                              " ",
                                                                              "♦",
                                                                              spaceCount
                                                                          )
                                                                      ) - 1
                                                                  ),
                                                                  cutText
                                                              ) & " ...",

                                                              txt
                                                          )
                                                      )
                                                  )
                                                Width: =210
                                                X: =50
                                                Y: =4
                                          - LblTaskDoneDate:
                                              Control: Label@2.5.1
                                              Properties:
                                                AlignInContainer: =AlignInContainer.Start
                                                BorderColor: =RGBA(0, 18, 107, 1)
                                                Font: =Font.'Open Sans'
                                                Height: =20
                                                OnSelect: |-
                                                  =// #removing-toggle-circle-checked
                                                  /*Patch(
                                                      colMainActions,
                                                      ThisItem,
                                                      {Checked: !ThisItem.Checked}
                                                  )*/
                                                PaddingLeft: =0
                                                Size: =10
                                                Strikethrough: |-
                                                  =// #removing-toggle-circle-checked
                                                  // ThisItem.Checked
                                                Text: |
                                                  =// ThisItem.Action_Item
                                                  Text(ThisItem.actionDoneDate, "dd.mm.yyyy")
                                                Width: =200
                                                X: =50
                                                Y: =20
            - ConFooterNew:
                Control: GroupContainer@1.5.0
                Variant: AutoLayout
                Properties:
                  DropShadow: =DropShadow.None
                  Fill: =RGBA(245, 244, 239, 1)
                  FillPortions: =0
                  Height: =60
                  LayoutAlignItems: =LayoutAlignItems.Center
                  LayoutDirection: =LayoutDirection.Horizontal
                  PaddingBottom: =8
                  PaddingLeft: =16
                  PaddingRight: =16
                  PaddingTop: =8
                  X: =40
                  Y: =40
                Children:
                  - ConBtnThemeFooter:
                      Control: GroupContainer@1.5.0
                      Variant: AutoLayout
                      Properties:
                        AlignInContainer: =AlignInContainer.Center
                        DropShadow: =DropShadow.None
                        FillPortions: =0.5
                        Height: =ConFooterNew.Height
                        LayoutDirection: =LayoutDirection.Horizontal
                        LayoutGap: =10
                        LayoutMinHeight: '=ConFooterNew.Height '
                        PaddingTop: =15
                        Width: =Parent.Width
                      Children:
                        - BtnThemesFooter:
                            Control: Classic/Button@2.2.0
                            Properties:
                              BorderColor: |-
                                =// RGBA(72, 95, 146, 1)
                                varFooterBtnBorderColor
                              BorderThickness: '=2   '
                              Color: =varTabTextColor
                              Fill: =If(locSelectedTab = "Neue Themen", RGBA(255,255,255,1), RGBA(239,239,239,1))
                              FontWeight: =varTabFontWeight
                              Height: =32
                              HoverBorderColor: =varTabHoverFill
                              HoverFill: =varTabHoverFill
                              OnSelect: |
                                =/*  
                                    DEV-NOTES:
                                    Footer button "Neues Sitzungsthema". Creates a new empty meeting template,
                                    loads it into glbLoadMeetingId, rebuilds colMainMeetings, and navigates to
                                    ScrMeeting with a reset flag.

                                    Reads:  —
                                    Writes: gblMarker (varMarker), INT003_Meetings_List (Patch),
                                            glbLoadMeetingId, colMainMeetings (rebuilt), glbResetForm
                                    Navigates to: ScrMeeting

                                    Process:
                                    1. Create new meeting with marker Title ("TMP-" & GUID)
                                    2. Lookup new ID by marker → glbLoadMeetingId
                                    3. Rebuild colMainMeetings
                                    4. Set glbResetForm = true
                                    5. Navigate to ScrMeeting


                                    @gaudenz

                                    Tags:
                                    #introduce-fix-meetingID-oncreate
                                    #introduce-glbResetForm
                                */
                                // #introduce-fix-meetingID-oncreate
                                Set(
                                    varMarker,
                                    "TMP-" & GUID()
                                );
                                Patch(
                                    INT003_Meetings_List,
                                    Defaults(INT003_Meetings_List),
                                    {
                                        Titel: varMarker,
                                        Topic: ""
                                    }
                                );
                                Set(
                                    glbLoadMeetingId,
                                    LookUp(
                                        INT003_Meetings_List,
                                        Titel = varMarker
                                    ).ID
                                );
                                ClearCollect(
                                    colMainMeetings,
                                    AddColumns(
                                        INT003_Meetings_List,
                                        meetID, ID,
                                        meetTitle, Titel,
                                        meetTopic, Topic,
                                        meetDescription, Description,
                                        meetStarts, Starts,
                                        meetEnds, Ends,
                                        meetLocation, Location
                                    )
                                );
                                // #introduce-glbResetForm
                                Set(
                                    glbResetForm,
                                    true
                                );
                                Navigate(
                                    ScrMeeting,
                                    ScreenTransition.Fade
                                )
                              PressedBorderColor: |-
                                =// App.Theme.Colors.Darker40
                                Color.LightGray
                              PressedFill: |-
                                =// App.Theme.Colors.Darker40
                                Color.LightGray
                              RadiusBottomLeft: =6
                              RadiusBottomRight: =6
                              RadiusTopLeft: =6
                              RadiusTopRight: =6
                              Size: =varFooterBtnFontSize
                              Text: ="Neues Sitzungsthema"
                              Width: =150
                  - ConBtnPrepMeetingFooter:
                      Control: GroupContainer@1.5.0
                      Variant: AutoLayout
                      Properties:
                        AlignInContainer: =AlignInContainer.Center
                        DropShadow: =DropShadow.None
                        Height: =ConFooterNew.Height
                        LayoutDirection: =LayoutDirection.Horizontal
                        LayoutGap: =10
                        LayoutMinHeight: =ConFooterNew.Height
                        PaddingLeft: =12
                        PaddingTop: =15
                        Width: =Parent.Width
                      Children:
                        - BtnPrepMeeting:
                            Control: Classic/Button@2.2.0
                            Properties:
                              BorderColor: |-
                                =// RGBA(72, 95, 146, 1)
                                varFooterBtnBorderColor
                              Color: =varTabTextColor
                              DisplayMode: |-
                                =/*
                                Button Disabled as long as there exists no Protocol_id
                                */

                                If(
                                    IsBlank(glbSelectedMeetingId),
                                    DisplayMode.Disabled,
                                    DisplayMode.Edit
                                )
                              Fill: =If(locSelectedTab = "PrepSession", RGBA(255,255,255,1), RGBA(239,239,239,1))
                              FontWeight: =varTabFontWeight
                              Height: =32
                              HoverBorderColor: =varTabHoverFill
                              HoverFill: =varTabHoverFill
                              OnSelect: |-
                                =/*  
                                    DEV-NOTES:
                                    Footer button "Sitzung planen und starten". Loads the currently selected
                                    dashboard topic into ScrMeeting for editing, resets the two sub-form flags,
                                    and navigates.

                                    Reads:  glbSelectedMeetingId
                                    Writes: glbLoadMeetingId, glbAddAgendaItem = false, glbAddParticipant = false
                                    Navigates to: ScrMeeting

                                    Process:
                                    1. Guard: glbSelectedMeetingId must be set
                                    2. Copy glbSelectedMeetingId → glbLoadMeetingId (transit)
                                    3. Clear glbAddAgendaItem / glbAddParticipant (fresh form)
                                    4. Navigate

                                    @gaudenz

                                    Tags:
                                    #navigate-to-scrmeeting-load-selected-topic
                                */

                                If(
                                    IsBlank(glbSelectedMeetingId),
                                    Notify("Bitte zuerst ein Thema auswählen.", NotificationType.Warning),
                                    Set(glbLoadMeetingId, glbSelectedMeetingId);
                                    Set(glbAddAgendaItem,  false);
                                    Set(glbAddParticipant, false);
                                    Navigate(ScrMeeting, ScreenTransition.Fade)
                                )
                              PressedBorderColor: |-
                                =// App.Theme.Colors.Darker40
                                Color.LightGray
                              PressedFill: |-
                                =// App.Theme.Colors.Darker40
                                Color.LightGray
                              RadiusBottomLeft: =6
                              RadiusBottomRight: =6
                              RadiusTopLeft: =6
                              RadiusTopRight: =6
                              Size: =varFooterBtnFontSize
                              Text: ="Sitzung planen und starten"
                              Width: =220
                  - ConBtnEditProtocollFooter:
                      Control: GroupContainer@1.5.0
                      Variant: AutoLayout
                      Properties:
                        AlignInContainer: =AlignInContainer.Center
                        DropShadow: =DropShadow.None
                        FillPortions: =2
                        Height: '=ConFooterNew.Height '
                        LayoutDirection: =LayoutDirection.Horizontal
                        LayoutGap: =10
                        LayoutMinHeight: =ConFooterNew.Height
                        PaddingLeft: =17
                        PaddingTop: =15
                        Width: =Parent.Width
                      Children:
                        - BtnEditProtocoll:
                            Control: Classic/Button@2.2.0
                            Properties:
                              BorderColor: |-
                                =// RGBA(72, 95, 146, 1)
                                varFooterBtnBorderColor
                              Color: =varTabTextColor
                              DisplayMode: |-
                                =/*
                                Button Disabled as long as there exists no Protocol_id
                                */

                                If(
                                    IsBlank(glbSelectedProtocolId),
                                    DisplayMode.Disabled,
                                    DisplayMode.Edit
                                )
                              Fill: =If(locSelectedTab = "Edit Protocoll", RGBA(255,255,255,1), RGBA(239,239,239,1))
                              FontWeight: =varTabFontWeight
                              Height: =32
                              HoverBorderColor: =varTabHoverFill
                              HoverFill: =varTabHoverFill
                              OnSelect: |
                                =/*  
                                    DEV-NOTES:
                                    Footer button "Protokoll bearbeiten". Opens ScrProtocol for the protocol
                                    currently selected in GalProtocols.

                                    Reads:  glbSelectedProtocolId, GalProtocols.Selected
                                    Writes: glbSelectedMeetingId, glbSelectedProtocolId
                                    Navigates to: ScrProtocol

                                    Process:
                                    1. Guard: glbSelectedProtocolId must be set
                                    2. Copy GalProtocols.Selected.protocolMeetingId → glbSelectedMeetingId
                                    3. Copy GalProtocols.Selected.protocolID → glbSelectedProtocolId
                                    4. Navigate

                                    @gaudenz

                                    Tags:
                                    #introduce-glbSelectedProtocolId
                                */

                                If(
                                    IsBlank(glbSelectedProtocolId),
                                    Notify("Bitte ein Thema oder Protokoll auswählen.", NotificationType.Warning),
                                    Set(glbSelectedMeetingId, GalProtocols.Selected.protocolMeetingId);
                                    Set(glbSelectedProtocolId, GalProtocols.Selected.protocolID);
                                    Navigate(ScrProtocol, ScreenTransition.Fade)
                                )
                              PressedBorderColor: |-
                                =// App.Theme.Colors.Darker40
                                Color.LightGray
                              PressedFill: |-
                                =// App.Theme.Colors.Darker40
                                Color.LightGray
                              RadiusBottomLeft: =6
                              RadiusBottomRight: =6
                              RadiusTopLeft: =6
                              RadiusTopRight: =6
                              Size: =varFooterBtnFontSize
                              Text: ="Protokoll bearbeiten"
                              Width: =140
      - ContDebugPanel:
          Control: GroupContainer@1.5.0
          Variant: ManualLayout
          Properties:
            Fill: =RGBA(255, 255, 255, 1)
            Height: =App.Height
            Width: =App.Width / 3
            X: |
              =If(
                  varDebugPanelVisible,
                  App.Width - ContDebugPanel.Width,
                  App.Width
              )
          Children:
            - ConDebugContent:
                Control: GroupContainer@1.5.0
                Variant: AutoLayout
                Properties:
                  Height: =Parent.Height
                  LayoutDirection: =LayoutDirection.Vertical
                  LayoutGap: =6
                  PaddingLeft: =10
                  PaddingRight: =20
                  PaddingTop: =17
                  Width: =Parent.Width
                Children:
                  - IcoToggleDebugPanelOut:
                      Control: Classic/Icon@2.5.0
                      Properties:
                        AlignInContainer: =AlignInContainer.End
                        BorderColor: =RGBA(0, 18, 107, 1)
                        Color: =RGBA(149, 149, 149, 1)
                        Height: =30
                        Icon: =Icon.NextArrow
                        OnSelect: |
                          =Set(varDebugPanelVisible, !varDebugPanelVisible)
                        Width: =30
                        X: =40
                        Y: =40
                  - GalDebugVarsEtc:
                      Control: Gallery@2.15.0
                      Variant: BrowseLayout_Vertical_TwoTextOneImageVariant_ver5.0
                      Properties:
                        BorderColor: =RGBA(0, 18, 107, 1)
                        Items: |
                          =colDebugVars
                        LayoutMaxHeight: =700
                        LayoutMaxWidth: '=350 '
                        LayoutMinHeight: =16
                        LayoutMinWidth: =16
                        TemplateSize: =60
                        Width: '=400 '
                        Y: '=40  '
                      Children:
                        - LblVarValue:
                            Control: Label@2.5.1
                            Properties:
                              BorderColor: =RGBA(0, 0, 0, 1)
                              Color: =RGBA(50, 49, 48, 1)
                              Font: =Font.'Open Sans'
                              FontWeight: =If(ThisItem.IsSelected, FontWeight.Semibold, FontWeight.Normal)
                              Height: =Self.Size * 1.8
                              OnSelect: =Select(Parent)
                              PaddingBottom: =0
                              PaddingLeft: =0
                              PaddingRight: =0
                              PaddingTop: =0
                              Size: =11
                              Text: |
                                =ThisItem.Value
                              VerticalAlign: =VerticalAlign.Top
                              Width: =Parent.TemplateWidth - 173
                              X: =1
                              Y: =25
                        - LblVarName:
                            Control: Label@2.5.1
                            Properties:
                              BorderColor: =RGBA(0, 0, 0, 1)
                              Font: =Font.'Open Sans'
                              FontWeight: =If(ThisItem.IsSelected, FontWeight.Semibold, FontWeight.Normal)
                              Height: =Self.Size * 1.8
                              OnSelect: =Select(Parent)
                              PaddingBottom: =0
                              PaddingLeft: =0
                              PaddingRight: =0
                              PaddingTop: =0
                              Size: =11
                              Text: |
                                =ThisItem.Name
                              VerticalAlign: =VerticalAlign.Top
                              Width: =LblVarValue.Width
                              X: =1
                              Y: =6
                        - IconNextArrowWhat:
                            Control: Classic/Icon@2.5.0
                            Properties:
                              AccessibleLabel: =Self.Tooltip
                              BorderColor: =RGBA(0, 0, 0, 1)
                              Color: =RGBA(166, 166, 166, 1)
                              DisabledBorderColor: =RGBA(56, 56, 56, 1)
                              DisabledColor: =RGBA(119, 119, 119, 1)
                              Height: =50
                              Icon: =Icon.ChevronRight
                              OnSelect: =Select(Parent)
                              PaddingBottom: =16
                              PaddingLeft: =16
                              PaddingRight: =16
                              PaddingTop: =16
                              Tooltip: ="View item details"
                              Width: =1
                  - BtnDebugCont:
                      Control: Classic/Button@2.2.0
                      Properties:
                        BorderColor: =ColorFade(Self.Fill, -15%)
                        Color: =RGBA(255, 255, 255, 1)
                        DisabledBorderColor: =RGBA(166, 166, 166, 1)
                        Fill: =RGBA(56, 96, 178, 1)
                        Font: =Font.'Open Sans'
                        HoverBorderColor: =ColorFade(Self.BorderColor, 20%)
                        HoverColor: =RGBA(255, 255, 255, 1)
                        HoverFill: =ColorFade(RGBA(56, 96, 178, 1), -20%)
                        LayoutMinHeight: =16
                        LayoutMinWidth: =16
                        OnSelect: |
                          =// Set(varDebugPanelVisible, !varDebugPanelVisible);


                          If(
                              varDebugPanelVisible,
                              // Debug variable viewer (script + collection counts)
                              ClearCollect(
                                  colDebugVars,
                                  { Name: "glbSelectedProtocolId", Value: Text(glbSelectedProtocolId) },
                                  { Name: "glbSelectedMeetingId", Value: Text(glbSelectedMeetingId) },
                                  { Name: "locSelectedTab", Value: Text(locSelectedTab) },
                                  { Name: "varDebugPanelVisible", Value: Text(varDebugPanelVisible) },

                                  // Collection counts
                                  { Name: "colMainMeetings.Count", Value: Text(CountRows(colMainMeetings)) },
                                  { Name: "colMainProtocols.Count", Value: Text(CountRows(colMainProtocols)) },
                                  { Name: "colMainParticipants.Count", Value: Text(CountRows(colMainParticipants)) },
                                  { Name: "colMainActions.Count", Value: Text(CountRows(colMainActions)) },
                                  { Name: "colCurrentActions.Count", Value: Text(CountRows(colCurrentActions)) }

                              )

                          );
                        PressedBorderColor: =Self.Fill
                        PressedColor: =Self.Fill
                        PressedFill: =Self.Color
                        Text: ="Refresh Vars"
      - ContCheckConcurrencyState_1:
          Control: GroupContainer@1.5.0
          Variant: ManualLayout
          Properties:
            BorderColor: =RGBA(0, 18, 107, 1)
            BorderThickness: =1
            Fill: =RGBA(232, 244, 217, 1)
            Height: =270
            Visible: =false
            Width: =1330
            X: =19
            Y: =480
          Children:
            - BtnRefreshScreen_1:
                Control: Classic/Button@2.2.0
                Properties:
                  BorderColor: =ColorFade(Self.Fill, -15%)
                  Color: =RGBA(255, 255, 255, 1)
                  DisabledBorderColor: =RGBA(166, 166, 166, 1)
                  Fill: =RGBA(56, 96, 178, 1)
                  Font: =Font.'Open Sans'
                  HoverBorderColor: =ColorFade(Self.BorderColor, 20%)
                  HoverColor: =RGBA(255, 255, 255, 1)
                  HoverFill: =ColorFade(RGBA(56, 96, 178, 1), -20%)
                  OnSelect: =Navigate(App.ActiveScreen, ScreenTransition.None);
                  PressedBorderColor: =Self.Fill
                  PressedColor: =Self.Fill
                  PressedFill: =Self.Color
                  Text: ="BtnRefreshScreen"
                  Width: =214
                  X: =1099
                  Y: =6
            - LblTraceMessage_1:
                Control: Label@2.5.1
                Properties:
                  BorderColor: =RGBA(0, 18, 107, 1)
                  BorderThickness: =1
                  Font: =Font.'Open Sans'
                  Height: =210
                  Text: =SCS.traceMessage
                  VerticalAlign: =VerticalAlign.Bottom
                  Width: =1303
                  X: =10
                  Y: =53
            - BtnPatchUserStatus_1:
                Control: Classic/Button@2.2.0
                Properties:
                  BorderColor: =ColorFade(Self.Fill, -15%)
                  Color: =RGBA(255, 255, 255, 1)
                  DisabledBorderColor: =RGBA(166, 166, 166, 1)
                  Fill: =RGBA(56, 96, 178, 1)
                  Font: =Font.'Open Sans'
                  HoverBorderColor: =ColorFade(Self.BorderColor, 20%)
                  HoverColor: =RGBA(255, 255, 255, 1)
                  HoverFill: =ColorFade(RGBA(56, 96, 178, 1), -20%)
                  OnSelect: "=/***********************************************************************************************************\r\n    @author: Chris\r\n    @date: 2026-09-17\r\n    @tags: #concurrency-control-patch-user-status\r\n\r\n    Create or update the current user's concurrency-state record in SharePoint and ensure that the\r\n    stored status accurately reflects the user's current editing state. SCS.targetStatusName must be \r\n    either \"edit-permission-requested\", \"edit-permission-granted\", or \"edit-permission-ignored\".\r\n\r\n    Called by\r\n    - BtnCheckConcurrencyState\r\n    - TimerCheckEditPermission\r\n    - TimerCheckUserIdle\r\n\r\n    Preconditions\r\n    - SCS.targetStatusName contains the status to be persisted.\r\n    - The current meeting or protocol context has already been stored in SCS.\r\n\r\n    1. Check whether SCS.targetStatusName contains a value.\r\n    2. Create local working variables:\r\n    - mId: current meeting ID\r\n    - pId: current protocol ID\r\n    - tsn: target status name\r\n    - rec: existing SharePoint record for the current user\r\n\r\n    3. Determine the status to persist:\r\n    - Use SCS.targetStatusName when a meeting or protocol context exists.\r\n    - Use \"edit-permission-ignored\" when no valid context exists.\r\n\r\n    4. Retrieve the current user's existing record from INT003_Concurrency_States_List.\r\n\r\n    5. Compare the existing SharePoint values with the target values.\r\n\r\n    6. If no record exists, or if at least one value differs:\r\n    - Execute Patch().\r\n    - Update State_Name.\r\n    - Update User_Email.\r\n    - Update Meeting_Id.\r\n    - Update Protocol_Id.\r\n    - Update Heartbeat.\r\n    - Create the record if necessary.\r\n    7. Handle any Patch() errors using IfError().\r\n    - Display an error notification when patching fails.\r\n    8. Optionally display a diagnostic notification showing the values written.\r\n    9. Clear SCS.targetStatusName.\r\n    10. Clear SCS.targetUserEmail\r\n    11. Start TimerCheckEditPermissionUser so that the current edit-permission owner\r\n        can be re-evaluated after the status update.\r\n\r\n    Globals\r\n    - glbUserEmail\r\n    - SCS.meetingId\r\n    - SCS.protocolId\r\n    - SCS.targetStatusName\r\n    - glbStartCheckEditPermissionUser\r\n\r\n    Local variables\r\n    - mId\r\n    - pId\r\n    - tsn\r\n    - rec\r\n\r\n    Data Sources\r\n    - INT003_Concurrency_States_List\r\n*/\r\nIf(\r\n    SCS.targetStatusName <> \"\" && glbUserEmail <> \"\" && !IsBlank(glbUserEmail),\r\n\r\n    With(\r\n        {\r\n            mId: SCS.meetingId,\r\n            pId: SCS.protocolId,\r\n            tsn: If(\r\n                SCS.meetingId > 0 || SCS.protocolId > 0, \r\n                SCS.targetStatusName, \r\n                \"edit-permission-ignored\"\r\n            ),\r\n            rec: LookUp(\r\n                INT003_Concurrency_States_List,\r\n                User_Email = glbUserEmail\r\n            )\r\n        },\r\n        If( // Only patch if the record does not yet exist or there is at least one different value.\r\n            IsBlank(rec) ||\r\n            rec.State_Name <> tsn ||\r\n            rec.Meeting_Id <> If(mId > 0, mId, -1) ||\r\n            rec.Protocol_Id <> If(pId > 0, pId, -1),\r\n            \r\n            IfError(\r\n                Patch(\r\n                    INT003_Concurrency_States_List, // #sp-patch\r\n                    Coalesce(\r\n                        rec,\r\n                        Defaults(INT003_Concurrency_States_List)\r\n                    ),\r\n                    {\r\n                        State_Name: tsn,\r\n                        User_Email: glbUserEmail,\r\n                        Meeting_Id: If(mId > 0, mId, -1),\r\n                        Protocol_Id: If(pId > 0, pId, -1),\r\n                        Heartbeat: Now()\r\n                    }\r\n                ),\r\n                Notify(\r\n                    \"Error while patching user status: \" & FirstError.Message,\r\n                    NotificationType.Error\r\n                );\r\n                Blank()\r\n            ); \r\n            // Notify(\"Patched tsn = \" & tsn & \", mId = \" & mId & \", pId = \" & pId)\r\n        )\r\n    )\r\n);\r\n\r\n// Finally reset targetStatusName and start timer that checks the user that has edit-permission.\r\nSet(SCS, Patch(SCS, {\r\n        targetStatusName: \"\",\r\n        targetUserEmail: \"\"\r\n}));\r\n\r\nSet(glbStartCheckEditPermissionUser, true);\r\n// ********************************************************************************************************/"
                  PressedBorderColor: =Self.Fill
                  PressedColor: =Self.Fill
                  PressedFill: =Self.Color
                  Text: ="Patch User Status"
                  Width: =204
                  X: =437
                  Y: =6
            - BtnCheckConcurrencyState_1:
                Control: Classic/Button@2.2.0
                Properties:
                  BorderColor: =ColorFade(Self.Fill, -15%)
                  Color: =RGBA(255, 255, 255, 1)
                  DisabledBorderColor: =RGBA(166, 166, 166, 1)
                  Fill: =RGBA(56, 96, 178, 1)
                  Font: =Font.'Open Sans'
                  HoverBorderColor: =ColorFade(Self.BorderColor, 20%)
                  HoverColor: =RGBA(255, 255, 255, 1)
                  HoverFill: =ColorFade(RGBA(56, 96, 178, 1), -20%)
                  OnSelect: |-
                    =/***********************************************************************************************************
                        @author: Chris
                        @date: 2026-09-23
                        @tags: #concurrency-control-register-edit-permission-request

                        Determine the current concurrency state for the active meeting or protocol and decide whether the
                        current user can edit immediately or must request edit permission.

                        Triggered by Screen.OnVisible

                        1. Refresh INT003_Concurrency_States_List and rebuild ColMain_ConcurrencyStates.
                        2. Determine which user currently holds edit permission for the active meeting or protocol and
                        store the result in SCS.editPermissionUserEmail.
                        3. Evaluate the current concurrency situation.
                        4. If no user currently holds edit permission:
                        - Prepare status "edit-permission-requested".
                        - Set the target user to the current user.
                        - Start TimerCheckEditPermission.
                        - Trigger BtnPatchUserStatus to register the request.
                        5. If the current user already holds edit permission:
                        - Set SCS.isEditable to true.
                        6. If another user holds edit permission:
                        - Set SCS.isEditable to false.
                        7. Start TimerCheckUserIdle.
                        8. Update SCS.traceMessage with the current concurrency status.

                        Globals
                        - glbUserEmail
                        - SCS
                        - glbStartCheckEditPermission
                        - glbStartCheckUserIdle

                        Collections
                        - ColMain_ConcurrencyStates

                        Data Sources
                        - INT003_Concurrency_States_List

                        Helper Functions
                        - EditPermissionUserEmail()
                        - ScreenStatusMessage()

                        Calls
                        - BtnPatchUserStatus
                    */

                    // Refresh ColMain_ConcurrencyStates from INT003_Concurrency_States_List to get the latest concurrency information in SharePoint.
                    Refresh(INT003_Concurrency_States_List);
                    ClearCollect(ColMain_ConcurrencyStates, INT003_Concurrency_States_List);

                    // Update editPermissionUserEmail as preparation for the next Switch().
                    Set(SCS, Patch(SCS, { editPermissionUserEmail: EditPermissionUserEmail(SCS.meetingId, SCS.protocolId)}));

                    Switch(
                        true,

                        /* -------------------------------------------------------------------------------------
                            Nobody has edit-permission yet: Request the edit-permission next and 
                            start the timer that evaluates the permission request after a timeout.
                        */
                        IsBlank(SCS.editPermissionUserEmail) || SCS.editPermissionUserEmail = "",
                        Set(SCS, Patch(SCS, { 
                            targetStatusName: "edit-permission-requested",
                            targetUserEmail: glbUserEmail
                        }));
                        Set(glbStartCheckEditPermission, true);
                        Select(BtnPatchUserStatus_1),

                        // The current user already has the edit-permission. -----------------------------------
                        SCS.editPermissionUserEmail = glbUserEmail,
                        Set(SCS, Patch(SCS, { isEditable: true })),

                        // Another user has the edit-permission already. ---------------------------------------
                        SCS.editPermissionUserEmail <> glbUserEmail,
                        Set(SCS, Patch(SCS, { isEditable: false }))
                    );

                    // Start "check-user-idle"-timer
                    Set(glbStartCheckUserIdle, true);

                    /*
                        @author: Chris
                        @date: 2026-09-15
                        @tags: #concurrency-control-trace-globals

                        Trace message with screen status data.
                    */
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
                    // ********************************************************************************************************/
                  PressedBorderColor: =Self.Fill
                  PressedColor: =Self.Fill
                  PressedFill: =Self.Color
                  Text: ="BtnCheckConcurrencyState"
                  Width: =313
                  X: =10
                  Y: =6
            - Label1_1:
                Control: Label@2.5.1
                Properties:
                  BorderColor: =RGBA(0, 18, 107, 1)
                  Font: =Font.'Open Sans'
                  Text: =glbIsUserIdleCount
                  X: =876
                  Y: =6
