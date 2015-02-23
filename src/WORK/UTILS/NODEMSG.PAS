{$IFDEF DPMI}
  REAL MODE ONLY!
{$ENDIF}
{$M 65500,0,655360}
PROGRAM NodeMsg;


{$I DEFINES.INC}

USES Dos,BsVideo,Gunshot,BsString,BsFile;


VAR  TheNode   : Word;
     FNode     : File Of _NodeFile_Record;
     Node      : _NodeFile_Record;
     TFile     : Text;
     TextFile  : String;
     Temp      : String;


PROCEDURE GetCommandLineOptions;
VAR  Code  : Integer;
     Loop  : Word;
BEGIN
     TheNode  := 0;
     TextFile := '';
     FOR loop := 1 TO paramcount DO
     BEGIN
          Temp := _UpperCase(paramstr(loop));
          IF ((Temp[1]='-') OR (Temp[1]='/')) THEN
          BEGIN
               DELETE(Temp,1,1);
               CASE Temp[1] OF
{NODE NUMBER}  'N' : BEGIN
                          Delete(Temp,1,1);
                          VAL(Temp,TheNode,code);
                     END;
               'F' : BEGIN
                          Delete(Temp,1,1);
                          TextFile := Temp;
                     END;
               END;
          END;
     END;
END;


BEGIN
     FileMode := 66;
     GetCommandLineOptions;
     IF ((TheNode=0) OR (TextFile='') OR NOT(_FileExists(TextFile))) THEN
     BEGIN
          AppHeader('NodeMsg - Node Message Sender');
          WRITELN(' A utility to set the node activity for other nodes to view.');
          WRITELN;
          WRITELN('      SYNTAX:  NODEMSG.EXE -N<node##> -F<textfile>');
          WRITELN;
          WRITELN('                     <node##>:   The node number to send the message');
          WRITELN('                   <textfile>:   The text file containing the message');
          WRITELN('                                 The text file must have the format:');
          WRITELN('                                     -Line #1:   The user name');
          WRITELN('                                     -Line #2:   The activity');
          Halt;
     END;
     FileMode := 66;
     FillChar(Node,SizeOf(Node),0);
     Node.Available := False;
     Node.Node      := TheNode;
     ASSIGN(TFile,TextFile);
     RESET(TFile);
     {$I-}
     READLN(TFile,Temp); Node.User := _PadRight(Temp,30);
     READLN(TFile,Temp); Node.Activity := _PadRight(Temp,40);
     {$I+}
     IF IOResult=0 THEN;
     CLOSE(TFile);
     _CreatePath('\GUNSHOT\INTRNODE');
     ASSIGN(FNode,'\GUNSHOT\INTRNODE\NODE'+_String(TheNode)+'.$$$');
     {$I-}RESET(FNode);{$I+}
     IF (IOResult<>0) THEN REWRITE(FNode);
     WRITE(FNode,Node);
     CLOSE(FNode);
END.
