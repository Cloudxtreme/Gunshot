{$S-,R-,V-,I-,B-,F+,O-,A-}
{*********************************************************}
{*                 OOPMAIN0.PAS 2.03                     *}
{*        Copyright (c) TurboPower Software 1991.        *}
{*                 All rights reserved.                  *}
{*********************************************************}

{$I OPDEFINE.INC}
{$I APDEFINE.INC}

unit OopMain0;
interface

uses
  {$IFNDEF DPMI}
  overlay,
  {$ENDIF}
  dos,                            {DOS/BIOS stuff}
  opinline,                       {inline macros}
  oproot,                         {base objects, error codes, etc.}
  opcmd,                          {command processing}
  opcrt,                          {low-level screen handling}
  {$IFDEF UseMouse}
  opmouse,                        {mouse handling}
  {$ENDIF}
  opstring,                       {string handling}
  opdos,                          {misc. DOS/BIOS routines}
  opframe,                        {frames, shadows, etc.}
  opwindow,                       {window management}
  opbrowse,                       {file browser}
  opmemo,                         {memo editor}
  opeditor,                       {text editor}
  opabsfld,                       {abstract field, picture mask stuff}
  opfield,                        {field definitions}
  opedit,                         {line editor}
  opselect,                       {selectors}
  opentry,                        {entry screens}
  oppick,                         {pick lists}
  opdir,                          {directory lists}
  opmenu,                         {menus}
  ophelp,
  ooui,                           {object oriented user interface}
  ApPort,
  {ApUart,}                                                            {!!.01}
  ApMisc,
  ApTimer,
  OOAbsPcl,
  OOXModem,
  OOYModem,
  OOZModem,
  OOKermit,
  OOCom,
  OOModem,
  OOEmu,
  termwin;                        {APRO terminal windows}

{$I OOPMAIN.PCD}

const
  Version         = '2.03';
  ModuleName      : String[6] = 'OOPCOM'; {module name for standard interface}
  ProgName        : String[39] = 'OOPCOM '+Version+': OOP Communications Program';
  Copyright       : String[41] = 'Copyright (c) 1991 by TurboPower Software';


  pwCloseOnCompetion = $0001;
  FeederFileName : String = 'OOPMAIN.PAS';
  FeedFromFile   : Boolean = False;
  HelpOK         : Boolean = False;

type
  ModemNameString = String[12];
  ArrayOfModem = Array[1..512] of ModemNameString;
  ArrayOfModemPtr = ^ArrayOfModem;
  ModemList =
    object
      Static : Boolean;
      Num  : Word;
      List : ArrayOfModemPtr;
      constructor Init(LibName : String);
      constructor InitStatic;
      function AllocList(Number : Word) : Boolean;
      procedure SetEntry(Index : Word; S : String);
      function Entry(Index : Word) : String;
      function Widest : Word;
      function InstantiateModem(Index : Word;
                                P : AbstractPortPtr) : AbstractModemPtr;
      function ModemIndex(Name : ModemNameString) : Word;
    end;

var
  BrowseWin       : Browser;         {file browser}
  EditWin         : TextEditor;      {editor}
  HelpWin         : ScrollingHelpWindow;
  OptWin          : EntryScreen;
  MainMenu        : Menu;            {main menu}
  LocalMenu       : Menu;            {basic local menu}
  ProtocolCommands: CommandProcessor;
  StatusCommands  : CommandProcessor;
  PhoneCommands   : CommandProcessor;
  OldGetKeyProc   : GetKeyProc;      {to save GetKeyProc}
  OldKeyPressed   : KeyPressedProc;
  BrowseMenu      : Menu;
  ModemTypes      : ModemList;
  SystemIsPs2     : Boolean;

const
  EditTitle       = 'Editor: ';
  BrowseTitle     = 'Browser: ';
  PhoneTitle      = 'Phones: ';
  HelpTitle       = ' Help: ';
  YesNoSt         : array[Boolean] of array[1..3] of Char = ('No ', 'Yes');
  OffOn           : Array[Boolean] of String[3] = ('off', 'on');

function SizeOfConfig : Word;

function InitializeModems(var LibFound : Boolean) : Boolean;
  {-Init the global ModemTypes ModemList}

implementation

  function SizeOfConfig : Word;
  begin
    SizeOfConfig := Ofs(DeskMainCfgEnd) - Ofs(OopComID);
  end;

  constructor ModemList.Init(LibName : String);

  var
    {$IFDEF Opro12}
    Lib : OpLibrary;
    {$ELSE}
    Lib : Library;
    {$ENDIF}
    Count, I, Entries : Word;
  begin
    if not Lib.Init(LibName, SOpenRead, 1024, ModemLibSig) then
      Fail;
    with Lib do begin
      Entries := CurrentEntries;
      if Entries = 0 then begin
        Lib.Done;
        Fail;
      end;
      if not AllocList(Entries) then begin
        Lib.Done;
        Fail;
      end;
      Count := 0;
      for I := 1 to MaxEntries do
        with FindEntryByIndex(I)^ do
          if (not deOptionsAreOn(deUnused)) and
             (not deOptionsAreOn(deDeleted)) then begin
            Inc(Count);
            SetEntry(Count, GetEntryName);
          end;
    end;
    Lib.Done;
    Static := False;
  end;

  constructor ModemList.InitStatic;
  begin
    if not AllocList(4) then
      Fail;
    SetEntry(1, 'Hayes');
    SetEntry(2, 'Courier');
    SetEntry(3, 'Microcom');
    SetEntry(4, 'Null');
    Static := True;
  end;

  function ModemList.ModemIndex(Name : ModemNameString) : Word;
  var
    I : Word;
  begin
    for I := 1 to Num do
      if Name = Entry(I) then begin
        ModemIndex := I;
        Exit;
      end;
    ModemIndex := 0;
  end;

  function ModemList.InstantiateModem(Index : Word;
                                      P : AbstractPortPtr) : AbstractModemPtr;
  var
    M : AbstractModemPtr;
    {$IFDEF Opro12}
    Lib : OpLibrary;
    {$ELSE}
    Lib : Library;
    {$ENDIF}
  begin
    InstantiateModem := Nil;
    if Index > Num then
      Exit;
    if Static then begin
      case Index of
        1 : M := New(HayesModemPtr, Init(P));
        2 : M := New(CourierModemPtr, Init(P));
        3 : M := New(MicrocomModemPtr, Init(P));
        4 : M := New(NullModemPtr, Init(P));
        else M := Nil;
      end;
    end
    else begin
      M := Nil;
      {load from lib}
      if not Lib.Init(ModemLibName, SOpenRead, 1024, ModemLibSig) then
        Exit;
      Lib.RegisterHier(AllModemStream);
      Lib.RegisterPointer(ptPortPtr, P);
      M := AbstractModemPtr(Lib.GetEntryPtr(Entry(Index)));
      if Lib.GetStatus <> 0 then
        M := Nil;
      Lib.Done;
    end;
    InstantiateModem := M;
  end;

  procedure ModemList.SetEntry(Index : Word; S : String);
  begin
    List^[Index] := S;
  end;

  function ModemList.Widest : Word;
  var
    I, W, L : Word;
  begin
    W := 0;
    for I := 1 to Num do begin
      L := Length(Entry(I));
      if L > W then
        W := L;
    end;
    Widest := W;
  end;

  function ModemList.AllocList(Number : Word) : Boolean;
  begin
    Num := Number;
    AllocList := GetMemCheck(List, Number * SizeOf(ModemNameString));
  end;

  function ModemList.Entry(Index : Word) : String;
  begin
    if Index <= Num then
      Entry := List^[Index]
    else
      Entry := '';
  end;

  function InitializeModems(var LibFound : Boolean) : Boolean;
  begin
    InitializeModems := False;
    if ModemTypes.Init(ModemLibName) then
      LibFound := True
    else begin
      LibFound := False;
      if not ModemTypes.InitStatic then
        Exit;
    end;
    InitializeModems := True;
  end;


end.
