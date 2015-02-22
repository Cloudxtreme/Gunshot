{$I DEFINES.INC}
UNIT Misc;


INTERFACE


USES Shotgun;


FUNCTION  IsOurNode     (InAddress: AddrType): Boolean;


IMPLEMENTATION


USES Globals,BsAkas;


FUNCTION IsOurNode(InAddress: AddrType): Boolean;
BEGIN
     ASSIGN(FNetwork,Shotgun_Directory+'\DATA\NETWORK.DAT');
     RESET(FNetwork);
     REPEAT
           READ(FNetwork,Network);
           IF AkasMatch(InAddress,Network.Net_Address) THEN
           BEGIN
                CLOSE(FNetwork);
                IsOurNode := True;
                Exit;
           END;
     UNTIL EOF(FNetwork);
     CLOSE(FNetwork);
     IsOurNode := False;
END;


END.