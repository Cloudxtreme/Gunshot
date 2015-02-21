
Unit ShowHeap;

interface

uses
  CRT,UMB_Heap;

  Procedure Show_Heap;

implementation

type
  PFreeRec = ^TFreeRec;      {  From pg. 216 of the TP6 programmer's guide.  }
  TFreeRec = record          {  It's used for traversing the free blocks of  }
    Next : PFreeRec;         {  the heap.                                    }
    Size : Pointer;
  end;

Function Pointer_To_LongInt(P : Pointer) : LongInt;
  type
    PtrRec = record
      Lo,Hi : Word;
    end;
  Begin
    Pointer_To_LongInt := LongInt(PtrRec(P).Hi)*16+PtrRec(P).Lo;
  End;

Procedure Show_Heap;
  var
    N : Word;
    BlockSize,Total : LongInt;
    Temp : PFreeRec;
  Begin
    N := 1;
    Total := 0;
    if (FreeList <> HeapPtr) then
      begin
        Temp := FreeList;
        repeat
          BlockSize := Pointer_To_LongInt(Temp^.Size);
          Total := Total+BlockSize;
          Write('   Block ',N,' contains  ',BlockSize:6,' bytes');
          if (Seg(Temp^) > $A000) then
            WriteLn(' (UMB)')
          else
            WriteLn;
          Inc(N);
          Temp := Temp^.Next;
        until (Temp = HeapPtr);
      end;
    BlockSize := Pointer_to_LongInt(HeapEnd)-Pointer_to_LongInt(HeapPtr);
    Write('   Block ',N,' contains  ',BlockSize:6,' bytes');
    if (Seg(HeapPtr^) > $A000) then
      WriteLn(' (UMB)')
    else
      WriteLn;
    Total := Total+BlockSize;
    WriteLn('   -------------------------------');
    WriteLn('   Total heap size = ',Total:6,' bytes');
    WriteLn;
  End;

BEGIN
END.