{$I DEFINES.INC}
UNIT _Images;


INTERFACE


FUNCTION  ScaleImage         (Source,Dest: String; Var W,H: Word; SetW,SetH: Word) : Boolean;
PROCEDURE LoadGraphicLib     (FName: String; x1,y1,x2,y2: Word);
PROCEDURE LoadGraphicFile    (FName: String; x1,y1,x2,y2: Word; DitherMatrix,GScale,Effect: Byte; Progress: Boolean);
PROCEDURE TileGraphicFile    (FName: String);


IMPLEMENTATION


USES Img2_Bp,Gx2_Bp,Gx2_BpVC,Fx2_Bp,Globals,BsGraph,_Virtual,Screens,BsFile;


PROCEDURE LoadGraphicLib(FName: String; x1,y1,x2,y2: Word);
VAR  Error    : Integer;
     imghdr   : IMGINHDR;
     dipal    : Array[0..767] Of Byte;
BEGIN
     gxSetDitherMatrix(gxNODITHER);
     Error := gxOpenLib(gxGXL,GraphicsLibrary,GraphLib,Nil,0);
     IF (Error<>GxSuccess) THEN Exit;
     {Get the image header}
     Error := imgLibGetHeader(GraphLib,FName,0,imghdr,@dipal[0]);
     IF (Error<>GxSuccess) THEN
     BEGIN
          Error := gxCloseLib(GraphLib);
          Exit;
     END;
     {Create the buffer}
     CreateVirtual(BMPFile,imghdr.width,imghdr.height,TheDisplay);
     gxSetConvertPalette(GxPAL5,@P256);
     Error := imgLibConvert(GraphLib,FName,0,BMPFile);
     IF Error=gxSuccess THEN gxVirtualDisplay(BMPFile,0,0,x1,y1,x2,y2,0);
     gxCloseLib(GraphLib);
     DestroyVirtual(BMPFile);
END;
{==========================================================================}
{                                                                          }
{  Load a bitmap file to the screen (with convert of course)               }
{                                                                          }
{==========================================================================}
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
     DestroyVirtual(BMPFile);
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
          fxVirtualDisplay(BMPFile,0,0,0,0,GraphMaxX,YWindow,fxDOWN);
          fxSetTile(fxFALSE);
     END;
     DestroyVirtual(BMPFile);
END;


FUNCTION ScaleImage(Source,Dest: String; Var W,H: Word; SetW,SetH: Word) : Boolean;
VAR  Error   : Integer;
     imghdr  : IMGINHDR;
     dipal   : Array[0..767] Of Byte;
     gxctype : Integer;
     gxtype  : Integer;
BEGIN
     {Get the image header}
     Error := imgFileGetHeader(Source,0,imghdr,@dipal[0]);
     IF (Error<>GxSuccess) THEN
     BEGIN
          ScaleImage := False;
          Exit;
     END;
     IF ImgHdr.Format=imgJPEG THEN system_prompt('',180)
                              ELSE system_prompt('',179);
     W := imghdr.width;
     H := imghdr.height;
     gxCType := gxGetColorType(imghdr.BitsPerPixel);
     gxType  := gxMatchDisplayType(imghdr.Width,imghdr.Height,gxctype,gxMATCHANY);
     CreateVirtual(BMPFile,SetW,SetH,gxType);
     imgFileScale(Source,0,BMPFile);
     imgVirtualFile(BMPFile,0,0,SetW-1,SetH-1,Dest,imgBMP,imgTRUNC,@dipal[0]);
     DestroyVirtual(BMPFile);
     _EraseFile(_NoExtension(Dest)+'.TMP');
     ScaleImage := True;
END;


END.
