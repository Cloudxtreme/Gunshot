{$S-,R-,V-,I-,B-,F+,O-,A-}

{Conditional defines that may affect this unit}
{$I APDEFINE.INC}

{*********************************************************}
{*                   FSCLIST.PAS 2.03                    *}
{*        Copyright (c) TurboPower Software 1991.        *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit FsCList;
  {-Command file list for Fax server}

interface

uses
  Dos,
  {$IFDEF UseOPRO}
  OpRoot,
  OpString,
  {$ENDIF}
  {$IFDEF UseTPRO}
  TpMemChk,
  TpString,
  {$ENDIF}
  {$IFDEF UsePModeDLL}                                                 {!!.02}
  ApComD,                                                              {!!.02}
  ApFaxD;                                                              {!!.02}
  {$ELSE}                                                              {!!.02}
  ApMisc;                                                              {!!.02}
  {$ENDIF}                                                             {!!.02}

const
  MaxFilesToSend  = 20;

type
  CmdFileNodePtr  = ^CmdFileNode;
  CmdFileNode     = record
    CmdFileName   : PathStr;     {name of the fax command file}
    CmdFileTime   : LongInt;     {file date and time}
    Scheduled     : LongInt;     {packed date time}
    SendBaudRate  : LongInt;     {baud rate to use to send the fax}
    FileName      : array[1..MaxFilesToSend] of PathStr; {fax file(s) to send}
    DeleteFlag    : array[1..MaxFilesToSend] of Boolean; {fax file(s) to delete}
    SenderID      : string[20];  {station ID to used for this send}
    CoverPage     : PathStr;     {file to use as the cover page}
    Sender        : string[80];  {replaces the $F tag}
    Recipient     : string[80];  {replaces the $R tag}
    UseHeaderLine : Boolean;     {true to print a header line}
    HeaderText    : string[80];  {replaces the $S tag in the header line}
    Phone         : string[36];  {phone number to send to}
    Retries       : Byte;        {count of attemps to send}
    {"Next" must be last item in record}
    Next          : CmdFileNodePtr;  {pointer to next node}
  end;

  CmdFileList    = record
    Head, Tail   : CmdFileNodePtr;
    Count        : Integer;
  end;

procedure InitCmdFileList(var CFL : CmdFileList);
  {-Initialize a CmdFileList}
procedure DoneCmdFileList(var CFL : CmdFileList);
  {-Dispose of a CmdFileList}
procedure SortCmdFileList(var CFL : CmdFileList);
  {-Sorts CFL in ascending order by date/time field}
function AddCmdFileNode(var CFL : CmdFileList; var CFN : CmdFileNode) : Boolean;
  {-Add CFN to a list of command file nodes. maintain sorted order}
procedure DeleteCmdFileNode(var CFL : CmdFileList; var NP : CmdFileNodePtr);
  {-Delete a node from the command file list}
function FindCmdFileNode(var CFL : CmdFileList; FN : PathStr) : CmdFileNodePtr;
  {-Return pointer to node if found, nil otherwise}

implementation

procedure InitCmdFileList(var CFL : CmdFileList);
  {-Initialize a CmdFileList}
begin
  CFL.Head := nil;
  CFL.Tail := nil;
  CFL.Count := 0;
end;

procedure DoneCmdFileList(var CFL : CmdFileList);
  {-Dispose of a CmdFileList}
var
  P, NP : CmdFileNodePtr;
begin
  with CFL do begin
    P := Head;
    while (P <> nil) do begin
      NP := P^.Next;
      FreeMemCheck(P, SizeOf(P^));
      P := NP;
    end;
    Head := nil;
    Tail := nil;
  end;
end;

function AddCmdFileNode(var CFL : CmdFileList; var CFN : CmdFileNode) : Boolean;
  {-Add CFN to a list of command file nodes. maintain sorted order}
var
  P, PP, NP : CmdFileNodePtr;
begin
  AddCmdFileNode := True;

  CFN.Next := nil;
  if not GetMemCheck(NP, SizeOf(NP^)) then
    AddCmdFileNode := False
  else begin
    NP^ := CFN;
    PP := nil;
    P := CFL.Head;

    {find location for the new node}
    while (P <> nil) and (P^.Scheduled < NP^.Scheduled) do begin
      PP := P;
      P := P^.Next;
    end;

    if CFL.Head = nil then begin
      {first node}
      CFL.Head := NP;
      CFL.Tail := NP;
    end else if PP = nil then begin
      {insert as new head of list}
      NP^.Next := CFL.Head;
      CFL.Head := NP;
    end else if P = nil then begin
      {insert as new tail of list}
      PP^.Next := NP;
      NP^.Next := nil;
      CFL.Tail := NP;
    end else begin
      {insert somewhere in the middle of the list}
      NP^.Next := PP^.Next;
      PP^.Next := NP;
    end;
    Inc(CFL.Count);
  end;
end;

function FindCmdFileNode(var CFL : CmdFileList; FN : PathStr) : CmdFileNodePtr;
  {-Return pointer to node if found, nil otherwise}
var
  NP : CmdFileNodePtr;
begin
  with CFL do begin
    NP := Head;
    while (NP <> nil) and (JustFileName(NP^.CmdFilename) <> JustFileName(FN)) do
      NP := NP^.Next;
  end;
  FindCmdFileNode := NP
end;

procedure DeleteCmdFileNode(var CFL : CmdFileList; var NP : CmdFileNodePtr);
  {-Delete a node from the command file list}
var
  PP, P : CmdFileNodePtr;
begin
  with CFL do begin
    P := Head;
    PP := nil;
    while (P <> nil) and (P <> NP) do begin
      PP := P;
      P := P^.Next;
    end;
    if P = NP then begin
      {link previous node to next node}
      if PP <> nil then
        PP^.Next := NP^.Next
      else
        Head := NP^.Next;
      FreeMemCheck(NP, SizeOf(NP^));
    end;
  end;
  Dec(CFL.Count);
end;

procedure SortCmdFileList(var CFL : CmdFileList);
  {-Sorts CFL in ascending order by date/time field}
var
  CurHead     : CmdFileNodePtr;
  NP          : CmdFileNodePtr;
  Lowest      : CmdFileNodePtr;
  LowDateTime : LongInt;
  Temp        : CmdFileNode;
begin
  if CFL.Count < 2 then
    Exit;

  CurHead := CFL.Head;

  {Loop until all items in place}
  repeat
    Lowest := nil;
    LowDateTime := MaxLongInt;

    {Find the (next) lowest datetime}
    NP := CurHead;
    repeat
      if (NP^.Scheduled < LowDateTime) then begin
        LowDateTime := NP^.Scheduled;
        Lowest := NP;
      end;
      NP := NP^.Next;
    until NP = nil;

    {move the the node data, ommiting the next pointer}
    Move(CurHead^, Temp, SizeOf(CmdFileNode)-SizeOf(Pointer));
    Move(Lowest^, CurHead^, SizeOf(CmdFileNode)-SizeOf(Pointer));
    Move(Temp, Lowest^, SizeOf(CmdFileNode)-SizeOf(Pointer));

    {Move up CurHead}
    CurHead := CurHead^.Next;
  until CurHead = nil;
end;


end.
