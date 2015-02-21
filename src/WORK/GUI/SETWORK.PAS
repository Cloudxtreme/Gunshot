{$I DEFINES.INC}
UNIT SetWork;


INTERFACE


PROCEDURE SetupWork;
PROCEDURE GetWindowDefaults;


IMPLEMENTATION


USES BsString,Globals,Gr2_Bp,BsGraph,Bhandler,ObjSet;


PROCEDURE GetWindowDefaults;
VAR  Temp    : String;
     FFile   : Text;
     Work    : Word;
     Command : String;
BEGIN
     ASSIGN(FFile,'WINDOW.DEF');
     {$I-}RESET(FFile);{$I+}
     IF IOResult=0 THEN
     BEGIN
          REPEAT
                READLN(FFile,Temp);
                Work := Pos('=',Temp);
                IF Work<>0 THEN
                BEGIN
                     Command := _UpperCase(_Mid(Temp,1,Work-1));
                     Delete(Temp,1,Work);
                     Work := _Numeric(Temp);
                          IF Command='WINDOWBACKGROUND' THEN HoldRaw.Colour1 := Work
                     ELSE IF Command='WINDOWBORDER' THEN HoldRaw.Colour2 := Work
                     ELSE IF Command='WINDOWHIGHLIGHT' THEN HoldRaw.Colour3 := Work
                     ELSE IF Command='WINDOWSHADOW' THEN HoldRaw.Colour4 := Work
                     ELSE IF Command='HEADERBACKGROUND' THEN HoldRaw.Colour5 := Work
                     ELSE IF Command='HEADERHIGHLIGHT' THEN HoldRaw.Colour6 := Work
                     ELSE IF Command='HEADERSHADOW' THEN HoldRaw.Colour7 := Work
                     ELSE IF Command='HEADERTEXT' THEN HoldRaw.Colour8 := Work
                     ELSE IF Command='WINDOWSTYLE' THEN HoldRaw.Style := Work;
                END;
          UNTIL EOF(FFile);
          CLOSE(FFile);
     END;
END;


PROCEDURE SetupWork;
VAR  LoopX   : Word;
     LoopY   : Word;
     X,Y     : Word;
     Counter : Word;
BEGIN
     GrSetFillStyle(GrFSolid,0,GrOpaque);
     GrDrawRect(0,0,GraphMaxX,YWindow,GrFill);
     GrSetFillStyle(GrFSolid,WindowBack,GrOpaque);
     GrDrawRect(0,YWindow+2,639,GraphMaxY-1,GrFill);
     GrSetColor(WindowHigh); GrDrawLine(0,YWindow+1,639,YWindow+1);
     GrSetColor(WindowLow);  GrDrawLine(0,GraphMaxY,639,GraphMaxY);
     GrSetColor(WindowHigh); GrDrawLine(503,YWindow+1,503,GraphMaxY-1);
     GrSetColor(WindowLow);  GrDrawLine(502,YWindow+1,502,GraphMaxY-1);
     GrSetColor(WindowHigh); GrDrawLine(428,YWindow+1,428,GraphMaxY-1);
     GrSetColor(WindowLow);  GrDrawLine(427,YWindow+1,427,GraphMaxY-1);
     GrSetColor(WindowHigh); GrDrawLine(382,YWindow+1,382,GraphMaxY-1);
     GrSetColor(WindowLow);  GrDrawLine(381,YWindow+1,381,GraphMaxY-1);
     NButtons := 0;
     SystemButton(600,YWindow+17,630,YWindow+47,1,False,True);
     SystemButton(510,YWindow+17,570,YWindow+47,1,False,True);
     SystemButton(570,YWindow+17,600,YWindow+47,1,False,True);
     SystemButton(480,YWindow+16,495,YWindow+31,1,False,True);
     SystemButton(480,YWindow+31,495,YWindow+46,1,False,True);
     SystemButton(390,YWindow+16,420,YWindow+46,1,False,True);
     ASSIGN(FWorkSG,WorkDir+'TEMPWORK.$$$');
     REWRITE(FWorkSG);
     {SCREEN BACKGROUND}
     FillChar(WorkSG,SizeOf(WorkSG),0);
     WorkSG.Number  := 1;
     WorkSG.Style   := 2;  {0-Solid 1-Icon 2-None}
     WorkSG.Colour1 := 0;  {Colour}
     WorkSG.Colour4 := 94;
     WorkSG.ObjFile := 'ICONLIB1.30';
     WRITE(FWorkSG,WorkSG);
     {SCREEN MOUSE}
     FillChar(WorkSG,SizeOf(WorkSG),0);
     WorkSG.Number  := 2;
     WorkSG.Style   := 0; {0-No Change 1-Change}
     WorkSG.ObjFile := 'MOUSELIB.MSE';
     WorkSG.Colour1 := 1;
     WRITE(FWorkSG,WorkSG);
     {SCREEN SOUND}
     FillChar(WorkSG,SizeOf(WorkSG),0);
     WorkSG.Number  := 3;
     WorkSG.Style   := 0; {0-None 1-VOC File 2-Music File}
     WorkSG.ObjFile := '';
     WRITE(FWorkSG,WorkSG);
     CLOSE(FWorkSG);

     {VARIABLES}
     Grid             := 5;
     MouseOn          := False;
     DrawMode         := True;
     DrawingSomething := False;
     DoARedraw        := False;
     ObjectNumber     := 0;
     CurrentFile      := 'UNTITLED.SG';

     {SETUP OPENING DRAWING TOOL}
     HoldRaw.number   := 4;   {Lines}
     HoldRaw.colour1  := 15;  {Colour}
     HoldRaw.colour2  := 1;   {Line Thickness}
     ScreenSetup4;
END;


END.
