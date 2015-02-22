{$IFNDEF DPMI}
  DPMI_ONLY!
{$ENDIF}
PROGRAM ShotgunSGFileViewer;
{$M 64000}
{$I DEFINES.INC}


USES Gx2_Bp,Gx2_BpVC,Gr2_Bp,Fx2_Bp,Tx2_Bp,Shotgun,MkFFile,Dos,
     Img2_Bp,BsGraph,BsString,BsFile,Crt,BsMulti,BsVideo,FMode;


TYPE LiPoint3D       = RECORD
     X,Y,Z           : LongInt;
     END;
TYPE Poly_Points     = Array[0..32000] Of Integer;
TYPE GFX_Buffer      = Array[0..65534] Of Byte;
VAR  FRawFile        : FFileObj;
     RawFile         : _Raw_File;
     RESOURCES       : String;
     FIcon30         : File Of _Icon30x30;
     FIcon16         : File Of _Icon16x16;
     Icon30          : _Icon30x30;
     Icon16          : _Icon16x16;
     IconHdr         : GXHeader;
     GetPut          : GXHeader;
     BMPFile         : GXHeader;
     P256            : Array[0..767] Of Byte;
     G256            : Array[0..767] Of Byte;
     GraphicsLibrary : String[80];
     WorkFont        : TXHeader;
     LastFont        : String[12];
     SystemFont      : TxHeader;
     HelvFont        : TxHeader;
     RomanFont       : TxHeader;
     BitFont8x8      : TxHeader;
     BitFont8x14     : TxHeader;
     BitFont8x16     : TxHeader;
     PolyPoint       : ^Poly_Points;
     CtrlPt          : Array [-1..8] Of LiPoint3D;
     Ax,Bx,Cx,Dx     : Real;
     Ay,By,Cy,Dy     : Real;
     WorkWord        : Longint;
     DirInfo         : SearchRec;
     InSpec          : String;
     SGDirectory     : String;
     C               : Char;
     GraphLib        : GXLIB;
     GFXBuffer       : ^GFX_Buffer;


FUNCTION CreateVirtual(VAR VBuffer: GXHeader; W,H: Word; CT: Integer): Boolean;
VAR  Error : Integer;
LABEL        Continue;
BEGIN
     Error := gxCreateVirtual(gxCMM,VBuffer,CT,W,H);
     IF Error=GxSuccess THEN GOTO Continue;
     Halt;
     Continue:
     CreateVirtual := True;
END;


PROCEDURE Get(x1,y1,x2,y2: Word);
BEGIN
     CreateVirtual(GetPut,x2-x1+1,y2-y1+1,TheDisplay);
     gxDisplayVirtual(x1,y1,x2,y2,0,GetPut,0,0);
END;


PROCEDURE Put(x,y: Word; Kill: Boolean);
BEGIN
     gxVirtualDisplay(GetPut,0,0,x,y,GraphMaxX,GraphMaxY,0);
     IF Kill THEN gxDestroyVirtual(GetPut);
END;


PROCEDURE SystemIcon(x,y,num: Word);
VAR  LoopX   : Word;
     LoopY   : Word;
     GLib    : GxLib;
BEGIN
     IF ((Num<1) OR (Num>100)) THEN Exit;
     gxOpenLib(gxGXL,GraphicsLibrary,GLib,Nil,0);
     gxLibBuffer(GLib,_String(Num)+'.ICO',0,900,@Icon30);
     gxCloseLib(GLib);
     gxDisplayVirtual(x,y,x+29,y+29,0,IconHdr,0,0);
     grSetActiveVirtual(IconHdr);
     grSetVirtual(gxTrue);
     WITH Icon30 DO
     BEGIN
      FOR LoopX := 0 TO 29 DO
       FOR loopY := 0 TO 29 DO
        IF Matrix[loopX+1,loopY+1]<>255 THEN
         GrPutPixel(loopX,loopY,Matrix[loopX+1,loopY+1]);
     END;
     grSetVirtual(gxFalse);
     gxVirtualDisplay(IconHdr,0,0,x,y,x+29,y+29,0);
END;


PROCEDURE TileGraphicFile(FName: String);
VAR  Error    : Integer;
     imghdr   : IMGINHDR;
     dipal    : Array[0..767] Of Byte;
BEGIN
     IF NOT(_FileExists(FName)) THEN Exit;
     gxSetDitherMatrix(gxNODITHER);
     {Get the image header}
     Error := imgFileGetHeader(FName,0,imghdr,@dipal[0]);
     IF (Error<>GxSuccess) THEN Exit;
     {Create the buffer}
     CreateVirtual(BMPFile,imghdr.width,imghdr.height,TheDisplay);
     gxSetConvertPalette(GxPAL5,@P256);
     Error := imgFileConvert(FName,0,BMPFile);
     IF Error=gxSuccess THEN
     BEGIN
          fxSetDelay(0);
          fxSetGrain(1,1,1);
          fxSetEffect(fxWIPE);
          fxSetTile(fxTRUE);
          fxVirtualDisplay(BMPFile,0,0,0,0,GraphMaxX,GraphMaxY,fxDOWN);
          fxSetTile(fxFALSE);
     END;
     gxDestroyVirtual(BMPFile);
END;


FUNCTION ConvertColourCodes(InString: String): String;
VAR  Work : Word;
     Loop : Word;
     Temp : String;
BEGIN
     FOR Loop := 0 TO 15 DO
     BEGIN
          Temp := '{'+_String(Loop)+'}';
          REPEAT
                Work := Pos(Temp,InString);
                IF Work<>0 THEN
                BEGIN
                     Delete(InString,Work,LENGTH(Temp));
                     Insert(#1+CHR(Loop),InString,Work);
                END;
          UNTIL Work=0;
     END;
     ConvertColourCodes := InString;
END;


PROCEDURE DoText(Raw: _Raw_File);
VAR  Error : Integer;
     Face  : Integer;
     Loop  : Word;
     X     : Word;
LABEL        Continue;
BEGIN
     IF Raw.Text='' THEN Exit;
     IF Raw.Colour7=0 THEN
     BEGIN
          IF ((Raw.Crc32+'.FNT'<>LastFont) AND (LastFont<>'')) THEN txFreeFont(workfont);
          IF (Raw.Crc32+'.FNT'<>LastFont) THEN
          BEGIN
               Error := txFileFont(gxCMM,RESOURCES+Raw.Crc32+'.FNT',workfont);
               IF Error=txSuccess THEN GOTO Continue;
               Halt;
          END;
          Continue:
          LastFont := Raw.Crc32+'.FNT';
          Error := txSetFont(workfont);
     END
     ELSE
     BEGIN
          CASE Raw.Colour7 OF
          1:   Error := txSetFont(SystemFont);
          2:   Error := txSetFont(BitFont8x16);
          3:   Error := txSetFont(BitFont8x14);
          4:   Error := txSetFont(BitFont8x8);
          5:   Error := txSetFont(HelvFont);
          6:   Error := txSetFont(RomanFont);
          END;
     END;
     Face  := txTRANS;
     IF Raw.Colour3=1 THEN Face := Face+txSHADOW; {SHADOWED}
     IF Raw.Colour4=1 THEN Face := Face+txITALIC; {ITALICS}
     IF Raw.Colour5=1 THEN Face := Face+txUNDER;  {UNDERLINE}
     IF Raw.Colour6=1 THEN Face := Face+txBOLD;   {BOLD}
     txSetFace(Face);
     txSetColor(Raw.Colour1,0);
     txSetShadowColor(Raw.Colour2);
     txSetShadowPos(1,1);
     Raw.Text := ConvertColourCodes(Raw.Text);
     X        := Raw.X1;
     Loop     := 1;
     REPEAT
           IF Raw.Text[Loop]=#1 THEN
           BEGIN
                txSetColor(ORD(Raw.Text[Loop+1]),0);
                INC(Loop);
           END
           ELSE
           BEGIN
                TxOutCharXY(Raw.Text[Loop],X,Raw.Y1);
                INC(X,txStrWidth(Raw.Text[Loop]));
           END;
           INC(Loop);
     UNTIL (Loop>Length(Raw.Text));
     Error := txSetFont(SystemFont);
END;


PROCEDURE DrawTheWindow(Raw: _Raw_File);
VAR  x1,y1,x2,y2 : Word;
     Raw2        : _Raw_File;
BEGIN
     Raw2.Text    := Raw.Text;
     Raw2.Colour1 := Raw.Colour8;
     Raw2.Colour7 := 1;
     Raw2.Colour3 := 0;
     Raw2.Colour4 := 0;
     Raw2.Colour5 := 0;
     Raw2.Colour6 := 0;
     Raw2.Colour2 := 0;
     x1 := Raw.x1; y1 := Raw.y1;
     x2 := Raw.x2; y2 := Raw.y2;
     CASE Raw.Style OF
     1:   BEGIN {Classic Relief}
               GrSetColor(0);
               {Window Face}
               CASE Raw.Colour10 OF
               0:   GrSetFillStyle(GrFSolid,Raw.Colour1,GrOpaque);
               1:   GrSetFillStyle(GrFCloseDot,Raw.Colour1,GrTrans);
               END;
               GrDrawRect(X1,Y1,X2,Y2,GrFill+GrOutline);
               {Window Shadows}
               GrSetColor(Raw.Colour4);
               GrDrawLine(x1+1,y2-1,x2-1,y2-1);
               GrDrawLine(x2-1,y1+1,x2-1,y2-1);
               GrSetColor(Raw.Colour3);
               GrDrawLine(x1+1,y1+1,x2-1,y1+1);
               GrDrawLine(x1+1,y1+1,x1+1,y2-1);
               GrSetColor(Raw.Colour3);
               GrDrawLine(x2-4,y1+4,x2-4,y1+26);
               GrDrawLine(x1+4,y1+26,x2-4,y1+26);
               GrSetColor(Raw.Colour4);
               GrDrawLine(x1+4,y1+4,x2-4,y1+4);
               GrDrawLine(x1+4,y1+4,x1+4,y1+26);
               {Header Background}
               GrSetFillStyle(GrFSolid,Raw.Colour5,GrOpaque);
               GrDrawRect(X1+5,Y1+5,X2-5,Y1+25,GrFill);
               {Do The Header}
               IF Raw.Colour9=1 THEN
               BEGIN {Mimimized Header}
                    SystemIcon(x1+5,y1+5,55);
                    SystemIcon(x2-25,y1+5,56);
                    GrSetColor(Raw.Colour7);
                    GrDrawLine(x1+26,y1+25,x2-26,y1+25);
                    GrDrawLine(x2-26,y1+5,x2-26,y1+25);
                    GrSetColor(Raw.Colour6);
                    GrDrawLine(x1+26,y1+5,x1+26,y1+25);
                    GrDrawLine(x1+26,y1+5,x2-26,y1+5);
                    Raw2.x1 := x1+41;
                    Raw2.y1 := y1+8;
               END
               ELSE
               BEGIN {Non-Mimimized Header}
                    GrSetColor(Raw.Colour7);
                    GrDrawLine(x1+5,y1+25,x2-5,y1+25);
                    GrDrawLine(x2-5,y1+5,x2-5,y1+25);
                    GrSetColor(Raw.Colour6);
                    GrDrawLine(x1+5,y1+5,x1+5,y1+25);
                    GrDrawLine(x1+5,y1+5,x2-5,y1+5);
                    Raw2.x1 := x1+15;
                    Raw2.y1 := y1+8;
               END;
               DoText(Raw2);
          END;
     2:   BEGIN {Stamped Headers}
               GrSetColor(0);
               {Window Face}
               CASE Raw.Colour10 OF
               0:   GrSetFillStyle(GrFSolid,Raw.Colour1,GrOpaque);
               1:   GrSetFillStyle(GrFCloseDot,Raw.Colour1,GrTrans);
               END;
               GrDrawRect(X1,Y1,X2,Y2,GrFill+GrOutline);
               {Window Shadows}
               GrSetColor(Raw.Colour4);
               GrDrawLine(x1+1,y2-1,x2-1,y2-1);
               GrDrawLine(x2-1,y1+1,x2-1,y2-1);
               GrSetColor(Raw.Colour3);
               GrDrawLine(x1+1,y1+1,x2-1,y1+1);
               GrDrawLine(x1+1,y1+1,x1+1,y2-1);
               IF Raw.Colour9=1 THEN
               BEGIN
                    {Header Background}
                    GrSetFillStyle(GrFSolid,Raw.Colour5,GrOpaque);
                    GrDrawRect(X1+30,Y1+5,X2-30,Y1+25,GrFill);
                    {Highlight Header}
                    SystemIcon(x1+5,y1+5,55);
                    SystemIcon(x2-25,y1+5,56);
                    GrSetColor(Raw.Colour6);
                    GrDrawLine(x1+30,y1+25,x2-30,y1+25);
                    GrDrawLine(x2-30,y1+5,x2-30,y1+25);
                    GrSetColor(Raw.Colour7);
                    GrDrawLine(x1+30,y1+5,x1+30,y1+25);
                    GrDrawLine(x1+30,y1+5,x2-30,y1+5);
                    Raw2.x1 := x1+40;
                    Raw2.y1 := y1+8;
               END
               ELSE
               BEGIN
                    {Header Background}
                    GrSetFillStyle(GrFSolid,Raw.Colour5,GrOpaque);
                    GrDrawRect(X1+5,Y1+5,X2-5,Y1+25,GrFill);
                    {Highlight Header}
                    GrSetColor(Raw.Colour6);
                    GrDrawLine(x1+5,y1+25,x2-5,y1+25);
                    GrDrawLine(x2-5,y1+5,x2-5,y1+25);
                    GrSetColor(Raw.Colour7);
                    GrDrawLine(x1+5,y1+5,x1+5,y1+25);
                    GrDrawLine(x1+5,y1+5,x2-5,y1+5);
                    Raw2.x1 := x1+15;
                    Raw2.y1 := y1+8;
               END;
               DoText(Raw2);
          END;
     3:   BEGIN {Dozzzy Windows}
               GrSetColor(0);
               {Window Face}
               CASE Raw.Colour10 OF
               0:   GrSetFillStyle(GrFSolid,Raw.Colour1,GrOpaque);
               1:   GrSetFillStyle(GrFCloseDot,Raw.Colour1,GrTrans);
               END;
               GrDrawRect(X1,Y1,X2,Y2,GrFill+GrOutline);
               {Window Borders Etc.}
               GrSetColor(Raw.Colour2);
               GrDrawRect(X1+1,Y1+1,X2-1,Y2-1,GrOutline);
               GrDrawRect(X1+2,Y1+2,X2-2,Y2-2,GrOutline);
               GrDrawRect(X1+3,Y1+3,X2-3,Y2-3,GrOutline);
               GrSetColor(0);
               GrDrawRect(x1+4,y1+4,x2-4,y2-4,GrOutline);
               GrDrawLine(x1+4,y1+26,x2-4,y1+26);
               GrDrawLine(x1,y1+15,x1+4,y1+15);
               GrDrawLine(x1+15,y1,x1+15,y1+4);
               GrDrawLine(x2,y1+15,x2-4,y1+15);
               GrDrawLine(x2-15,y1,x2-15,y1+4);
               GrDrawLine(x1,y2-15,x1+4,y2-15);
               GrDrawLine(x1+15,y2-4,x1+15,y2);
               GrDrawLine(x2,y2-15,x2-4,y2-15);
               GrDrawLine(x2-15,y2-4,x2-15,y2);
               {Header Background}
               GrSetFillStyle(GrFSolid,Raw.Colour5,GrOpaque);
               GrDrawRect(X1+5,Y1+5,X2-5,Y1+25,GrFill);
               IF Raw.Colour9=1 THEN
               BEGIN
                    SystemIcon(x1+5,y1+5,55);
                    SystemIcon(x2-25,y1+5,56);
                    GrSetColor(0);
                    GrDrawLine(x1+26,y1+5,x1+26,y1+25);
                    GrDrawLine(x2-26,y1+5,x2-26,y1+25);
                    Raw2.x1 := x1+40;
                    Raw2.y1 := y1+8;
               END
               ELSE
               BEGIN
                    Raw2.x1 := x1+15;
                    Raw2.y1 := y1+8;
               END;
               DoText(Raw2);
          END;
     4:   BEGIN {Panel Windows}
               GrSetColor(0);
               {Window Face}
               CASE Raw.Colour10 OF
               0:   GrSetFillStyle(GrFSolid,Raw.Colour1,GrOpaque);
               1:   GrSetFillStyle(GrFCloseDot,Raw.Colour1,GrTrans);
               END;
               GrDrawRect(X1,Y1,X2,Y2,GrFill+GrOutline);
               {Window Shadows}
               GrSetColor(Raw.Colour4);
               GrDrawLine(x1+1,y2-1,x2-1,y2-1);
               GrDrawLine(x2-1,y1+1,x2-1,y2-1);
               GrSetColor(Raw.Colour3);
               GrDrawLine(x1+1,y1+1,x2-1,y1+1);
               GrDrawLine(x1+1,y1+1,x1+1,y2-1);
          END;
     END;
     {WINDOW SHADOW}
     GrSetFillStyle(GrFCloseDot,0,GrTrans);
     GrDrawRect(x1+5,y2+1,x2+5,y2+5,GrFill);
     GrDrawRect(x2+1,y1+5,x2+5,y2+5,GrFill);
END;


PROCEDURE DrawIcon(x,y,num,size,effect: Word; FName: String);
VAR  LoopX   : Word;
     LoopY   : Word;
     BB      : Byte;

     PROCEDURE DrawIconWithEffect(x1,y1,x2,y2: Word);
     BEGIN
          fxSetGrain(1,1,1);
          CASE Effect OF
          1:   BEGIN {Blind - Horiz}
                    fxSetDelay(15);
                    fxSetEffect(fxBLIND);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxHORIZ);
               END;
          2:   BEGIN {Blind - Verti}
                    fxSetDelay(15);
                    fxSetEffect(fxBLIND);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxVERT);
               END;
          3:   BEGIN {Crush - Horiz}
                    fxSetDelay(15);
                    fxSetEffect(fxCRUSH);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxHORIZ);
               END;
          4:   BEGIN {Crush - Verti}
                    fxSetDelay(15);
                    fxSetEffect(fxCRUSH);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxVERT);
               END;
          5:   BEGIN {Diagonal - Up/Right}
                    fxSetDelay(5);
                    fxSetEffect(fxDIAGONAL);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxUP+fxRIGHT);
               END;
          6:   BEGIN {Diagonal - Dn/Right}
                    fxSetDelay(5);
                    fxSetEffect(fxDIAGONAL);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxDOWN+fxRIGHT);
               END;
          7:   BEGIN {Diagonal - Up/Left}
                    fxSetDelay(5);
                    fxSetEffect(fxDIAGONAL);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxUP+fxLEFT);
               END;
          8:   BEGIN {Diagonal - Dn/Left}
                    fxSetDelay(5);
                    fxSetEffect(fxDIAGONAL);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxDOWN+fxLEFT);
               END;
          9:   BEGIN {Drip - Up}
                    fxSetDelay(2);
                    fxSetEffect(fxDRIP);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxUP);
               END;
          10:  BEGIN {Drip - Down}
                    fxSetDelay(2);
                    fxSetEffect(fxDRIP);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxDOWN);
               END;
          11:  BEGIN {Explode - In}
                    fxSetDelay(10);
                    fxSetEffect(fxEXPLODE);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxIN);
               END;
          12:  BEGIN {Explode - Out}
                    fxSetDelay(10);
                    fxSetEffect(fxEXPLODE);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxOUT);
               END;
          13:  BEGIN {Interleave - Horiz}
                    fxSetDelay(1);
                    fxSetEffect(fxINTERLEAVE);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxHORIZ);
               END;
          14:  BEGIN {Interleave - Verti}
                    fxSetDelay(1);
                    fxSetEffect(fxINTERLEAVE);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxVERT);
               END;
          15:  BEGIN {Random}
                    fxSetDelay(1);
                    fxSetEffect(fxRANDOM);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxNONE);
               END;
          16:  BEGIN {Sand - Up}
                    fxSetDelay(2);
                    fxSetEffect(fxSAND);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxUP);
               END;
          17:  BEGIN {Sand - Down}
                    fxSetDelay(2);
                    fxSetEffect(fxSAND);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxDOWN);
               END;
          18:  BEGIN {Slide - Up}
                    fxSetDelay(5);
                    fxSetEffect(fxSLIDE);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxUP);
               END;
          19:  BEGIN {Slide - Down}
                    fxSetDelay(5);
                    fxSetEffect(fxSLIDE);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxDOWN);
               END;
          20:  BEGIN {Slide - Left}
                    fxSetDelay(5);
                    fxSetEffect(fxSLIDE);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxLEFT);
               END;
          21:  BEGIN {Slide - Right}
                    fxSetDelay(5);
                    fxSetEffect(fxSLIDE);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxRIGHT);
               END;
          22:  BEGIN {Slide Blind - Horiz}
                    fxSetDelay(1);
                    fxSetEffect(fxSLIDEBLIND);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxHORIZ);
               END;
          23:  BEGIN {Slide Blind - Verti}
                    fxSetDelay(1);
                    fxSetEffect(fxSLIDEBLIND);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxVERT);
               END;
          24:  BEGIN {Slide Weave - Horiz}
                    fxSetDelay(1);
                    fxSetEffect(fxSLIDEWEAVE);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxHORIZ);
               END;
          25:  BEGIN {Slide Weave - Verti}
                    fxSetDelay(1);
                    fxSetEffect(fxSLIDEWEAVE);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxVERT);
               END;
          26:  BEGIN {Spiral - In}
                    fxSetDelay(1);
                    fxSetEffect(fxSPIRAL);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxIN);
               END;
          27:  BEGIN {Spiral - Out}
                    fxSetDelay(1);
                    fxSetEffect(fxSPIRAL);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxOUT);
               END;
          28:  BEGIN {Split - Horiz}
                    fxSetDelay(10);
                    fxSetEffect(fxSPLIT);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxHORIZ);
               END;
          29:  BEGIN {Split - Verti}
                    fxSetDelay(10);
                    fxSetEffect(fxSPLIT);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxVERT);
               END;
          30:  BEGIN {Weave - Horiz}
                    fxSetDelay(10);
                    fxSetEffect(fxWEAVE);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxHORIZ);
               END;
          31:  BEGIN {Weave - Verti}
                    fxSetDelay(10);
                    fxSetEffect(fxWEAVE);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxVERT);
               END;
          32:  BEGIN {Wipe - Up}
                    fxSetDelay(5);
                    fxSetEffect(fxWIPE);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxUP);
               END;
          33:  BEGIN {Wipe - Down}
                    fxSetDelay(5);
                    fxSetEffect(fxWIPE);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxDOWN);
               END;
          34:  BEGIN {Wipe - Left}
                    fxSetDelay(5);
                    fxSetEffect(fxWIPE);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxLEFT);
               END;
          35:  BEGIN {Wipe - Right}
                    fxSetDelay(5);
                    fxSetEffect(fxWIPE);
                    fxVirtualDisplay(IconHdr,0,0,x1,y1,x2,y2,fxRIGHT);
               END;
          END;
     END;

BEGIN
     CASE Size OF
     16:  BEGIN
               ASSIGN(FIcon16,RESOURCES+FName);
               {$I-}
               RESET(FIcon16);
               {$I+}
               IF IOResult=0 THEN
               BEGIN
                    READ(FIcon16,Icon16);
                    CLOSE(FIcon16);
                    gxDisplayVirtual(x,y,x+15,y+15,0,IconHdr,0,0);
                    grSetActiveVirtual(IconHdr);
                    grSetVirtual(gxTrue);
                    WITH Icon16 DO
                    BEGIN
                     FOR LoopX := 0 TO 15 DO
                      FOR loopY := 0 TO 15 DO
                       IF Matrix[loopX+1,loopY+1]<>255 THEN
                        GrPutPixel(loopX,loopY,Matrix[loopX+1,loopY+1]);
                    END;
                    grSetVirtual(gxFalse);
                    IF Effect=0 THEN gxVirtualDisplay(IconHdr,0,0,x,y,x+15,y+15,0)
                                ELSE DrawIconWithEffect(x,y,x+15,y+15);
               END;
          END;
     30:  BEGIN
               ASSIGN(FIcon30,RESOURCES+FName);
               {$I-}
               RESET(FIcon30);
               {$I+}
               IF IOResult=0 THEN
               BEGIN
                    READ(FIcon30,Icon30);
                    CLOSE(FIcon30);
                    gxDisplayVirtual(x,y,x+29,y+29,0,IconHdr,0,0);
                    grSetActiveVirtual(IconHdr);
                    grSetVirtual(gxTrue);
                    WITH Icon30 DO
                    BEGIN
                     FOR LoopX := 0 TO 29 DO
                      FOR loopY := 0 TO 29 DO
                       IF Matrix[loopX+1,loopY+1]<>255 THEN
                        GrPutPixel(loopX,loopY,Matrix[loopX+1,loopY+1]);
                    END;
                    grSetVirtual(gxFalse);
                    IF Effect=0 THEN gxVirtualDisplay(IconHdr,0,0,x,y,x+29,y+29,0)
                                ELSE DrawIconWithEffect(x,y,x+29,y+29);
               END;
          END;
     END;
END;


FUNCTION CalcX(T: Real): Real;
BEGIN
     CalcX := ((Ax*T*T*T)+(Bx*T*T)+(Cx*T)+Dx)/6;
END;


FUNCTION CalcY(T: Real): Real;
BEGIN
     CalcY := ((Ay*T*T*T)+(By*T*T)+(Cy*T)+Dy)/6;
END;


PROCEDURE ComputeCoeffs(N: Integer);
BEGIN
     Ax := -CtrlPt[N-1].X+3*CtrlPt[N].X-3*CtrlPt[N+1].X+CtrlPt[N+2].X;
     Bx := 3*CtrlPt[N-1].X-6*CtrlPt[N].X+3*CtrlPt[N+1].X;
     Cx := -3*CtrlPt[N-1].X+3*CtrlPt[N+1].X;
     Dx := CtrlPt[N-1].X+4*CtrlPt[N].X+CtrlPt[N+1].X;
     Ay := -CtrlPt[N-1].Y+3*CtrlPt[N].Y-3*CtrlPt[N+1].Y+CtrlPt[N+2].Y;
     By := 3*CtrlPt[N-1].Y-6*CtrlPt[N].Y+3*CtrlPt[N+1].Y;
     Cy := -3*CtrlPt[N-1].Y+3*CtrlPt[N+1].Y;
     Dy := CtrlPt[N-1].Y+4*CtrlPt[N].Y+CtrlPt[N+1].Y;
END;


PROCEDURE GrDrawBezier(x1,y1,x2,y2,x3,y3,x4,y4: Integer);
CONST Res = 10;
VAR  I,J        : Integer;
     X,Y,Lx,Ly  : Real;
     PolyPoints : Array[0..400] Of Integer;
     Counter    : Word;
BEGIN
     CtrlPt[1].X  := x1;
     CtrlPt[1].Y  := y1;
     CtrlPt[2].X  := x2;
     CtrlPt[2].Y  := y2;
     CtrlPt[3].X  := x3;
     CtrlPt[3].Y  := y3;
     CtrlPt[4].X  := x4;
     CtrlPt[4].Y  := y4;
     CtrlPt[-1]   := CtrlPt[1];
     CtrlPt[0]    := CtrlPt[1];
     CtrlPt[5]    := CtrlPt[4];
     CtrlPt[6]    := CtrlPt[4];
     Counter := 0;
     For I := 0 To 4 Do
     Begin
          ComputeCoeffs(I);
          Lx := CalcX(0);
          Ly := CalcY(0);
          For J := 1 To Res Do
          Begin
               X := CalcX(J/Res);
               Y := CalcY(J/Res);
               PolyPoints[Counter] := Round(Lx); INC(Counter);
               PolyPoints[Counter] := Round(Ly); INC(Counter);
               IF ((Round(Lx)<>Round(X)) OR (Round(Ly)<>Round(Y))) THEN
               BEGIN
                    PolyPoints[Counter] := Round(X); INC(Counter);
                    PolyPoints[Counter] := Round(Y); INC(Counter);
               END;
               Lx := X; Ly := Y;
          End;
     End;
     GrDrawPoly(@PolyPoints,Trunc((Counter+1)/2),GrOutline);
END;


PROCEDURE AddToBezier(x1,y1,x2,y2,x3,y3,x4,y4: Integer);
CONST Res = 10;
VAR  I,J        : Integer;
     X,Y,Lx,Ly  : Real;
BEGIN
     CtrlPt[1].X  := x1;
     CtrlPt[1].Y  := y1;
     CtrlPt[2].X  := x2;
     CtrlPt[2].Y  := y2;
     CtrlPt[3].X  := x3;
     CtrlPt[3].Y  := y3;
     CtrlPt[4].X  := x4;
     CtrlPt[4].Y  := y4;
     CtrlPt[-1]   := CtrlPt[1];
     CtrlPt[0]    := CtrlPt[1];
     CtrlPt[5]    := CtrlPt[4];
     CtrlPt[6]    := CtrlPt[4];
     For I := 0 To 4 Do
     Begin
          ComputeCoeffs(I);
          Lx := CalcX(0);
          Ly := CalcY(0);
          For J := 1 To Res Do
          Begin
               X := CalcX(J/Res);
               Y := CalcY(J/Res);
               PolyPoint^[WorkWord] := Round(Lx); INC(WorkWord);
               PolyPoint^[WorkWord] := Round(Ly); INC(WorkWord);
               IF ((Round(Lx)<>Round(X)) OR (Round(Ly)<>Round(Y))) THEN
               BEGIN
                    PolyPoint^[WorkWord] := Round(X); INC(WorkWord);
                    PolyPoint^[WorkWord] := Round(Y); INC(WorkWord);
               END;
               Lx := X; Ly := Y;
          End;
     End;
END;


FUNCTION GetStringWidth(VarNumber: Byte): Word;
CONST Widths : Array [1..31] Of Byte =
               (30,30,20,8,30,30,30,30,20,20,20,9,9,4,4,2,
               12,8,9,30,10,20,30,40,50,60,70,30,20,20,60);
BEGIN
     IF ((VarNumber>0) AND (VarNumber<32))
        THEN GetStringWidth := Widths[VarNumber]
        ELSE GetStringWidth := 1;
END;


PROCEDURE RaisedBox(x1,y1,x2,y2: Word);
BEGIN
     GrSetColor(8);
     GrDrawLine(x1,y2,x2,y2);
     GrDrawLine(x2,y1,x2,y2);
     GrSetColor(15);
     GrDrawLine(x1,y1,x2,y1);
     GrDrawLine(x1,y1,x1,y2);
END;


PROCEDURE InvertedBox(x1,y1,x2,y2: Word);
BEGIN
     GrSetColor(15);
     GrDrawLine(x1,y2,x2,y2);
     GrDrawLine(x2,y1,x2,y2);
     GrSetColor(8);
     GrDrawLine(x1,y1,x2,y1);
     GrDrawLine(x1,y1,x1,y2);
END;


PROCEDURE SystemField(Raw: _Raw_File);
VAR  Work : Word;
BEGIN
     Work := GetStringWidth(Raw.Colour4);
     GrSetFillStyle(GrFSolid,Raw.Colour1,GrOpaque);
     GrDrawRect(Raw.x1,Raw.y1,Raw.x1+(Work*8)+20,Raw.y1+20,GrFill);
     InvertedBox(Raw.x1,Raw.y1,Raw.x1+(Work*8)+20,Raw.y1+20);
END;


PROCEDURE LoadGraphicFile(FName: String; x1,y1,x2,y2: Word; DitherMatrix,GScale,Effect: Byte; Progress: Boolean);
VAR  Error    : Integer;
     imghdr   : IMGINHDR;
     dipal    : Array[0..767] Of Byte;
BEGIN
     IF NOT(_FileExists(FName)) THEN Exit;
     CASE DitherMatrix OF
     1:   gxSetDitherMatrix(gxMAGICSQ);
     2:   gxSetDitherMatrix(gxDISPERSED);
     3:   gxSetDitherMatrix(gxCLUSTERED);
     4:   gxSetDitherMatrix(gxNODITHER);
     END;
     {Get the image header}
     Error := imgFileGetHeader(FName,0,imghdr,@dipal[0]);
     IF (Error<>GxSuccess) THEN Exit;
     {Create the buffer}
     CreateVirtual(BMPFile,imghdr.width,imghdr.height,TheDisplay);
     CASE GScale OF
     0:   gxSetConvertPalette(GxPAL5,@P256);
     1:   gxSetConvertPalette(GxPAL5,@G256);
     END;
     Error := imgFileConvert(FName,0,BMPFile);
     IF Error=gxSuccess THEN
     BEGIN
          fxSetDelay(0);
          CASE Effect OF
          1:   BEGIN {Blind - Horiz}
                    fxSetGrain(2,2,2);
                    fxSetEffect(fxBLIND);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxHORIZ);
               END;
          2:   BEGIN {Blind - Verti}
                    fxSetGrain(2,2,2);
                    fxSetEffect(fxBLIND);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxVERT);
               END;
          3:   BEGIN {Crush - Horiz}
                    fxSetGrain(2,2,2);
                    fxSetEffect(fxCRUSH);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxHORIZ);
               END;
          4:   BEGIN {Crush - Verti}
                    fxSetGrain(2,2,2);
                    fxSetEffect(fxCRUSH);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxVERT);
               END;
          5:   BEGIN {Diagonal - Up/Right}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxDIAGONAL);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxUP+fxRIGHT);
               END;
          6:   BEGIN {Diagonal - Dn/Right}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxDIAGONAL);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxDOWN+fxRIGHT);
               END;
          7:   BEGIN {Diagonal - Up/Left}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxDIAGONAL);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxUP+fxLEFT);
               END;
          8:   BEGIN {Diagonal - Dn/Left}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxDIAGONAL);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxDOWN+fxLEFT);
               END;
          9:   BEGIN {Drip - Up}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxDRIP);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxUP);
               END;
          10:  BEGIN {Drip - Down}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxDRIP);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxDOWN);
               END;
          11:  BEGIN {Explode - In}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxEXPLODE);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxIN);
               END;
          12:  BEGIN {Explode - Out}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxEXPLODE);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxOUT);
               END;
          13:  BEGIN {Interleave - Horiz}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxINTERLEAVE);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxHORIZ);
               END;
          14:  BEGIN {Interleave - Verti}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxINTERLEAVE);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxVERT);
               END;
          15:  BEGIN {Random}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxRANDOM);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxNONE);
               END;
          16:  BEGIN {Sand - Up}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxSAND);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxUP);
               END;
          17:  BEGIN {Sand - Down}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxSAND);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxDOWN);
               END;
          18:  BEGIN {Slide - Up}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxSLIDE);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxUP);
               END;
          19:  BEGIN {Slide - Down}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxSLIDE);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxDOWN);
               END;
          20:  BEGIN {Slide - Left}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxSLIDE);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxLEFT);
               END;
          21:  BEGIN {Slide - Right}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxSLIDE);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxRIGHT);
               END;
          22:  BEGIN {Slide Blind - Horiz}
                    fxSetGrain(16,16,16);
                    fxSetEffect(fxSLIDEBLIND);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxHORIZ);
               END;
          23:  BEGIN {Slide Blind - Verti}
                    fxSetGrain(16,16,16);
                    fxSetEffect(fxSLIDEBLIND);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxVERT);
               END;
          24:  BEGIN {Slide Weave - Horiz}
                    fxSetGrain(16,16,16);
                    fxSetEffect(fxSLIDEWEAVE);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxHORIZ);
               END;
          25:  BEGIN {Slide Weave - Verti}
                    fxSetGrain(16,16,16);
                    fxSetEffect(fxSLIDEWEAVE);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxVERT);
               END;
          26:  BEGIN {Spiral - In}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxSPIRAL);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxIN);
               END;
          27:  BEGIN {Spiral - Out}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxSPIRAL);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxOUT);
               END;
          28:  BEGIN {Split - Horiz}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxSPLIT);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxHORIZ);
               END;
          29:  BEGIN {Split - Verti}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxSPLIT);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxVERT);
               END;
          30:  BEGIN {Weave - Horiz}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxWEAVE);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxHORIZ);
               END;
          31:  BEGIN {Weave - Verti}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxWEAVE);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxVERT);
               END;
          32:  BEGIN {Wipe - Up}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxWIPE);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxUP);
               END;
          33:  BEGIN {Wipe - Down}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxWIPE);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxDOWN);
               END;
          34:  BEGIN {Wipe - Left}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxWIPE);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxLEFT);
               END;
          35:  BEGIN {Wipe - Right}
                    fxSetGrain(4,4,4);
                    fxSetEffect(fxWIPE);
                    fxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,fxRIGHT);
               END;
          ELSE gxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,0);
          END;
     END;
     gxDestroyVirtual(BMPFile);
END;


PROCEDURE RedrawScreen(FName: String);
VAR  LoopX       : Word;
     LoopY       : Word;
     Loop        : Word;
     BytesRead   : Word;
BEGIN
     FRawFile.OpenFile(FName,SetFileMode);
     GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
     GrSetClipping(GrClip);
     REPEAT
       FRawFile.BlkRead(RawFile,SizeOf(RawFile),BytesRead);
       IF (BytesRead<>0) THEN
       BEGIN
           CASE RawFile.Number OF
           1:   BEGIN {SCREEN BACKGROUND}
                     CASE RawFile.Style OF
                     0:   BEGIN {SOLID}
                               GrSetFillStyle(GrFSolid,RawFile.Colour1,GrOpaque);
                               GrDrawRect(0,0,GraphMaxX,GraphMaxY,GrFill);
                          END;
                     1:   BEGIN {ICON}
                               GrSetFillStyle(GrFSolid,0,GrOpaque);
                               GrDrawRect(0,0,GraphMaxX,GraphMaxY,GrFill);
                               IF _FileExists(RESOURCES+RawFile.Crc32+'.ICO') THEN
                               BEGIN
                                    ASSIGN(FIcon30,RESOURCES+RawFile.Crc32+'.ICO');
                                    RESET(FIcon30);
                                    READ(FIcon30,Icon30);
                                    CLOSE(FIcon30);
                                    gxDisplayVirtual(0,0,29,29,0,IconHdr,0,0);
                                    grSetActiveVirtual(IconHdr);
                                    grSetVirtual(gxTrue);
                                    WITH Icon30 DO
                                    BEGIN
                                      FOR LoopX := 0 TO 29 DO
                                        FOR loopY := 0 TO 29 DO
                                          IF Matrix[loopX+1,loopY+1]<>255 THEN
                                             GrPutPixel(loopX,loopY,Matrix[loopX+1,loopY+1]);
                                    END;
                                    grSetVirtual(gxFalse);
                                    gxVirtualDisplay(IconHdr,0,0,0,0,29,29,0);
                                    Get(0,0,29,29);
                                    LoopX := 30;
                                    REPEAT
                                          Put(LoopX,0,False);
                                          INC(LoopX,30);
                                    UNTIL (LoopX>GraphMaxX);
                                    Put(0,0,True);
                                    Get(0,0,GraphMaxX,29);
                                    LoopY := 30;
                                    REPEAT
                                          Put(0,LoopY,False);
                                          INC(LoopY,30);
                                    UNTIL (LoopY>GraphMaxY);
                                    Put(0,0,True);
                               END;
                          END;
                     3:   TileGraphicFile(RESOURCES+RawFile.Crc32+'.IMG');
                     ELSE BEGIN
                               GrSetFillStyle(GrFSolid,0,GrOpaque);
                               GrDrawRect(0,0,GraphMaxX,GraphMaxY,GrFill);
                          END;
                     END;
                END;
           4:   BEGIN {LINES}
                     GrSetColor(RawFile.colour1);
                     GrSetLineStyle(GrLSolid,RawFile.colour2);
                     GrDrawLine(RawFile.x1,RawFile.y1,RawFile.x2,RawFile.y2);
                     GrSetLineStyle(GrLSolid,1);
                END;
           5:   BEGIN {RECTANGLES}
                     IF RawFile.Colour2=255 THEN
                     BEGIN
                          IF RawFile.Colour1<>255 THEN
                          BEGIN
                               GrSetColor(RawFile.colour1);
                               GrDrawRect(RawFile.x1,RawFile.y1,RawFile.x2,RawFile.y2,GrOutline);
                          END;
                     END
                     ELSE
                     BEGIN
                          IF RawFile.Colour1=255 THEN
                          BEGIN
                               GrSetFillStyle(GrFSolid,RawFile.Colour2,GrOpaque);
                               GrDrawRect(RawFile.X1,RawFile.Y1,RawFile.X2,RawFile.Y2,GrFill);
                          END
                          ELSE
                          BEGIN
                               GrSetColor(RawFile.colour1);
                               GrSetFillStyle(GrFSolid,RawFile.Colour2,GrOpaque);
                               GrDrawRect(RawFile.X1,RawFile.Y1,RawFile.X2,RawFile.Y2,GrFill+GrOutline);
                          END;
                     END;
                END;
           6:   BEGIN {ELLIPSES}
                     IF RawFile.Colour2=255 THEN
                     BEGIN
                          IF RawFile.Colour1<>255 THEN
                          BEGIN
                               GrSetColor(RawFile.colour1);
                               GrDrawEllipse(RawFile.x1,RawFile.y1,RawFile.x2,RawFile.y2,GrOutline);
                          END;
                     END
                     ELSE
                     BEGIN
                          IF RawFile.Colour1=255 THEN
                          BEGIN
                               GrSetFillStyle(GrFSolid,RawFile.Colour2,GrOpaque);
                               GrDrawEllipse(RawFile.X1,RawFile.Y1,RawFile.X2,RawFile.Y2,GrFill);
                          END
                          ELSE
                          BEGIN
                               GrSetColor(RawFile.colour1);
                               GrSetFillStyle(GrFSolid,RawFile.Colour2,GrOpaque);
                               GrDrawEllipse(RawFile.X1,RawFile.Y1,RawFile.X2,RawFile.Y2,GrFill+GrOutline);
                          END;
                     END;
                END;
           7:   BEGIN {FLOODFILL}
                     GrSetFillStyle(GrFSolid,RawFile.Colour1,GrOpaque);
                     GrFloodSpill(RawFile.x1,RawFile.y1);
                END;
           8:   BEGIN {Normal Buttons}
                     GrSetColor(0);
                     GrSetFillStyle(GrFSolid,RawFile.Colour1,GrOpaque);
                     GrDrawRect(RawFile.X1,RawFile.Y1,RawFile.X2,RawFile.Y2,GrFill+GrOutline);
                     GrSetColor(RawFile.Colour3);
                     GrDrawLine(RawFile.X1+1,RawFile.Y2-1,RawFile.X2-1,RawFile.Y2-1);
                     GrDrawLine(RawFile.X2-1,RawFile.Y1+1,RawFile.X2-1,RawFile.Y2-1);
                     GrSetColor(RawFile.Colour2);
                     GrDrawLine(RawFile.X1+1,RawFile.Y1+1,RawFile.X1+1,RawFile.Y2-1);
                     GrDrawLine(RawFile.X1+1,RawFile.Y1+1,RawFile.X2-1,RawFile.Y1+1);
                END;
           9:   BEGIN {Panel Buttons}
                     GrSetFillStyle(GrFSolid,RawFile.Colour1,GrOpaque);
                     GrDrawRect(RawFile.X1,RawFile.Y1,RawFile.X2,RawFile.Y2,GrFill);
                     GrSetColor(RawFile.Colour2);
                     GrDrawRect(RawFile.X1+1,RawFile.Y1+1,RawFile.X2,RawFile.Y2,GrOutline);
                     GrSetColor(RawFile.Colour3);
                     GrDrawLine(RawFile.X1,RawFile.Y1,RawFile.X1,RawFile.Y2);
                     GrDrawLine(RawFile.X1,RawFile.Y1,RawFile.X2,RawFile.Y1);
                     GrDrawLine(RawFile.X1+2,RawFile.Y2-1,RawFile.X2-1,RawFile.Y2-1);
                     GrDrawLine(RawFile.X2-1,RawFile.Y1+2,RawFile.X2-1,RawFile.Y2-1);
                END;
           10:  BEGIN {Pop Buttons}
                     SystemIcon(RawFile.x1,RawFile.y1,21);
                END;
           11:  BEGIN {Window}
                     DrawTheWindow(RawFile);
                END;
           12:  BEGIN {Icon}
                     DrawIcon(RawFile.X1,RawFile.Y1,RawFile.Colour1,
                              RawFile.Style,RawFile.Colour3,RawFile.Crc32+'.ICO');
                END;
           13:  BEGIN {Text}
                     DoText(RawFile);
                END;
           14:  BEGIN {POLYLINES}
                     GrSetColor(RawFile.colour1);
                     GrSetLineStyle(GrLSolid,RawFile.colour2);
                     GrDrawLine(RawFile.x1,RawFile.y1,RawFile.x2,RawFile.y2);
                     REPEAT
                           FRawFile.BlkRead(RawFile,SizeOf(RawFile),BytesRead);
                           GrDrawLine(RawFile.x1,RawFile.y1,RawFile.x2,RawFile.y2);
                     UNTIL RawFile.Style=255;
                     GrSetLineStyle(GrLSolid,1);
                END;
           15:  BEGIN {POLYGONS}
                     GrSetColor(RawFile.colour1);
                     GrSetFillStyle(GrFSolid,RawFile.Colour2,GrOpaque);
                     LoopX := 2;
                     PolyPoint^[0] := RawFile.x1;
                     PolyPoint^[1] := RawFile.y1;
                     REPEAT
                           FRawFile.BlkRead(RawFile,SizeOf(RawFile),BytesRead);
                           IF RawFile.Style<>255 THEN
                           BEGIN
                                PolyPoint^[LoopX] := RawFile.x1; INC(LoopX);
                                PolyPoint^[LoopX] := RawFile.y1; INC(LoopX);
                           END;
                     UNTIL RawFile.Style=255;
                     PolyPoint^[LoopX] := RawFile.x1; INC(LoopX);
                     PolyPoint^[LoopX] := RawFile.y1; INC(LoopX);
                     PolyPoint^[LoopX] := RawFile.x2; INC(LoopX);
                     PolyPoint^[LoopX] := RawFile.y2; INC(LoopX);
                     IF RawFile.colour1=255
                        THEN GrDrawPoly(@PolyPoint^,Trunc(LoopX/2),GrFill)
                        ELSE GrDrawPoly(@PolyPoint^,Trunc(LoopX/2),GrOutline+GrFill);
                END;
           16:  BEGIN {BEZIER CURVES}
                     GrSetColor(RawFile.colour1);
                     GrSetLineStyle(GrLSolid,RawFile.colour2);
                     GrDrawBezier(RawFile.x1,RawFile.y1,RawFile.Colour3,RawFile.Colour4,
                                  RawFile.Colour5,RawFile.Colour6,RawFile.x2,RawFile.y2);
                     REPEAT
                           FRawFile.BlkRead(RawFile,SizeOf(RawFile),BytesRead);
                           GrDrawBezier(RawFile.x1,RawFile.y1,RawFile.Colour3,RawFile.Colour4,
                                        RawFile.Colour5,RawFile.Colour6,RawFile.x2,RawFile.y2);
                     UNTIL RawFile.Style=255;
                     GrSetLineStyle(GrLSolid,1);
                END;
           17:  BEGIN {BEZIER OBJECTS}
                     GrSetColor(RawFile.colour1);
                     GrSetFillStyle(GrFSolid,RawFile.Colour2,GrOpaque);
                     WorkWord := 0;
                     AddToBezier(RawFile.x1,RawFile.y1,RawFile.Colour3,RawFile.Colour4,
                                 RawFile.Colour5,RawFile.Colour6,RawFile.x2,RawFile.y2);
                     REPEAT
                           FRawFile.BlkRead(RawFile,SizeOf(RawFile),BytesRead);
                           AddToBezier(RawFile.x1,RawFile.y1,RawFile.Colour3,RawFile.Colour4,
                                       RawFile.Colour5,RawFile.Colour6,RawFile.x2,RawFile.y2);
                     UNTIL RawFile.Style=255;
                     IF RawFile.colour1=255
                        THEN GrDrawPoly(@PolyPoint^,Trunc((WorkWord+1)/2),GrFill)
                        ELSE GrDrawPoly(@PolyPoint^,Trunc((WorkWord+1)/2),GrFill+GrOutline);
                END;
           18:  BEGIN {Progress Indicators}
                END;
           19:  BEGIN {PROMPT BOXES}
                     SystemField(RawFile);
                END;
           20:  BEGIN {DIMENSION FRAMES}
                     GrSetColor(RawFile.Colour2);
                     GrDrawLine(RawFile.x1,RawFile.y2,RawFile.x2,RawFile.y2);
                     GrDrawLine(RawFile.x2,RawFile.y1,RawFile.x2,RawFile.y2);
                     GrSetColor(RawFile.Colour1);
                     GrDrawLine(RawFile.x1,RawFile.y1,RawFile.x2,RawFile.y1);
                     GrDrawLine(RawFile.x1,RawFile.y1,RawFile.x1,RawFile.y2);
                END;
           21:  BEGIN {WORK AREAS}
                     GrSetColor(0);
                     GrSetFillStyle(GrFSolid,15,GrOpaque);
                     GrDrawRect(RawFile.x1,RawFile.y1,RawFile.x2,RawFile.y2,GrOutline+GrFill);
                     GrSetFillStyle(GrFSolid,7,GrOpaque);
                     GrDrawRect(RawFile.x2-19,RawFile.y1+1,RawFile.x2-1,RawFile.y2-1,GrFill);
                     GrDrawLine(RawFile.x2-20,RawFile.y1,RawFile.x2-20,RawFile.y2);
                     GrDrawLine(RawFile.x2-20,RawFile.y1+20,RawFile.x2,RawFile.y1+20);
                     GrDrawLine(RawFile.x2-20,RawFile.y2-20,RawFile.x2,RawFile.y2-20);
                     RaisedBox(RawFile.x2-19,RawFile.y1+1,RawFile.x2-1,RawFile.y1+19);
                     RaisedBox(RawFile.x2-19,RawFile.y2-19,RawFile.x2-1,RawFile.y2-1);
                END;
           22:  BEGIN {GRAPHIC IMAGES}
                     LoadGraphicFile(RESOURCES+RawFile.Crc32+'.IMG',RawFile.x1,RawFile.y1,
                                     RawFile.x2,RawFile.y2,RawFile.Colour2,RawFile.Colour1,
                                     RawFile.Colour3,True);
                END;
           23:  BEGIN {String Pad}
                END;
           24:  BEGIN
                     DrawIcon(RawFile.X1,RawFile.Y1,RawFile.Colour1,
                              RawFile.Style,RawFile.Colour3,RawFile.Crc32+'.CC');
                END;
           25:  BEGIN
                     DrawIcon(RawFile.X1,RawFile.Y1,RawFile.Colour1,
                              RawFile.Style,RawFile.Colour9,RawFile.Crc32+'.ANI');
                END;
           26:  BEGIN {PLAIN ARCS}
                     GrSetColor(RawFile.colour1);
                     GrSetLineStyle(GrLSolid,RawFile.colour2);
                     GrDrawBezier(RawFile.x1,RawFile.y1,RawFile.Colour3,RawFile.Colour4,
                                  RawFile.Colour5,RawFile.Colour6,RawFile.x2,RawFile.y2);
                     GrSetLineStyle(GrLSolid,1);
                END;
           27:  BEGIN {Clickable Regions}
                END;
           28:  BEGIN
                     GrSetColor(0);
                     GrSetFillStyle(GrFSolid,15,GrOpaque);
                     GrDrawRect(RawFile.x1,RawFile.y1,RawFile.x2,RawFile.y2,GrOutline+GrFill);
                     GrSetFillStyle(GrFSolid,7,GrOpaque);
                     GrDrawRect(RawFile.x2-19,RawFile.y1+1,RawFile.x2-1,RawFile.y2-1,GrFill);
                     GrDrawLine(RawFile.x2-20,RawFile.y1,RawFile.x2-20,RawFile.y2);
                     GrDrawLine(RawFile.x2-20,RawFile.y1+20,RawFile.x2,RawFile.y1+20);
                     GrDrawLine(RawFile.x2-20,RawFile.y2-20,RawFile.x2,RawFile.y2-20);
                     RaisedBox(RawFile.x2-19,RawFile.y1+1,RawFile.x2-1,RawFile.y1+19);
                     RaisedBox(RawFile.x2-19,RawFile.y2-19,RawFile.x2-1,RawFile.y2-1);
                END;
           END;
       END;
     UNTIL BytesRead=0;
     FRawFile.CloseFile;
     GrSetClipRegion(0,0,GraphMaxX,GraphMaxY);
     GrSetClipping(GrClip);
END;


PROCEDURE SetDefaultPalette;
VAR  Error    : Integer;
     Ct       : Word;
BEGIN
     Error := gxGetConvertPalette(GxPAL5,@P256);
     Ct    := 0;
     {Basic Palette}
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 42; INC(ct);
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 42; INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);
     P256[Ct] := 21; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 21; INC(ct);
     P256[Ct] := 21; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 21; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 21; INC(ct);
     P256[Ct] := 21; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 21; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 21; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     {Purple}
     P256[Ct] := 15; INC(ct);  P256[Ct] := 3;  INC(ct);  P256[Ct] := 12; INC(ct);
     P256[Ct] := 18; INC(ct);  P256[Ct] := 6;  INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 21; INC(ct);  P256[Ct] := 9;  INC(ct);  P256[Ct] := 18; INC(ct);
     P256[Ct] := 24; INC(ct);  P256[Ct] := 12; INC(ct);  P256[Ct] := 21; INC(ct);
     P256[Ct] := 28; INC(ct);  P256[Ct] := 16; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 32; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 29; INC(ct);
     P256[Ct] := 36; INC(ct);  P256[Ct] := 24; INC(ct);  P256[Ct] := 33; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 28; INC(ct);  P256[Ct] := 37; INC(ct);
     P256[Ct] := 44; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 41; INC(ct);
     P256[Ct] := 48; INC(ct);  P256[Ct] := 36; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 52; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 49; INC(ct);
     P256[Ct] := 56; INC(ct);  P256[Ct] := 44; INC(ct);  P256[Ct] := 53; INC(ct);
     P256[Ct] := 58; INC(ct);  P256[Ct] := 46; INC(ct);  P256[Ct] := 55; INC(ct);
     P256[Ct] := 60; INC(ct);  P256[Ct] := 48; INC(ct);  P256[Ct] := 57; INC(ct);
     P256[Ct] := 62; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 59; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 54; INC(ct);  P256[Ct] := 60; INC(ct);
     {Blues}
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 18; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 23; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 28; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 33; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 38; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 43; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 48; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 53; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 58; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 0;  INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 8;  INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     {Dusty Blues}
     P256[Ct] := 7;  INC(ct);  P256[Ct] := 10; INC(ct);  P256[Ct] := 31; INC(ct);
     P256[Ct] := 12; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 41; INC(ct);
     P256[Ct] := 17; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 41; INC(ct);
     P256[Ct] := 22; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 46; INC(ct);
     P256[Ct] := 27; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 51; INC(ct);
     P256[Ct] := 32; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 56; INC(ct);
     P256[Ct] := 37; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 61; INC(ct);
     P256[Ct] := 41; INC(ct);  P256[Ct] := 48; INC(ct);  P256[Ct] := 63; INC(ct);

     P256[Ct] := 15; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 60; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 55; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 58; INC(ct);  P256[Ct] := 31; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 5; INC(ct);  P256[Ct] := 22; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 10; INC(ct);  P256[Ct] := 27; INC(ct);  P256[Ct] := 5; INC(ct);
     P256[Ct] := 15; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 37; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 47; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 57; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 62; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 5; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 26; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 34; INC(ct);
     P256[Ct] := 18; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 43; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 48; INC(ct);
     P256[Ct] := 52; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 54; INC(ct);
     P256[Ct] := 58; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 34; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 38; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 46; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 54; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 58; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 62; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 22; INC(ct);  P256[Ct] := 22; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 32; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 43; INC(ct);  P256[Ct] := 43; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 52; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 57; INC(ct);  P256[Ct] := 57; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 9; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 14; INC(ct);  P256[Ct] := 5; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 19; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 24; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 29; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 34; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 39; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 55; INC(ct);  P256[Ct] := 44; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 60; INC(ct);  P256[Ct] := 49; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 43; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 48; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 57; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 29; INC(ct);  P256[Ct] := 12; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 37; INC(ct);  P256[Ct] := 16; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 41; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 48; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 53; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 56; INC(ct);  P256[Ct] := 21; INC(ct);  P256[Ct] := 3; INC(ct);
     P256[Ct] := 59; INC(ct);  P256[Ct] := 24; INC(ct);  P256[Ct] := 6; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 28; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 38; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 43; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 49; INC(ct);  P256[Ct] := 18; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 54; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 56; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 58; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 0; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 55; INC(ct);
     P256[Ct] := 0; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 60; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 41; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 52; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 43; INC(ct);  P256[Ct] := 0; INC(ct);  P256[Ct] := 27; INC(ct);
     P256[Ct] := 46; INC(ct);  P256[Ct] := 1; INC(ct);  P256[Ct] := 29; INC(ct);
     P256[Ct] := 53; INC(ct);  P256[Ct] := 2; INC(ct);  P256[Ct] := 34; INC(ct);
     P256[Ct] := 59; INC(ct);  P256[Ct] := 8; INC(ct);  P256[Ct] := 36; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 12; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 41; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 44; INC(ct);
     P256[Ct] := 62; INC(ct);  P256[Ct] := 31; INC(ct);  P256[Ct] := 47; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 49; INC(ct);
     P256[Ct] := 62; INC(ct);  P256[Ct] := 44; INC(ct);  P256[Ct] := 56; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 49; INC(ct);  P256[Ct] := 60; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 10; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 55; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 5;  INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 55; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 60; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 58; INC(ct);
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 10; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 0;  INC(ct);  P256[Ct] := 17; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 10; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 15; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 45; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 55; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);
     P256[Ct] := 25; INC(ct);  P256[Ct] := 15; INC(ct);  P256[Ct] := 0;  INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 5;  INC(ct);
     P256[Ct] := 35; INC(ct);  P256[Ct] := 25; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 15; INC(ct);
     P256[Ct] := 45; INC(ct);  P256[Ct] := 35; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 25; INC(ct);
     P256[Ct] := 55; INC(ct);  P256[Ct] := 45; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 60; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 35; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 55; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 60; INC(ct);  P256[Ct] := 45; INC(ct);
     {Grays}
     P256[Ct] := 2;  INC(ct);  P256[Ct] := 2;  INC(ct);  P256[Ct] := 2;  INC(ct);
     P256[Ct] := 5;  INC(ct);  P256[Ct] := 5;  INC(ct);  P256[Ct] := 5;  INC(ct);
     P256[Ct] := 8;  INC(ct);  P256[Ct] := 8;  INC(ct);  P256[Ct] := 8;  INC(ct);
     P256[Ct] := 10; INC(ct);  P256[Ct] := 10; INC(ct);  P256[Ct] := 10; INC(ct);
     P256[Ct] := 12; INC(ct);  P256[Ct] := 12; INC(ct);  P256[Ct] := 12; INC(ct);
     P256[Ct] := 14; INC(ct);  P256[Ct] := 14; INC(ct);  P256[Ct] := 14; INC(ct);
     P256[Ct] := 16; INC(ct);  P256[Ct] := 16; INC(ct);  P256[Ct] := 16; INC(ct);
     P256[Ct] := 18; INC(ct);  P256[Ct] := 18; INC(ct);  P256[Ct] := 18; INC(ct);
     P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);  P256[Ct] := 20; INC(ct);
     P256[Ct] := 22; INC(ct);  P256[Ct] := 22; INC(ct);  P256[Ct] := 22; INC(ct);
     P256[Ct] := 24; INC(ct);  P256[Ct] := 24; INC(ct);  P256[Ct] := 24; INC(ct);
     P256[Ct] := 26; INC(ct);  P256[Ct] := 26; INC(ct);  P256[Ct] := 26; INC(ct);
     P256[Ct] := 28; INC(ct);  P256[Ct] := 28; INC(ct);  P256[Ct] := 28; INC(ct);
     P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);  P256[Ct] := 30; INC(ct);
     P256[Ct] := 32; INC(ct);  P256[Ct] := 32; INC(ct);  P256[Ct] := 32; INC(ct);
     P256[Ct] := 34; INC(ct);  P256[Ct] := 34; INC(ct);  P256[Ct] := 34; INC(ct);
     P256[Ct] := 36; INC(ct);  P256[Ct] := 36; INC(ct);  P256[Ct] := 36; INC(ct);
     P256[Ct] := 38; INC(ct);  P256[Ct] := 38; INC(ct);  P256[Ct] := 38; INC(ct);
     P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);  P256[Ct] := 40; INC(ct);
     P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);  P256[Ct] := 42; INC(ct);
     P256[Ct] := 44; INC(ct);  P256[Ct] := 44; INC(ct);  P256[Ct] := 44; INC(ct);
     P256[Ct] := 46; INC(ct);  P256[Ct] := 46; INC(ct);  P256[Ct] := 46; INC(ct);
     P256[Ct] := 48; INC(ct);  P256[Ct] := 48; INC(ct);  P256[Ct] := 48; INC(ct);
     P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);  P256[Ct] := 50; INC(ct);
     P256[Ct] := 52; INC(ct);  P256[Ct] := 52; INC(ct);  P256[Ct] := 52; INC(ct);
     P256[Ct] := 54; INC(ct);  P256[Ct] := 54; INC(ct);  P256[Ct] := 54; INC(ct);
     P256[Ct] := 56; INC(ct);  P256[Ct] := 56; INC(ct);  P256[Ct] := 56; INC(ct);
     P256[Ct] := 58; INC(ct);  P256[Ct] := 58; INC(ct);  P256[Ct] := 58; INC(ct);
     P256[Ct] := 61; INC(ct);  P256[Ct] := 61; INC(ct);  P256[Ct] := 61; INC(ct);
     P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);  P256[Ct] := 63; INC(ct);
     Error := gxSetConvertPalette(GxPAL5,@P256);
     Error := GxSetDisplayPalette(@P256);
     {Grayscale palette}
     FillChar(G256,SizeOf(G256),0);
     FOR Ct := 678 TO 767 DO G256[Ct] := P256[Ct];
END;


PROCEDURE ShutDownTheThing;
BEGIN
     FRawFile.Done;
     Dispose(PolyPoint);
     gxDestroyVirtual(IconHdr);
     txFreeFont(SystemFont);
     txFreeFont(HelvFont);
     txFreeFont(RomanFont);
     IF (LastFont<>'') THEN txFreeFont(workfont);
     txFreeFont(BitFont8x16);
     txFreeFont(BitFont8x14);
     txFreeFont(BitFont8x8);
     gxSetMode(GxText);
     gxDone;
     Dispose(GFXBuffer);
     Halt;
END;


BEGIN
     FileMode := SetFileMode;
     InSpec := ParamStr(1);
     IF ((InSpec='-?') OR (InSpec='')) THEN
     BEGIN
          AppHeader('SGView - SVGA Screen Viewer');
          Window(1,1,80,25);
          GotoXY(1,7);
          TextColor(7);
          WriteLn('SGView Command Line Options:');
          WriteLn;
          WriteLn('      SGVIEW.EXE <filespec>');
          WriteLn;
          WriteLn('             <filespec>   : Complete path & filename of *.SG screens.');
          WriteLn('                            Wildcards may be used.');
          TextColor(7);
          Halt;
     END;
     IF SGDirectory[LENGTH(SGDirectory)]='\' THEN DEC(SGDirectory[0]);
     SGDirectory := '\SHOTGUN';
     RESOURCES := SGDirectory+'\RESLOCAL\';
     GraphicsLibrary := SGDirectory+'\BIN\GUI.GXL';
     New(GFXBuffer);
     GxSetBuffer(@GFXBuffer^,SizeOf(GFXBuffer^));
     GraphicsMode_BS(256,640,True,True);
     SetDefaultPalette;
     CreateVirtual(IconHdr,30,30,TheDisplay);
     gxOpenLib(gxGXL,GraphicsLibrary,GraphLib,Nil,0);
     txLibFont(gxCMM,GraphLib,'GUI_____.GFT',SystemFont);
     txLibFont(gxCMM,GraphLib,'HELV____.GFT',HelvFont);
     txLibFont(gxCMM,GraphLib,'ROMAN___.GFT',RomanFont);
     txLibFont(gxCMM,GraphLib,'BIT8X16.GFT',BitFont8x16);
     txLibFont(gxCMM,GraphLib,'BIT8X14.GFT',BitFont8x14);
     txLibFont(gxCMM,GraphLib,'BIT8X8.GFT',BitFont8x8);
     gxCloseLib(GraphLib);
     txSetFont(SystemFont);
     New(PolyPoint);
     FRawFile.Init(32768);
     FindFirst(InSpec,Anyfile-Directory-VolumeID,DirInfo);
     WHILE DosError = 0 DO
     BEGIN
          RedrawScreen(_GetFilePath(InSpec)+DirInfo.Name);
          REPEAT
                TimeSlice;
          UNTIL KeyPressed;
          C := ReadKey;
          CASE C OF
          #0:  C := ReadKey;
          #27: ShutDownTheThing;
          END;
          FindNext(DirInfo);
     END;
     ShutDownTheThing;
END.
