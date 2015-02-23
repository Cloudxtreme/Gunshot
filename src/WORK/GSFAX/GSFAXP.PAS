{$IFDEF DPMI}
 Duh, real mode stupid!
{$ENDIF}

{$I DEFINES.INC}
{$M 32000,0,655360}
PROGRAM GSMailFaxPrinter;


USES Dos,Crt,ApMisc,ApFaxCvt,ApFaxPrn,BsString,BsFile;


CONST PrintDest               : PathStr = 'PRN';
      UseEpson                : Boolean = False;
      UseEpson24              : Boolean = False;
      UseHP300                : Boolean = False;
      UsePcl5Mode             : Boolean = False;
VAR   Printer                 : FaxPrinterPtr;
      FaxFN                   : PathStr;
      PrinterToUse            : PrinterType;
      ConfigSetupPrinter      : Byte;
      ConfigSetupPrinterModel : Byte;


FUNCTION MyLineNotifyFunc(Lines,LineSize: Word): Boolean; FAR;
BEGIN
     MyLineNotifyFunc := False;
END;


FUNCTION MyPageNotifyFunc(Page,Pages: Word) : Boolean; FAR;
BEGIN
     MyPageNotifyFunc := False;
END;


PROCEDURE PrintTheFax(FName: String);
BEGIN
     IF ((ConfigSetupPrinter<0) OR (ConfigSetupPrinter>3)) THEN Exit;
     IF ((ConfigSetupPrinterModel<0) OR (ConfigSetupPrinterModel>5)) THEN Exit;
     UseEpson    := False;
     UseEpson24  := False;
     UseHP300    := False;
     UsePcl5Mode := False;
     FaxFN       := FName;
     CASE ConfigSetupPrinter OF
     1:   PrintDest := 'LPT1';
     2:   PrintDest := 'LPT2';
     3:   PrintDest := 'LPT3';
     END;
     CASE ConfigSetupPrinterModel OF
     1:   BEGIN
               UseEpson     := True;
               PrinterToUse := Epson;
          END;
     2:   BEGIN
               UseEpson24   := True;
               PrinterToUse := Epson24;
          END;
     3:   BEGIN
               PrinterToUse := HP150;
          END;
     4:   BEGIN
               UseHP300     := True;
               PrinterToUse := HP300;
          END;
     5:   BEGIN
               UseHP300     := True;
               UsePcl5Mode  := True;
               PrinterToUse := HP300;
          END;
     END;
     InitFaxPrinter(Printer);
     IF GetAsyncStatus=ecOk THEN
     BEGIN
          SetPageNotifyFunc(Printer,MyPageNotifyFunc);
          SetLineNotifyFunc(Printer,MyLineNotifyFunc);
          IF NOT(UseEpson OR UseEpson24) THEN SetPcl5Mode(Printer,UsePcl5Mode);
          SetScaling(Printer,True);
          SetHeader(Printer,True);
          SetBlankLineSuppression(Printer,False);
          PrintFaxDocument(Printer,PrinterToUse,PrintDest,FaxFN);
          DoneFaxPrinter(Printer);
     END;
END;


BEGIN
     ConfigSetupPrinter      := _Numeric(ParamStr(1));
     ConfigSetupPrinterModel := _Numeric(ParamStr(2));
     IF _FileExists(ParamStr(3)) THEN PrintTheFax(ParamStr(3));
END.