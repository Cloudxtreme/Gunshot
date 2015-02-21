{$I DEFINES.INC}
UNIT _VSave;


INTERFACE


FUNCTION VerifySave(InString1,InString2,InString3: String): Boolean;


IMPLEMENTATION


USES _Win,Gr2_Bp,Globals,BHandler,_Icons,_Text;


FUNCTION VerifySave(InString1,InString2,InString3: String): Boolean;
VAR  C : Word;
BEGIN
     SaveWindow(4);
     GrDisplayMouse(GrHide);
     NButtons := 0;
     DrawWindow(170,120,469,260,'WARNING!!!',LoadSaveWarning);
     SystemButton(180,210,315,250,1,False,True);
     SystemButton(325,210,459,250,1,False,True);
     SystemIcon(190,215,65);
     SystemIcon(335,215,64);
     SystemIcon(180,160,62);
     OutTextXY(245,225,0,255,1,'Yes');
     OutTextXY(390,225,0,255,1,'No');
     OutTextXY(215,154,0,255,1,InString1);
     OutTextXY(215,170,0,255,1,InString2);
     OutTextXY(215,186,0,255,1,InString3);
     GrDisplayMouse(GrShow);
     REPEAT
           C := MouseHandler(False);
           CASE C OF
           1:   VerifySave := True;
           2:   VerifySave := False;
           END;
     UNTIL (C<>0);
     KillWindow;
     ReloadWindow(4);
END;


END.