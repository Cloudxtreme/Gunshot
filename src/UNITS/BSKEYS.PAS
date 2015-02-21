{$I DEFINES.INC}
UNIT BsKeys;


INTERFACE


FUNCTION  _AltToNormal(C: Char): Char;
FUNCTION  _NormalToAlt(C: Char): Char;
FUNCTION  IsTheKeyOk(Key: Char; Alt: Boolean): Char;
PROCEDURE _HideCursor;
PROCEDURE _ShowCursor;


IMPLEMENTATION


FUNCTION _AltToNormal(C: Char): Char;
BEGIN
     CASE ORD(C) OF
     30:  _AltToNormal := 'A';
     48:  _AltToNormal := 'B';
     46:  _AltToNormal := 'C';
     32:  _AltToNormal := 'D';
     18:  _AltToNormal := 'E';
     33:  _AltToNormal := 'F';
     34:  _AltToNormal := 'G';
     35:  _AltToNormal := 'H';
     23:  _AltToNormal := 'I';
     36:  _AltToNormal := 'J';
     37:  _AltToNormal := 'K';
     38:  _AltToNormal := 'L';
     50:  _AltToNormal := 'M';
     49:  _AltToNormal := 'N';
     24:  _AltToNormal := 'O';
     25:  _AltToNormal := 'P';
     16:  _AltToNormal := 'Q';
     17:  _AltToNormal := 'R';
     31:  _AltToNormal := 'S';
     20:  _AltToNormal := 'T';
     22:  _AltToNormal := 'U';
     47:  _AltToNormal := 'V';
     17:  _AltToNormal := 'W';
     45:  _AltToNormal := 'X';
     21:  _AltToNormal := 'Y';
     44:  _AltToNormal := 'Z';
     120: _AltToNormal := '1';
     121: _AltToNormal := '2';
     122: _AltToNormal := '3';
     123: _AltToNormal := '4';
     124: _AltToNormal := '5';
     125: _AltToNormal := '6';
     126: _AltToNormal := '7';
     127: _AltToNormal := '8';
     128: _AltToNormal := '9';
     129: _AltToNormal := '0';
     ELSE _AltToNormal := #0;
     END;
END;


PROCEDURE _HideCursor; Assembler;
ASM
   MOV ax,$0100
   MOV cx,$2607
   INT $10
END;


PROCEDURE _ShowCursor; Assembler;
ASM
   MOV ax,$0100
   MOV cx,$0506
   INT $10
END;


FUNCTION IsTheKeyOk(Key: Char; Alt: Boolean): Char;
VAR  Current : Char;
BEGIN
     Current := #0;
     IF Alt THEN
     BEGIN
          CASE Ord(Key) OF
          15:           ;
          59..68:       ; {Function Keys}
          71:           ; {Home}
          72:           ; {Up}
          73:           ; {PgUp}
          75:           ; {Left}
          77:           ; {Right}
          79:           ; {End}
          80:           ; {Down}
          81:           ; {PgDn}
          82:           ; {Insert}
          83:           ; {Delete}
          115:          ;
          116:          ;
          117:          ; {Ctrl-End}
          118:          ; {Ctrl-PgDn}
          119:          ; {Ctrl-Home}
          132:          ; {Ctrl-PgUp}
          ELSE Current := Chr(Ord(Key)+128);
          END;
     END
     ELSE
     BEGIN
          CASE Ord(Key) OF
          1..26:        ; {Can't use any of these}
          27:           ; {Can't use ESC codes}
          127:          ; {CTRL-BackSpace}
          ELSE Current := Key;
          END;
     END;
     IsTheKeyOk := Current;
END;


FUNCTION _NormalToAlt(C: Char): Char;
BEGIN
     CASE C OF
     'A': _NormalToAlt := #30;
     'B': _NormalToAlt := #48;
     'C': _NormalToAlt := #46;
     'D': _NormalToAlt := #32;
     'E': _NormalToAlt := #18;
     'F': _NormalToAlt := #33;
     'G': _NormalToAlt := #34;
     'H': _NormalToAlt := #35;
     'I': _NormalToAlt := #23;
     'J': _NormalToAlt := #36;
     'K': _NormalToAlt := #37;
     'L': _NormalToAlt := #38;
     'M': _NormalToAlt := #50;
     'N': _NormalToAlt := #49;
     'O': _NormalToAlt := #24;
     'P': _NormalToAlt := #25;
     'Q': _NormalToAlt := #16;
     'R': _NormalToAlt := #17;
     'S': _NormalToAlt := #31;
     'T': _NormalToAlt := #20;
     'U': _NormalToAlt := #22;
     'V': _NormalToAlt := #47;
     'W': _NormalToAlt := #17;
     'X': _NormalToAlt := #45;
     'Y': _NormalToAlt := #21;
     'Z': _NormalToAlt := #44;
     '1': _NormalToAlt := #120;
     '2': _NormalToAlt := #121;
     '3': _NormalToAlt := #122;
     '4': _NormalToAlt := #123;
     '5': _NormalToAlt := #124;
     '6': _NormalToAlt := #125;
     '7': _NormalToAlt := #126;
     '8': _NormalToAlt := #127;
     '9': _NormalToAlt := #128;
     '0': _NormalToAlt := #129;
     ELSE _NormalToAlt := C;
     END;
END;


END.