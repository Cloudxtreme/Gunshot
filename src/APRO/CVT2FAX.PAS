{$S-,R-,V-,I-,B-,F+,A-}

{$I APDEFINE.INC}

{******************************************************}
{*                 CVT2FAX.PAS  2.03                  *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

program Cvt2Fax;
  {-Convert text, PCX, DCX, TIFF, or BMP file to fax format}

uses
  {$IFDEF LeakCheck}                                                   {!!.01}
  LeakChek,                                                            {!!.01}
  {$ENDIF}                                                             {!!.01}
  Dos,
  {$IFDEF UseOPro}
  OpCrt,
  OpString,
  {$ENDIF}
  {$IFDEF UseTPro}
  TpCrt,
  TpString,
  {$ENDIF}
  {$IFDEF Standalone}
  Crt,
  {$ENDIF}
  {$IFDEF UsePModeDLL}
  ApComD,
  ApFaxD;
  {$ELSE}
  ApMisc,
  ApFaxCvt;
  {$ENDIF}

type
  CvtFileType = (cvtNone, cvtText, cvtPcx, cvtDcx, cvtTiff, cvtBmp);   {!!.03}

const
  CvtFile     : String = '';
  StaID       : String = 'FAX DEMO';
  CvtType     : CvtFileType = cvtText;
  HiRes       : Boolean = False;
  HiResFont   : Boolean = False;
  UseHPFont   : Boolean = False;
  HPFontName  : PathStr = '';
  PgBrk       : Integer = 0;
  SingleWidth : Boolean = False;
  LeftImage   : Boolean = False;
  ExtraWide   : Boolean = False;  {!!.03}

var
  FCP : FaxConverterPtr;

  procedure Abort(S : String);
  begin
    WriteLn(S);
    Halt(1);
  end;

  function Long2Str(L : LongInt) : String;
  var
    S : String[20];
  begin
    Str(L, S);
    Long2Str := S;
  end;

  procedure ShowHelp;
  begin
    WriteLn('Usage: CVT2FAX [options] FileName');
    WriteLn('  /T           Convert from ASCII text to fax (default)');
    WriteLn('  /P           Convert from PCX (mono) to fax');
    WriteLn('  /D           Convert from DCX (mono) to fax');
    WriteLn('  /F           Convert from TIFF (mono) to fax');
    Writeln('  /M           Convert from BMP (mono) to fax');          {!!.03}
    WriteLn('  /L Lines     Specify page break (text only, default=0 (no breaks),');
    WriteLn('  /H           High resolution output (200x200; default=100x200)');
    WriteLn('  /B           Use high resolution font when converting text');
    WriteLn('  /S FontName  Use HP soft font file');
    WriteLn('  /N           No width doubling for graphics files');
    WriteLn('  /W           General 2048 pixel wide fax');             {!!.03}
    WriteLn('  /J           Left justify graphics images instead of centering them');
    WriteLn('  /?           This screen');
    Halt(0);
  end;

  procedure ParseCmdLine;
  var
    S : String;
    I, N, C : Integer;
  begin
    if ParamCount = 0 then
      ShowHelp;
    I := 1;
    while I <= ParamCount do begin
      S := ParamStr(I);
      if S[1] in ['/','-'] then begin
        case Upcase(S[2]) of
          '?':
            ShowHelp;
          'T':
            CvtType := cvtText;
          'P':
            CvtType := cvtPCX;
          'D':
            CvtType := cvtDCX;
          'F':
            CvtType := cvtTIFF;
          'M':                                                         {!!.03}
            CvtType := cvtBmp;                                         {!!.03}
          'H':
            HiRes := True;
          'B' :
            HiResFont := True;
          'I':
            begin
              Inc(I);
              StaID := ParamStr(I);
            end;
          'L':
            begin
              Inc(I);
              S := ParamStr(I);
              Val(S, N, C);
              if (C = 0) and (N >= 0) then
                PgBrk := N
              else
                ShowHelp;
            end;
          'S' :
            begin
              Inc(I);
              HPFontName := ParamStr(I);
              UseHPFont := True;
            end;
          'N' :
            SingleWidth := True;
          'W' :                      {!!.03}
            ExtraWide := True;       {!!.03}
          'J' :
            LeftImage := True;
          else
            begin
              WriteLn('Unknown parameter "'+S+'"');
              ShowHelp;
            end;
        end;
      end else
        CvtFile := StUpcase(S);

      Inc(I);
    end;

    if CvtFile = '' then begin
      WriteLn('No filename provided');
      ShowHelp;
    end;
  end;

  function OurStatusFunc(FC : FaxConverterPtr;
                         Starting, Ending : Boolean) : Boolean;
  {$IFDEF UsePModeDLL} Export; {$ENDIF}
  const
    First : Boolean = True;
  var
    Line : LongInt;
    Page : Integer;
  begin
    if First then begin
      WriteLn('Converting ', StUpcase(GetFileName(FC)));
      First := False;
    end;
    GetStatusInfo(FC, Line, Page);
    if (GetAsyncStatus mod 10000 )= ecHPFontCvt then
      Write(^H^H^H^H^H'('+PadCh(Long2Str(FC^.PData^.CID), ' ', 3)+')')
    else
      Write(^M'Processing line ', Line:4, ' of page ', Page:4);

    {Check for abort request}
    if KeyPressed then
      OurStatusFunc := (ReadKey = #27)
    else
      OurStatusFunc := False;
  end;

begin
  Assign(Output, '');
  Rewrite(Output);

  WriteLn('CVT2FAX 2.03 - Convert text, PCX, DCX, TIFF, or BMP files to APF format');{!!.03}
  WriteLn('Copyright (c)1993  TurboPower Software');
  ParseCmdLine;

  case CvtType of
    cvtPCX  : InitPcxConverter(FCP);
    cvtDCX  : InitDcxConverter(FCP);
    cvtTIFF : InitTiffConverter(FCP);
    cvtBMP  : InitBmpConverter(FCP);                                   {!!.03}
    else      InitTextConverter(FCP);
  end;
  if GetAsyncStatus <> ecOk then
    Abort('Error '+Long2Str(GetAsyncStatus)+' initializing converter object');

  {Set hooks}
  SetStatusFunc(FCP, OurStatusFunc);
  SetPageSize(FCP, PgBrk);
  SetResolutionMode(FCP, HiRes);
  if ExtraWide then                     {!!.03}
    SetResolutionWidth(FCP, rw2048);    {!!.03}
  SetStationIDCvt(FCP, StaID);

  {Pick a font}
  if UseHPFont then begin
    Write('Loading HP font ', HPFontName, ':      ');
    if not LoadHPFont(FCP, HPFontName, HiResFont) then
      Abort(^M^J'Failed to load HP soft font, font uses an supported feature');
    WriteLn;
  end else if HiResFont then
    if not LoadFont(FCP, StandardFont, True) then ;

  (* test margin setting
  SetMargins(FCP, 100, 10);
  *)

  {Convert it}
  case CvtType of
    cvtPCX, cvtDCX:
      begin
        if SingleWidth then
          fcOptionsOff(FCP, fcDoubleWidth);
        if LeftImage then
          fcOptionsOff(FCP, fcCenterImage);
        if CvtType = cvtPCX then
          ConvertFaxPcx(FCP, CvtFile)
        else
          ConvertFaxDcx(FCP, CvtFile);
      end;
    cvtTiff:
      begin                                                            {!!.02}
        if SingleWidth then                                            {!!.02}
          fcOptionsOff(FCP, fcDoubleWidth);                            {!!.02}
        if LeftImage then                                              {!!.02}
          fcOptionsOff(FCP, fcCenterImage);                            {!!.02}
        ConvertFaxTiff(FCP, CvtFile);
      end;                                                             {!!.02}
    cvtBmp:                                                            {!!.03}
      begin                                                            {!!.03}
        if SingleWidth then                                            {!!.03}
          fcOptionsOff(FCP, fcDoubleWidth);                            {!!.03}
        if LeftImage then                                              {!!.03}
          fcOptionsOff(FCP, fcCenterImage);                            {!!.03}
        ConvertFaxBmp(FCP, CvtFile);                                   {!!.03}
      end;                                                             {!!.03}
    else
      {Assumed to be text}
      ConvertFaxText(FCP, CvtFile);
  end;

  {Cleanup}
  case GetAsyncStatus of
    0 :     WriteLn(^M^J'Conversion complete');
    9976 :  WriteLn(^M^J'Input file is bad or uses an unsupported feature');
    else    WriteLn(^M^J'Error ', GetAsyncStatus, ' converting file');
  end;
  WriteLn;
  case CvtType of
    cvtPCX  : DonePcxConverter(FCP);
    cvtDCX  : DoneDcxConverter(FCP);
    cvtTiff : DoneTiffConverter(FCP);
    cvtBmp  : DoneBmpConverter(FCP);                                   {!!.03}
    else      DoneTextConverter(FCP);
  end;
end.
