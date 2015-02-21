{$S-,R-,F+,O+,I-}
{*********************************************************}
{*                 OOPMAIN1.PAS 2.03                     *}
{*        Copyright (c) TurboPower Software 1991.        *}
{*                 All rights reserved.                  *}
{*********************************************************}

unit OopMain1;

interface

uses Dos;

const
  NotConfigFile    = $FFFF;
  OutOfMem         = 8;

function StoreConfiguration(ConfigFile : PathStr;
                            StartAddr : Pointer; Size : Word) : Word;

function LoadConfiguration(ConfigFile : PathStr; ID : String;
                           StartAddr : Pointer; Size : Word) : Word;

implementation

  function StoreConfiguration(ConfigFile : PathStr;
                              StartAddr : Pointer; Size : Word) : Word;
  var
    F : File;
    E : Word;
    NumWritten : Word;
  begin
    Assign(F, ConfigFile);
    Rewrite(F, 1);
    E := IoResult;
    if E = 0 then begin
      BlockWrite(F, StartAddr^, Size, NumWritten);
      E := IoResult;
      if (E = 0) and (NumWritten <> Size) then
        E := 1;
      Close(F);
      if IoResult = 0 then ;
    end;
    StoreConfiguration := E;
  end;

  function LoadConfiguration(ConfigFile : PathStr; ID : String;
                             StartAddr : Pointer; Size : Word) : Word;
  type
    StringPtr = ^String;
  var
    S : String;
    F : File;
    NumRead : Word;
    E : Word;
  begin
    Assign(F, ConfigFile);
    Reset(F, 1);
    E := IoResult;
    if E = 0 then begin
      if FileSize(F) = Size then begin
        BlockRead(F, S, SizeOf(S), NumRead);
        E := IoResult;
        if (E = 0) then begin
          if S = ID then begin
            Seek(F, 0);
            BlockRead(F, StartAddr^, Size, NumRead);
            E := IoResult;
            if (E = 0) and (NumRead<> Size) then
              E := 1;
          end
          else
            E := NotConfigFile;
        end;
      end
      else
        E := NotConfigFile;
    end;
    Close(F);
    if IoResult = 0 then ;
    LoadConfiguration := E;
  end;

end.
