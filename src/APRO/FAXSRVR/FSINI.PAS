{$R-,S-,F-,I-,V-,B-,A+}

{******************************************************}
{*                  FSINI.PAS  2.03                   *}
{*      Copyright (c) TurboPower Software 1994.       *}
{*                All rights reserved.                *}
{******************************************************}

{$I APDEFINE.INC}

unit FsIni;
  {-unit for managing INI files}

interface

uses
  Dos,
  {$IFDEF UseOPRO}
  OpString,
  {$ENDIF}
  {$IFDEF UseTPRO}
  TpString,
  {$ENDIF}
  {$IFDEF UsePModeDLL}                                                 {!!.02}
  ApComD,                                                              {!!.02}
  ApFaxD;                                                              {!!.02}
  {$ELSE}                                                              {!!.02}
  ApMisc;                                                              {!!.02}
  {$ENDIF}                                                             {!!.02}

type
  DoubleNodePtr = ^DoubleListNode;
  DoubleListNode = object
    dlNext : DoubleNodePtr;
    dlPrev : DoubleNodePtr;
    constructor Init;
      {-Initialize a doubly linked list node}
    destructor Done; virtual;
      {-Destroy list}
  end;

  DoubleListPtr = ^DoubleList;
  DoubleList = object
    dlHead : DoubleNodePtr;     {Start of list}
    dlTail : DoubleNodePtr;     {End of list}
    dlCount: LongInt;           {Size of list}

    constructor Init;
      {-Initialize an empty list of items}
    destructor Done; virtual;
      {-Destroy list}
    procedure Clear;
      {-Remove all items from list}
    procedure Append(P : DoubleNodePtr);
      {-Add element to end of list}
    procedure Insert(P : DoubleNodePtr);
      {-Insert element at start of list}
    procedure Place(P, L : DoubleNodePtr);
      {-Place element P into list _after_ existing element L}
    procedure Delete(P : DoubleNodePtr);
      {-Delete existing element in list, disposing of its contents}
    function Head : DoubleNodePtr;
      {-Return pointer to head of list}
    function Tail : DoubleNodePtr;
      {-Return pointer to tail of list}
    function Next(P : DoubleNodePtr) : DoubleNodePtr; virtual;
      {-Returns a pointer to the next node}
  end;

  PStr = ^string;
  PLine = ^TLine;
  TLine = object(DoubleListNode)
    PL : PStr;
    constructor Init(S : String);
    destructor Done; virtual;
    function Update(S : string) : Boolean;
  end;

  PIni = ^TIni;
  TIni = object(DoubleList)
    IniName   : PathStr;

    constructor Init(FN : String; Sparse : Boolean);
      {-Construct our INI file object.  if Sparse=True, load only "active"
        lines (file is considered read-only.)  if Sparse=False, File always
        updates on changes; use SetFlushMode to control.}
    destructor Done; virtual;
      {-Destroy object when done}
    procedure FlushFile;
      {-Force an update of the physical file from the current list}
    procedure SetFlushMode(Always : Boolean);
      {-Turn off/on auto-updating of file when an item is modified}
    function GetProfileString(Title, Group, Default : String) : String;
      {-Return string item "Title" in "[Group]", or default if not found}
    function GetProfileBool(Title, Group : String; Default : Boolean) : Boolean;
      {-Return boolean item "Title" in "[Group]", or default if not found}
    function GetProfileByte(Title, Group : String; Default : Byte) : Byte;
      {-Return byte item "Title" in "[Group]", or default if not found}
    function GetProfileInt(Title, Group : String; Default : Integer) : Integer;
      {-Return integer item "Title" in "[Group]", or default if not found}
    function GetProfileWord(Title, Group : String; Default : Word) : Word;
      {-Return word item "Title" in "[Group]", or default if not found}
    function GetProfileLong(Title, Group : String; Default : LongInt) : LongInt;
      {-Return longint item "Title" in "[Group]", or default if not found}
    function SetProfileString(Title, Group, NewVal : String) : Boolean;
      {-Change existing item "Title" in "[Group]" to "NewVal"}
    function AddProfileString(Title, Group, NewVal : String) : Boolean;
      {-Add new item "Title=NewVal" to "[Group]".  Creates [Group] if not
        found, else adds "Title=NewVal" as last item in [Group]}
    function EnumGroups(P : DoubleListPtr) : Boolean;
      {-Return P loaded with the names of all groups in the file.  Returns
        false only on error.  Items on P are of type PLine.}
    function EnumGroupItems(P : DoubleListPtr; Group : String) : Boolean;
      {-Return P loaded with all items in group [Group].  Returns false
        if Group not found or error.  Items on P are of type PLine.}

  private  {these used internally only}
    IniF      : Text;
    NeedUpd   : Boolean;
    AlwaysUpd : Boolean;
    IsSparse  : Boolean;

    function GetIniNode(Title, Group : String) : PLine;
    function GetLastNodeInGroup(Group : String) : PLine;
    function GetProfilePrim(Title, Group : String) : String;
  end;


implementation

{*** General ***}

{!! move to apmisc}
function Str2Long(S : String; var L : LongInt) : Boolean;
  {-Return value of S as a longint}
var
  Code : Integer;
begin
  Val(S, L, Code);
  Str2Long := Code = 0;
end;

{!! move to apmisc}
function Trim(S : string) : string;
  {-Return a string with leading and trailing white space removed}
var
  I : Word;
  SLen : Byte absolute S;
begin
  while (SLen > 0) and (S[SLen] <= ' ') do
    Dec(SLen);
  I := 1;
  while (I <= SLen) and (S[I] <= ' ') do
    Inc(I);
  Dec(I);
  if I > 0 then
    System.Delete(S, 1, I);
  Trim := S;
end;

{*** DoubleListNode ***}

constructor DoubleListNode.Init;
  {-Called when node is created}
begin
  dlNext := nil;
  dlPrev := nil;
end;

destructor DoubleListNode.Done;
  {-Called when node is destroyed}
begin
end;

{*** DoubleList ***}

constructor DoubleList.Init;
  {-Initialize an empty list}
begin
  dlHead  := nil;
  dlTail  := nil;
  dlCount := 0;
end;

destructor DoubleList.Done;
  {-Destroy a list}
begin
  Clear;
end;

procedure DoubleList.Clear;
  {-Destroy a list}
type
  OS = record
    O, S : Word;
  end;
var
  N : DoubleNodePtr;
  P : DoubleNodePtr;
begin
  N := dlTail;
  while N <> nil do begin
    {Get DoubleNodePtr to previous node}
    P := N^.dlPrev;
{$IFDEF Dpmi}
    Dispose(N, Done);
{$ELSE}
    if OS(N).S >= OS(HeapOrg).S then
      {Deallocate and destroy this node}
      Dispose(N, Done)
    else
      {Just destroy it since it's not a heap variable}
      N^.Done;
    {Do the previous node}
{$ENDIF}
    N := P;
  end;
  dlTail  := nil;
  dlHead  := nil;
  dlCount := 0;
end;

procedure DoubleList.Append(P : DoubleNodePtr);
  {-Add element to end of list}
begin
  {Exit for bad input}
  if P = nil then Exit;

  P^.dlPrev := dlTail;
  P^.dlNext := nil;
  if dlHead = nil then begin
    {Special case for first node}
    dlHead := P;
    dlTail := P;
  end else begin
    {Add at end of existing list}
    dlTail^.dlNext := P;
    dlTail := P;
  end;
  Inc(dlCount);
end;

procedure DoubleList.Insert(P : DoubleNodePtr);
  {-Insert element at start of list}
begin
  {Exit for bad input}
  if P = nil then Exit;

  P^.dlPrev := nil;
  P^.dlNext := dlHead;
  if dlHead = nil then
    {Special case for first node}
    dlTail := P
  else
    {Add at start of existing list}
    dlHead^.dlPrev := P;
  dlHead := P;
  Inc(dlCount);
end;

procedure DoubleList.Place(P : DoubleNodePtr; L : DoubleNodePtr);
  {-Place element P into list _after_ existing element L}
begin
  {Exit for bad input}
  if (P = nil) or (P = L) then Exit;

  if L = nil then
    Insert(P)
  else if L = dlTail then
    Append(P)
  else begin
    P^.dlPrev := L;
    P^.dlNext := L^.dlNext;
    L^.dlNext^.dlPrev := P;
    L^.dlNext := P;
    Inc(dlCount);
  end;
end;

procedure DoubleList.Delete(P : DoubleNodePtr);
  {-Delete existing node from list, optionally disposing of it}
var
  This : DoubleNodePtr;
begin
  {Exit for bad input}
  if (P = nil) or (dlCount = 0) then Exit;

  This := P;
  with This^ do begin
    {Fix pointers of surrounding nodes}
    if dlNext <> nil then
      dlNext^.dlPrev := dlPrev;
    if dlPrev <> nil then
      dlPrev^.dlNext := dlNext;
  end;

  {Fix head and tail of list}
  if dlTail = This then
    dlTail := dlTail^.dlPrev;
  if dlHead = This then
    dlHead := dlHead^.dlNext;

  Dec(dlCount);

  {Dispose of the node}
  Dispose(This, Done);
end;

function DoubleList.Head : DoubleNodePtr;
  {-Return DoubleNodePtr to head of list}
begin
  Head := dlHead;
end;

function DoubleList.Tail : DoubleNodePtr;
  {-Return DoubleNodePtr to tail of list}
begin
  Tail := dlTail;
end;

function DoubleList.Next(P : DoubleNodePtr) : DoubleNodePtr;
  {-Returns a DoubleNodePtr to the next node}
begin
  Next := P^.dlNext;
end;

{*** TLine ***}

constructor TLine.Init(S : String);
begin
  if not DoubleListNode.Init then
    Fail;
  PL := PStr(StringToHeap(S));
  if PL = nil then
    Fail;
end;

destructor TLine.Done;
begin
  if PL <> nil then
    DisposeString(Pointer(PL));
  DoubleListNode.Done;
end;

function TLine.Update(S : String) : Boolean;
var
  L : PStr;
begin
  Update := False;
  L := PStr(StringToHeap(S));
  if L = nil then Exit;

  DisposeString(Pointer(PL));
  PL := L;
  Update := True;
end;

{*** TIni ***}

constructor TIni.Init(FN : String; Sparse : Boolean);
var
  P : PLine;
  S : String;
begin
  if not DoubleList.Init then
    Fail;

  NeedUpd := False;
  AlwaysUpd := True;
  IsSparse := Sparse;

  IniName := DefaultExtension(FN, 'INI');
  Assign(IniF, IniName);
  Reset(IniF);
  if IOResult <> 0 then begin
    {file doesn't yet exist; drop out}
    NeedUpd := True;
    Exit;
  end;

  while not EOF(IniF) do begin
    ReadLn(IniF, S);
    if IOResult <> 0 then begin
      Close(IniF);  if IOresult = 0 then ;
      Done;
      Fail;
    end;

    S := Trim(S);
    if (not(Sparse)) or ((S <> '') and (S[1] <> ';')) then begin
      New(P, Init(S));
      if P = nil then begin
        {out of memory}
        Close(IniF);
        if IOResult = 0 then ;
        Done;
        Fail;
      end;
      Append(P);
    end;
  end;
  Close(IniF);
  if IOResult = 0 then ;
end;

destructor TIni.Done;
begin
  if NeedUpd then
    FlushFile;
  DoubleList.Done;
end;

procedure TIni.SetFlushMode(Always : Boolean);
begin
  AlwaysUpd := Always;
end;

procedure TIni.FlushFile;
var
  S : String;
  P : PLine;
begin
  if IsSparse then
    Exit;

  Assign(IniF, IniName);
  Rewrite(IniF);
  if IOResult <> 0 then
    Exit;

  P := PLine(Head);
  while P <> nil do begin
    WriteLn(IniF, P^.PL^);
    if IOResult <> 0 then begin
      Close(IniF);
      if IOResult = 0 then ;
      exit;
    end;
    P := PLine(Next(P));
  end;

  Close(IniF);
  if IOResult = 0 then ;
  NeedUpd := False;
end;

function TIni.GetIniNode(Title, Group : String) : PLine;
var
  P : PLine;
  S : String;
  GroupSeen : Boolean;
begin
  GetIniNode := nil;
  if dlCount = 0 then exit;

  {fixup strings as needed}
  if Group[1] <> '[' then
    Group := '['+Group+']';
  Group := StUpcase(Group);
  Title := StUpcase(Title);

  {search}
  GroupSeen := False;
  P := PLine(Head);
  while P <> nil do begin
    if P^.PL^[1] = '[' then begin
      {a group header...}
      if StUpcase(P^.PL^) = Group then
        {in our group}
        GroupSeen := True
      else if GroupSeen then
        {exhausted all options in our group; get out}
        exit;
    end else if (GroupSeen) and (P^.PL^[1] <> ';') then begin
      {in our group, see if the title matches}
      S := Copy(P^.PL^, 1, Pos('=', P^.PL^)-1);
      S := Trim(S);
      S := StUpcase(S);
      if Title = S then begin
        GetIniNode := P;
        Exit;
      end;
    end;
    P := PLine(Next(P));
  end;
end;

function TIni.GetLastNodeInGroup(Group : String) : PLine;
var
  P,Q : PLine;
  S : String;
  GroupSeen : Boolean;
begin
  GetLastNodeInGroup := nil;
  if dlCount = 0 then exit;

  {fixup strings as needed}
  if Group[1] <> '[' then
    Group := '['+Group+']';
  Group := StUpcase(Group);

  {search}
  GroupSeen := False;
  Q := nil;
  P := PLine(Head);
  while P <> nil do begin
    if P^.PL^[1] = '[' then begin
      {a group header...}
      if StUpcase(P^.PL^) = Group then
        {in our group}
        GroupSeen := True
      else if (GroupSeen) then begin
        {exhausted all lines in our group, return the last pointer}
        if Q = nil then
          Q := PLine(P^.dlPrev);
        GetLastNodeInGroup := Q;
        exit;
      end;
    end;
    Q := P;
    P := PLine(Next(P));
  end;
  if GroupSeen then
    GetLastNodeInGroup := Q
  else
    GetLastNodeInGroup := nil;
end;

function TIni.GetProfilePrim(Title, Group : String) : String;
var
  P : PLine;
  S : String;
begin
  P := GetIniNode(Title, Group);
  if P = nil then
    GetProfilePrim := ''
  else begin
    S := P^.PL^;
    S := Copy(S, Pos('=', S)+1, 255);
    S := Trim(S);
    GetProfilePrim := S;
  end;
end;

function TIni.GetProfileString(Title, Group, Default : String) : String;
var
 S : String;
begin
  S := GetProfilePrim(Title, Group);
  if S = '' then
    S := Default;
  GetProfileString := S;
end;

function TIni.GetProfileBool(Title, Group : String; Default : Boolean) : Boolean;
var
  S : String;
begin
  S := GetProfilePrim(Title, Group);
  if S <> '' then begin
    S := StUpcase(S);
    if (S = 'TRUE') or (S = '1') or (S = 'YES') then
      GetProfileBool := True
    else if (S = 'FALSE') or (S = '0') or (S = 'NO') then
      GetProfileBool := False
    else
      GetProfileBool := Default;
  end else
    GetProfileBool := Default;
end;

function TIni.GetProfileByte(Title, Group : String; Default : Byte) : Byte;
var
  S : String;
  I : LongInt;
begin
  S := GetProfilePrim(Title, Group);
  if S <> '' then begin
    if Str2Long(S, I) then
      GetProfileByte := Byte(I)
    else
      GetProfileByte := Default;
  end else
    GetProfileByte := Default;
end;

function TIni.GetProfileInt(Title, Group : String; Default : Integer) : Integer;
var
  S : String;
  I : LongInt;
begin
  S := GetProfilePrim(Title, Group);
  if S <> '' then begin
    if Str2Long(S, I) then
      GetProfileInt := Integer(I)
    else
      GetProfileInt := Default;
  end else
    GetProfileInt := Default;
end;

function TIni.GetProfileWord(Title, Group : String; Default : Word) : Word;
var
  S : String;
  I : LongInt;
begin
  S := GetProfilePrim(Title, Group);
  if S <> '' then begin
    if Str2Long(S, I) then
      GetProfileWord := Word(I)
    else
      GetProfileWord := Default;
  end else
    GetProfileWord := Default;
end;

function TIni.GetProfileLong(Title, Group : String; Default : LongInt) : LongInt;
var
  S : String;
  I : LongInt;
begin
  S := GetProfilePrim(Title, Group);
  if S <> '' then begin
    if Str2Long(S, I) then
      GetProfileLong := I
    else
      GetProfileLong := Default;
  end else
    GetProfileLong := Default;
end;

function TIni.SetProfileString(Title, Group, NewVal : String) : Boolean;
var
  S : String;
  P : PLine;
begin
  SetProfileString := False;
  if IsSparse then Exit;

  P := GetIniNode(Title, Group);
  if P = nil then
    Exit
  else begin
    S := P^.PL^;
    System.Delete(S, Pos('=', S)+1, 255);
    S := S + NewVal;
    if P^.Update(S) then begin
      SetProfileString := True;
      if AlwaysUpd then
        FlushFile
      else
        NeedUpd := True;
    end;
  end;
end;

function TIni.AddProfileString(Title, Group, NewVal : String) : Boolean;
var
  P,Q : PLine;
begin
  AddProfileString := False;
  if IsSparse then Exit;

  {fixup strings as needed}
  if Group[1] <> '[' then
    Group := '['+Group+']';
  Group := StUpcase(Group);

  P := GetLastNodeInGroup(Group);
  if P = nil then begin
    {group not found, create a new one}
    New(Q, Init(Group));
    if Q = nil then Exit;
    Append(Q);
    P := Q;
  end;
  {add our new element after}
  New(Q, Init(Title+'='+NewVal));
  if Q <> nil then begin
    Place(Q, P);
    AddProfileString := True;
    if AlwaysUpd then
      FlushFile
    else
      NeedUpd := True;
  end;
end;

function TIni.EnumGroups(P : DoubleListPtr) : Boolean;
  {-Return P loaded with the names of all groups in the file.  Returns
    false only on error.  Items on P are of type PLine.}
var
  Q, R : PLine;

  function StripBrackets(S : String) : String;
  var
    B : Byte absolute S;
  begin
    S := Trim(S);
    if S[b] = ']' then
      Dec(B);
    if S[1] = '[' then begin
      Move(S[2], S[1], B-1);
      Dec(B);
    end;
    StripBrackets := StUpcase(S);
  end;

begin
  EnumGroups := False;
  Q := PLine(Head);
  while Q <> nil do begin
    if Q^.PL^[1] = '[' then begin
      New(R, Init(StripBrackets(Q^.PL^)));
      if R = nil then
        Exit;
      P^.Append(R);
    end;
    Q := PLine(Q^.dlNext);
  end;
  EnumGroups := True;
end;

function TIni.EnumGroupItems(P : DoubleListPtr; Group : String) : Boolean;
  {-Return P loaded with all items in group [Group].  Returns false
    if Group not found or error.  Items on P are of type PLine.}
var
  Q, R : PLine;
  S : String;
begin
  EnumGroupItems := False;

  {fixup strings as needed}
  if Group[1] <> '[' then
    Group := '['+Group+']';
  Group := StUpcase(Group);

  Q := PLine(Head);
  while Q <> nil do begin
    if StUpcase(Q^.PL^) = Group then begin
      Q := PLine(Q^.dlNext);
      while (Q <> nil) and (Q^.PL^[1] <> '[') do begin
        S := Trim(Q^.PL^);
        if (S <> '') and (S[1] <> ';') then begin
          New(R, Init(S));
          if R = nil then
            Exit
          else
            P^.Append(R);
        end;
        Q := PLine(Q^.dlNext);
      end;
      EnumGroupItems := True;
      Exit;
    end;
    Q := PLine(Q^.dlNext);
  end;
end;

end.
