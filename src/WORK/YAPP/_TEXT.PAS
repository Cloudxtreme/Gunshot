{$I DEFINES.INC}
UNIT _Text;


INTERFACE


USES Globals,Gunshot;


PROCEDURE DrawText           (x,y,f,b: Word; InString: String);
PROCEDURE OutTextXY          (x,y,f,b,size: word; s: String);
PROCEDURE OutTextXYFR        (x,y,f,b: word; s: String);
PROCEDURE DrawChar           (x,y,f: Word; C: Char);
PROCEDURE DoText             (Raw: _Raw_File);


IMPLEMENTATION


USES Gx2_Bp,Gr2_Bp,Tx2_Bp,_Token,_Convert,Process,Crt;


PROCEDURE DrawText(x,y,f,b: Word; InString: String);
VAR  Loop2 : Word;
BEGIN
     GrDisplayMouse(GrHide);
     txSetFont(BitFont8x14);
     txSetFace(txNORMAL);
     txSetFace(txNORMAL+txFIXED);
     txSetSpace(7);
     txSetColor(f,b);
     txOutTextXy(InString,x,y);
     txSetFont(SystemFont);
     GrDisplayMouse(GrShow);
END;


PROCEDURE DrawChar(x,y,f: Word; C: Char);
BEGIN
     GrDisplayMouse(GrHide);
     txSetFont(BitFont8x14);
     txSetFace(txNORMAL+txTRANS);
     txSetColor(f,0);
     txOutTextXy(C,x,y);
     txSetFont(SystemFont);
     GrDisplayMouse(GrShow);
END;
{==========================================================================}
{                                                                          }
{         PLACES A TEXT STRING ON THE SCREEN - SYSTEM FONT                 }
{                                                                          }
{==========================================================================}
PROCEDURE OutTextXY(x,y,f,b,size: word; s: String);
VAR  Trans : Integer;
BEGIN
     CASE Size OF
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


PROCEDURE DoText(Raw: _Raw_File);
VAR  Error : Integer;
     Face  : Integer;
     Loop  : Word;
     X     : Word;
LABEL        Continue;
BEGIN
     IF Pos('@',Raw.Text)<>0 THEN Raw.Text := ProcessBuffer(Raw.Text);
     Raw.Text := Process_Special(Raw.Text,False);
     IF Raw.Text='' THEN Exit;
     IF Raw.Colour7=0 THEN
     BEGIN
          IF ((Raw.Crc32+'.FNT'<>LastFont) AND (LastFont<>'')) THEN txFreeFont(workfont);
          IF (Raw.Crc32+'.FNT'<>LastFont) THEN
          BEGIN
               Error := txFileFont(gxCMM,RESOURCES+Raw.Crc32+'.FNT',workfont);
               IF Error=txSuccess THEN GOTO Continue;
               TextMode(co80);
               Halt(1);
          END;
          Continue:
          LastFont := Raw.Crc32+'.FNT';
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
          txSetFont(SystemFont);
END;


END.
