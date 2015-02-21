{$A+,B-,D-,E-,F+,G+,I+,L-,N-,O+,P-,Q-,R-,S-,T-,V-,X+,Y-}
Unit RipLink1;

interface

{Include file for RipLink(tm) - Copyright (C) 1994 by InterProgramming}
{                               All rights reserved                   }

{ This file contains the tables for the font adjustment for the Buttons }

Type
  MetricRec = record
    Top,
    Bow,
    Base,
    Drop : word;
  end;

  MetricArrayType = Array[0..10,1..10] of MetricRec;

Const
  MetricArray : MetricArrayType =
  (((Top: 0; Bow: 2; Base: 6; Drop: 7),
    (Top: 0; Bow: 4; Base:13; Drop:15),
    (Top: 0; Bow: 6; Base:20; Drop:23),
    (Top: 0; Bow: 8; Base:27; Drop:31),
    (Top: 0; Bow:10; Base:34; Drop:39),  {Default Font : 0}
    (Top: 0; Bow:12; Base:41; Drop:47),
    (Top: 0; Bow:14; Base:48; Drop:55),
    (Top: 0; Bow:16; Base:55; Drop:63),
    (Top: 0; Bow:18; Base:62; Drop:71),
    (Top: 0; Bow:20; Base:69; Drop:79)),

   ((Top: 6; Bow:10; Base:18; Drop:22),
    (Top: 6; Bow:11; Base:20; Drop:24),
    (Top: 8; Bow:13; Base:23; Drop:28),
    (Top:10; Bow:17; Base:31; Drop:38),
    (Top:13; Bow:23; Base:41; Drop:50),  {Triplex Font : 1}
    (Top:16; Bow:28; Base:51; Drop:62),
    (Top:20; Bow:34; Base:62; Drop:76),
    (Top:25; Bow:42; Base:77; Drop:94),
    (Top:30; Bow:51; Base:93; Drop:114),
    (Top:40; Bow:67; Base:124;Drop:152)),

   ((Top: 2; Bow: 3; Base: 5; Drop: 6),
    (Top: 2; Bow: 4; Base: 6; Drop: 7),
    (Top: 2; Bow: 3; Base: 6; Drop: 7),
    (Top: 3; Bow: 5; Base: 9; Drop:11),
    (Top: 4; Bow: 7; Base:12; Drop:14),  {Small Font : 2}
    (Top: 5; Bow: 9; Base:15; Drop:18),
    (Top: 6; Bow:10; Base:13; Drop:22),
    (Top: 7; Bow:12; Base:22; Drop:27),
    (Top: 9; Bow:15; Base:27; Drop:33),
    (Top:12; Bow:20; Base:36; Drop:44)),

   ((Top: 7; Bow:11; Base:19; Drop:23),
    (Top: 7; Bow:12; Base:21; Drop:25),
    (Top: 9; Bow:14; Base:24; Drop:29),
    (Top:11; Bow:18; Base:32; Drop:39),
    (Top:14; Bow:24; Base:42; Drop:51),  {Sans Serif Font : 3}
    (Top:18; Bow:30; Base:53; Drop:64),
    (Top:22; Bow:36; Base:64; Drop:78),
    (Top:28; Bow:45; Base:80; Drop:97),
    (Top:33; Bow:54; Base:96; Drop:117),
    (Top:74; Bow:102;Base:158;Drop:186)),

   ((Top: 7; Bow:11; Base:19; Drop:23),
    (Top: 7; Bow:12; Base:21; Drop:25),
    (Top: 9; Bow:14; Base:24; Drop:29),
    (Top:11; Bow:18; Base:32; Drop:39),
    (Top:14; Bow:24; Base:42; Drop:51),  {Gothic Font : 4}
    (Top:18; Bow:30; Base:53; Drop:64),
    (Top:22; Bow:36; Base:64; Drop:78),
    (Top:28; Bow:45; Base:80; Drop:97),
    (Top:33; Bow:54; Base:96; Drop:117),
    (Top:44; Bow:72; Base:128;Drop:156)),

   ((Top:10; Bow:17; Base:22; Drop:29),
    (Top:10; Bow:18; Base:24; Drop:32),
    (Top:12; Bow:21; Base:27; Drop:36),
    (Top:16; Bow:28; Base:37; Drop:49),
    (Top:21; Bow:37; Base:49; Drop:65),  {Script Font : 5}
    (Top:26; Bow:46; Base:61; Drop:80),
    (Top:32; Bow:56; Base:74; Drop:98),
    (Top:40; Bow:70; Base:92; Drop:122),
    (Top:48; Bow:84; Base:111;Drop:147),
    (Top:63; Bow:111;Base:147;Drop:195)),

   ((Top: 9; Bow:13; Base:21; Drop:25),
    (Top: 9; Bow:14; Base:23; Drop:27),
    (Top:11; Bow:16; Base:26; Drop:31),
    (Top:14; Bow:21; Base:35; Drop:42),
    (Top:18; Bow:28; Base:46; Drop:56),  {Simplex Font : 6}
    (Top:23; Bow:35; Base:58; Drop:69),
    (Top:28; Bow:42; Base:70; Drop:84),
    (Top:35; Bow:52; Base:87; Drop:104),
    (Top:42; Bow:63; Base:105;Drop:126),
    (Top:56; Bow:84; Base:140;Drop:168)),

   ((Top: 5; Bow: 9; Base:17; Drop:21),
    (Top: 5; Bow:10; Base:19; Drop:23),
    (Top: 7; Bow:12; Base:22; Drop:27),
    (Top: 9; Bow:16; Base:30; Drop:37),
    (Top:12; Bow:22; Base:40; Drop:49),  {Triplex Script Font : 7}
    (Top:15; Bow:27; Base:50; Drop:61),
    (Top:19; Bow:33; Base:61; Drop:75),
    (Top:24; Bow:41; Base:77; Drop:93),
    (Top:29; Bow:50; Base:92; Drop:113),
    (Top:39; Bow:67; Base:123;Drop:151)),

   ((Top: 8; Bow:12; Base:20; Drop:24),
    (Top: 8; Bow:13; Base:22; Drop:26),
    (Top:10; Bow:15; Base:25; Drop:30),
    (Top:13; Bow:20; Base:34; Drop:41),
    (Top:17; Bow:27; Base:45; Drop:54),  {Complex Font : 8}
    (Top:22; Bow:34; Base:57; Drop:68),
    (Top:27; Bow:41; Base:69; Drop:83),
    (Top:34; Bow:51; Base:86; Drop:103),
    (Top:41; Bow:62; Base:104;Drop:125),
    (Top:54; Bow:83; Base:139;Drop:167)),

   ((Top: 7; Bow:14; Base:32; Drop:38),
    (Top: 7; Bow:15; Base:35; Drop:41),
    (Top: 9; Bow:18; Base:40; Drop:47),
    (Top:12; Bow:24; Base:54; Drop:64),
    (Top:16; Bow:32; Base:72; Drop:85),  {European Font : 9}
    (Top:20; Bow:40; Base:96; Drop:106),
    (Top:25; Bow:49; Base:109;Drop:129),
    (Top:31; Bow:61; Base:136;Drop:161),
    (Top:38; Bow:74; Base:164;Drop:194),
    (Top:51; Bow:99; Base:219;Drop:259)),

   ((Top:11; Bow:17; Base:35; Drop:39),
    (Top:13; Bow:19; Base:39; Drop:43),
    (Top:14; Bow:22; Base:44; Drop:49),
    (Top:19; Bow:29; Base:59; Drop:66),
    (Top:27; Bow:39; Base:79; Drop:88),  {Bold Font : 10}
    (Top:33; Bow:49; Base:99; Drop:110),
    (Top:39; Bow:59; Base:119;Drop:133),
    (Top:49; Bow:74; Base:149;Drop:166),
    (Top:59; Bow:89; Base:179;Drop:200),
    (Top:79; Bow:199;Base:239;Drop:267)));

  Low_Char : Array[0..255] of Byte =
    (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
     0,0,0,0,0,0,0,1,0,0,1,0,0,0,0,0,1,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,
     1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,1,
     0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
     1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
     0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0);
const
  MegaArray : array[0..35] of Char = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

type
  Str2  = string[2];
  Str4  = string[4];

  CharMapRecord = record
    s8x8   : Array[1..8] of Byte;
    s7x8   : Array[1..8] of Byte;
    s8x14  : Array[1..14] of Byte;
    s7x14  : Array[1..14] of Byte;
    s16x14 : Array[1..14] of Word;
  end;

Function BackSlash(instring : string) : string;
Function EscapeString(instring : string) : string;
Function WordToMega(Num : word) : Str2;
Function WordToMega4(Num : word) : Str4;
Function MegaToWord(S2 : Str2) : Word;
Function Mega4ToLong(S4 : Str4) : Longint;
Procedure DisplayChar(x,y:word;clr,bclr:byte;c:CharMapRecord;tsize:byte);

implementation

uses
  dos,graph;

Function BackSlash(instring : string) : string;
begin
  if not ((instring[length(instring)]) = '\') then
    backslash := instring + '\'
  else
    backslash := instring;
end;

Function EscapeString(instring : string) : string;
var
  st : string;
  c  : byte;
begin
  st := '';
  for c := 1 to length(instring) do
  begin
    if instring[c] in ['!','\','|'] then
      st := st + '\';
    st := st + instring[c];
  end;
  escapestring := st;
end;

Function WordToMega(Num : word) : Str2;
var
  work          : str2;
begin
  work := '';
  if (Num < 0) or (Num > 1295) then
  begin
    WordToMega := '  ';
    Exit;
  end;
  while Num >0 do
  begin
    work := megaarray[num mod 36]+work;
    num := num div 36;
  end;
  while length(work)<2 do
    work := '0'+work;
  WordToMega := work;
end;

Function WordToMega4(Num : word) : Str4;
var
  work          : str4;
begin
  work := '';
  while Num >0 do
  begin
    work := megaarray[num mod 36]+work;
    num := num div 36;
  end;
  while length(work)<4 do
    work := '0'+work;
  WordToMega4 := work;
end;

Function MegaToWord(S2 : Str2) : Word;
var
  Num           : word;
begin
  num := 0;
  if not ord(upcase(s2[1])) in [48..57,65..90] then Exit;
  if not ord(upcase(s2[2])) in [48..57,65..90] then Exit;
  while s2 <> '' do
  begin
    if s2[1] > '9' then
      num := num*36+ord(s2[1])-55
    else
      num := num*36+ord(s2[1])-48;
    delete(s2,1,1);
  end;
  MegaToWord := num;
end;

Function Mega4ToLong(S4 : Str4) : Longint;
var
  Num           : longint;
begin
  num := 0;
  if not ord(upcase(s4[1])) in [48..57,65..90] then Exit;
  if not ord(upcase(s4[2])) in [48..57,65..90] then Exit;
  if not ord(upcase(s4[3])) in [48..57,65..90] then Exit;
  if not ord(upcase(s4[4])) in [48..57,65..90] then Exit;
  while s4 <> '' do
  begin
    if s4[1] > '9' then
      num := num*36+ord(s4[1])-55
    else
      num := num*36+ord(s4[1])-48;
    delete(s4,1,1);
  end;
  Mega4ToLong := num;
end;

Function FlagOn(Flags : Byte; FlagMask : Byte) : Boolean;
begin
  if FlagMask = 0 then
  begin
    flagon := true;
    exit;
  end;
  FlagOn := (Flags and FlagMask) <> 0;
end;

Procedure DisplayChar(x,y:word;clr,bclr:byte;c:CharMapRecord;tsize:byte);
var
  ct : byte;
begin
  case tsize of
    0 : begin {8x8}
          for ct := 1 to 8 do
          begin
            if flagon(c.s8x8[ct],$01) then putpixel(x  ,y+ct-1,clr) else putpixel(x  ,y+ct-1,bclr);
            if flagon(c.s8x8[ct],$02) then putpixel(x+1,y+ct-1,clr) else putpixel(x+1,y+ct-1,bclr);
            if flagon(c.s8x8[ct],$04) then putpixel(x+2,y+ct-1,clr) else putpixel(x+2,y+ct-1,bclr);
            if flagon(c.s8x8[ct],$08) then putpixel(x+3,y+ct-1,clr) else putpixel(x+3,y+ct-1,bclr);
            if flagon(c.s8x8[ct],$10) then putpixel(x+4,y+ct-1,clr) else putpixel(x+4,y+ct-1,bclr);
            if flagon(c.s8x8[ct],$20) then putpixel(x+5,y+ct-1,clr) else putpixel(x+5,y+ct-1,bclr);
            if flagon(c.s8x8[ct],$40) then putpixel(x+6,y+ct-1,clr) else putpixel(x+6,y+ct-1,bclr);
            if flagon(c.s8x8[ct],$80) then putpixel(x+7,y+ct-1,clr) else putpixel(x+7,y+ct-1,bclr);
          end;
        end;
    1 : begin {7x8}
          for ct := 1 to 8 do
          begin
            if flagon(c.s7x8[ct],$01) then putpixel(x  ,y+ct-1,clr) else putpixel(x  ,y+ct-1,bclr);
            if flagon(c.s7x8[ct],$02) then putpixel(x+1,y+ct-1,clr) else putpixel(x+1,y+ct-1,bclr);
            if flagon(c.s7x8[ct],$04) then putpixel(x+2,y+ct-1,clr) else putpixel(x+2,y+ct-1,bclr);
            if flagon(c.s7x8[ct],$08) then putpixel(x+3,y+ct-1,clr) else putpixel(x+3,y+ct-1,bclr);
            if flagon(c.s7x8[ct],$10) then putpixel(x+4,y+ct-1,clr) else putpixel(x+4,y+ct-1,bclr);
            if flagon(c.s7x8[ct],$20) then putpixel(x+5,y+ct-1,clr) else putpixel(x+5,y+ct-1,bclr);
            if flagon(c.s7x8[ct],$40) then putpixel(x+6,y+ct-1,clr) else putpixel(x+6,y+ct-1,bclr);
          end;
        end;
    2 : begin {8x14}
          for ct := 1 to 14 do
          begin
            if flagon(c.s8x14[ct],$01) then putpixel(x  ,y+ct-1,clr) else putpixel(x  ,y+ct-1,bclr);
            if flagon(c.s8x14[ct],$02) then putpixel(x+1,y+ct-1,clr) else putpixel(x+1,y+ct-1,bclr);
            if flagon(c.s8x14[ct],$04) then putpixel(x+2,y+ct-1,clr) else putpixel(x+2,y+ct-1,bclr);
            if flagon(c.s8x14[ct],$08) then putpixel(x+3,y+ct-1,clr) else putpixel(x+3,y+ct-1,bclr);
            if flagon(c.s8x14[ct],$10) then putpixel(x+4,y+ct-1,clr) else putpixel(x+4,y+ct-1,bclr);
            if flagon(c.s8x14[ct],$20) then putpixel(x+5,y+ct-1,clr) else putpixel(x+5,y+ct-1,bclr);
            if flagon(c.s8x14[ct],$40) then putpixel(x+6,y+ct-1,clr) else putpixel(x+6,y+ct-1,bclr);
            if flagon(c.s8x14[ct],$80) then putpixel(x+7,y+ct-1,clr) else putpixel(x+7,y+ct-1,bclr);
          end;
        end;
    3 : begin {7x14}
          for ct := 1 to 14 do
          begin
            if flagon(c.s7x14[ct],$01) then putpixel(x  ,y+ct-1,clr) else putpixel(x  ,y+ct-1,bclr);
            if flagon(c.s7x14[ct],$02) then putpixel(x+1,y+ct-1,clr) else putpixel(x+1,y+ct-1,bclr);
            if flagon(c.s7x14[ct],$04) then putpixel(x+2,y+ct-1,clr) else putpixel(x+2,y+ct-1,bclr);
            if flagon(c.s7x14[ct],$08) then putpixel(x+3,y+ct-1,clr) else putpixel(x+3,y+ct-1,bclr);
            if flagon(c.s7x14[ct],$10) then putpixel(x+4,y+ct-1,clr) else putpixel(x+4,y+ct-1,bclr);
            if flagon(c.s7x14[ct],$20) then putpixel(x+5,y+ct-1,clr) else putpixel(x+5,y+ct-1,bclr);
            if flagon(c.s7x14[ct],$40) then putpixel(x+6,y+ct-1,clr) else putpixel(x+6,y+ct-1,bclr);
          end;
        end;
    4 : begin {16x14}
          for ct := 1 to 14 do
          begin
            if flagon(lo(c.s16x14[ct]),$01) then putpixel(x   ,y+ct-1,clr) else putpixel(x   ,y+ct-1,bclr);
            if flagon(lo(c.s16x14[ct]),$02) then putpixel(x+1 ,y+ct-1,clr) else putpixel(x+1 ,y+ct-1,bclr);
            if flagon(lo(c.s16x14[ct]),$04) then putpixel(x+2 ,y+ct-1,clr) else putpixel(x+2 ,y+ct-1,bclr);
            if flagon(lo(c.s16x14[ct]),$08) then putpixel(x+3 ,y+ct-1,clr) else putpixel(x+3 ,y+ct-1,bclr);
            if flagon(lo(c.s16x14[ct]),$10) then putpixel(x+4 ,y+ct-1,clr) else putpixel(x+4 ,y+ct-1,bclr);
            if flagon(lo(c.s16x14[ct]),$20) then putpixel(x+5 ,y+ct-1,clr) else putpixel(x+5 ,y+ct-1,bclr);
            if flagon(lo(c.s16x14[ct]),$40) then putpixel(x+6 ,y+ct-1,clr) else putpixel(x+6 ,y+ct-1,bclr);
            if flagon(lo(c.s16x14[ct]),$80) then putpixel(x+7 ,y+ct-1,clr) else putpixel(x+7 ,y+ct-1,bclr);
            if flagon(hi(c.s16x14[ct]),$01) then putpixel(x+8 ,y+ct-1,clr) else putpixel(x+8 ,y+ct-1,bclr);
            if flagon(hi(c.s16x14[ct]),$02) then putpixel(x+9 ,y+ct-1,clr) else putpixel(x+9 ,y+ct-1,bclr);
            if flagon(hi(c.s16x14[ct]),$04) then putpixel(x+10,y+ct-1,clr) else putpixel(x+10,y+ct-1,bclr);
            if flagon(hi(c.s16x14[ct]),$08) then putpixel(x+11,y+ct-1,clr) else putpixel(x+11,y+ct-1,bclr);
            if flagon(hi(c.s16x14[ct]),$10) then putpixel(x+12,y+ct-1,clr) else putpixel(x+12,y+ct-1,bclr);
            if flagon(hi(c.s16x14[ct]),$20) then putpixel(x+13,y+ct-1,clr) else putpixel(x+13,y+ct-1,bclr);
            if flagon(hi(c.s16x14[ct]),$40) then putpixel(x+14,y+ct-1,clr) else putpixel(x+14,y+ct-1,bclr);
            if flagon(hi(c.s16x14[ct]),$80) then putpixel(x+15,y+ct-1,clr) else putpixel(x+15,y+ct-1,bclr);
          end;
        end;
  end;
end;

End.
