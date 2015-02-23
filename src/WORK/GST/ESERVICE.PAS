{$I DEFINES.INC}
UNIT EService;


INTERFACE


PROCEDURE EditService(Index: Word);


IMPLEMENTATION


USES Globals,__Gfx,BsMulti,BsString,
     {$IFDEF DPMI}
     Gr2_Bp;
     {$ELSE}
     Gr_Tp;
     {$ENDIF}


PROCEDURE EditService(Index: Word);
VAR  C    : Word;
     Temp : String;

     PROCEDURE DrawMailerBypass;
     BEGIN
          IF DialDir.DoESCs THEN GrSetFillStyle(GrFSolid,4,GrOpaque)
                            ELSE GrSetFillStyle(GrFSolid,7,GrOpaque);
          GrDrawRect(Buttons[1].x1+4,Buttons[1].y1+4,
                     Buttons[1].x1+9,Buttons[1].y1+9,GrFill);
     END;

     PROCEDURE DrawSound;
     BEGIN
          IF DialDir.Sound THEN GrSetFillStyle(GrFSolid,4,GrOpaque)
                           ELSE GrSetFillStyle(GrFSolid,7,GrOpaque);
          GrDrawRect(Buttons[2].x1+4,Buttons[2].y1+4,
                     Buttons[2].x1+9,Buttons[2].y1+9,GrFill);
     END;

BEGIN
     ASSIGN(FDialDir,'GST.DIR');
     RESET(FDialDir);
     SEEK(FDialDir,Index-1);
     READ(FDialDir,DialDir);
     CLOSE(FDialDir);
     grDisplayMouse(GrHide);
     DrawWindow(15,30,620,420,'EDIT SERVICE',2);
     SystemField(140,70,2,30,DialDir.Name);      OutTextXYFR(130,72,1,255,1,'System Name:');
     SystemField(140,95,4,20,DialDir.Phone);     OutTextXYFR(130,97,1,255,1,'Phone Number:');
     SystemField(140,130,2,30,DialDir.Logon);    OutTextXYFR(130,132,1,255,1,'Your Login:');
     SystemField(140,155,0,20,DialDir.Password); OutTextXYFR(130,157,1,255,1,'Your Password:');
     SystemButton(570,140,0,0,4,False,True);     OutTextXYFR(560,140,1,255,1,'Mailer Bypass');
     SystemButton(570,160,0,0,4,False,True);     OutTextXYFR(560,160,1,255,1,'Sound Blaster');
     GrSetFillStyle(GrFSolid,242,GrOpaque);
     GrDrawRect(20,195,615,210,GrFill);
     OutTextXY(25,195,15,255,1,'Function Keys');
     SystemField(50,225,0,30,DialDir.F1);   OutTextXYFR(45,227,1,255,1,'F1:');
     SystemField(50,250,0,30,DialDir.F2);   OutTextXYFR(45,252,1,255,1,'F2:');
     SystemField(50,275,0,30,DialDir.F3);   OutTextXYFR(45,277,1,255,1,'F3:');
     SystemField(50,300,0,30,DialDir.F4);   OutTextXYFR(45,302,1,255,1,'F4:');
     SystemField(50,325,0,30,DialDir.F5);   OutTextXYFR(45,327,1,255,1,'F5:');
     SystemField(345,225,0,30,DialDir.F6);  OutTextXYFR(340,227,1,255,1,'F6:');
     SystemField(345,250,0,30,DialDir.F7);  OutTextXYFR(340,252,1,255,1,'F7:');
     SystemField(345,275,0,30,DialDir.F8);  OutTextXYFR(340,277,1,255,1,'F8:');
     SystemField(345,300,0,30,DialDir.F9);  OutTextXYFR(340,302,1,255,1,'F9:');
     SystemField(345,325,0,30,DialDir.F10); OutTextXYFR(340,327,1,255,1,'F10:');
     InvertedBox(20,215,615,360);
     DrawMailerBypass;
     DrawSound;
     DoOkButton(530,370);
     grDisplayMouse(GrShow);
     REPEAT
           c := MouseHandler(True);
           CASE C OF
           0:   TimeSlice;
           1:   BEGIN
                     IF DialDir.DoESCs THEN DialDir.DoESCs := False
                                       ELSE DialDir.DoESCs := True;
                     grDisplayMouse(GrHide);
                     DrawMailerBypass;
                     grDisplayMouse(GrShow);
                END;
           2:   BEGIN
                     IF DialDir.Sound THEN DialDir.Sound := False
                                      ELSE DialDir.Sound := True;
                     grDisplayMouse(GrHide);
                     DrawSound;
                     grDisplayMouse(GrShow);
                END;
           END;
     UNTIL c=NButtons;
     DialDir.Name     := Fields[1].Text;
     DialDir.Phone    := Fields[2].Text;
     DialDir.Logon    := Fields[3].Text;
     DialDir.Password := Fields[4].Text;
     DialDir.F1       := Fields[5].Text;
     DialDir.F2       := Fields[6].Text;
     DialDir.F3       := Fields[7].Text;
     DialDir.F4       := Fields[8].Text;
     DialDir.F5       := Fields[9].Text;
     DialDir.F6       := Fields[10].Text;
     DialDir.F7       := Fields[11].Text;
     DialDir.F8       := Fields[12].Text;
     DialDir.F9       := Fields[13].Text;
     DialDir.F10      := Fields[14].Text;
     KillWindow;
     ASSIGN(FDialDir,'GST.DIR');
     RESET(FDialDir);
     SEEK(FDialDir,Index-1);
     WRITE(FDialDir,DialDir);
     CLOSE(FDialDir);
     Temp := ' '+_PadRight(DialDir.Name,30)+_PadRight(DialDir.Phone,20);
     PickList^[Index] := _PadRight(Temp,PickInfo.MaxChars);
     grDisplayMouse(GrHide);
     SetUpPickList;
     grDisplayMouse(GrShow);
END;


END.