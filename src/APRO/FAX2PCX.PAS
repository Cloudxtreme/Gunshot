{$S-,R-,V-,I-,B-,F+,A-}

{$I APDEFINE.INC}

{******************************************************}
{*                   PCX2FAX.PAS  2.03                *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

program Fax2Pcx;
  {-Converts a FAX to a PCX/DCX}

uses
  {$IFDEF LeakCheck}                                                   {!!.01}
  LeakChek,                                                            {!!.01}
  {$ENDIF}                                                             {!!.01}
  Crt,
  Dos,
  {$IFDEF UseOPRO}
  OpString,
  {$ENDIF}
  {$IFDEF UseTPRO}
  TpString,
  {$ENDIF}
  ApMisc,
  {$IFDEF UsePModeDLL}
  ApFaxD;
  {$ELSE}
  ApFaxCvt;
  {$ENDIF}

const
  CopyrightLine = 'FAX2PCX 2.03 -- APF to PCX/DCX   (c)1993 TurboPower Software';
  HalveIt : Boolean = False;  {True to use 1/2 horizontal width}
  IsDcx   : Boolean = False;  {True to create a DCX file}

var
  UFP : UnpackToPcxPtr;
  PcxFile : PathStr;
  FaxFile : PathStr;
  Lines : Word;
  Status : Word;
  DotPos : Byte;

  procedure ShowHelp;
  begin
    WriteLn('Usage: FAX2PCX [options] FaxFile');
    WriteLn('  /H    Reduce image width (50% reduction)');
    WriteLn('  /D    Output is a DCX file');
    WriteLn('  /?    Show this screen');
    Halt(1);
  end;

  procedure ParseCmdLine;
  var
    S : String;
    I : Integer;
  begin
    FaxFile := '';
    if ParamCount = 0 then
      ShowHelp;
    I := 1;
    repeat
      S := ParamStr(I);
      if S[1] in ['/','-'] then begin
        case Upcase(S[2]) of
          'H' : HalveIt := True;
          'D' : IsDcx := True;
          else  ShowHelp;
        end;
      end else
        FaxFile := DefaultExtension(StUpcase(S), 'APF');
      Inc(I);
    until I > ParamCount;
    if FaxFile = '' then
      ShowHelp;
  end;

  function ConvertFaxLine(UP : UnpackFaxPtr; Buffer : PByteBuffer;
                          Len : Word; PH : PageHeaderRec) : Boolean;
    {-No conversion to do, just show status or abort}
  {$IFDEF UsePModeDLL} Export; {$ENDIF}
  var
    C : Char;
  begin
    if KeyPressed then begin
      C := ReadKey;
      if C = #0 then
        C := ReadKey
      else
        ConvertFaxLine := C = #27;
    end else begin
      ConvertFaxLine := False;
      Inc(Lines);
      if Lines mod 10 = 0 then
        Write(^H^H^H^H^H, Lines:5);
    end;
  end;

begin
  WriteLn(CopyrightLine);

  ParseCmdLine;

  {Create the output file}
  DotPos := Pos('.', FaxFile);
  if IsDcx then
    PcxFile := Copy(FaxFile, 1, DotPos-1) + '.DCX'
  else
    PcxFile := Copy(FaxFile, 1, DotPos-1) + '.PCX';

  {Init the fax decompressor}
  if IsDcx then
    InitUnpackToDcx(UFP)
  else
    InitUnpackToPcx(UFP);
  if UFP = nil then begin
    WriteLn('Error initializing unpacker');
    Halt;
  end;

  if HalveIt then
    ufOptionsOn(UFP^.UF, ufHalfWidth);

  {Convert the fax}
  Write(^M^J'converting raster line:    ');
  SetOutputLineFunc(UFP^.UF, ConvertFaxLine);
  Lines := 0;
  if IsDcx then
    UnpackFileToDcx(UFP, FaxFile, PcxFile)
  else
    UnpackFileToPcx(UFP, FaxFile, PcxFile);
  if GetAsyncStatus <> 0 then
    WriteLn(^M^J'Decompress error ', GetAsyncStatus);                  {!!.01}

  if IsDcx then
    DoneUnpackToDcx(UFP)
  else
    DoneUnpackToPcx(UFP);                                              {!!.01}
end.

