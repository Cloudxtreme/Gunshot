{$I-,O-,R-}
{$IFDEF VER70}
{$Q-}
{$ENDIF}

unit Extend;

{ This unit allows a program to open more than the standard DOS maximum of 20
  open files at one time.  You must also be sure to set a FILES=XX statement
  in your CONFIG.SYS file.  This program installs a special interrupt handler
  under DOS 2.x, some semi-documented features under DOS 3.x prior to
  DOS 3.3 and the DOS extend files call under DOS 3.3 or later.  This
  unit USES the DOS unit and should be used before any other units other than
  the DOS unit.  This code was based upon earlier work by Randy Forgaard, Bela
  Lubkin and Kim Kokkonen.  See EXTEND.DOC for more information.

  Scott Bussinger
  Professional Practice Systems
  110 South 131st Street
  Tacoma, WA  98444
  (206)531-8944
  Compuserve [72247,2671] }

{ ** Revision History **
  1 EXTEND.PAS 9-Mar-89,`SCOTT' First version using TLIB -- Based on 3.2
  2 EXTEND.PAS 15-Sep-89,`SCOTT'
           Added SwapVectorsExtend procedure
           Put handle table into DOS memory
           Use DOS 3.3 extended handles function when available
  3 EXTEND.PAS 2-Oct-89,`SCOTT'
           Fixed bug in determining the DOS version
  4 EXTEND.PAS 5-Oct-89,`SCOTT'
           Yet another bug in the DosVersion detection
  5 EXTEND.PAS 9-Oct-92,14:59:50,`SCOTT'
           Added compiler check for compatibility with BP 7
           Added support for protected mode operation
  6 EXTEND.PAS 5-Dec-92,`SCOTT'
           Complete compatibility with BP7 protected and real modes
  ** Revision History ** }

{ Version 3.2 --  9/25/1988 -- Added O- compiler directive to prevent overlaying
                               Moved extended handle table off of heap to support overlay manager
                               Used DosVersion from DOS unit
                               Turned off Range and I/O checking directives
                               Fix exit procedure to chain first rather than last
                               Compiled EXTEND.ASM with TASM
                               Moved USES statement to implementation section
          3.1 --  4/21/1988 -- Removed compiler directives (just uses defaults)
          3.0 -- 10/16/1987 -- Reworked as a UNIT for use with Turbo Pascal 4
                               EXTEND.ASM reworked to be compatible with A86 assembler
                               Added support for DOS 3.3
          2.5 --  3/16/1987 -- EXTEND.ASM worked on by Kim Kokkonen and Brian Foley to work
                                 with Turbo Extender and whittle off a few clock cycles
          2.4 -- 12/16/1986 -- Fixed a problem with DUP under DOS 2.x
                               Now allocates the new handle table on heap
                                 under DOS 3.x (compatible with TDebug+)
          2.3 -- 11/18/1986 -- EXTEND now only affects DOS calls made from
                                 same code segment it was installed from (fixes
                                 problems with EXEC and batch files and already
                                 resident TSR programs
          2.2 -- 10/04/1986 -- Fixed problem with EXEC function destroying all
                                 registers including the stack
                               Changed way that original handle number is kept
                               Permit FORCEDUP to change a standard handle
                               Improve some comments
          2.1 -- 10/02/1986 -- Fixed problem of Turbo assuming the registers
                                 valid after the DOS call
          2.0 -- 10/01/1986 -- Initial release of interrupt handler version
          1.5                  Last version of EXTEND.PAS using explicit
                                 calls to extend files. }

interface

procedure SwapVectorsExtend;
  { Swap interrupt vectors taken over by Extend unit with system vectors }

implementation

uses Dos,Shrink
     {$IFDEF DPMI}
     ,WinAPI
     {$ENDIF}
     ;

type HandleArray = array[0..254] of byte;        { Room for 255 handles }
     HandleArrayPtr = ^HandleArray;

var ExitSave: pointer;                           { Previous exit procedure }

var OldInt21: pointer;                           { Save old INT 21 }

var DosMemory: pointer;                          { Pointer to memory gained from DOS }
    OldHandleTable: HandleArrayPtr;              { Pointer to original table }
    OldNumHandles: byte;                         { Original number of handles }

{$IFNDEF DPMI}
{$L EXTEND }
procedure ExtendInit; external;                  { Initialize interrupt handler }
procedure ExtendHandler; external;               { Replacement INT 21 handler }
{$ENDIF}

procedure SwapVectorsExtend;
  { Swap interrupt vectors taken over by Extend unit with system vectors }
  var TempVector: pointer;
  begin
  {$IFNDEF DPMI}                                 { This can't apply to a DPMI program }
  if lo(DosVersion) = 2 then
    begin
    GetIntVec($21,TempVector);                   { Swap the INT 21 vectors }
    SetIntVec($21,OldInt21);
    OldInt21 := TempVector
    end
  {$ENDIF}
  end;

procedure ExtendHandles;
  { Install the extended handles interrupt.  No files (other than
    standard handles) should be open when unit starts up. }
  var DontCare: word;
      Regs: Registers;
      TempSelector: word;

  function Linear(P: pointer): longint;
    { Convert a real pointer into a linear address }
    type Split = record
           Ofs: word;
           Seg: word
           end;
    begin
    Linear := (longint(Split(P).Seg) shl 4) + Split(P).Ofs
    end;

  begin
  {$IFNDEF DPMI}                                 { Can't run DOS 2 on a DPMI system }
  if lo(DosVersion) = 2
   then
    begin
    GetIntVec($21,OldInt21);                     { Install interrupt handler under DOS 2.x }
    ExtendInit;                                  { Initialize the interrupt handler }
    SetIntVec($21,@ExtendHandler)
    end
   else
  {$ENDIF}
    begin
    DosNewShrink(DosMemory,sizeof(HandleArray));
    if DosMemory <> nil then                     { There wasn't enough memory for a handle table, so just quit }
      if (lo(DosVersion)>=4) or (hi(DosVersion)>=30) { Does this DOS version support the handles call? }
       then
        begin
        DosDispose(DosMemory);                   { Free up the DOS memory block so that the next function will succeed }
        fillchar(Regs,sizeof(Regs),0);           { To avoid protected mode problems }
        with Regs do
          begin
          AH := $67;                             { Tell DOS to allow us 255 handles }
          BX := 255;                             { KEEP THIS NUMBER ODD TO AVOID BUG IN SOME VERSIONS OF DOS 3.3!! }
          MsDos(Regs)
          end
        end
       else
        begin
        fillchar(DosMemory^,sizeof(HandleArray),$FF);     { Initialize new handles as unused }
        OldNumHandles := mem[prefixseg:$0032];            { Get old table length }
        mem[prefixseg:$0032] := sizeof(HandleArray);      { Set new table length }
        {$IFDEF DPMI}
        TempSelector := AllocSelector(0);
        DontCare := SetSelectorBase(TempSelector,Linear(pointer(ptr(prefixseg,$0034)^)));
        DontCare := SetSelectorLimit(TempSelector,256);
        OldHandleTable := ptr(TempSelector,0);            { Save address of old table }
        memw[prefixseg:$0034] := GetSelectorBase(seg(DosMemory^)) and $F; { Point to new handle table (offset) }
        memw[prefixseg:$0036] := GetSelectorBase(seg(DosMemory^)) shr 4;  { Point to new handle table (segment) }
        move(OldHandleTable^,DosMemory^,OldNumHandles);   { Copy the current handle table to the new handle table }
        DontCare := FreeSelector(TempSelector)
        {$ELSE}
        OldHandleTable := pointer(ptr(prefixseg,$0034)^); { Save address of old table }
        pointer(meml[prefixseg:$0034]) := DosMemory;      { Point to new handle table }
        move(OldHandleTable^,DosMemory^,OldNumHandles)    { Copy the current handle table to the new handle table }
        {$ENDIF}
        end
    end
  end;

{$IFNDEF DPMI}                                   { Most of this unit is simply commented out in protected mode }
{$F+}
procedure ExitHandler;
{$F-}
  { Uninstall the extended handles interrupt.  All files (other
    than standard handles) should be closed before unit exits. }
  begin
  ExitProc := ExitSave;                          { Chain to next exit routine }
  SwapVectorsExtend                              { Restore original interrupt vectors }
  end;
{$ENDIF}

begin
{$IFNDEF DPMI}                                   { Most of this unit is simply commented out in protected mode }
ExitSave := ExitProc;                            { Remember the previous exit routine }
ExitProc := @ExitHandler;                        { Install our exit routine }
{$ENDIF}
ExtendHandles                                    { Enable the extra handles }
end.
