{$I DEFINES.INC}
UNIT Config;


INTERFACE


PROCEDURE DoConfiguration;
PROCEDURE LoadConfiguration;


IMPLEMENTATION


USES Globals,__Gfx,BsMulti,Crt,BsFile,BsString,
     {$IFDEF DPMI}
     Gr2_Bp;
     {$ELSE}
     Gr_Tp;
     {$ENDIF}


PROCEDURE LoadConfiguration;
VAR  FFile : File;
     BRead : Word;
BEGIN
     FillChar(CommDef,SizeOf(CommDef),0);
     IF _FileExists('SGT.CFG') THEN
     BEGIN
          ASSIGN(FFile,'SGT.CFG');
          RESET(FFile,1);
          BLOCKREAD(FFile,CommDef,SizeOf(CommDef),BRead);
          CLOSE(FFile);
     END
     ELSE
     BEGIN
          CommDef.Device       := 1;
          CommDef.Port         := 1;
          CommDef.PortAddr     := '0';
          CommDef.Irq          := 0;
          CommDef.Baud         := 8;
          CommDef.DataInit     := 'AT&F&C1&D2&K3V1E1X4W2S95=2M0H0';
          CommDef.FaxInit      := 'ATE0Q0V1X4S0=0&K5';
          CommDef.Hangup       := '~~+++~ATH0';
          CommDef.DPrefix      := 'ATDT';
          CommDef.UlDir        := 'C:\';
          CommDef.DlDir        := 'C:\';
          CommDef.VideoMode    := 0;
          CommDef.DialTimeout  := 15;
          CommDef.CommandDelay := 500;
          CommDef.DataInit2    := '';
          CommDef.DataInit3    := '';
          CommDef.YappToUse    := 2;
          ASSIGN(FFile,'SGT.CFG');
          REWRITE(FFile,1);
          BLOCKWRITE(FFile,CommDef,SizeOf(CommDef));
          CLOSE(FFile);
     END;
     IF CommDef.DialTimeout=0 THEN CommDef.DialTimeout  := 15;
     IF CommDef.CommandDelay=0 THEN CommDef.CommandDelay := 500;
END;


PROCEDURE DoModemSelect;
VAR  C    : Word;
     DoIt : Boolean;
BEGIN
     grDisplayMouse(GrHide);
     DrawWindow(50,40,590,450,'MODEM SELECTION',3);
     NewPickList(60,75,21,60,True);
     ASSIGN(FModems,'MODEMS.DAT');
     {$I-}RESET(FModems);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READ(FModems,Modems);
                AddToPickList(Modems.ModemName);
          UNTIL EOF(FModems);
          CLOSE(FModems);
     END;
     SetUpPickList;
     DoOkButton(500,400);
     grDisplayMouse(GrShow);
     DoIt := False;
     REPEAT
           c := MouseHandler(False);
           CASE C OF
           0:   TimeSlice;
           3:   IF (PickInfo.Current<>0) THEN
                BEGIN
                     DoIt := True;
                     ASSIGN(FModems,'MODEMS.DAT');
                     RESET(FModems);
                     SEEK(FModems,PickInfo.Current-1);
                     READ(FModems,Modems);
                     CLOSE(FModems);
                END;
           END;
     UNTIL C=NButtons;
     KillWindow;
     IF DoIt THEN
     BEGIN
          IF VerifySave('Doing this will replace your existing init',
                        'strings with preset defaults. Do you wish',
                        'to continue?') THEN
          BEGIN
               CommDef.DataInit     := Modems.Init1;
               CommDef.DataInit2    := Modems.Init2;
               CommDef.DataInit3    := Modems.Init3;
               CommDef.DPrefix      := Modems.DialString;
               CommDef.Hangup       := Modems.Hangup;
               CommDef.CommandDelay := Modems.CommandDelay;
               GrDisplayMouse(GrHide);
               ChangeField(1);
               Fields[1].Text := CommDef.DataInit;
               Fields[1].CursorPos := LENGTH(Fields[1].Text)+1;
               RedrawField;
               ChangeField(2);
               Fields[2].Text := CommDef.DataInit2;
               Fields[2].CursorPos := LENGTH(Fields[2].Text)+1;
               RedrawField;
               ChangeField(3);
               Fields[3].Text := CommDef.DataInit3;
               Fields[3].CursorPos := LENGTH(Fields[3].Text)+1;
               RedrawField;
               ChangeField(5);
               Fields[5].Text := CommDef.Hangup;
               Fields[5].CursorPos := LENGTH(Fields[5].Text)+1;
               RedrawField;
               ChangeField(6);
               Fields[6].Text := _String(CommDef.CommandDelay);
               Fields[6].CursorPos := LENGTH(Fields[6].Text)+1;
               RedrawField;
               ChangeField(7);
               Fields[7].Text := CommDef.DPrefix;
               Fields[7].CursorPos := LENGTH(Fields[7].Text)+1;
               RedrawField;
               ChangeField(1);
               GrDisplayMouse(GrShow);
          END;
     END;
END;


PROCEDURE DoConfiguration;
VAR  C     : Word;
     FFile : File;
     BRead : Word;

     PROCEDURE DrawComPort;
     VAR  Loop : Word;
     BEGIN
          FOR Loop := 1 TO 8 DO
          BEGIN
               IF CommDef.Port=Loop THEN GrSetFillStyle(GrFSolid,4,GrOpaque)
                                    ELSE GrSetFillStyle(GrFSolid,7,GrOpaque);
               GrDrawRect(Buttons[Loop].x1+4,Buttons[Loop].y1+4,
                          Buttons[Loop].x1+9,Buttons[Loop].y1+9,GrFill);
          END;
     END;

     PROCEDURE DrawBaudRate;
     VAR  Loop : Word;
     BEGIN
          FOR Loop := 1 TO 8 DO
          BEGIN
               IF CommDef.Baud=Loop+2 THEN GrSetFillStyle(GrFSolid,4,GrOpaque)
                                      ELSE GrSetFillStyle(GrFSolid,7,GrOpaque);
               GrDrawRect(Buttons[8+Loop].x1+4,Buttons[8+Loop].y1+4,
                          Buttons[8+Loop].x1+9,Buttons[8+Loop].y1+9,GrFill);
          END;
     END;

     PROCEDURE DrawDevice;
     VAR  Loop : Word;
     BEGIN
          FOR Loop := 1 TO 3 DO
          BEGIN
               IF CommDef.Device=Loop THEN GrSetFillStyle(GrFSolid,4,GrOpaque)
                                      ELSE GrSetFillStyle(GrFSolid,7,GrOpaque);
               GrDrawRect(Buttons[16+Loop].x1+4,Buttons[16+Loop].y1+4,
                          Buttons[16+Loop].x1+9,Buttons[16+Loop].y1+9,GrFill);
          END;
     END;

     PROCEDURE DrawVideoMode;
     VAR  Loop : Word;
     BEGIN
          FOR Loop := 1 TO 3 DO
          BEGIN
               IF CommDef.VideoMode=Loop-1 THEN GrSetFillStyle(GrFSolid,4,GrOpaque)
                                           ELSE GrSetFillStyle(GrFSolid,7,GrOpaque);
               GrDrawRect(Buttons[19+Loop].x1+4,Buttons[19+Loop].y1+4,
                          Buttons[19+Loop].x1+9,Buttons[19+Loop].y1+9,GrFill);
          END;
     END;

     PROCEDURE CheckDevice;
     BEGIN
          Buttons[15].Enabled := True;
          Buttons[16].Enabled := True;
          SystemIcon(Buttons[15].x1,Buttons[15].y1,51);
          SystemIcon(Buttons[16].x1,Buttons[16].y1,51);
          DrawBaudRate;
     END;

BEGIN
     LoadConfiguration;
     grDisplayMouse(GrHide);
     DrawWindow(5,5,630,470,'CONFIGURATION & SETUP',4);
     InvertedBox(15,40,620,195);

     C := 45;
     SystemField(160,C,0,50,CommDef.DataInit);
       OutTextXYFR(145,C+2,1,255,1,'Data Init String #1:'); INC(C,25);
     SystemField(160,C,0,50,CommDef.DataInit2);
       OutTextXYFR(145,C+2,1,255,1,'Data Init String #2:'); INC(C,25);
     SystemField(160,C,0,50,CommDef.DataInit3);
       OutTextXYFR(145,C+2,1,255,1,'Data Init String #3:'); INC(C,25);
     SystemField(160,C,0,50,CommDef.FaxInit);
       OutTextXYFR(145,C+2,1,255,1,'Fax Init String:'); INC(C,25);
     SystemField(160,C,0,20,CommDef.Hangup);
       OutTextXYFR(145,C+2,1,255,1,'Hangup String:');
     SystemField(528,C,1,4,_String(CommDef.CommandDelay));
       OutTextXYFR(513,C+2,1,255,1,'MS Between Init Strings:'); INC(C,25);
     SystemField(160,C,0,20,CommDef.DPrefix);
       OutTextXYFR(145,C+2,1,255,1,'Dial Prefix:');
     SystemField(528,C,1,4,_String(CommDef.DialTimeout));
       OutTextXYFR(513,C+2,1,255,1,'Seconds Between Calls:');

     GrSetFillStyle(GrFSolid,242,GrOpaque);
     GrDrawRect(15,205,620,220,GrFill);
     OutTextXY(20,205,15,255,1,'Default Directories');
     InvertedBox(15,225,620,280);
     SystemField(160,230,0,50,CommDef.DLDir);
     SystemField(160,255,0,50,CommDef.ULDir);
     OutTextXYFR(145,232,1,255,1,'Download Directory:');
     OutTextXYFR(145,257,1,255,1,'Upload Directory:');

     GrSetFillStyle(GrFSolid,242,GrOpaque);
     GrDrawRect(15,290,460,305,GrFill);
     OutTextXY(20,290,15,255,1,'Com Port Configuration');
     InvertedBox(15,310,460,460);

     C := 315;
     SystemButton(85,C,0,0,4,False,True); OutTextXY(40,C,1,255,1,'Com 1'); INC(C,18);
     SystemButton(85,C,0,0,4,False,True); OutTextXY(40,C,1,255,1,'Com 2'); INC(C,18);
     SystemButton(85,C,0,0,4,False,True); OutTextXY(40,C,1,255,1,'Com 3'); INC(C,18);
     SystemButton(85,C,0,0,4,False,True); OutTextXY(40,C,1,255,1,'Com 4'); INC(C,18);
     SystemButton(85,C,0,0,4,False,True); OutTextXY(40,C,1,255,1,'Com 5'); INC(C,18);
     SystemButton(85,C,0,0,4,False,True); OutTextXY(40,C,1,255,1,'Com 6'); INC(C,18);
     SystemButton(85,C,0,0,4,False,True); OutTextXY(40,C,1,255,1,'Com 7'); INC(C,18);
     SystemButton(85,C,0,0,4,False,True); OutTextXY(40,C,1,255,1,'Com 8');

     C := 315;
     SystemButton(205,C,0,0,4,False,True); OutTextXYFR(195,C,1,255,1,'1200 BPS'); INC(C,18);
     SystemButton(205,C,0,0,4,False,True); OutTextXYFR(195,C,1,255,1,'2400 BPS'); INC(C,18);
     SystemButton(205,C,0,0,4,False,True); OutTextXYFR(195,C,1,255,1,'4800 BPS'); INC(C,18);
     SystemButton(205,C,0,0,4,False,True); OutTextXYFR(195,C,1,255,1,'9600 BPS'); INC(C,18);
     SystemButton(205,C,0,0,4,False,True); OutTextXYFR(195,C,1,255,1,'19200 BPS'); INC(C,18);
     SystemButton(205,C,0,0,4,False,True); OutTextXYFR(195,C,1,255,1,'38400 BPS'); INC(C,18);
     SystemButton(205,C,0,0,4,False,True); OutTextXYFR(195,C,1,255,1,'57600 BPS'); INC(C,18);
     SystemButton(205,C,0,0,4,False,True); OutTextXYFR(195,C,1,255,1,'115200 BPS');

     C := 315;
     SystemButton(335,C,0,0,4,False,True); OutTextXYFR(325,C,1,255,1,'16550 UART'); INC(C,18);
     SystemButton(335,C,0,0,4,False,True); OutTextXYFR(325,C,1,255,1,'Fossil Driver'); INC(C,18);
     SystemButton(335,C,0,0,4,False,True); OutTextXYFR(325,C,1,255,1,'DigiBoard');

     SystemField(335,380,0,4,CommDef.PortAddr);     OutTextXYFR(325,382,1,255,1,'* Port Address');
     SystemField(335,405,1,2,_String(CommDef.Irq)); OutTextXYFR(325,407,1,255,1,'* Port IRQ');
     OutTextXY(230,441,8,255,1,'* Leave as "0" to use default settings');

     GrSetFillStyle(GrFSolid,242,GrOpaque);
     GrDrawRect(470,290,620,305,GrFill);
     OutTextXY(475,290,15,255,1,'YAPP Settings');
     InvertedBox(470,310,620,370);

     C := 315;
     SystemButton(595,C,0,0,4,False,True); OutTextXYFR(585,C,1,255,1,'640x480x256'); INC(C,18);
     SystemButton(595,C,0,0,4,False,True); OutTextXYFR(585,C,1,255,1,'800x600x256'); INC(C,18);
     SystemButton(595,C,0,0,4,False,True); OutTextXYFR(585,C,1,255,1,'1024x768x256');

     SystemButton(20,170,75,190,1,False,True);
     OutTextXY(30,174,0,255,5,'Modem');

     DoOkButton(540,420);
     CheckDevice;
     DrawComPort;
     DrawDevice;
     DrawVideoMode;
     grDisplayMouse(GrShow);
     REPEAT
           c := MouseHandler(True);
           CASE C OF
           0:       TimeSlice;
           1..8:    BEGIN
                         CommDef.Port := c;
                         grDisplayMouse(GrHide);
                         DrawComPort;
                         grDisplayMouse(GrShow);
                    END;
           9..16:   BEGIN
                         CommDef.Baud := c-6;
                         grDisplayMouse(GrHide);
                         DrawBaudRate;
                         grDisplayMouse(GrShow);
                    END;
           17..19:  BEGIN
                         CommDef.Device := c-16;
                         grDisplayMouse(GrHide);
                         CheckDevice;
                         DrawDevice;
                         grDisplayMouse(GrShow);
                    END;
           20..22:  BEGIN
                         CommDef.VideoMode := c-20;
                         grDisplayMouse(GrHide);
                         DrawVideoMode;
                         grDisplayMouse(GrShow);
                    END;
           23:      BEGIN
                         DoModemSelect;
                    END;
           END;
     UNTIL c=NButtons;
     CommDef.DataInit     := Fields[1].Text;
     CommDef.DataInit2    := Fields[2].Text;
     CommDef.DataInit3    := Fields[3].Text;
     CommDef.FaxInit      := Fields[4].Text;
     CommDef.Hangup       := Fields[5].Text;
     CommDef.CommandDelay := _Numeric(Fields[6].Text);
     CommDef.DPrefix      := Fields[7].Text;
     CommDef.DialTimeout  := _Numeric(Fields[8].Text);
     CommDef.DLDir        := _Path(Fields[9].Text);
     CommDef.ULDir        := _Path(Fields[10].Text);
     CommDef.PortAddr     := Fields[11].Text;
     CommDef.Irq          := _Numeric(Fields[12].Text);
     _CreatePath(CommDef.DLDir);
     _CreatePath(CommDef.ULDir);
     KillWindow;
     ASSIGN(FFile,'SGT.CFG');
     REWRITE(FFile,1);
     BLOCKWRITE(FFile,CommDef,SizeOf(CommDef));
     CLOSE(FFile);
END;


END.
