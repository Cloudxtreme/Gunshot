{$I DEFINES.INC}
UNIT _FSelect;


INTERFACE


FUNCTION FileSelector(Path,Spec1,Spec2: String; VAR FName: String; AllowOpen,AllowNew,IsSave: Boolean): Byte;


IMPLEMENTATION


USES Dos,_Win,BsString,Gr2_Bp,Globals,_Text,BHandler,PickLst,Crt,BsFile;


FUNCTION FileSelector(Path,Spec1,Spec2: String; VAR FName: String; AllowOpen,AllowNew,IsSave: Boolean): Byte;
VAR  NumFiles    : Word;
     DirInfo     : SearchRec;
     Temp        : String;
     Temp2       : String;
     Loop        : Word;
     Work        : Word;
     Top         : Word;
     Bot         : Word;
     AllDone     : Boolean;
     DoJob       : Word;
     TypeWindowX : Word;
     TypeWindowY : Word;
     C           : Char;
     DT          : DateTime;
     FileTime    : Longint;
     YY,MM,DD    : String;
     EditPos     : Word;
     x,y         : Word;
     I,J         : Word;
     Current     : Word;
     TmpPick     : String[60];
LABEL              SkipHandler;
BEGIN
     SaveWindow(4);
     IF Path[Length(Path)]='\' THEN Delete(Path,Length(Path),1);
     NumFiles := 0;
     GrDisplayMouse(GrHide);
     NButtons := 0;
     DrawWindow(150,50,405,360,'FILE SELECTOR',FileBoxWindow);
     {Space definitions}
     TypeWindowX := ScreenInfo.OrigX1+ScreenInfo.XOffset+15;
     TypeWindowY := ScreenInfo.OrigY1+ScreenInfo.YOffset+53;
     {Window Text}
     OutTextXY(ScreenInfo.OrigX1+10,ScreenInfo.OrigY1+35,1,255,1,'Filename:');
     OutTextXY(ScreenInfo.OrigX1+10,ScreenInfo.OrigY1+80,1,255,1,'Files:');
     {Window Areas}
     GrSetColor(0);
     GrSetLineStyle(GrLCloseDot,1);
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     GrDrawRect(ScreenInfo.OrigX1+10,ScreenInfo.OrigY1+50,ScreenInfo.OrigX1+229,ScreenInfo.OrigY1+70,GrFill+GrOutline);
     GrSetLineStyle(GrLSolid,1);
     InvertedBox(ScreenInfo.OrigX1+9,ScreenInfo.OrigY1+49,ScreenInfo.OrigX1+230,ScreenInfo.OrigY1+71);
     {Buttons}
     SystemButton(ScreenInfo.OrigX1+10,ScreenInfo.OrigY1+270,ScreenInfo.OrigX1+75,ScreenInfo.OrigY1+300,1,False,True);
     IF NOT(AllowOpen) THEN DEC(NButtons);
     SystemButton(ScreenInfo.OrigX1+80,ScreenInfo.OrigY1+270,ScreenInfo.OrigX1+145,ScreenInfo.OrigY1+300,1,False,True);
     IF NOT(AllowNew)  THEN DEC(NButtons);
     SystemButton(ScreenInfo.OrigX1+150,ScreenInfo.OrigY1+270,ScreenInfo.OrigX1+215,ScreenInfo.OrigY1+300,1,False,True);
     IF NOT(AllowOpen) THEN OutTextXY(ScreenInfo.OrigX1+30,ScreenInfo.OrigY1+277,8,255,1,'Load')
                       ELSE OutTextXY(ScreenInfo.OrigX1+30,ScreenInfo.OrigY1+277,0,255,1,'Load');
     IF IsSave THEN
     BEGIN
          IF NOT(AllowNew) THEN OutTextXY(ScreenInfo.OrigX1+100,ScreenInfo.OrigY1+277,8,255,1,'Save')
                           ELSE OutTextXY(ScreenInfo.OrigX1+100,ScreenInfo.OrigY1+277,0,255,1,'Save');
     END
     ELSE
     BEGIN
          IF NOT(AllowNew) THEN OutTextXY(ScreenInfo.OrigX1+95,ScreenInfo.OrigY1+277,8,255,1,'Create')
                           ELSE OutTextXY(ScreenInfo.OrigX1+95,ScreenInfo.OrigY1+277,0,255,1,'Create');
     END;
     OutTextXY(ScreenInfo.OrigX1+165,ScreenInfo.OrigY1+277,0,255,1,'Cancel');
     {Stuffed Filename}
     OutTextXY(ScreenInfo.OrigX1+15,ScreenInfo.OrigY1+53,0,15,2,FName);
     OutTextXY(ScreenInfo.OrigX1+15+(Length(FName)*8),ScreenInfo.OrigY1+54,0,15,2,'_');

     NewPickList(ScreenInfo.OrigX1+ScreenInfo.XOffset+11,
                 ScreenInfo.OrigY1+ScreenInfo.YOffset+96,10,24);

     {CHECK THE FIRST SPEC}
     FindFirst(Path+'\'+Spec1,Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          Temp := _UpperCase(DirInfo.Name);
          INC(NumFiles);
          FileTime := DirInfo.Time;
          UnpackTime(FileTime,dt);
          WITH dt DO
          BEGIN
               YY    := _String(Year);
               MM    := _String(Month); IF Length(MM)=1 THEN MM := '0'+MM;
               DD    := _String(Day);   IF Length(DD)=1 THEN DD := '0'+DD;
               Temp2 := _PadRight(_NoExtension(Temp)+'.'+
                        _GetFileExtension(Temp),14)+
                        MM+'-'+DD+'-'+YY;
          END;
          AddToPickList(Temp2);
          FindNext(DirInfo);
     END;
     {CHECK THE SECOND SPEC}
     IF Spec2<>'' THEN
     BEGIN
          FindFirst(Path+'\'+Spec2,Anyfile-Directory-VolumeID,DirInfo);
          WHILE DosError = 0 DO
          BEGIN
               Temp := _UpperCase(DirInfo.Name);
               INC(NumFiles);
               FileTime := DirInfo.Time;
               UnpackTime(FileTime,dt);
               WITH dt DO
               BEGIN
                    YY    := _String(Year);
                    MM    := _String(Month); IF Length(MM)=1 THEN MM := '0'+MM;
                    DD    := _String(Day);   IF Length(DD)=1 THEN DD := '0'+DD;
                    Temp2 := _PadRight(_NoExtension(Temp)+'.'+
                             _GetFileExtension(Temp),14)+
                             MM+'-'+DD+'-'+YY;
               END;
               AddToPickList(Temp2);
               FindNext(DirInfo);
          END;
     END;
     PickInfo.Current := 0;
     Current          := 0;
     {Sort The File Names}
     FOR i := 1 TO PickInfo.NumItems DO
     BEGIN
          FOR j := 1 TO PickInfo.NumItems DO
          BEGIN
               IF PickList^[i]<PickList^[j] THEN
               BEGIN
                    TmpPick := PickList^[i];
                    PickList^[i] := PickList^[j];
                    PickList^[j] := TmpPick;
               END;
          END;
     END;
     SetUpPickList;
     GrDisplayMouse(GrShow);
     AllDone := False;
     EditPos := Length(FName)+1;
     REPEAT
           TypeWindowX := ScreenInfo.OrigX1+ScreenInfo.XOffset+15;
           TypeWindowY := ScreenInfo.OrigY1+ScreenInfo.YOffset+53;
           IF KeyPressed THEN
           BEGIN
                C := UpCase(ReadKey);
                IF Ord(C)=0 THEN
                BEGIN
                     C := ReadKey;
                     CASE ORD(C) OF
                     71:  BEGIN {HOME}
                               GrDisplayMouse(GrHide);
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                               EditPos := 1;
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                               GrDisplayMouse(GrShow);
                               GOTO SkipHandler;
                          END;
                     79:  BEGIN {END}
                               GrDisplayMouse(GrHide);
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                               EditPos := Length(FName)+1;
                               OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                               GrDisplayMouse(GrShow);
                               GOTO SkipHandler;
                          END;
                     83:  BEGIN {DELETE}
                               IF (EditPos<=Length(FName)) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    Delete(FName,EditPos,1);
                                    OutTextXY(TypeWindowX,TypeWindowY,0,15,2,FName+' ');
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                                    GOTO SkipHandler;
                               END;
                          END;
                     75:  BEGIN {LEFT ARROW}
                               IF EditPos>1 THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    DEC(EditPos);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                                    GOTO SkipHandler;
                               END;
                          END;
                     77:  BEGIN {RIGHT ARROW}
                               IF (EditPos<=LENGTH(FName)) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    INC(EditPos);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                                    GOTO SkipHandler;
                               END;
                          END;
                     END;
                END
                ELSE
                BEGIN
                     CASE Ord(c) OF
                     8:   BEGIN
                               IF (EditPos>1) THEN
                               BEGIN
                                    GrDisplayMouse(GrHide);
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                    Delete(FName,EditPos-1,1);
                                    DEC(EditPos);
                                    OutTextXY(TypeWindowX,TypeWindowY,0,15,2,FName+' ');
                                    OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                    GrDisplayMouse(GrShow);
                                    GOTO SkipHandler;
                               END;
                          END;
                     ELSE BEGIN
                               IF LENGTH(FName)<12 THEN
                               BEGIN
                                    IF (((ORD(c)>47) AND (ORD(c)<58)) OR ((ORD(c)>64) AND (ORD(c)<91)) OR
                                       (c='~') OR (c='@') OR (c='#') OR (c='$') OR (c='-') OR (c='.') OR (c='_')) THEN
                                    BEGIN
                                         GrDisplayMouse(GrHide);
                                         OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                                         FName := _Mid(FName,1,EditPos-1)+
                                                  C+
                                                  _Mid(FName,EditPos,LENGTH(FName));
                                         INC(EditPos);
                                         OutTextXY(TypeWindowX,TypeWindowY,0,15,2,FName);
                                         OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                                         GrDisplayMouse(GrShow);
                                         GOTO SkipHandler;
                                    END;
                               END;
                          END;
                     END;
                END;
           END;
           DoJob := MouseHandler(False);
           IF (PickInfo.Current<>Current) THEN
           BEGIN
                Current := PickInfo.Current;
                Temp := _RemoveSpaces(_Mid(GetFromPickList(Current),1,12));
                IF FName<>Temp THEN
                BEGIN
                     FName := Temp;
                     GrDisplayMouse(GrHide);
                     OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,15,255,2,'_');
                     OutTextXY(TypeWindowX,TypeWindowY,0,15,2,_PadRight(FName,13));
                     EditPos := LENGTH(FName)+1;
                     OutTextXY(TypeWindowX+((EditPos-1)*8),TypeWindowY+1,0,255,2,'_');
                     GrDisplayMouse(GrShow);
                END;
           END;
           IF (AllowOpen AND AllowNew) THEN
           BEGIN
                CASE DoJob OF
                1:   BEGIN {LOAD}
                          IF _FileExists(Path+'\'+FName) THEN
                          BEGIN
                               AllDone      := True;
                               FileSelector := 1;
                          END;
                     END;
                2:   BEGIN {SAVE}
                          IF FName<>'' THEN
                          BEGIN
                               AllDone      := True;
                               FileSelector := 2;
                          END;
                     END;
                3:   BEGIN {CANCEL}
                          AllDone      := True;
                          FileSelector := 3;
                     END;
                END;
           END
           ELSE IF AllowOpen THEN
           BEGIN
                CASE DoJob OF
                1:   BEGIN {LOAD}
                          IF _FileExists(Path+'\'+FName) THEN
                          BEGIN
                               AllDone      := True;
                               FileSelector := 1;
                          END;
                     END;
                2:   BEGIN {CANCEL}
                          AllDone      := True;
                          FileSelector := 3;
                     END;
                END;
           END
           ELSE IF AllowNew THEN
           BEGIN
                CASE DoJob OF
                1:   BEGIN {SAVE}
                          IF FName<>'' THEN
                          BEGIN
                               AllDone      := True;
                               FileSelector := 2;
                          END;
                     END;
                2:   BEGIN {CANCEL}
                          AllDone      := True;
                          FileSelector := 3;
                     END;
                END;
           END
           ELSE
           BEGIN
                CASE DoJob OF
                1:   BEGIN {CANCEL}
                          AllDone      := True;
                          FileSelector := 3;
                     END;
                END;
           END;
           SkipHandler:
     UNTIL AllDone;
     KillWindow;
     ReloadWindow(4);
     KillPickList;
END;


END.
