{$A+,F+,I-,R-,S-,V-}

unit IniTools;  {unit for managing INI files - requires Object Professional}

{***************************************************}
{*               INITOOLS.PAS  1.03                *}
{*     Copyright (c) TurboPower Software 1993      *}
{***************************************************}

(*
  This unit provides an object for creating, maintaining and using Windows-
  format information (INI) files.  This allows programs to maintain a config
  or other program data file in a ASCII text format while treating information
  in the file as an appropriate string, boolean or integer data type.  Items
  are stored in "Title=Value" format, where Title is a unique descriptive name
  for the item, and Value is a string representation of the data.  The equals
  sign is required, and may have spaces on one or both sides.  Similar or
  related items are maintained under "group headers"; all files must have at
  least one group header, in "[GroupName]" format.  The file as used here has
  one restriction that Windows itself does not have: each item must be
  contained in a single line.  Blank lines, and lines beginning with a
  semicolon (;) are considered comments.

  The IniFile object loads the file's contents into a DoubleList for speed
  of access.  If the constructor's boolean parameter "Sparse" is set to True,
  only "active" lines (group headers and item lines) are loaded to conserve
  memory, but the file is then treated as read-only and any attempts to
  change or add items will fail.  If Sparse = False, the entire file is
  loaded; this takes more memory and increases the disk I/O time, but allows
  items to be changed or added. Which mode you use will need to be
  determined by the size of your file, how much memory you want to devote to
  the file and whether modifying or adding items is required in your
  application.

  An example of items in a file:

    [Mouse Support]

    ; controls mouse sensitivity
    MouseXSens=16
    MouseYSens=8

  Items in the file are accessed by group and title, so to access the two
  example items you would use the following code:

  {...}
  var
    MyIni : TIni;
    MXSens : Integer;
    MYSens : Integer;
  {...}
    if MyIni.Init(ForceExtension(ParamStr(0), 'INI'), True) then begin
      MXSens := MyIni.GetProfileInt('MouseXSens', 'Mouse Support', 16);
      MYSens := MyIni.GetProfileInt('MouseYSens', 'Mouse Support', 8);
      MyIni.Done;
    end;
  {...}

  This code instantiates the TIni object in Sparse mode, using a filename of
  the program's name with an extension of INI.  It then looks for the
  MouseXSens item in group Mouse Support, returning the item's value if found,
  otherwise returning the default value provided as the third parameter.  Note
  that while the two string parameters are not case sensitive, and the Group
  name may or may not have the surrounding brackets, they must both exactly
  match the group and item name in all other respects.

  Methods are provided for returning vars of type String, Boolean, Byte,
  Integer, Word and LongInt.  String types do not need to be quoted;
  everything after the separating "=" is returned.  Boolean type items can be
  "True/False", "Yes/No", "On/Off" or "1/0".  Methods to modify an existing
  item or add a new item, in string format, are also provided.  If sparse mode
  is enabled, these two methods will return False immediately.  The FlushFile
  method will also abort immediately if sparse mode is on.

  By default, any time you modify or add an item, the physical file is updated
  to reflect the change.  This behavior may not be desired in all cases, such
  as when you update multiple entries in one block of code, so a method is
  provided (SetFlushMode) to allow you to en/disable the updates as needed.
  When updates are made with flushing turned off, an internal flag is set so
  that the file will be flushed when the object is disposed, or you can
  manually call the FlushFile method to update the physical file as you wish.

  While it is not used often, the ability to scan in all items in a given
  group at one time is occasionally very handy - for example, it allows you
  to have a list of group titles in the .INI file, from which you can choose
  a specific configuration set group.  Similarly, being able to enumerate
  all of the group names in a file is occasionally needed.  In V1.02 I have
  added two new methods that provide these capabilities.  Each takes as a
  parameter a pointer to a DoubleList object, which must be instantiated.
  The DoubleList may be empty or may contain items; the new items are
  appended to the end of the list.  The EnumGroups method takes only the
  pointer parameter and returns the list loaded with the names of all
  groups in the file (stripped of their surrounding brackets).  The
  EnumGroupItems method takes an additional string parameter of the name of
  the group to find, and returns the complete string of each item in the
  group ("title=value" rather than the usual "value" only.)  In both cases,
  the nodes added to the DoubleList are of type PLine.

  Steve Sneed, TurboPower Software

  --------------------------------

  Rev history:

  1.00 - Original release.

  1.01 - Corrected bug that would cause a GPF when adding a new item to an
         empty list.  Corrected bug that left the "=" sign on extracted
         strings, causing the default value to always be used on numeric
         extractions (the Str2Xxx call would always return False.)

  1.02 - Added EnumGroups and EnumGroupItems methods.  Added missing
         compiler directives to top of file.  Changed handling of Group
         names slightly to eliminate potential problems.

  1.03 - Modified to allow use in Windows programs, by popular demand.
         When compiled for Windows, requires our Win/Sys Library.
*)

{$IFNDEF Ver15}
  {$IFNDEF Ver60}
    {$IFNDEF Ver70}
      !! STOP COMPILE: This unit requires TP6 or later or TPW 1.5 !!
    {$ENDIF}
  {$ENDIF}
{$ENDIF}

interface

uses
  OpString,
{$IFDEF Windows}
  WsList;
{$ELSE}
  OpRoot;
{$ENDIF}

{$IFDEF Windows}
type
  DoubleListPtr = PDoubleList;
  DoubleListNode = DoubleNode;
{$ENDIF}

type
  PStr = ^String;
  PLine = ^TLine;
  TLine =
    object(DoubleListNode)
      PL : PStr;

      constructor Init(S : String);
      destructor Done; virtual;
      function Update(S : String) : Boolean;
    end;

  PIni = ^TIni;
  TIni =
    object(DoubleList)
      IniName   : String;

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
    if L = nil then exit;
    DisposeString(Pointer(PL));
    PL := L;
    Update := True;
  end;

{---------------------------------------------------------------------------}

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
    System.Reset(IniF);
    if IOResult <> 0 then begin
      {file doesn't yet exist; drop out}
      NeedUpd := True;
      Exit;
    end;

    while not EOF(IniF) do begin
      ReadLn(IniF, S);
      if IOResult <> 0 then begin
        {read error here means something is wrong; bomb it}
        Close(IniF);  if IOresult = 0 then ;
        Done;
        Fail;
      end;

      S := Trim(S);
      if (not(Sparse)) or ((S <> '') and (S[1] <> ';')) then begin
        New(P, Init(S));
        if P = nil then begin
          {out of memory, bomb it}
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
    if Size = 0 then exit;

    {fixup strings as needed}
    if Group[1] <> '[' then
      Group := '['+Group+']';                                        {!!.02}
    Group := StUpcase(Group);                                        {!!.02}
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
      end
      else if (GroupSeen) and (P^.PL^[1] <> ';') then begin
        {in our group, see if the title matches}
        S := Copy(P^.PL^, 1, Pos('=', P^.PL^)-1);
        S := Trim(S);
        S := StUpcase(S);
        if Title = S then begin
          GetIniNode := P;
          exit;
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
    if Size = 0 then exit;

    {fixup strings as needed}
    if Group[1] <> '[' then
      Group := '['+Group+']';                                        {!!.02}
    Group := StUpcase(Group);                                        {!!.02}

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
    if GroupSeen then                                                  {!!.01}
      GetLastNodeInGroup := Q                                          {!!.01}
    else                                                               {!!.01}
      GetLastNodeInGroup := nil;                                       {!!.01}
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
      S := Copy(S, Pos('=', S)+1, 255);                                {!!.01}
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
    end
    else
      GetProfileBool := Default;
  end;

  function TIni.GetProfileByte(Title, Group : String; Default : Byte) : Byte;
  var
    S : String;
    I : Integer;
  begin
    S := GetProfilePrim(Title, Group);
    if S <> '' then begin
      if Str2Int(S, I) then
        GetProfileByte := Byte(I)
      else
        GetProfileByte := Default;
    end
    else
      GetProfileByte := Default;
  end;

  function TIni.GetProfileInt(Title, Group : String; Default : Integer) : Integer;
  var
    S : String;
    I : Integer;
  begin
    S := GetProfilePrim(Title, Group);
    if S <> '' then begin
      if Str2Int(S, I) then
        GetProfileInt := I
      else
        GetProfileInt := Default;
    end
    else
      GetProfileInt := Default;
  end;

  function TIni.GetProfileWord(Title, Group : String; Default : Word) : Word;
  var
    S : String;
    I : Word;
  begin
    S := GetProfilePrim(Title, Group);
    if S <> '' then begin
      if Str2Word(S, I) then
        GetProfileWord := I
      else
        GetProfileWord := Default;
    end
    else
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
    end
    else
      GetProfileLong := Default;
  end;

  function TIni.SetProfileString(Title, Group, NewVal : String) : Boolean;
  var
    S : String;
    P : PLine;
  begin
    SetProfileString := False;
    if IsSparse then exit;

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
    {!!.01 - Rewritten to correct GPF when adding a string to an empty list}
  var
    P,Q : PLine;
  begin
    AddProfileString := False;
    if IsSparse then exit;

    {fixup strings as needed}
    if Group[1] <> '[' then
      Group := '['+Group+']';                                        {!!.02}
    Group := StUpcase(Group);                                        {!!.02}

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

  {!!.02 begin new routines}
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

  function TIni.EnumGroups(P : DoubleListPtr) : Boolean;
    {-Return P loaded with the names of all groups in the file.  Returns
      false only on error.  Items on P are of type PLine.}
  var
    Q, R : PLine;
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
