{$I DEFINES.INC}
UNIT DrawScrn;


INTERFACE


PROCEDURE DrawWindow        (x1,y1,x2,y2: Word; Title: String; Shad: Boolean);
PROCEDURE DropShadow        (xx1,yy1,xx2,yy2 : Word);
PROCEDURE InvertedBox       (x1,y1,x2,y2: Word);


IMPLEMENTATION


USES Crt,FastW1,Globals,Time,SaveScrn,Misc,Version,BsString,BsVideo;


PROCEDURE DrawWindow(x1,y1,x2,y2: Word; Title: String; Shad: Boolean);
VAR  LoopY  : Word;
     LoopX  : Word;
     Loop2  : Word;
     Temp   : String;
     Attr1  : Word;
     Attr2  : Word;
BEGIN
     IF Shad THEN DropShadow(x1,y1,x2,y2);
     Attr1 := 16;
     Attr2 := 25;
     FOR LoopY := y1 TO y2 DO
     BEGIN
          IF LoopY=y1 THEN
          BEGIN
               FastWrite('Ú',LoopY,x1,Attr2);
               FastWrite(_Replicate('Ä',x2-x1-1),LoopY,x1+1,Attr2);
               FastWrite('¿',LoopY,x2,Attr1);
          END
          ELSE IF LoopY=y2 THEN
          BEGIN
               FastWrite('À',LoopY,x1,Attr2);
               FastWrite(_Replicate('Ä',x2-x1-1),LoopY,x1+1,Attr1);
               FastWrite('Ù',LoopY,x2,Attr1);
          END
          ELSE
          BEGIN
               FastWrite('³',LoopY,x1,Attr2);
               FastWrite(_PadRight('',x2-x1-1),LoopY,x1+1,Attr1);
               FastWrite('³',LoopY,x2,Attr1);
          END;
     END;
     IF (Title<>'') THEN
     BEGIN
          Title := '  '+Title+'  ';
          FastWrite(Title,y1,x1+3,31);
     END;
END;


PROCEDURE DropShadow(xx1,yy1,xx2,yy2 : Word);
VAR  xshad   : Word;
     yshad   : Word;
     x       : Word;
     y       : Word;
     Loop    : Word;
BEGIN
     x := ((yy2*160)+(xx1*2))+1;
     FOR Loop := xx1 to xx2 DO
     BEGIN
          Mem[SegB800:x] := 8;
          INC(x,2);
     END;
     y := ((yy1*160)+((xx2)*2))+1;
     FOR Loop := yy1 to yy2 DO
     BEGIN
          Mem[SegB800:y] := 8;
          INC(y,160);
     END;
END;


PROCEDURE Get(x1,y1,x2,y2: Word);
VAR  Loop   : Word;
     Count  : Word;
BEGIN
     New(GetPut1);
     GetPut1^.NumLines := y2-y1+1;
     Count := 1;
     FOR Loop := y1 TO y2 DO
     BEGIN
          GetPut1^.Lines[Count].LineLength := x2-x1+1;
          Move(MEM[SegB800:(((Loop-1)*160)+((x1-1)*2))],GetPut1^.Lines[Count].Line,(x2-x1+1)*2);
          INC(Count);
     END;
END;


PROCEDURE Put(x,y: Word; Kill: Boolean);
VAR  Loop   : Word;
     Count  : Word;
BEGIN
     Count := 1;
     FOR Loop := y TO (y+GetPut1^.NumLines-1) DO
     BEGIN
          Move(GetPut1^.Lines[Count].Line,MEM[SegB800:(((Loop-1)*160)+((x-1)*2))],(GetPut1^.Lines[Count].LineLength)*2);
          INC(Count);
     END;
     IF Kill THEN Dispose(GetPut1);
END;


PROCEDURE InvertedBox(x1,y1,x2,y2: Word);
VAR  Loop  : Word;
     Attr1 : Word;
     Attr2 : Word;
BEGIN
     Attr1 := 16;
     Attr2 := 25;
     FastWrite('Ú',y1,x1,Attr1);
     FastWrite(_Replicate('Ä',x2-x1-1),y1,x1+1,Attr1);
     FastWrite('¿',y1,x2,Attr2);
     FOR Loop := y1+1 TO y2-1 DO
     BEGIN
          FastWrite('³',Loop,x1,Attr1);
          FastWrite('³',Loop,x2,Attr2);
     END;
     FastWrite('À',y2,x1,Attr1);
     FastWrite(_Replicate('Ä',x2-x1-1),y2,x1+1,Attr2);
     FastWrite('Ù',y2,x2,Attr2);
END;


END.