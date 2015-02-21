{$I DEFINES.INC}
UNIT _Text;


INTERFACE


USES Globals,Shotgun;


FUNCTION  GetStringWidth(VarNumber: Byte): Word;
FUNCTION  StripColourCodes(InString: String): String;
FUNCTION  ConvertColourCodes(InString: String): String;
PROCEDURE GetFontSize(FontType: Byte; FName,TxtString: String; VAR W,H: Word);
PROCEDURE OutTextXY(x,y,f,b,size: word; s: String);
PROCEDURE OutTextXYFR(x,y,f,b: word; s: String);
PROCEDURE OutTextXYS(x,y,f,b: word; s: String);
PROCEDURE DoText(Raw: _Raw_File);
PROCEDURE LoadFontFiles;
PROCEDURE CursorOff;
PROCEDURE CursorOn;


IMPLEMENTATION


USES Tx2_Bp,Gx2_Bp,Gx2_BpVC,Gr2_Bp,ErrorOut,BsString;


FUNCTION FontLoaded(FileName: String; VAR TextHeader: TxHeader): Boolean;
VAR  AnyGood : Boolean;
     Error   : Integer;
LABEL          AllIsOk;
BEGIN
     AnyGood := True;
     Error := txFileFont(gxCMM,FileName,TextHeader);
     IF Error=txSuccess THEN GOTO AllIsOk;
     AnyGood := False;
     AllIsOk:
     FontLoaded := AnyGood;
END;


PROCEDURE GetFontSize(FontType: Byte; FName,TxtString: String; VAR W,H: Word);
VAR  Ascent,Descent : Integer;
BEGIN
     TxtString := StripColourCodes(TxtString);
     CASE FontType OF
     0:   BEGIN
               IF ((FName<>LastFont) AND (LastFont<>'')) THEN txFreeFont(workfont);
               IF (FName<>LastFont) THEN
               BEGIN
                    IF NOT(FontLoaded(FONTDir+FName,workfont)) THEN DropError(10);
               END;
               LastFont := FName;
               txSetFont(workfont);
               W := txStrWidth(TxtString);
               TxGetPos(Ascent,Descent);
               H := Ascent+Descent;
               txSetFont(SystemFont);
          END;
     1:   BEGIN
               txSetFont(SystemFont);
               W := txStrWidth(TxtString);
               TxGetPos(Ascent,Descent);
               H := Ascent+Descent;
          END;
     2:   BEGIN
               w := Length(TxtString)*8;
               h := 16;
          END;
     3:   BEGIN
               w := Length(TxtString)*8;
               h := 14;
          END;
     4:   BEGIN
               w := Length(TxtString)*8;
               h := 8;
          END;
     5:   BEGIN
               txSetFont(HelvFont);
               W := txStrWidth(TxtString);
               TxGetPos(Ascent,Descent);
               H := Ascent+Descent;
               txSetFont(SystemFont);
          END;
     6:   BEGIN
               txSetFont(RomanFont);
               W := txStrWidth(TxtString);
               TxGetPos(Ascent,Descent);
               H := Ascent+Descent;
               txSetFont(SystemFont);
          END;
     END;
END;


PROCEDURE DoText(Raw: _Raw_File);
VAR  Face  : Integer;
     Loop  : Word;
     X     : Word;
BEGIN
     IF Raw.Colour7=0 THEN
     BEGIN
          IF ((Raw.ObjFile<>LastFont) AND (LastFont<>'')) THEN txFreeFont(workfont);
          IF (Raw.ObjFile<>LastFont) THEN
          BEGIN
               IF NOT(FontLoaded(FONTDir+Raw.ObjFile,workfont)) THEN DropError(11);
          END;
          LastFont := Raw.ObjFile;
          txSetFont(workfont);
     END
     ELSE
     BEGIN
          CASE Raw.Colour7 OF
          1:   txSetFont(SystemFont);
          2:   txSetFont(BitFont8x16);
          3:   txSetFont(BitFont8x14);
          4:   txSetFont(BitFont8x8);
          5:   txSetFont(HelvFont);
          6:   txSetFont(RomanFont);
          END;
     END;

     Face := txTRANS;
     IF ((Raw.Colour7<2) OR (Raw.Colour7>4)) THEN
     BEGIN
          IF Raw.Colour3=1 THEN Face := Face+txSHADOW; {SHADOWED}
          IF Raw.Colour4=1 THEN Face := Face+txITALIC; {ITALICS}
          IF Raw.Colour5=1 THEN Face := Face+txUNDER;  {UNDERLINE}
          IF Raw.Colour6=1 THEN Face := Face+txBOLD;   {BOLD}
     END;
     txSetFace(Face);
     txSetColor(Raw.Colour1,0);
     txSetShadowColor(Raw.Colour2);
     txSetShadowPos(1,1);
     IF (StripColourCodes(Raw.Text)<>Raw.Text) THEN
     BEGIN
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
     END
     ELSE txOutTextXy(Raw.Text,Raw.X1,Raw.Y1);
     txSetFont(SystemFont);
END;


FUNCTION GetStringWidth(VarNumber: Byte): Word;
BEGIN
     CASE VarNumber OF
     1:   GetStringWidth := 30; {user's real name}
     2:   GetStringWidth := 30; {user's alias}
     3:   GetStringWidth := 20; {user's password}
     4:   GetStringWidth := 10; {user's birthdate}
     5:   GetStringWidth := 30; {user's street address}
     6:   GetStringWidth := 30; {user's city}
     7:   GetStringWidth := 30; {user's province}
     8:   GetStringWidth := 30; {user's country}
     9:   GetStringWidth := 20; {user's postal code}
     10:  GetStringWidth := 20; {user's data phone}
     11:  GetStringWidth := 20; {user's voice phone}
     12:  GetStringWidth := 9;  {deposit bytes}
     13:  GetStringWidth := 9;  {withdraw bytes}
     14:  GetStringWidth := 4;  {deposit minutes}
     15:  GetStringWidth := 4;  {withdraw minutes}
     16:  GetStringWidth := 2;  {# file display lines}
     17:  GetStringWidth := 12; {General File Name}
     18:  GetStringWidth := 10; {General Date}
     19:  GetStringWidth := 9;  {General Numeric}
     20:  GetStringWidth := 30; {General Proper Name}
     21:  GetStringWidth := 10; {General String 10}
     22:  GetStringWidth := 20; {General String 20}
     23:  GetStringWidth := 30; {General String 30}
     24:  GetStringWidth := 40; {General String 40}
     25:  GetStringWidth := 50; {General String 50}
     26:  GetStringWidth := 60; {General String 60}
     27:  GetStringWidth := 70; {General String 70}
     28:  GetStringWidth := 30; {Users BBS Name}
     29:  GetStringWidth := 20; {Users BBS Address}
     30:  GetStringWidth := 20; {Users BBS Phone Number}
     31:  GetStringWidth := 60; {Users Comment}
     END;
END;


FUNCTION StripColourCodes(InString: String): String;
VAR  Work : Word;
     Loop : Word;
     Temp : String;
BEGIN
     FOR Loop := 0 TO 15 DO
     BEGIN
          Temp := '{'+_String(Loop)+'}';
          REPEAT
                Work := Pos(Temp,InString);
                IF Work<>0 THEN Delete(InString,Work,LENGTH(Temp));
          UNTIL Work=0;
     END;
     StripColourCodes := InString;
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
{==========================================================================}
{                                                                          }
{         OUTPUTS PLAIN TEXT USING THE SYSTEM FONT                         }
{                                                                          }
{==========================================================================}
PROCEDURE OutTextXYS(x,y,f,b: word; s: String);
BEGIN
     txSetFont(BitFont8x16);
     IF B<>255 THEN txSetFace(txNORMAL)
               ELSE txSetFace(txTRANS);
     txSetColor(f,b);
     txOutTextXy(s,x,y);
     txSetFont(SystemFont);
END;
{==========================================================================}
{                                                                          }
{         TURN THE CURSOR OFF IN GRAPHICS MODE                             }
{                                                                          }
{==========================================================================}
PROCEDURE CursorOff;
BEGIN
     GrDisplayMouse(GrHide);
     gxVirtualDisplay(P,0,0,OldX,OldY+14,639,YWindow,0);
     IsOn := False;
END;
{==========================================================================}
{                                                                          }
{         TURN THE CURSOR ON IN GRAPHICS MODE                              }
{                                                                          }
{==========================================================================}
PROCEDURE CursorOn;
BEGIN
     GrSetFillStyle(GrFSolid,15,GrOpaque);
     OldX := (CurX*8)-8;
     OldY := (CurY*16)-16;
     gxDisplayVirtual(OldX,OldY+14,OldX+7,OldY+15,0,P,0,0);
     GrDrawRect(OldX,OldY+14,OldX+7,OldY+15,GrFill);
     IsOn := True;
     GrDisplayMouse(GrShow);
END;


PROCEDURE LoadFontFiles;
BEGIN
     gxOpenLib(gxGXL,GraphicsLibrary,GraphLib,Nil,0);
     txLibFont(gxCMM,GraphLib,'GUI_____.GFT',SystemFont);
     txLibFont(gxCMM,GraphLib,'HELV____.GFT',HelvFont);
     txLibFont(gxCMM,GraphLib,'ROMAN___.GFT',RomanFont);
     txLibFont(gxCMM,GraphLib,'BIT8X8.GFT',BitFont8x8);
     txLibFont(gxCMM,GraphLib,'BIT8X14.GFT',BitFont8x14);
     txLibFont(gxCMM,GraphLib,'BIT8X16.GFT',BitFont8x16);
     gxCloseLib(GraphLib);
     txSetFont(SystemFont);
END;


PROCEDURE OutTextXY(x,y,f,b,size: word; s: String);
BEGIN
     CASE size OF
     1:   txSetFont(SystemFont);
     2:   txSetFont(BitFont8x16);
     3:   txSetFont(BitFont8x14);
     4:   txSetFont(BitFont8x8);
     END;
     IF b=255 THEN txSetFace(txNormal+txTrans)
              ELSE txSetFace(txNormal);
     txSetColor(f,b);
     txOutTextXy(s,x,y);
     txSetFont(SystemFont);
END;


PROCEDURE OutTextXYFR(x,y,f,b: word; s: String);
VAR  Width : Integer;
BEGIN
     Width := TxStrWidth(s);
     IF b=255 THEN
     BEGIN
          txSetFace(txNormal+txTrans);
          txSetColor(f,b);
          txOutTextXy(s,x-Width,y);
     END
     ELSE
     BEGIN
          txSetFace(txNormal);
          txSetColor(f,b);
          txOutTextXy(s,x-Width,y);
     END;
END;


END.
