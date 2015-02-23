{$IFDEF DPMI}
 Duh, real mode stupid!
{$ENDIF}

{$I DEFINES.INC}
{$M 32000,0,655360}
PROGRAM GSMailFaxViewer;


USES Dos,Crt,ApMisc,ApFaxCvt,BsMulti,BsFile;


CONST Up               = #$48;
      Down             = #$50;
      Left             = #$4B;
      Right            = #$4D;
      Home             = #$47;
      EndKey           = #$4F;
      PgUp             = #$49;
      PgDn             = #$51;
      Esc              = #$1B;
      MaxLines         = 4000;
      CurPage          : Word = 1;
TYPE  PLine            = ^TLine;
      TLine            = Array[0..$FFF0] of Byte;
      PNode            = ^TNode;
      TNode            = record
      Data             : PLine;
      Len              : Word;
      end;
TYPE  PList            = ^TList;
      TList            = record
      Lines            : Array[1..MaxLines] of PNode;
      LineCnt          : Word;
      end;
CONST SelMode          : Byte = $12;
      SelWid           = 640;
      WidthBytes       = SelWid shr 3;
      SelHit           = 480;
VAR   RasterList       : TList;
      Unpacker         : UnpackFaxPtr;
      FaxFile          : String;
      TmpBuffer        : PLine;
      FaxHeader        : FaxHeaderRec;
      PageHeader       : PageHeaderRec;
      C                : Char;
      DT               : DateTime;
TYPE  RasterByteArray  = array[0..639] of Byte;
CONST ScaleIt          : Boolean = False;
      ScaleFact        : Word = 3;
      ScaleThre        : Word = 1;
VAR   RasterCounts     : RasterByteArray;
      Temp             : String;


PROCEDURE PackBuffer(VAR Buffer; VAR Len: Word);
TYPE PW  = ^Word;
VAR  TL  : TLine ABSOLUTE Buffer;
     W,X : Word;
     P   : PW;
BEGIN
     X := Len SHR 1;
     Len := X;
     ASM
        mov    cx,X
        jcxz   @@3
        push   ds
        les    di,Buffer
        lds    si,Buffer
@@1:
        push   cx
        mov    ax,word ptr ds:[si]
        xchg   al,ah
        xor    bl,bl
        mov    cx,0008h
@@2:
        shl    ax,1
        shl    ax,1
        rcl    bl,1
        loop   @@2
        mov    es:[di],bl
        inc    di
        inc    si
        inc    si
        pop    cx
        loop   @@1
        pop    ds
@@3:
     END;
END;


FUNCTION InitNode(VAR T: TNode; VAR Buffer; L: Word): Boolean;
VAR  I : Word;
BEGIN
     InitNode := False;
     T.Data := NIL;
     IF (L=0) THEN
     BEGIN
          T.Len := 0;
          InitNode := True;
          Exit;
     END;
     IF NOT GetMemCheck(T.Data,L) THEN Exit;
     InitNode := True;
     Move(Buffer,T.Data^,L);
     T.Len := L;
     ASM
        les    di,T
        les    di,TNode(es:[di]).Data
        mov    cx,L
@@1:    not    byte ptr es:[di]
        inc    di
        loop   @@1
     END;
END;


PROCEDURE DoneNode(VAR P: PNode);
BEGIN
     WITH P^ DO FreeMemCheck(Data,Len);
     Dispose(P);
END;


PROCEDURE ClearRasterList;
VAR  W : Word;
BEGIN
     WITH RasterList DO
     BEGIN
          W := LineCnt;
          WHILE W>0 DO
          BEGIN
               DoneNode(Lines[w]);
               Dec(W);
          END;
     END;
     FillChar(RasterList,SizeOf(RasterList),0);
END;


PROCEDURE ClearRasterCounts;
BEGIN
     FillChar(RasterCounts,SizeOf(RasterCounts),0);
END;


PROCEDURE UpdateRasterCounts(Buffer: PByteBuffer; Len: Word; VAR RasterCounts: RasterByteArray);
VAR  BPos : Word;
     BLen : Word;
BEGIN
     BLen := (Len SHL 3)-1;
     IF BLen DIV ScaleFact>639 THEN BLen := 639*ScaleFact;
     FOR BPos := 0 TO BLen DO
     BEGIN
          IF Buffer^[BPos SHR 3] AND ($80 SHR (BPos AND 7))<>0
             THEN Inc(RasterCounts[BPos DIV ScaleFact]);
     END;
END;


PROCEDURE PackRasterCounts(Buffer: PByteBuffer; VAR RasterCounts: RasterByteArray; VAR Len: Word);
VAR  BPos      : Word;
     BytePos   : Word;
     Threshold : Word;
     B         : Byte;
BEGIN
     FillChar(Buffer^,Len,0);
     Threshold := ScaleThre;
     FOR BPos := 0 TO 639 DO
     BEGIN
          IF RasterCounts[BPos]>=Threshold THEN
          BEGIN
               BytePos := BPos SHR 3;
               Buffer^[BytePos] := Buffer^[BytePos] OR ($80 SHR (BPos AND 7));
          END;
     END;
     Len := 640 SHR 3;
END;


FUNCTION UnpLine(UP: UnpackFaxPtr; Buffer: PByteBuffer; Len: Word; PH: PageHeaderRec): Boolean;
CONST B : Boolean = True;
VAR   P : PNode;
BEGIN
     UnpLine := False;
     SetAsyncStatus(ecOK);
     IF ScaleIt THEN UpdateRasterCounts(Buffer,Len,RasterCounts);
     WITH UP^,RasterList DO
     BEGIN
          New(P);
          IF P<>NIL THEN
          BEGIN
               FillChar(P^,SizeOf(TNode),0);
               IF ScaleIt THEN
               BEGIN
                    PackRasterCounts(Buffer,RasterCounts,Len);
                    ClearRasterCounts;
               END
               ELSE PackBuffer(Buffer^,Len);
               IF InitNode(P^,Buffer^,Len) THEN
               BEGIN
                    Inc(LineCnt);
                    IF LineCnt>MaxLines THEN SetAsyncStatus(ecOutOfMemory)
                                        ELSE Lines[LineCnt] := P;
               END
               ELSE SetAsyncStatus(ecOutOfMemory);
          END
          ELSE SetAsyncStatus(ecOutOfMemory);
     END;
END;


PROCEDURE Mode3;
VAR  R: Registers;
BEGIN
     R.AX := $0003;
     Intr($10,R);
END;


PROCEDURE ClrMode12;
BEGIN
     Fillchar(Ptr(SegA000,0)^,$FFFF,$FF);
END;


PROCEDURE Mode12;
VAR  R : Registers;
BEGIN
     R.AX := SelMode;
     Intr($10,R);
     R.AX := $0F00;
     Intr($10,R);
END;


PROCEDURE BltLine(VAR Buffer; Len,X,Y: Word); ASSEMBLER;
ASM
   mov   bx,WidthBytes
   xor   dx,dx
   cld
   mov   ax,SegA000
   mov   es,ax
   mov   ax,Y
   mul   bx
   mov   di,ax
   push  ds
   lds   si,Buffer
   mov   ax,X
   mov   cx,Len
   cmp   ax,cx
   ja    @3
   add   si,ax
   sub   cx,ax
   cmp   cx,bx
   jb    @1
   mov   cx,bx
@1:
   mov   dx,cx
   shr   cx,1
   jnc   @2
   movsb
@2:
   jcxz  @3
   rep   movsw
@3:
   sub   bx,dx
   mov   cx,bx
   jcxz  @9
   mov   ax,$FFFF
   shr   cx,1
   jnc   @4
   stosb
@4:
   jcxz  @9
   rep   stosw
@9:
   pop   ds
END;


PROCEDURE ShowTheFax;
VAR  Y        : Word;
     X        : Word;
     C        : Char;
     W        : Word;
     Finished : Boolean;

     FUNCTION Min(A,B: Word): Word;
     BEGIN
          IF A<B THEN Min := A ELSE Min := B;
     END;

     PROCEDURE UpdScrn;
     VAR  N : Word;
          Z : Word;
          P : PNode;
          B : Byte;
          S : String;
     BEGIN
          IF Y>RasterList.LineCnt THEN Exit;
          B := $FF;
          N := 0;
          Z := Y;
          P := RasterList.Lines[z];
          IF P=NIL THEN Exit;
          FOR N := 1 TO SelHit DO
          BEGIN
               IF P<>NIL THEN BltLine(P^.Data^,P^.Len,X,N)
                         ELSE BltLine(B,1,X,N);
               IF P<>NIL THEN
               BEGIN
                    Inc(Z);
                    IF Z>RasterList.LineCnt THEN P := NIL
                                            ELSE P := RasterList.Lines[z]
               END;
          END;
     END;

BEGIN
     ClrScr;
     Mode12;
     ClrMode12;
     Y := 1;
     X := 0;
     WHILE True DO
     BEGIN
          UpdScrn;
          Finished := False;
          REPEAT
                IF KeyPressed THEN
                BEGIN
                     C := ReadKey;
                     IF C=#0 THEN
                     BEGIN
                          C := ReadKey;
                          Finished := True;
                     END
                     ELSE
                     BEGIN
                          C := Upcase(C);
                          Finished := C IN [Esc];
                     END;
                END
                ELSE TimeSlice;
          UNTIL Finished;
          CASE C OF
          Esc:    BEGIN
                       Mode3;
                       Exit;
                  END;
          Up:     BEGIN
                       W := 72;
                       WHILE W>0 DO
                       BEGIN
                            IF Y>1 THEN Dec(Y);
                            Dec(W);
                       END;
                  END;
          Down:   BEGIN
                       W := 72;
                       WHILE W>0 DO
                       BEGIN
                            IF Y<RasterList.LineCnt THEN Inc(Y);
                            Dec(W);
                       END;
                  END;
          Left:   IF X>0 THEN Dec(X,8);
          Right:  IF X<255 THEN Inc(X,8);
          Home:   BEGIN
                       X := 0;
                       Y := 1;
                  END;
          EndKey: BEGIN
                       Y := RasterList.LineCnt;
                       W := 455;
                       WHILE W>0 DO
                       BEGIN
                            IF Y>1 THEN Dec(Y);
                            IF Y=1 THEN W := 0
                                   ELSE Dec(W);
                       END;
                       X := 0;
                  END;
          PgUp:   IF CurPage>1 THEN
                  BEGIN
                       Dec(CurPage);
                       ClearRasterList;
                       UnpackPage(Unpacker,FaxFile,CurPage);
                       IF GetAsyncStatus<>0 THEN
                       BEGIN
                            Mode3;
                            Exit;
                       END;
                       X := 0;
                       Y := 1;
                  END
                  ELSE
                  BEGIN
                       Sound(440);
                       Delay(100);
                       NoSound;
                  END;
          PgDn:   IF CurPage<Unpacker^.FaxHeader.PageCount THEN
                  BEGIN
                       Inc(CurPage);
                       ClearRasterList;
                       UnpackPage(Unpacker,FaxFile,CurPage);
                       IF GetAsyncStatus<>0 THEN
                       BEGIN
                            Mode3;
                            Exit;
                       END;
                       X := 0;
                       Y := 1;
                  END
                  ELSE
                  BEGIN
                       Sound(440);
                       Delay(100);
                       NoSound;
                  END;
          END;
     END;
END;


PROCEDURE DisplayTheFax(FName: String);
LABEL CleanUp;
BEGIN
     FaxFile := FName;
     FillChar(RasterList,SizeOf(RasterList),0);
     InitUnpacker(Unpacker);
     IF Unpacker=NIL THEN Exit;
     SetOutputLineFunc(Unpacker,UnpLine);
     ClearRasterCounts;
     GetFaxHeader(Unpacker,FaxFile,FaxHeader);
     IF GetAsyncStatus<>0 THEN GOTO Cleanup;
     GetPageHeader(Unpacker,FaxFile,CurPage,PageHeader);
     IF GetAsyncStatus<>0 THEN GOTO Cleanup;
     UnpackPage(Unpacker,FaxFile,CurPage);
     IF GetAsyncStatus<>0 THEN GOTO Cleanup;
     ShowTheFax;
     Cleanup:
     DoneUnpacker(Unpacker);
     ClearRasterList;
END;


BEGIN
     Temp := ParamStr(1);
     IF _FileExists(Temp) THEN DisplayTheFax(Temp);
END.