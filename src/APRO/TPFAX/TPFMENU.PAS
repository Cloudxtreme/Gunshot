{******************************************************}
{*                 TPFMENU.PAS  2.03                  *}
{*      Copyright (c) TurboPower Software 1993.       *}
{*                All rights reserved.                *}
{******************************************************}

{$I OPDEFINE.INC}
{$IFDEF Ver70}
{$I APDEFINE.INC}
{$ENDIF}

{$IFDEF DPMI}
{$V-,B-,R-,S-,F-,O-,A+,I-,X+}
{$ELSE}
{$V-,B-,R-,S-,F+,O+,A+,I-,X+}
{$ENDIF}

unit TpfMenu;

interface

uses
  OpInline,
  OpString,
  OpRoot,
  OpCrt,
  OpMouse,
  OpCmd,
  OpFrame,
  OpWindow,
  ApMisc,
  OpColor,
  TpfColor,
  TpfDia,
  OpMenu;

{$IFDEF Ver60}
{$I APDEFINE.INC}
{$ENDIF}

const
  mmAbout     = 1;
  mmConvert   = 1000;
  mmSend      = 2000;
  mmView      = 3000;
  mmPrint     = 4000;
  mmPhonebook = 5000;
  mmExit      = 9000;

function InitMainMenu : MenuPtr;


implementation

  procedure CurrentItemProc(CurrentItem : MenuItemNodePtr; MPtr : MenuPtr); far;
  var
    S : String;
    L : Byte absolute S;

  begin
    if (CurrentItem = nil) then
      S := ''
    else
      S := CurrentItem^.HelpString;

    L := MinWord(L, 78);
    ClearStatus;
    FastText(S, ScreenHeight, 2);
  end;

  function InitMainMenu : MenuPtr;
  var
    M : MenuPtr;

  begin
    InitMainMenu := nil;

    New(M, InitCustom(1, 1, 80, 1, MenuColors,
                      wClear+wUserContents+wCoversOnDemand,
                      Horizontal));
    if (M = nil) then
      Exit;

    with M^ do begin
      mnOptionsOn(mnAlphaMatch+mnSelectOnMatch+mnArrowSelect+mnAllHotSpots+
                  mnAllowPending+mnSelectOnClick+mnAltMatch);
      mnOptionsOff(mnPopOnSelect);
      SetSelectMarker(#32, #32);
      AddItemHelp(#240, 2, 1, mmAbout,
                  'About TPFAX');
      AddItemHelp('Convert', 7, 1, mmConvert,
                  'Convert a file (PCX, TIF, TXT, DCX) to APRO fax format');
      AddItemHelp('Send', 18, 1, mmSend,
                  'Fax one or more files');
      AddItemHelp('View', 26, 1, mmView,
                  'View a fax file');
      AddItemHelp('Print', 34, 1, mmPrint,
                  'Print one or more fax files');
      AddItemHelp('Phonebook', 43, 6, mmPhonebook,
                  'Load a TPFAX phonebook file');
      AddItemHelp('eXit', 74, 2, mmExit,
                  'Exit to DOS');
      ItemsDone;

      SetCurrentItemProc(CurrentItemProc);

      InitStatus := RawError;
      if (InitStatus = ecOK) then
        InitMainMenu := M
      else
        Dispose(M, Done);
    end;
  end;

end.
