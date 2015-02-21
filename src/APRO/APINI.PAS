{$A+,F+,I-,V-}

{$I APDEFINE.INC}
{$X+}
unit ApIni;
  {unit for managing INI files}

{***************************************************}
{*               APINI.PAS  2.03                   *}
{*     Copyright (c) TurboPower Software 1995      *}
{***************************************************}

(*
    Originally written by Steve Sneed, TurboPower Software
    Modified by Jason Leveille, TurboPower Software
*)

interface

uses
{$IFDEF UseTPro}
  TpString,
  TpMemChk,
{$ENDIF}
{$IFDEF UseOPro}
  OpRoot,
  OpString,
{$ENDIF}
  ApMisc;

{$I APINI.PA0}

implementation
{$IFNDEF UseOPro}
  {$IFNDEF UseTPro}
  function Str2Int(S : String; var I : Integer) : Boolean;
    {-Convert a String to an integer, returning true if successful}
  var
    Code : Word;
    SLen : Byte absolute S;

  begin
    while S[SLen] = ' ' do
      Dec(SLen);
    if (SLen > 1) and (Upcase(S[SLen]) = 'H') then begin
      Move(S[1], S[2], SLen-1);
      S[1] := '$';
    end
    else if (SLen > 2) and (S[1] = '0') and (Upcase(S[2]) = 'X') then begin
      Dec(SLen);
      Move(S[3], S[2], SLen-1);
      S[1] := '$';
    end;
    Val(S, I, code);
    if code <> 0 then begin
      I := code;
      Str2Int := False;
    end else
      Str2Int := True;
  end;

  function Str2Word(S : String; var I : Word) : Boolean;
    {-Convert a String to a word, returning true if successful}
  var
    Code : Word;
    SLen : Byte absolute S;

  begin
    while S[SLen] = ' ' do
      Dec(SLen);
    if (SLen > 1) and (Upcase(S[SLen]) = 'H') then begin
      Move(S[1], S[2], SLen-1);
      S[1] := '$';
    end
    else if (SLen > 2) and (S[1] = '0') and (Upcase(S[2]) = 'X') then begin
      Dec(SLen);
      Move(S[3], S[2], SLen-1);
      S[1] := '$';
    end;
    Val(S, I, code);
    if code <> 0 then begin
      I := code;
      Str2Word := False;
    end else
      Str2Word := True;
  end;

  function Str2Long(S : String; var I : LongInt) : Boolean;
    {-Convert a String to a longint, returning true if successful}
  var
    Code : Word;
    SLen : Byte absolute S;

  begin
    while S[SLen] = ' ' do
      Dec(SLen);
    if (SLen > 1) and (Upcase(S[SLen]) = 'H') then begin
      Move(S[1], S[2], SLen-1);
      S[1] := '$';
    end
    else if (SLen > 2) and (S[1] = '0') and (Upcase(S[2]) = 'X') then begin
      Dec(SLen);
      Move(S[3], S[2], SLen-1);
      S[1] := '$';
    end;
    Val(S, I, code);
    if code <> 0 then begin
      I := code;
      Str2Long := False;
    end else
      Str2Long := True;
  end;

  function Trim(S : String) : String;
    {-Return a String with leading and trailing white space removed}
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
  {$ENDIF}
{$ENDIF}

  procedure InitIniLinePtr(var L : IniLinePtr; S : String);

  begin
    if not GetMemCheck(L, SizeOf(IniLine)) then begin
      SetAsyncStatus(ecOutOfMemory);
      Exit;
    end;

    with L^ do begin
      dlPrev := nil;
      dlNext := nil;
      PL := StrPtr(StringToHeap(S));
      if PL = nil then
        SetAsyncStatus(ecOutofMemory)
    end;
  end;

  procedure DoneIniLinePtr(var L : IniLinePtr);

  begin
    if L^.PL <> nil then
      DisposeString(Pointer(L^.PL));
    FreeMemCheck(L, SizeOf(IniLine));
  end;

  function Update(L : IniLinePtr; S : String) : Boolean;

  var
    P : StrPtr;

  begin
    Update := False;
    P := StrPtr(StringToHeap(S));
    if P = nil then
      Exit;
    DisposeString(Pointer(L^.PL));
    L^.PL := P;
    Update := True;
  end;

  procedure Append(I : IniMgrRecPtr; P : IniLinePtr);
    {-Add P to end of list}

  begin
    with I^ do begin
      if dlHead = nil then begin
        P^.dlNext := nil;
        P^.dlPrev := nil;
        dlHead := P;
        dlTail := P;
      end else begin
        P^.dlNext := nil;
        P^.dlPrev := dlTail;
        dlTail := P;
        P^.dlPrev^.dlNext := P;
      end;
      if P^.dlPrev = dlHead then
        dlHead^.dlNext := P;
    end;
  end;

  procedure Insert(I : IniMgrRecPtr; P : IniLinePtr);
    {-Put P at beginning of list}

  begin
    with I^ do begin
      if dlHead = nil then begin
        P^.dlNext := nil;
        P^.dlPrev := nil;
        dlHead := P;
        dlTail := P;
      end else begin
        P^.dlNext := dlHead;
        P^.dlPrev := nil;
        dlHead := P;
        P^.dlNext^.dlPrev := P;
      end;
      if P^.dlNext = dlTail then
        dlTail^.dlPrev := P;
    end;
  end;

  procedure Delete(I : IniMgrRecPtr; P : IniLinePtr);
    {-Delete P from list}

  var
    TempNode : IniLinePtr;

  begin
    if P = nil then
      Exit;
    {change pointers around node}
      TempNode := P^.dlPrev;
      if TempNode <> nil then
        TempNode^.dlNext := P^.dlNext;
      if P = I^.dlTail then
        I^.dlTail := TempNode;
      TempNode := P^.dlNext;
      if TempNode <> nil then
        TempNode^.dlPrev := P^.dlPrev;
      if P = I^.dlHead then
        I^.dlHead := TempNode;
      {remove the node}
      DoneIniLinePtr(P);
  end;

  procedure Place(I : IniMgrRecPtr; P, ExistNode : IniLinePtr);
    {-Place P after ExistNode}

  var
    TempNode : IniLinePtr;

  begin
    if ExistNode = nil then begin
      Insert(I, P);
      Exit;
    end;
    P^.dlPrev := ExistNode;
    P^.dlNext := ExistNode^.dlNext;
    ExistNode^.dlNext := P;
    TempNode := P^.dlNext;
    if ExistNode = I^.dlTail then
      I^.dlTail := P
    else
      TempNode^.dlPrev := P;
  end;
{---------------------------------------------------------------------------}

  procedure InitIniMgr(var I : IniMgrRecPtr; FN : String; Sparse : Boolean);

  var
    P : IniLinePtr;
    S : String;

  begin
    if not GetMemCheck(I, SizeOf(IniMgrRec)) then begin
      SetAsyncStatus(ecOutOfMemory);
      Exit;
    end;

    with I^ do begin
      dlHead := nil;
      dlTail := nil;
    end;

    with I^ do begin
      NeedUpd := False;
      AlwaysUpd := True;
      IsSparse := Sparse;

      IniName := DefaultExtension(FN, 'INI');
      Assign(IniF, IniName);
      System.Reset(IniF);
      if IOResult <> 0 then begin
      {file doesn't yet exist; drop out}
(*
      NeedUpd := True;
*)
        Exit;
      end;

      while not EOF(IniF) do begin
        ReadLn(IniF, S);
        SetAsyncStatus(IOResult);
        if GetAsyncStatus <> ecOK then begin
          {read error here means something is wrong; bomb it}
          Close(IniF);  if IOresult = 0 then ;
          DoneIniMgr(I);
          Exit;
        end;

        S := Trim(S);
        if (not(Sparse)) or ((S <> '') and (S[1] <> ';')) then begin
          InitIniLinePtr(P, S);
          if P = nil then begin
          {out of memory, bomb it}
            Close(IniF);
            if IOResult = 0 then ;
            SetAsyncStatus(ecOutOfMemory);
            DoneIniMgr(I);
            Exit;
          end;
          Append(I, P);
        end;
      end;
      Close(IniF);
      if IOResult = 0 then ;
    end;
  end;

  procedure DoneIniMgr(I : IniMgrRecPtr);

  var
    TempNode1, TempNode2 : IniLinePtr;

  begin
    with I^ do begin
      TempNode1 := dlHead;
      TempNode2 := dlHead;
    end;
    while TempNode2 <> nil do begin
      TempNode1 := TempNode2;
      TempNode2 := TempNode1^.dlNext;
      DoneIniLinePtr(TempNode1);
    end;
    FreeMemCheck(I, SizeOf(IniMgrRec));
  end;

  procedure SetFlushMode(I : IniMgrRecPtr; Always : Boolean);
    {-Turn off/on auto-updating of file when an item is modified}
  begin
    I^.AlwaysUpd := Always;
  end;

  procedure ChangeFileName(I : IniMgrRecPtr; NewIniName : String);
    {-Associates database now with file NewIniName}

  begin
    I^.IniName := DefaultExtension(NewIniName, 'INI');
    I^.NeedUpd := True;
  end;

  function GetFileName(I : IniMgrRecPtr) : String;

  begin
    GetFileName := I^.IniName;
  end;

  procedure ForceUpd(I : IniMgrRecPtr);

  begin
    I^.NeedUpd := True;
    FlushFile(I);
  end;

  procedure FlushFile(I : IniMgrRecPtr);
    {-Force an update of the physical file from the current list}
  var
    P : IniLinePtr;
    S : String;

  begin
    with I^ do begin
      if IsSparse then
        Exit;
      if AlwaysUpd or NeedUpd then begin
        Assign(IniF, IniName);
        Rewrite(IniF);
        SetAsyncStatus(IOResult);
        if GetAsyncStatus <> ecOK then
          Exit;
        P := IniLinePtr(dlHead);
        while P <> nil do begin
          if P^.PL^ <> '' then
            if (P^.PL^[1] = '[') and (P <> IniLinePtr(dlHead)) then
              WriteLn(IniF);
          if (P^.PL^ <> '') then
            WriteLn(IniF, P^.PL^);
          SetAsyncStatus(IOResult);
          if GetAsyncStatus <> ecOK then begin
            Close(IniF);
            if IOResult = 0 then ;
            Exit;
          end;
          P := IniLinePtr(P^.dlNext);
        end;

        Close(IniF);
        if IOResult = 0 then ;
        NeedUpd := False;
      end;
    end;
  end;

  function GetIniNode(I : IniMgrRecPtr; Title, Group : String) : IniLinePtr;
    {-Returns the IniLinePtr pointing to the item "Title" in "[Group]"}
  var
    P : IniLinePtr;
    GroupSeen : Boolean;
    S : String;


  begin
    GetIniNode := nil;
    SetAsyncStatus(ecRecordNotFound);
    if I^.dlHead = nil then begin
      SetAsyncStatus(ecDatabaseEmpty);
      Exit;
    end;

    {fixup Strings as needed}
    if Group[1] <> '[' then
      Group := '['+Group+']';
    Group := StUpcase(Group);
    Title := StUpcase(Title);

    {search}
    GroupSeen := False;
    P := IniLinePtr(I^.dlHead);
    while P <> nil do begin
      if (P^.PL^ <> '') and (P^.PL^[1] = '[') then begin
        {a group header...}
        if StUpcase(P^.PL^) = Group then
          {in our group}
          GroupSeen := True
        else if GroupSeen then
          {exhausted all options in our group; get out}
          Exit;
      end
      else if (GroupSeen) and (P^.PL^ <> '') and (P^.PL^[1] <> ';') then begin
        {in our group, see if the title matches}
        S := Copy(P^.PL^, 1, Pos('=', P^.PL^)-1);
        S := Trim(S);
        S := StUpcase(S);
        if Title = S then begin
          GetIniNode := P;
          SetAsyncStatus(ecOK);
          Exit;
        end;
      end;
      P := IniLinePtr(P^.dlNext);
    end;
  end;

  function GetIniGroupNode(I : IniMgrRecPtr; Group : String) : IniLinePtr;
    {-Returns the IniLinePtr pointing to "[Group]"}
  var
    P : IniLinePtr;
    S : String;

  begin
    GetIniGroupNode := nil;
    SetAsyncStatus(ecGroupNotFound);
    if I^.dlHead = nil then begin
      SetAsyncStatus(ecDatabaseEmpty);
      Exit;
    end;

    {fixup Strings as needed}
    if Group[1] <> '[' then
      Group := '['+Group+']';
    Group := StUpcase(Group);

    {search}
    P := IniLinePtr(I^.dlHead);
    while P <> nil do begin
      if (P^.PL^[1] = '[') and (StUpcase(P^.PL^) = Group) then begin
        GetIniGroupNode := P;
        SetAsyncStatus(ecOK);
      end;
      P := IniLinePtr(P^.dlNext);
    end;
  end;

  function GetLastNodeInGroup(I : IniMgrRecPtr; Group : String) : IniLinePtr;
    {-Returns the last node in group "[Group]"}
  var
    P, Q : IniLinePtr;
    GroupSeen : Boolean;
    S : String;

  begin
    GetLastNodeInGroup := nil;
    SetAsyncStatus(ecGroupNotFound);
    if I^.dlHead = nil then begin
      SetAsyncStatus(ecDatabaseEmpty);
      Exit;
    end;

    {fixup Strings as needed}
    if Group[1] <> '[' then
      Group := '['+Group+']';
    Group := StUpcase(Group);

    {search}
    GroupSeen := False;
    Q := nil;
    P := IniLinePtr(I^.dlHead);
    while P <> nil do begin
      if P^.PL^[1] = '[' then begin
        {a group header...}
        if StUpcase(P^.PL^) = Group then
          {in our group}
          GroupSeen := True
        else if (GroupSeen) then begin
          {exhausted all lines in our group, return the last pointer}
          if Q = nil then
            Q := IniLinePtr(P^.dlPrev);
          GetLastNodeInGroup := Q;
          SetAsyncStatus(ecOK);
          Exit;
        end;
      end;
      Q := P;
      P := IniLinePtr(P^.dlNext);
    end;
    if GroupSeen then
      GetLastNodeInGroup := Q
    else
      GetLastNodeInGroup := nil;
  end;

  function GetProfilePrim(I : IniMgrRecPtr; Title, Group : String) : String;
    {-Returns the item "Title" in group "[Group]" with all spaces removed.}
  var
    P : IniLinePtr;
    S : String;

  begin
    P := GetIniNode(I, Title, Group);
    if P = nil then
      GetProfilePrim := ''
    else begin
      S := P^.PL^;
      S := Copy(S, Pos('=', S)+1, 255);
      S := Trim(S);
      GetProfilePrim := S;
    end;
  end;

  function GetProfileString(I : IniMgrRecPtr; Title, Group, Default : String) : String;
    {-Returns String item "Title" in "[Group]", or default if not found}
  var
    S : String;

  begin
    S := GetProfilePrim(I, Title, Group);
    if S = '' then
      S := Default;
    GetProfileString := S;
  end;

  function GetProfileBool(I : IniMgrRecPtr; Title, Group : String; Default : Boolean) : Boolean;
    {-Returns boolean item "Title" in "[Group]", or default if not found}
  var
    S : String;

  begin
    S := GetProfilePrim(I, Title, Group);
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

  function GetProfileByte(I : IniMgrRecPtr; Title, Group : String; Default : Byte) : Byte;
    {-Returns byte item "Title" in "[Group]", or default if not found}
  var
    J : Integer;
    S : String;

  begin
    S := GetProfilePrim(I, Title, Group);
    if S <> '' then begin
      if Str2Int(S, J) then
        GetProfileByte := Byte(J)
      else
        GetProfileByte := Default;
    end
    else
      GetProfileByte := Default;
  end;

  function GetProfileInt(I : IniMgrRecPtr; Title, Group : String; Default : Integer) : Integer;
    {-Returns integer item "Title" in "[Group]", or default if not found}
  var
    J : Integer;
    S : String;

  begin
    S := GetProfilePrim(I, Title, Group);
    if S <> '' then begin
      if Str2Int(S, J) then
        GetProfileInt := J
      else
        GetProfileInt := Default;
    end
    else
      GetProfileInt := Default;
  end;

  function GetProfileWord(I : IniMgrRecPtr; Title, Group : String; Default : Word) : Word;
    {-Returns word item "Title" in "[Group]", or default if not found}
  var
    J : Word;
    S : String;

  begin
    S := GetProfilePrim(I, Title, Group);
    if S <> '' then begin
      if Str2Word(S, J) then
        GetProfileWord := J
      else
        GetProfileWord := Default;
    end
    else
      GetProfileWord := Default;
  end;

  function GetProfileLong(I : IniMgrRecPtr; Title, Group : String; Default : LongInt) : LongInt;
    {-Returns longint item "Title" in "[Group]", or default if not found}
  var
    J : LongInt;
    S : String;

  begin
    S := GetProfilePrim(I, Title, Group);
    if S <> '' then begin
      if Str2Long(S, J) then
        GetProfileLong := J
      else
        GetProfileLong := Default;
    end
    else
      GetProfileLong := Default;
  end;

  procedure DeleteProfileString(I : IniMgrRecPtr; Title, Group : String);
    {-Deletes item "Title" in group "[Group]" from list}
  var
    P : IniLinePtr;

  begin
    P := GetIniNode(I, Title, Group);
    if P = nil then
      SetAsyncStatus(ecRecordNotFound)
    else
      Delete(I, P);
  end;

  procedure DeleteProfileGroup(I : IniMgrRecPtr; Group: String);
    {-Deletes all items under group "[Group]"}
  var
    P, NextOne : IniLinePtr;

  begin
    SetAsyncStatus(ecOK);
    P := GetIniGroupNode(I, Group);
    if P <> nil then begin
      repeat
        NextOne := IniLinePtr(P^.dlNext);
        Delete(I, P);
        P := NextOne;
      until (P = nil) or (P^.PL^[1] = '[');
      if I^.AlwaysUpd then
        FlushFile(I)
      else
        I^.NeedUpd := True;
    end else
      SetAsyncStatus(ecGroupNotFound);
  end;

  function Modified(I : IniMgrRecPtr) : Boolean;

  begin
    Modified := I^.NeedUpd;
  end;

  procedure SetProfileString(I : IniMgrRecPtr; Title, Group, NewVal : String);
    {-Change existing item "Title" in "[Group]" to "NewVal"}
  var
    P : IniLinePtr;
    S : String;

  begin
    SetAsyncStatus(ecOK);
    if I^.IsSparse then exit;

    P := GetIniNode(I, Title, Group);
    if P = nil then
      AddProfileString(I, Title, Group, NewVal)
    else begin
      S := P^.PL^;
      Dec(S[0], Length(S) - Pos('=',S));
      S := S + NewVal;
      if Update(P, S) then begin
        SetAsyncStatus(ecOK);
        if I^.AlwaysUpd then
          FlushFile(I)
        else
          I^.NeedUpd := True;
      end else
        SetAsyncStatus(ecOutOfMemory);
    end;
  end;

  procedure AddProfileString(I : IniMgrRecPtr; Title, Group, NewVal : String);
    {-Add new item "Title=NewVal" to "[Group]".}
  var
    P,Q : IniLinePtr;

  begin
    SetAsyncStatus(ecOK);
    if I^.IsSparse then
      Exit;

    {make sure record doesn't already exist}
    GetIniNode(I, Title, Group);
    if (GetAsyncStatus <> ecRecordNotFound) and (GetAsyncStatus <> ecDataBaseEmpty)
      then begin
        SetAsyncStatus(ecRecordExists);
        Exit;
      end;

    {fixup Strings as needed}
    if Group[1] <> '[' then
      Group := '['+Group+']';
    Group := StUpcase(Group);

    P := GetLastNodeInGroup(I, Group);
    if P = nil then begin
      {group not found, create a new one}
      InitIniLinePtr(Q, Group);
      if Q = nil then begin
        SetAsyncStatus(ecOutOfMemory);
        Exit;
      end;
      Append(I, Q);
      P := Q;
    end;
    {add our new element after}
    InitIniLinePtr(Q, Title+'='+NewVal);
    if Q <> nil then begin
      Place(I, Q, P);
      SetAsyncStatus(ecOK);
      if I^.AlwaysUpd then
        FlushFile(I)
      else
        I^.NeedUpd := True;
    end else
      SetAsyncStatus(ecOutOfMemory);
  end;

  function StripBrackets(S : String) : String;
    {-Returns a String without brackets and in all upper case letters.}
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

  procedure EnumGroups(I : IniMgrRecPtr; var P : IniLinePtr);
    {-Returns P loaded with the names of all groups in the file.}
  var
    Prev, Q, R : IniLinePtr;

  begin
    Q := IniLinePtr(I^.dlHead);
    R := nil;
    if P = nil then begin
      InitIniLinePtr(P, '');
      if P = nil then begin
        SetAsyncStatus(ecOutOfMemory);
        Exit;
      end;
    end else
      P^.PL^ := '';
    while Q <> nil do begin
      if Q^.PL^[1] = '[' then begin
        if R <> nil then
          Prev := R;
        InitIniLinePtr(R, StripBrackets(Q^.PL^));
        if R = nil then begin
          Writeln('here');
          SetAsyncStatus(ecOutOfMemory);
          Exit;
        end;
        if P^.PL^ = '' then begin
          DoneIniLinePtr(P);
          P := R
        end else begin
          if P^.dlNext = nil then begin
            P^.dlNext := R;
            R^.dlPrev := P;
          end else begin
            R^.dlPrev := Prev;
            Prev^.dlNext := R;
          end;
        end;
      end;
      Q := IniLinePtr(Q^.dlNext);
    end;
    SetAsyncStatus(ecOK);
  end;

  procedure EnumGroupItems(I : IniMgrRecPtr; var P : IniLinePtr; Group : String;
                           Verbose : Boolean);
    {-Returns P loaded with all items in group "[Group]".}
  var
    Prev, Q, R : IniLinePtr;
    S : String;

  begin
    {fixup Strings as needed}
    if Group[1] <> '[' then
      Group := '['+Group+']';
    Group := StUpcase(Group);

    R := nil;
    if P = nil then begin
      InitIniLinePtr(P, '');
      if P = nil then begin
        SetAsyncStatus(ecOutOfMemory);
        Exit;
      end;
    end else
      P^.PL^ := '';

    Q := IniLinePtr(I^.dlHead);
    while Q <> nil do begin
      if StUpcase(Q^.PL^) = Group then begin
        Q := IniLinePtr(Q^.dlNext);
        while (Q <> nil) do begin
          if (Q^.PL^ <> '') and (Q^.PL^[1] <> '[') then begin
            S := Trim(Q^.PL^);
            if (S <> '') and (S[1] <> ';') then begin
              if not Verbose then
                S := ExtractWord(1, S, ['=']);
              if R <> nil then
                Prev := R;
              InitIniLinePtr(R, S);
              if R = nil then begin
                SetAsyncStatus(ecOutOfMemory);
                Exit;
              end;
              if P^.PL^ = '' then begin
                DoneIniLinePtr(P);
                P := R
              end else begin
                if P^.dlNext = nil then begin
                  P^.dlNext := R;
                  R^.dlPrev := P;
                end else begin
                  R^.dlPrev := Prev;
                  Prev^.dlNext := R;
                end;
              end;
            end;
          end;
          if (Q^.PL^ <> '') then begin
            if (Q^.PL^[1] <> '[') then
              Q := IniLinePtr(Q^.dlNext)
            else
              Q := nil;
          end else
            Q := IniLinePtr(Q^.dlNext);
        end;
        SetAsyncStatus(ecOK);
        Exit;
      end;
      Q := IniLinePtr(Q^.dlNext);
    end;
    SetAsyncStatus(ecGroupNotFound);
  end;

end.
