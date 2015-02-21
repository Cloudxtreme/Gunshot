{$I DEFINES.INC}
UNIT Intro;


INTERFACE


PROCEDURE DoAbout;
PROCEDURE LoadSystem;
PROCEDURE ShutDownSystem;


IMPLEMENTATION


USES Gx2_Bp,Gr2_Bp,Globals,_Win,BHandler,_Icons,_Text,_Images,BsString,
     Dos,BsGraph,ErrorOut,Tx2_Bp,DefPal,Gx2_BpVC,Fx2_Bp,Crt,Version,
     Shotgun;


PROCEDURE DoAbout;
CONST gxRevision: array [0..revMAXIMUM] of string[30] = (
                  'Unknown chip revision       ','Monochrome Display Adapter  ',
                  'Hercules Graphic Card       ','Color Graphics Adapter      ',
                  'Multi-Color Graphics Adapter','Enhanced Graphic Adapter    ',
                  'Video Graphic Array         ','Tseng Labs ET-3000 unknown  ',
                  'Tseng Labs ET-3000          ','Tseng Labs ET-4000 unknown  ',
                  'Tseng Labs ET-4000          ','Tseng Labs ET-4000 w/W32    ',
                  'Headland Video-7 unknown    ','Headland Technologies HT208 ',
                  'Headland Technologies HT209 ','Headland Technologies HT216 ',
                  'ATI unknown revision        ','ATI 18800                   ',
                  'ATI 18800-1                 ','ATI 28800-2                 ',
                  'ATI 28800-4                 ','ATI 28800-5                 ',
                  'ATI 28800-6                 ','ATI 68800                   ',
                  'Trident unknown revision    ','Trident 8800CS              ',
                  'Trident 8900B               ','Trident 8900C               ',
                  'Trident 8900CL              ','Trident 9000                ',
                  'Trident 9000i               ','Trident 9200CXr             ',
                  'Cirrus Logic unknown        ','Cirrus Logic GD5420         ',
                  'Cirrus Logic GD5420r1       ','Cirrus Logic GD5422         ',
                  'Cirrus Logic GD5424         ','Cirrus Logic GD5426         ',
                  'Cirrus Logic GD5428         ','Oak Technologies unknown    ',
                  'Oak Technologies OTI067     ','Oak Technologies OTI077     ',
                  'Oak Technologies OTI087     ','Compaq QVision unknown      ',
                  'Compaq QVision              ','S3 unknown revision         ',
                  'S3 911                      ','S3 924                      ',
                  'S3 801/805 of unknown       ','S3 801/805 revision B       ',
                  'S3 801/805 revision C       ','S3 928                      ',
                  'S3 928 revision D           ','S3 928 revision E           ',
                  'Ahead Systems unknown       ','Ahead Systems V5000B        ',
                  'Weitek unknown revision     ','Weitek 5186                 ',
                  'Weitek 5286                 ','XGA unknown revision        ',
                  'XGA                         ','VESA unknown revision       ',
                  'VESA v1.0                   ','VESA v1.1                   ',
                  'VESA v1.2                   ','Western Digital unknown     ',
                  'Western Digital PVGA1A      ','Western Digital WD90c00     ',
                  'Western Digital WD90c10     ','Western Digital WD90c11     ',
                  'Western Digital WD90c20/2   ','Western Digital WD90c24     ',
                  'Western Digital WD90c26     ','Western Digital WD90c30     ',
                  'Western Digital WD90c31     ','Western Digital WD90c33     ',
                  'Avance Logic unknown        ','Avance Logic ALG-2201       ',
                  'NCR unknown revision        ','NCR 77C32BLT                ',
                  'Oak Technologies OTI037C    ','Trident 9400CXI             ',
                  'ATI 68800 unknown revision  ','Cirrus Logic GD543x unknown ',
                  'Cirrus Logic GD5430         ','Cirrus Logic GD5434         ',
                  'S3 Vision unknown revision  ','S3 Vision 864               ',
                  'S3 Vision 964               ');
CONST gxFamily:   array [0..chipMAXIMUM] of string[25] = (
                  'Unknown family     ','Tseng ET3000       ',
                  'Western Digital    ','Headland           ',
                  'ATI                ','Tseng ET4000       ',
                  'Trident            ','VESA compatible    ',
                  'Cirrus Logic       ','Oak Technologies   ',
                  'S3                 ','Compaq QVision     ',
                  'Ahead Systems      ','Weitek             ',
                  'Avance Logic       ','NCR                ',
                  'IBM XGA            ','ATI Mach 32        ',
                  'Cirrus Logic GD543x','S3 Vision          ');
VAR  Temp         : String;
     Display      : GXDCONFIG;
BEGIN
     NButtons := 0;
     DrawWindow(30,80,595,340,'ABOUT SHOTGUN GUI EDITOR',AboutWindow);
     SystemButton(495,285,580,325,1,False,True);
     InvertedBox(494,284,581,326);
     SystemIcon(505,290,65);
     OutTextXY(546,301,0,255,1,'Ok');
     OutTextXY(545,300,15,255,1,'Ok');
     LoadGraphicLib('GUI_____.$$$',45,120,374,295);
     GrSetColor(8);
     GrDrawLine(44,273,276,273);
     GrDrawLine(276,120,276,273);
     GrSetColor(15);
     GrDrawLine(44,120,276,120);
     GrDrawLine(44,120,44,273);
     InvertedBox(43,119,277,274);
     OutTextXY(80,300,0,255,1,ShotgunCopyright);
     InvertedBox(285,120,580,275);
     gxGetDisplayConfig(Display);

     {Video Card}
     OutTextXYFR(390,130,0,255,'Video Card:');
     OutTextXY(400,130,0,255,1,gxFamily[Display.family]);

     {Chipset}
     OutTextXYFR(390,145,0,255,'Chipset:');
     OutTextXY(400,145,0,255,1,gxRevision[Display.revision]);

     {Video Memory}
     OutTextXYFR(390,160,0,255,'Video Memory:');
     OutTextXY(400,160,0,255,1,_String(Display.memory*64)+'K');

     {Swap File In Use}
     OutTextXYFR(390,175,0,255,'DPMI Swap:');
     IF UseSwapFile THEN Temp := 'Yes'
                    ELSE Temp := 'No';
     OutTextXY(400,175,0,255,1,Temp);

     {Swap File Size}
     OutTextXYFR(390,190,0,255,'Swap Size:');
     OutTextXY(400,190,0,255,1,_String(Trunc(SwapFileSize/1024))+'K');

     {RAM}
     OutTextXYFR(390,205,0,255,'Heap Available:');
     OutTextXY(400,205,0,255,1,_String(Trunc(MaxAvail/1024))+'K');

     {Disk Memory}
     OutTextXYFR(390,220,0,255,'Disk Available:');
     OutTextXY(400,220,0,255,1,_String(TRUNC(DiskFree(0)/1024))+'K');

     {ROM Fonts}
     OutTextXYFR(390,235,0,255,'Using ROM Fonts:');
     Temp := 'No';
     OutTextXY(400,235,0,255,1,Temp);

     GetFreeMem;
     GrDisplayMouse(GrShow);
     REPEAT
     UNTIL MouseHandler(False)=1;
     GrDisplayMouse(GrHide);
     KillWindow;
END;


PROCEDURE LoadINIFile;
VAR  Temp  : String;
     FFile : Text;
     XSens : Word;
     YSens : Word;
BEGIN
     XSens := 6;
     YSens := 10;
     WallPaper := '';
     GrowingWindows := True;
     ASSIGN(FFile,Shotgun_Dir+'\GUI.INI');
     {$I-}RESET(FFile);{$I+}
     IF IoResult=0 THEN
     BEGIN
          REPEAT
                READLN(FFile,Temp);
                Temp := _UpperCase(_RemoveSpaces(Temp));
                IF _Mid(Temp,1,9)='WALLPAPER' THEN
                BEGIN
                     Delete(Temp,1,10);
                     WallPaper := _UpperCase(Temp);
                END
                ELSE IF _Mid(Temp,1,11)='GROWWINDOWS' THEN
                BEGIN
                     Delete(Temp,1,12);
                     IF Temp='YES' THEN GrowingWindows := True
                                   ELSE GrowingWindows := False;
                END
                ELSE IF _Mid(Temp,1,6)='MOUSEX' THEN
                BEGIN
                     Delete(Temp,1,7);
                     XSens := _Numeric(Temp);
                END
                ELSE IF _Mid(Temp,1,6)='MOUSEY' THEN
                BEGIN
                     Delete(Temp,1,7);
                     YSens := _Numeric(Temp);
                END;
          UNTIL EOF(FFile);
          CLOSE(FFile);
     END;
     SetPixelToMickey(XSens,YSens);
END;


PROCEDURE LoadSystem;
CONST BarBack = 1;
CONST BarHigh = 9;
CONST BarLow  = 0;
VAR   Temp_Colour : Word;
      Loop_X      : Word;
      Loop_Y      : Word;
      GrDriver    : Integer;
      GrMode      : Integer;
      Error       : Integer;
BEGIN
     FillChar(Icn,SizeOf(Icn),1);
     Icn[1]  := 76;
     Icn[2]  := 69;
     Icn[3]  := 73;
     Icn[4]  := 40;
     Icn[5]  := 39;
     Icn[6]  := 41;
     Icn[7]  := 20;
     Icn[8]  := 34;
     Icn[9]  := 35;
     Icn[10] := 36;
     Icn[11] := 38;
     Icn[12] := 42;
     Icn[13] := 32;
     Icn[14] := 60;
     Icn[15] := 50;
     Icn[16] := 59;
     Icn[17] := 49;
     Icn[18] := 57;
     Icn[19] := 37;
     Icn[20] := 44;
     Icn[21] := 83;
     Icn[22] := 33;
     Icn[23] := 86;
     Icn[24] := 87;
     Icn[25] := 88;
     Icn[26] := 89;
     Icn[27] := 45;
     Icn[28] := 83;
     Icn[33] := 67;
     Icn[34] := 8;
     Icn[35] := 4;
     Icn[36] := 9;
     UseSwapFile := False;
     SwapFileSize := 0;
     GraphicsMode_BS(256,640,True,True);
     IF NOT(GraphicsInitialized) THEN DropError(2);
     GrSetClipRegion(0,0,GraphMaxX,GraphMaxY); GrSetClipping(GrClip);
     TxSetClipRegion(0,0,GraphMaxX,GraphMaxY); TxSetClipping(TxClip);
     SetDefaultPalette;
     Fade_Off;
     LoadFontFiles;
     GrSetFillStyle(GrFSolid,0,GrOpaque);
     GrDrawRect(0,0,15,15,GrFill);
     temp_colour := 8;
     FOR loop_y := 1 TO 9 DO
     BEGIN
          FOR loop_x := 1 TO 9 DO
          BEGIN
               IF temp_colour=7 THEN
               BEGIN
                    GrPutPixel(loop_x,loop_y,Temp_Colour);
                    temp_colour := 8;
               END
               ELSE
               BEGIN
                    GrPutPixel(loop_x,loop_y,Temp_Colour);
                    temp_colour := 7;
               END;
          END;
     END;
     gxCreateVirtual(gxCMM,Disabled,gxGetDisplay,GridSize,GridSize);
     gxCreateVirtual(gxCMM,IconHdr,TheDisplay,30,30);
     gxDisplayVirtual(1,1,GridSize,GridSize,0,Disabled,0,0);
     GrSetFillStyle(GrFSolid,1,GrOpaque);
     GrDrawRect(0,0,GraphMaxX,19,GrFill);
     GrSetColor(9); GrDrawLine(0,0,GraphMaxX,0);
     GrSetColor(0); GrDrawLine(0,20,GraphMaxX,20);
     GrSetFillStyle(GrFSolid,BarBack,GrOpaque);
     GrDrawRect(0,YWindow+2,639,GraphMaxY-1,GrFill);
     GrSetColor(BarHigh);
     GrDrawLine(0,YWindow+1,639,YWindow+1);
     GrDrawLine(150,YWindow+2,150,GraphMaxY-1);
     GrSetColor(BarLow);
     GrDrawLine(0,GraphMaxY,639,GraphMaxY);
     GrDrawLine(149,YWindow+2,149,GraphMaxY-1);
     OutTextXY(7,GraphMaxY-40,15,255,2,' MEM:');
     OutTextXY(7,GraphMaxY-24,15,255,2,'DISK:');
     OutTextXY(160,3,15,1,2,'Shotgun GUI Graphics Editor/16 - '+ShotgunVersion);
     LoadGraphicLib('LOGO____.$$$',475,GraphMaxY-42,639,GraphMaxY-2);
     GrSetMouseMode(gxGRAPHICS);
     Error := GrInitMouse;
     IF Error<>GxSuccess THEN DropError(1);
     GrSetMouseMode(gxGRAPHICS);
     GrTrackMouse(GrTrack);
     GrSetMouseBounds(0,0,GraphMaxX,GraphMaxY-4);
     GrSetMouseStyle(0,15);
     LoadINIFile;
     IF WallPaper='' THEN LoadGraphicLib('BACK____.$$$',0,21,639,YWindow)
                     ELSE LoadGraphicFile(WallPaper,0,21,639,YWindow,4,0,0,False);
END;


PROCEDURE ShutDownSystem;
BEGIN
     txFreeFont(SystemFont);
     txFreeFont(HelvFont);
     txFreeFont(RomanFont);
     txFreeFont(workfont);
     txFreeFont(BitFont8x16);
     txFreeFont(BitFont8x14);
     txFreeFont(BitFont8x8);
     gxDestroyVirtual(Disabled);
     gxDestroyVirtual(IconHdr);
     GrStopMouse;
     gxSetMode(GxText);
     gxDone;
     TEXTCOLOR(7);
     TEXTBACKGROUND(0);
     ClrScr;
END;


END.
