{$I DEFINES.INC}
UNIT _Keys;


INTERFACE


PROCEDURE DoFunctionKey (cc: Char);


IMPLEMENTATION


USES Startup,Globals;


PROCEDURE DoFunctionKey(cc: Char);
BEGIN
     CASE ORD(cc) OF
     59:  SendCommandString(YappDef.F1,False,False);
     60:  SendCommandString(YappDef.F2,False,False);
     61:  SendCommandString(YappDef.F3,False,False);
     62:  SendCommandString(YappDef.F4,False,False);
     63:  SendCommandString(YappDef.F5,False,False);
     64:  SendCommandString(YappDef.F6,False,False);
     65:  SendCommandString(YappDef.F7,False,False);
     66:  SendCommandString(YappDef.F8,False,False);
     67:  SendCommandString(YappDef.F9,False,False);
     68:  SendCommandString(YappDef.F10,False,False);
     END;
END;


END.
