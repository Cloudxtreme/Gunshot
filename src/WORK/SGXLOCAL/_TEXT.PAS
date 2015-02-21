{$I DEFINES.INC}
UNIT _Text;


INTERFACE


USES Globals,Shotgun;


PROCEDURE DrawChar           (x,y,f: Word; C: Char);
PROCEDURE DrawText           (x,y,f,b: Word; InString: String);
PROCEDURE OutTextXY          (x,y,f,b,size: word; s: String);
PROCEDURE DoText             (Raw: _Raw_File);


IMPLEMENTATION


USES Gx2_Bp,Gr2_Bp,Tx2_Bp,SBuffer,Special,ErrorLog,_Convert,_Mouse,_Virtual;


PROCEDURE DrawText(x,y,f,b: Word; InString: String);
VAR  Loop2 : Word;
BEGIN
     HideTheMouse;
     txSetFont(BitFont8x14);
     txSetFace(txNORMAL+txFIXED);
     txSetSpace(7);
     txSetColor(f,b);
     txOutTextXy(InString,x,y);
     txSetFont(SystemFont);
     ShowTheMouse;
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
{==========================================================================}
{                                                                          }
{         PLACES A TEXT STRING ON THE SCREEN                               }
{                                                                          }
{==========================================================================}
PROCEDURE DoText(Raw: _Raw_File);
VAR  Face  : Integer;
     Loop  : Word;
     X     : Word;
     Error : Integer;
LABEL        Continue;
BEGIN
     IF UsingBuffer THEN Raw.Text := ProcessBuffer(Raw.Text);
     Raw.Text := Process_Special(Raw.Text,False);
     IF Raw.Text='' THEN Exit;
     IF Raw.Colour7=0 THEN
     BEGIN
          IF (Raw.Crc32+'.FNT'<>LastFont) THEN
          BEGIN
               IF (LastFont<>'$%@$#^!%sf@$') THEN txFreeFont(workfont);
               Error := txFileFont(gxCMM,RESOURCES+Raw.Crc32+'.FNT',workfont);
               IF Error=txSuccess THEN GOTO Continue;
               DoErrorLog(106,'');
               Halt;
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


PROCEDURE DrawChar(x,y,f: Word; C: Char);
BEGIN
     HideTheMouse;
     txSetFont(BitFont8x14);
     txSetFace(txNORMAL+txTRANS);
     txSetColor(f,0);
     txOutTextXy(C,x,y);
     txSetFont(SystemFont);
     ShowTheMouse;
END;


END.
