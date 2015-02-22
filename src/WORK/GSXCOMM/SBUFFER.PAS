{$I DEFINES.INC}
UNIT SBuffer;


INTERFACE


PROCEDURE ClearBuffer;
PROCEDURE AddToBuffer(In1,In2: String);


IMPLEMENTATION


USES Globals,ErrorLog;


PROCEDURE ClearBuffer;
BEGIN
     InBuffer := 0;
     FillChar(WorkBuffer,SizeOf(WorkBuffer),0);
END;


PROCEDURE AddToBuffer(In1,In2: String);
BEGIN
     IF InBuffer<50 THEN
     BEGIN
          INC(InBuffer);
          WorkBuffer[InBuffer].Token := In1;
          WorkBuffer[InBuffer].Replacement := In2;
     END
     ELSE DoErrorLog(5,'');
END;


END.