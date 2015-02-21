{$I DEFINES.INC}
UNIT BsPrint;


INTERFACE


VAR  PrinterF : Text;


PROCEDURE PrintLine  (InString: String);
PROCEDURE PrintStart (Port: Byte);
PROCEDURE PrintEnd;


IMPLEMENTATION


PROCEDURE PrintStart(Port: Byte);
BEGIN
     CASE Port OF
     1:   ASSIGN(PrinterF,'LPT1');
     2:   ASSIGN(PrinterF,'LPT2');
     3:   ASSIGN(PrinterF,'LPT3');
     END;
     {$I-}
     REWRITE(PrinterF);
     {$I+}
     IF IOResult=0 THEN;
END;


PROCEDURE PrintEnd;
BEGIN
     {$I-}
     WRITE(PrinterF,#12);
     CLOSE(PrinterF);
     {$I+}
     IF IOResult=0 THEN;
END;


PROCEDURE PrintLine(InString: String);
BEGIN
     {$I-}
     WRITELN(PrinterF,InString);
     {$I+}
     IF IOResult=0 THEN;
END;


END.
