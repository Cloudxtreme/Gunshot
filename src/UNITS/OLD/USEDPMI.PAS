{$I DEFINES.INC}
{$X+}
UNIT UseDPMI;


INTERFACE


{$IFDEF DPMI}
VAR  GotDPMISwapFile : Boolean;
PROCEDURE CreateDPMISwapFile;
PROCEDURE RemoveDPMISwapFile;
{$ENDIF}


IMPLEMENTATION


{$IFDEF DPMI}
USES TimeTask,WinAPI,Strings;


CONST rtmOK          = $0;
      rtmNoMemory    = $1;
      rtmFileIOError = $22;


FUNCTION MemInitSwapFile(FileName: PChar; FileSize: Longint): Integer; FAR; EXTERNAL 'RTM' index 35;
FUNCTION MemCloseSwapFile(Delete: Integer): Integer; FAR; EXTERNAL 'RTM' index 36;


PROCEDURE CreateDPMISwapFile;
BEGIN
     IF (Task.Os=0) THEN
     BEGIN
          IF MemInitSwapFile('DPMISWAP.$$$',8192000)=rtmOK THEN GotDPMISwapFile := True;
     END;
END;


PROCEDURE RemoveDPMISwapFile;
BEGIN
     IF GotDPMISwapFile THEN MemCloseSwapFile(1);
     GotDPMISwapFile := False;
END;
{$ENDIF}

BEGIN
     {$IFDEF DPMI}
     GotDPMISwapFile := False;
     {$ENDIF}
END.