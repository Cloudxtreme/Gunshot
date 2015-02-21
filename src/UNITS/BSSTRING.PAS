{$I DEFINES.INC}
UNIT BsString;


INTERFACE


TYPE BitNum = 0..7;
     Bit    = 0..1;


FUNCTION _Replicate(InChar: Char; InCount: Byte): String;
FUNCTION _Pos2(Objct,Target: String; StartPos: Byte): Byte;
FUNCTION _PadRight(InString: String; LLen: Byte): String;
FUNCTION _PadLeft(InString: string; Pads: Word): String;
FUNCTION _PadBoth(InString: String; Total: Word): String;
FUNCTION _Mid(InString: String; Starting,Ending: Byte): String;
FUNCTION _String(InLong: Longint): String;
FUNCTION _Numeric(InString: String): Longint;
FUNCTION _UpperCase(InString: String): String;
FUNCTION _LowerCase(InString: String): String;
FUNCTION _ProperCase(InString: String): String;
FUNCTION _RemoveLeftSpaces(InString: String): String;
FUNCTION _RemoveRightSpaces(InString: String): String;
FUNCTION _RemoveSpaces(InString: String): String;
FUNCTION _RemoveUnderScores(InString: String): String;
FUNCTION _IsNumeric(Str: String): Boolean;
FUNCTION _GetBit(B: Byte; N: BitNum): Bit;
FUNCTION _SetBit(B: Byte; N: BitNum): Byte;
FUNCTION _ClrBit(B: Byte; N: BitNum): Byte;


IMPLEMENTATION


FUNCTION _Replicate(InChar: Char; InCount: Byte): String;
VAR  Temp : String;
BEGIN
     FillChar(Temp[1],InCount,InChar);
     Move(InCount,Temp[0],1);
     _Replicate := Temp;
END;


FUNCTION _PadRight(InString: String; LLen: Byte): String;
VAR  Temp : String;
BEGIN
     FillChar(Temp[1],LLen,#32);
     Move(InString[1],Temp[1],Ord(InString[0]));
     Temp[0] := Chr(LLen);
     _PadRight := Temp;
END;


FUNCTION _String(InLong: Longint): String;
VAR  Temp : String;
BEGIN
     Str(InLong,Temp);
     _String := Temp;
END;


FUNCTION _PadBoth(InString: String; Total: Word): String;
VAR  AddEachEnd   : String;
     Loop         : Word;
     LLen         : Word;
BEGIN
     LLen := Length(InString);
     IF (LLen>=Total) THEN
     BEGIN
       InString := _Mid(InString,1,Total);
     END
     ELSE
     BEGIN
       AddEachEnd := _Replicate(' ',Trunc((Total-LLen)/2));
       InString := AddEachEnd+InString+AddEachEnd;
       IF LENGTH(InString)<Total THEN InString := InString+' ';
     END;
     _PadBoth := InString;
END;


FUNCTION _Mid(InString: String; Starting,Ending: Byte): String;
VAR  NumberOfChars : Byte;
BEGIN
     IF Ending>=Starting THEN
     BEGIN
       NumberOfChars := Ending-Starting+1;
       _Mid := Copy(InString,Starting,NumberOfChars);
     END
     ELSE _Mid := '';
END;


FUNCTION _Numeric(InString: String): Longint;
VAR  Code : Integer;
     Work : Longint;
BEGIN
     Val(InString,Work,Code);
     _Numeric := Work;
END;


FUNCTION _RemoveSpaces(InString: String): String; Assembler;
ASM
   PUSH DS
   CLD
   MOV  BL,0
   LDS  SI,InString
   LES  DI,@Result
   LODSB
   STOSB
   XOR  AH,AH
   XCHG AX,CX
   JCXZ @3
@1:
   LODSB
   CMP  AL,' '
   JE   @2
   INC  BL
   STOSB
@2:
   LOOP @1
@3:
   LES  DI,@Result
   MOV  AL,BL
   STOSB
   POP  DS
END;


FUNCTION _RemoveLeftSpaces(InString: String): String;
VAR  Loop : Word;
     LLen : Word;
BEGIN
     IF (InString<>'') THEN
     BEGIN
       IF InString[1]=#32 THEN
       BEGIN
         WHILE ((InString[1]=#32) AND (InString<>'')) DO Delete(InString,1,1);
       END;
     END;
     _RemoveLeftSpaces := InString;
END;


FUNCTION _RemoveRightSpaces(InString: String): String;
BEGIN
     IF InString<>'' THEN
     BEGIN
       IF InString[LENGTH(InString)]=#32 THEN
       BEGIN
         REPEAT
           Dec(InString[0]);
         UNTIL ((InString[LENGTH(InString)]<>#32) OR (InString=''));
         _RemoveRightSpaces := InString;
       END
       ELSE _RemoveRightSpaces := InString;
     END
     ELSE _RemoveRightSpaces := InString;
END;


FUNCTION _RemoveUnderScores(InString: String): String; Assembler;
ASM
   PUSH DS
   CLD
   LDS  SI,InString
   LES  DI,@Result
   LODSB
   STOSB
   XOR  AH,AH
   XCHG AX,CX
   JCXZ @3
@1:
   LODSB
   CMP  AL,'_'
   JNE  @2
   MOV  AL,' '
@2:
   STOSB
   LOOP @1
@3:
   POP  DS
END;


FUNCTION _IsNumeric(Str: String): Boolean;
VAR  i: Word;
BEGIN
     FOR i := 1 TO Length(Str) DO
     BEGIN
       IF NOT(Str[i] IN ['0'..'9']) THEN
       BEGIN
         _IsNumeric := False;
         Exit;
       END;
     END;
     _IsNumeric := True;
END;


FUNCTION _PadLeft(InString: string; Pads: Word): String;
VAR  Loop : Word;
     LLen : Word;
BEGIN
     LLen := Length(InString);
     IF LLen<Pads THEN
     BEGIN
          InString := _Replicate(' ',Pads-LLen)+InString;
     END
     ELSE IF LLen>Pads THEN
     BEGIN
          InString := _Mid(InString,1,Pads);
     END;
     _PadLeft := InString;
END;


FUNCTION _getBit(B: Byte; N: BitNum): Bit;
BEGIN
     _GetBit := Bit(Odd(B SHR N));
END;


FUNCTION _SetBit(B: Byte; N: BitNum): Byte;
BEGIN
     _SetBit := B OR (1 SHL N);
END;


FUNCTION _ClrBit(B: Byte; N: BitNum): Byte;
BEGIN
     _ClrBit := B AND Hi($FEFF SHL N);
END;


FUNCTION _ProperCase(InString: String): String;
VAR  loop : word;
BEGIN
     InString := _LowerCase(InString);
     InString[1] := UpCase(InString[1]);
     FOR Loop := 2 TO LENGTH(InString) DO
     BEGIN
          IF InString[Loop]=' ' THEN InString[Loop+1] := UpCase(InString[Loop+1]);
     END;
     _ProperCase := InString;
END;


FUNCTION _Pos2(Objct,Target: String; StartPos: Byte): Byte; Assembler;
ASM
           {$IFOPT G+}
           PUSH    BP
           {$ENDIF}
           CLD
           PUSH    DS
           LES     DI, [Target]
           LDS     SI, [Objct]
           XOR     BX, BX
           OR      BL, [StartPos]
           JZ      @NoChange
           DEC     BX
@NoChange: LODSW
           SUB     AL, 1
           JB      @NotFound1
           MOV     CL, ES: [DI]
           MOV     CH, CL
           SUB     CL, AL
           JBE     @NotFound1
           SUB     CL, BL
           JBE     @NotFound1
           INC     DI
           ADD     DI, BX
           XCHG    CH, BH
           XCHG    AL, AH
           MOV     BP, SI
@Search1:  REPNZ   SCASB
           JNZ     @NotFound2
           MOV     BL, CL
           MOV     CL, AH
           MOV     DX, DI
           REPZ    CMPSB
           MOV     SI, BP
           MOV     DI, DX
           MOV     CL, BL
           JNZ     @Search1
           SUB     BH, BL
           SUB     BH, AH
@NotFound1:MOV     CH, BH
@NotFound2:MOV     AL, CH
           XOR     AH, AH
           POP     DS
           {$IFOPT G+}
           POP     BP
           {$ENDIF}
END;


FUNCTION _UpperCase(InString: String): String; Assembler;
ASM
   PUSH DS
   CLD
   LDS  SI,InString
   LES  DI,@Result
   LODSB
   STOSB
   XOR  AH,AH
   XCHG AX,CX
   JCXZ @3
@1:
   LODSB
   CMP  AL,'a'
   JB   @2
   CMP  AL,'z'
   JA   @2
   SUB  AL,20H
@2:
   STOSB
   LOOP @1
@3:
   POP  DS
END;


FUNCTION _LowerCase(InString: String): String; Assembler;
ASM
   PUSH DS
   CLD
   LDS  SI,InString
   LES  DI,@Result
   LODSB
   STOSB
   XOR  AH,AH
   XCHG AX,CX
   JCXZ @3
@1:
   LODSB
   CMP  AL,'A'
   JB   @2
   CMP  AL,'Z'
   JA   @2
   ADD  AL,20H
@2:
   STOSB
   LOOP @1
@3:
   POP  DS
END;


END.
