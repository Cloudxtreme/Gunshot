unit Shrink;

{ This unit allows you to allocate memory from the DOS memory pool rather than
  from the Turbo Pascal heap.  It also provides a procedure for shrinking the
  current program to free up DOS memory.  In protected mode, this allocates
  memory from real mode addressable memory.

  Scott Bussinger
  Professional Practice Systems
  110 South 131st Street
  Tacoma, WA  98444
  (206)531-8944
  Compuserve [72247,2671] }

{ ** Revision History **
  1 SHRINK.PAS 15-Sep-89,`SCOTT' Initial version of SHRINK unit
  2 SHRINK.PAS 19-Oct-90,`SCOTT'
           Added support for Turbo Pascal 6's new heap manager
  3 SHRINK.PAS 27-Feb-91,`SCOTT'
           Fixed problem in allocating memory in Turbo Pascal 6.0
           Fixed missing variable for compilers prior to Turbo Pascal 6.0
  4 SHRINK.PAS 9-Aug-92,23:29:46,`SCOTT'
           Added compiler check for compatibility with BP 7
  5 SHRINK.PAS 5-Dec-92,`SCOTT'
           Complete compatibility with BP7 protected and real modes
  ** Revision History ** }

interface

procedure DosNew(var P: pointer;
                     Bytes: word);
  { Get a pointer to a chunk of memory from DOS.  Returns NIL if
    sufficient DOS memory is not available. }

procedure DosDispose(var P: pointer);
  { Return an allocated chunk of memory to DOS.  Only call this function
    with pointers allocated with DosNew or DosNewShrink. }

procedure DosNewShrink(var P: pointer;
                           Bytes: word);
  { Get a pointer to a chunk of memory from DOS, shrinking current program
    to gain DOS memory if necessary.  Returns NIL if sufficient DOS memory
    is not available and there is insufficient free space in the heap to
    allow program to be shrunk to accomodate the request. }

implementation

{$DEFINE HEAP6}                                  { Define HEAP6 only if the Turbo 6 style heap is in effect }

{$IFDEF VER40}
{$UNDEF HEAP6}
{$ENDIF}

{$IFDEF VER50}
{$UNDEF HEAP6}
{$ENDIF}

{$IFDEF VER55}
{$UNDEF HEAP6}
{$ENDIF}

uses Dos
     {$IFDEF DPMI}
     ,WinAPI
     {$ENDIF}
     ;

const DosOverhead = 1;                           { Extra number of paragraphs that DOS requires in overhead for MCB chain }

function Linear(P: pointer): longint;
  { Return the pointer as a linear longint value }
  begin
  Linear := (longint(seg(P^)) shl 4) + ofs(P^)
  end;

{$IFDEF MSDOS}
procedure DosNew(var P: pointer;
                     Bytes: word);
  { Get a pointer to a chunk of memory from DOS.  Returns NIL if
    sufficient DOS memory is not available. }
  var DPMI: longint;
      Regs: Registers;
      SegsToAllocate: word;
  begin
  {$IFDEF DPMI}
  P := ptr(GlobalDosAlloc(Bytes) and $FFFF,$0000)
  {$ELSE}
  SegsToAllocate := (Bytes+15) shr 4;            { DOS allocates memory in paragraph sized pieces only }
  with Regs do
    begin
    AH := $48;
    BX := SegsToAllocate;
    MsDos(Regs);
    if odd(Flags)
     then
      P := nil                                   { No memory available }
     else
      P := ptr(AX,$0000)                         { Return pointer to memory block }
    end
  {$ENDIF}
  end;
{$ENDIF}
{$IFNDEF MSDOS}
procedure DosNew(var P: pointer;
                     Bytes: word);
  begin
    WriteLn('REEPORT SHRINK DosNew'); Halt;
  end;
{$ENDIF}

{$IFDEF MSDOS}
procedure DosDispose(var P: pointer);
  { Return an allocated chunk of memory to DOS.  Only call this function
    with pointers allocated with DosNew or DosNewShrink. }
  var DontCare: word;
      Regs: Registers;
  begin
  {$IFDEF DPMI}
  DontCare := GlobalDosFree(seg(P^))
  {$ELSE}
  with Regs do
    begin
    AH := $49;
    ES := seg(P^);
    MsDos(Regs)
    end
  {$ENDIF}
  end;
{$ENDIF}
{$IFNDEF MSDOS}
procedure DosDispose(var P: pointer);
  begin
    WriteLn('REEPORT SHRINK DosDispose'); Halt;
  end;
{$ENDIF}

{$IFDEF MSDOS}
procedure DosNewShrink(var P: pointer;
                           Bytes: word);
  { Get a pointer to a chunk of memory from DOS, shrinking current program
    to gain DOS memory if necessary.  Returns NIL if sufficient DOS memory
    is not available and there is insufficient free space in the heap to
    allow program to be shrunk to accomodate the request. In protected mode
    this just calls DosNew directly. }
  var BytesToAllocate: word;
      OldFreePtr: pointer;
      Regs: Registers;
  begin
  DosNew(P,Bytes);                               { Try to get memory the easy way first }
  {$IFNDEF DPMI}
  {$IFDEF HEAP6}                                 { Check for Turbo 6's new heap manager }
  BytesToAllocate := (((Bytes+15) shr 4) + DosOverhead) shl 4;
  if (P=nil) and (Linear(HeapEnd)-Linear(HeapPtr)>=BytesToAllocate) then
    begin                                        { The easy method didn't work but there is sufficient space in the heap }
    dec(longint(HeapEnd),longint(BytesToAllocate) shl 12); { Move the top of the heap down }
    with Regs do
      begin
      AH := $4A;
      BX := seg(HeapEnd^) - prefixseg;
      ES := prefixseg;
      MsDos(Regs)
      end;
    DosNew(P,Bytes)                              { Try the DOS allocation one more time }
    end
  {$ELSE}
  BytesToAllocate := (((Bytes+15) shr 4) + DosOverhead) shl 4;
  if (P=nil) and                                 { Handle the old free list style heap }
     (((ofs(FreePtr^)=0) and (Linear(FreePtr)+$10000-Linear(HeapPtr)>=BytesToAllocate)) or
      ((ofs(FreePtr^)<>0) and (Linear(FreePtr)-Linear(HeapPtr)>=BytesToAllocate))) then
    begin                                        { The easy method didn't work but there is sufficient space in the heap }
    OldFreePtr := FreePtr;
    dec(longint(FreePtr),longint(BytesToAllocate) shl 12); { Decrement the segment of the pointer to the free list }
    if ofs(OldFreePtr^) <> 0 then                { If free list is empty, then there's nothing to move }
      move(OldFreePtr^,FreePtr^,$10000-ofs(OldFreePtr^)); { Otherwise, move the free list down in memory }
    with Regs do
      begin
      AH := $4A;
      BX := seg(OldFreePtr^) + $1000 - prefixseg - (BytesToAllocate shr 4);
      ES := prefixseg;
      MsDos(Regs)
      end;
    DosNew(P,Bytes)                              { Try the DOS allocation one more time }
    end
  {$ENDIF}
  {$ENDIF}
  end;
{$ENDIF}
{$IFNDEF MSDOS}
procedure DosNewShrink(var P: pointer;
                           Bytes: word);
  begin
    WriteLn('REEPORT SHRINK DosNewShrink'); Halt;
  end;
{$ENDIF}

end.
