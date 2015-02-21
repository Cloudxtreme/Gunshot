{$I DEFINES.INC}
UNIT BsGraph;


INTERFACE


VAR   GraphicsColours     : Word;
      GraphMaxX           : Integer;
      GraphMaxY           : Integer;
      GraphicsInitialized : Boolean;
      TheDisplay          : Integer;
      fPal1,fPal2         : Array[0..255,0..2] of Byte;


PROCEDURE GraphicsMode_BS      (Display_Colours,size: Word; Force,ToGfx: Boolean);
PROCEDURE GraphicsMode_BSNC    (Display_Colours,size: Word; Force: Boolean);
PROCEDURE SetPixeltoMickey     (Horiz,Verti : Integer);
FUNCTION  GetMouseXG           (Gr: Word): Word;
FUNCTION  GetMouseYG           (Gr: Word): Word;
FUNCTION  GetMouseX            : Word;
FUNCTION  GetMouseY            : Word;
PROCEDURE fade_out;
PROCEDURE fade_in;
PROCEDURE fade_off;


IMPLEMENTATION

{$IFDEF DPMI}
USES Gx2_Bp,Gr2_Bp,Dos;
{$ELSE}
USES Gx_Tp,Gr_Tp,Dos;
{$ENDIF}


PROCEDURE GraphicsMode_BS(Display_Colours,size: Word; Force,ToGfx: Boolean);
VAR   Error      : Integer;
LABEL try16colour;
BEGIN
     Error := GxInit;
     IF Error<>GxSuccess THEN Halt;
     IF display_colours=16 THEN
     BEGIN
          IF Size=800 THEN
          BEGIN
               GraphMaxX       := 799;
               GraphMaxY       := 599;
               GraphicsColours := 16;
               Error := GxSetDisplay(gxVESA_102);
               IF Error=GxSuccess THEN
               BEGIN
                    IF ToGfx THEN GxSetMode(GxGraphics);
               END
               ELSE
               BEGIN
                    IF NOT(Force) THEN GOTO try16colour;
                    GraphicsInitialized := False;
                    Exit;
               END;
          END
          ELSE
          BEGIN
               try16colour:
               GraphMaxX       := 639;
               GraphMaxY       := 479;
               GraphicsColours := 16;
               Error := GxSetDisplay(gxVGA_12);
               IF Error=GxSuccess THEN
               BEGIN
                    IF ToGfx THEN GxSetMode(GxGraphics);
               END
               ELSE Halt;
          END;
     END
     ELSE IF display_colours=256 THEN
     BEGIN
          IF Size=1024 THEN
          BEGIN
               GraphMaxX       := 1023;
               GraphMaxY       := 767;
               GraphicsColours := 256;
               Error := GxSetDisplay(gxVESA_105);
               IF Error=GxSuccess THEN
               BEGIN
                    IF ToGfx THEN GxSetMode(GxGraphics);
               END
               ELSE
               BEGIN
                    IF NOT(Force) THEN GOTO try16colour;
                    GraphicsInitialized := False;
                    Exit;
               END;
          END
          ELSE IF Size=800 THEN
          BEGIN
               GraphMaxX       := 799;
               GraphMaxY       := 599;
               GraphicsColours := 256;
               Error := GxSetDisplay(gxVESA_103);
               IF Error=GxSuccess THEN
               BEGIN
                    IF ToGfx THEN GxSetMode(GxGraphics);
               END
               ELSE
               BEGIN
                    IF NOT(Force) THEN GOTO try16colour;
                    GraphicsInitialized := False;
                    Exit;
               END;
          END
          ELSE IF Size=360 THEN
          BEGIN
               GraphMaxX       := 359;
               GraphMaxY       := 479;
               GraphicsColours := 256;
               Error := GxSetDisplay(gxX_360x480);
               IF Error=GxSuccess THEN
               BEGIN
                    IF ToGfx THEN GxSetMode(GxGraphics);
               END
               ELSE
               BEGIN
                    IF NOT(Force) THEN GOTO try16colour;
                    GraphicsInitialized := False;
                    Exit;
               END;
          END
          ELSE IF Size=400 THEN
          BEGIN
               GraphMaxX       := 639;
               GraphMaxY       := 399;
               GraphicsColours := 256;
               Error := GxSetDisplay(gxVESA_100);
               IF Error=GxSuccess THEN
               BEGIN
                    IF ToGfx THEN GxSetMode(GxGraphics);
               END
               ELSE
               BEGIN
                    IF NOT(Force) THEN GOTO try16colour;
                    GraphicsInitialized := False;
                    Exit;
               END;
          END
          ELSE
          BEGIN
               GraphMaxX       := 639;
               GraphMaxY       := 479;
               GraphicsColours := 256;
               Error := GxSetDisplay(gxVESA_101);
               IF Error=GxSuccess THEN
               BEGIN
                    IF ToGfx THEN GxSetMode(GxGraphics);
               END
               ELSE
               BEGIN
                    IF NOT(Force) THEN GOTO try16colour;
                    GraphicsInitialized := False;
                    Exit;
               END;
          END;
     END;
     IF ToGfx THEN
     BEGIN
          GrSetViewPort(0,0,GraphMaxX,GraphMaxY);
          GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
          GrSetClipping(GrClip);
     END;
     TheDisplay := GxGetDisplay;
     GraphicsInitialized := True;
END;


PROCEDURE GraphicsMode_BSNC(Display_Colours,size: Word; Force: Boolean);
VAR   Error      : Integer;
LABEL try16colour;
BEGIN
     Error := GxInit;
     IF Error<>GxSuccess THEN Halt;
     IF display_colours=16 THEN
     BEGIN
          IF Size=800 THEN
          BEGIN
               GraphMaxX       := 799;
               GraphMaxY       := 599;
               GraphicsColours := 16;
               Error := GxSetDisplay(gxVESA_102);
               IF Error=GxSuccess THEN
               BEGIN
                    GxSetMode(GxNOCLEAR+GxGraphics);
               END
               ELSE
               BEGIN
                    IF NOT(Force) THEN GOTO try16colour;
                    GraphicsInitialized := False;
                    Exit;
               END;
          END
          ELSE
          BEGIN
               try16colour:
               GraphMaxX       := 639;
               GraphMaxY       := 479;
               GraphicsColours := 16;
               Error := GxSetDisplay(gxVGA_12);
               IF Error=GxSuccess THEN
               BEGIN
                    GxSetMode(GxNOCLEAR+GxGraphics);
               END
               ELSE Halt;
          END;
     END
     ELSE IF display_colours=256 THEN
     BEGIN
          IF Size=1024 THEN
          BEGIN
               GraphMaxX       := 1023;
               GraphMaxY       := 767;
               GraphicsColours := 256;
               Error := GxSetDisplay(gxVESA_105);
               IF Error=GxSuccess THEN
               BEGIN
                    GxSetMode(GxNOCLEAR+GxGraphics);
               END
               ELSE
               BEGIN
                    IF NOT(Force) THEN GOTO try16colour;
                    GraphicsInitialized := False;
                    Exit;
               END;
          END
          ELSE IF Size=800 THEN
          BEGIN
               GraphMaxX       := 799;
               GraphMaxY       := 599;
               GraphicsColours := 256;
               Error := GxSetDisplay(gxVESA_103);
               IF Error=GxSuccess THEN
               BEGIN
                    GxSetMode(GxNOCLEAR+GxGraphics);
               END
               ELSE
               BEGIN
                    IF NOT(Force) THEN GOTO try16colour;
                    GraphicsInitialized := False;
                    Exit;
               END;
          END
          ELSE IF Size=360 THEN
          BEGIN
               GraphMaxX       := 359;
               GraphMaxY       := 479;
               GraphicsColours := 256;
               Error := GxSetDisplay(gxX_360x480);
               IF Error=GxSuccess THEN
               BEGIN
                    GxSetMode(GxNOCLEAR+GxGraphics);
               END
               ELSE
               BEGIN
                    IF NOT(Force) THEN GOTO try16colour;
                    GraphicsInitialized := False;
                    Exit;
               END;
          END
          ELSE IF Size=400 THEN
          BEGIN
               GraphMaxX       := 639;
               GraphMaxY       := 399;
               GraphicsColours := 256;
               Error := GxSetDisplay(gxVESA_100);
               IF Error=GxSuccess THEN
               BEGIN
                    GxSetMode(GxNOCLEAR+GxGraphics);
               END
               ELSE
               BEGIN
                    IF NOT(Force) THEN GOTO try16colour;
                    GraphicsInitialized := False;
                    Exit;
               END;
          END
          ELSE
          BEGIN
               GraphMaxX       := 639;
               GraphMaxY       := 479;
               GraphicsColours := 256;
               Error := GxSetDisplay(gxVESA_101);
               IF Error=GxSuccess THEN
               BEGIN
                    GxSetMode(GxNOCLEAR+GxGraphics);
               END
               ELSE
               BEGIN
                    IF NOT(Force) THEN GOTO try16colour;
                    GraphicsInitialized := False;
                    Exit;
               END;
          END;
     END;
     GrSetViewPort(0,0,GraphMaxX,GraphMaxY);
     GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
     GrSetClipping(GrClip);
     TheDisplay := GxGetDisplay;
     GraphicsInitialized := True;
END;


PROCEDURE SetPixeltoMickey(Horiz,Verti : Integer);
VAR  Reg : Registers;
BEGIN
     FillChar(Reg,SizeOf(Reg),0);
     WITH Reg DO
     BEGIN
          Ax := 15;
          Cx := Horiz;
          Dx := Verti;
     END;
     Intr($33,Reg);
END;


FUNCTION GetMouseX: Word;
VAR  Work  : Integer;
     Crap  : Integer;
     Error : Integer;
BEGIN
     Error := GrGetMousePos(Work,Crap);
     IF Error=grSuccess THEN GetMouseX := Work
                        ELSE GetMouseX := 0;
END;


FUNCTION GetMouseY: Word;
VAR  Work  : Integer;
     Crap  : Integer;
     Error : Integer;
BEGIN
     Error := GrGetMousePos(Crap,Work);
     IF Error=grSuccess THEN GetMouseY := Work
                        ELSE GetMouseY := 0;
END;


FUNCTION GetMouseXG(Gr: Word): Word;
VAR  Work : Integer;
     Crap : Integer;
BEGIN
     GrGetMousePos(Work,Crap);
     GetMouseXG := (Trunc(Work/Gr))*Gr;
END;


FUNCTION GetMouseYG(Gr: Word): Word;
VAR  Work : Integer;
     Crap : Integer;
BEGIN
     GrGetMousePos(Crap,Work);
     GetMouseYG := (Trunc(Work/Gr))*Gr;
END;


PROCEDURE Fade_Out;
VAR  do_colour : boolean;
     count1    : word;
     count2    : word;
BEGIN
     FOR count1 := 0 to 255 do           {Get the current palette}
     begin
          Port[$03C7] := count1;
          fPal1[count1,0] := Port[$03C9];
          fPal1[count1,1] := Port[$03C9];
          fPal1[count1,2] := Port[$03C9];
     end;
     fPal2:=fPal1;
     For Count1 := 0 to 64 do           {this will fade the entire palette}
     begin                               {20 must be enough in Text mode}
          For Count2 := 0 to 255 do
          begin
               do_colour := false;
               If fPal2[Count2,0] > 0 then
               BEGIN
                    Dec(fPal2[Count2,0]);
                    do_colour := true;
               END;
               If fPal2[Count2,1] > 0 then
               BEGIN
                    Dec(fPal2[Count2,1]);
                    do_colour := true;
               END;
               If fPal2[Count2,2] > 0 then
               BEGIN
                    Dec(fPal2[Count2,2]);
                    do_colour := true;
               END;
               IF do_colour THEN
               BEGIN
                    Port[$03C8] := Count2;
                    Port[$03C9] := fPal2[Count2,0];
                    Port[$03C9] := fPal2[Count2,1];
                    Port[$03C9] := fPal2[Count2,2];
               END;
          end;
     end;
END;


PROCEDURE Fade_Off;
VAR
     do_colour : boolean;
     count1    : word;
     count2    : word;
BEGIN
     FOR count1 := 0 to 255 do           {Get the current palette}
     begin
          Port[$03C7] := count1;
          fPal1[count1,0] := Port[$03C9];
          fPal1[count1,1] := Port[$03C9];
          fPal1[count1,2] := Port[$03C9];
     end;
     FillChar(fPal2,SizeOf(fPal2),0);
     For Count1 := 0 to 255 do
     Begin
          Port[$03C8] := Count1;
          Port[$03C9] := 0;
          Port[$03C9] := 0;
          Port[$03C9] := 0;
     End;
END;


PROCEDURE fade_in;
VAR
     do_colour : boolean;
     count1    : word;
     count2    : word;
BEGIN
     For Count1 := 0 to 64 do   {Restore Original palette}
     begin
          For Count2 := 0 to 255 do
          begin
               do_colour := false;
               If fPal2[Count2,0] < fPal1[Count2,0] then
               BEGIN
                    INC(fPal2[Count2,0]);
                    do_colour := true;
               END;
               If fPal2[Count2,1] < fPal1[Count2,1] then
               BEGIN
                    INC(fPal2[Count2,1]);
                    do_colour := true;
               END;
               If fPal2[Count2,2] < fPal1[Count2,2] then
               BEGIN
                    INC(fPal2[Count2,2]);
                    do_colour := true;
               END;
               IF do_colour THEN
               BEGIN
                    Port[$03C8] := Count2;
                    Port[$03C9] := fPal2[Count2,0];
                    Port[$03C9] := fPal2[Count2,1];
                    Port[$03C9] := fPal2[Count2,2];
               END;
          end;
     end;
end;


BEGIN
     GraphicsInitialized := False;
END.