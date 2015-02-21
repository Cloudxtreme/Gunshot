unit gxm;

interface
uses tpalloc;

const
  MAXALLOCS = 100;

function MyFarMalloc(Bytes:longint):pointer;
function MyFarFree(Ptr:pointer):integer;
function MyFarCoreLeft:longint;

implementation

type
  NodeRec = record
    P     : pointer;
    Size  : longint;
  end;

var
  Nodes   : array[0..(MAXALLOCS-1)] of NodeRec;

function MyFarMalloc(Bytes:longint):pointer;
var
  P     : pointer;
  i     : integer;
  Found : boolean;
begin
  P := nil;
  i := 0;
  Found := false;
  while ((i < MAXALLOCS) and (not Found)) do begin
    if ((Nodes[i].P = NIL) and (Nodes[i].Size = 0)) then begin
      Found := true;
      HugeGetMem(P,Bytes);
      if (P <> NIL) then begin
        Nodes[i].P := P;
        Nodes[i].Size := Bytes;
      end;
    end
    else begin
      Inc(i);
    end;
  end;
  MyFarMalloc := P;
end;

function MyFarFree(Ptr:pointer):integer;
var
  i     : integer;
  Found : boolean;
begin
  i := 0;
  Found := false;
  while ((i < MAXALLOCS) and (not Found)) do begin
    if ((Nodes[i].P = Ptr) and (Nodes[i].Size > 0)) then begin
      Found := true;
      HugeFreeMem(Nodes[i].P,Nodes[i].Size);
      Nodes[i].P := nil;
      Nodes[i].Size := 0
    end
    else begin
      Inc(i);
    end;
  end;
  MyFarFree := 0;
end;

function MyFarCoreLeft:longint;
begin
  MyFarCoreLeft := MaxAvail;
end;

procedure InitList;
var
  i : integer;
begin
  for i := 0 to (MAXALLOCS-1) do begin
    Nodes[i].P := NIL;
    Nodes[i].Size := 0;
  end;
end;

begin
  InitList;
end.
