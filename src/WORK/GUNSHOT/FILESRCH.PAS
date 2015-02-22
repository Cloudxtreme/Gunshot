{$I DEFINES.INC}
UNIT FileSrch;


INTERFACE


PROCEDURE file_search  (SearchType: Char);
FUNCTION  search_file  (SearchType: Char) : longint;
FUNCTION  search_date  (SearchType: Char) : longint;
FUNCTION  search_text  (SearchType: Char) : longint;
FUNCTION  search_new   (Logon: Boolean)   : longint;


IMPLEMENTATION


USES ANSIMisc,Screens,Globals,KeyInput,ChangeFA,ListFile,ApTimer,
     BsLog,Toggle,MiscStr,TagArea,GotKeys,Dos,CDS,Time,Shotgun,
     BsString;


PROCEDURE file_search(SearchType: Char);
VAR  c            : char;
     number_files : word;
BEGIN
     SendCrLf(1);
     DisplayGraphicsFile('SEARCHES',True,False,True,True,False);
     SendCrLf(1);
     system_prompt('',1,false,True);
     c := UpCase(Get_Menu_Selection('CATSQ',#0));
     SendCrLf(1);
     IF (C<>'Q') THEN
     BEGIN
          IF c='S' THEN IF NOT(Change_FArea) THEN Exit;
          CASE SearchType OF
          'F' : BEGIN
                     number_files := search_file(c);
                     IF number_files<>0 THEN List_Files(NODE_Directory+'\SEARCH$$');
                END;
          'T' : BEGIN
                     number_files := search_text(c);
                     IF number_files<>0 THEN List_Files(NODE_Directory+'\SEARCH$$');
                END;
          'D' : BEGIN
                     number_files := search_date(c);
                     IF number_files<>0 THEN List_Files(NODE_Directory+'\SEARCH$$');
                END;
          END;
     END;
END;


FUNCTION search_text(SearchType: Char):longint;
VAR  RunningDescriptions : Longint;
     work                : string;
     found               : word;
     loop                : word;
     running_count       : longint;
     FoundIt             : Boolean;
     Crud                : Longint;
     Timer               : EventTimer;
     OldValue            : String;
LABEL                      QuitSearch,SkipIt;

     PROCEDURE Redraw;
     VAR  Poop : Word;
     BEGIN
          WRITECHAR(#08);
          FOR Poop := 1 TO (LENGTH(OldValue)+1) DO WRITECHAR(#08);
          OldValue := _String(Found);
          WRITEANSI(OldValue+' ',False,False);
          RedrawToggle;
     END;

BEGIN
     DisplayGraphicsFile('TEXTSRCH',false,false,True,True,False);
     Fore(15); Get_String(40,'',true,false,true,False);
     SendCrLf(1);
     IF input_string='' THEN
     BEGIN
          search_text := 0;
          Exit;
     END;
     work := _UpperCase(input_string);
     bsWriteLog('File search [Text] : "'+work+'"',False);
     SendCrLf(1);
     system_prompt('',16,false,True);
     found := 0;
     OldValue := '0';
     running_count := 0;
     RunningDescriptions := 1;
     Fore(Colours.SpinCursor);
     WRITECHAR('0');
     WRITECHAR(' ');
     WRITECHAR(' ');
     StartToggle(0);
     NewTimerSecs(Timer,1440*60);
     ASSIGN(FFileDefs2,NODE_Directory+'\SEARCH$$.FIL');
     ASSIGN(FFileDesc2,NODE_Directory+'\SEARCH$$.TXT');
     ASSIGN(FFileIndex,NODE_Directory+'\SEARCH$$.IDX');
     REWRITE(FFileDefs2);
     REWRITE(FFileDesc2);
     REWRITE(FFileIndex);
     ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(CurrentFileSub)+'.DAT');
     RESET(FFileArea);
     REPEAT
       READ(FFileArea,FileAreas);
       INC(running_count);
       CASE SearchType OF
       'C': IF (running_count<>CurrentFileArea) THEN GOTO SkipIt;
       'T': IF NOT(IsFileTagged(FileAreas.AreaId)) THEN GOTO SkipIt;
       'S': IF (running_count<>CurrentFileArea) THEN GOTO SkipIt;
       END;
       IF ((FileAreas.dl_access<=UserRecord.security) AND GotTheKeys(UserRecord.Tags,FileAreas.Tags)) THEN
       BEGIN
         IF ((FileAreas.CD_Rom<>0) AND (NOT(IsCDToggled(FileAreas.CD_Rom)))) THEN GOTO SkipIt;
         IF FileAreas.PassThrough THEN GOTO SkipIt;
         DoToggle;
         ASSIGN(FFileDefs,FileAreas.dos_name+'.FIL');
         {$I-}RESET(FFileDefs);{$I+}
         IF IOResult=0 THEN
         BEGIN
           ASSIGN(FFileDesc,FileAreas.dos_name+'.TXT');
           RESET(FFileDesc);
           REPEAT
             READ(FFileDefs,FileDefs);
             FoundIt := False;
             FOR Crud := 1 TO FileDefs.Desc_Lines DO
             BEGIN
               READ(FFileDesc,FileDesc[Crud]);
               IF ((NOT(FoundIt)) AND (Pos(work,_UpperCase(FileDesc[Crud].desc))<>0)) THEN FoundIt := True;
             END;
             IF FoundIt THEN
             BEGIN
               INC(found);
               {ADJUST VARIABLES}
               FileIndex.path      := FileAreas.area_path;
               FileIndex.cd_rom    := FileAreas.cd_rom;
               FileIndex.area_num  := running_count;
               FileIndex.area_name := FileAreas.area_name;
               FileIndex.area_Sub  := CurrentFileSub;
               FileDefs.First_Desc := RunningDescriptions;
               {WRITE OUT THE TEMPORARY FILES}
               WRITE(FFileDefs2,FileDefs);
               WRITE(FFileIndex,FileIndex);
               FOR Crud := 1 TO FileDefs.Desc_Lines DO WRITE(FFileDesc2,FileDesc[Crud]);
               RunningDescriptions := RunningDescriptions+FileDefs.Desc_Lines;
               Redraw;
             END;
           UNTIL ((EOF(FFileDefs)) OR (Found=1000));
           CLOSE(FFileDesc);
           CLOSE(FFileDefs);
         END;
         IF CommLookAhead=#27 THEN GOTO QuitSearch;
       END;
       SkipIt:
     UNTIL ((EOF(FFileArea)) OR (Found=1000));
     QuitSearch:
     CLOSE(FFileArea);
     CLOSE(FFileDefs2);
     CLOSE(FFileDesc2);
     CLOSE(FFileIndex);
     EndToggle;
     SendCrLf(2);
     bsWriteLog('Search complete : '+_String(Found)+' matches in '+_String(ElapsedTimeInSecs(Timer))+' seconds',False);
     system_prompt(_String(Found),17,true,False);
     GET_ENTER;
     search_text := found;
END;


FUNCTION search_date(SearchType: Char): longint;
VAR  RunningDescriptions : Longint;
     work                : String;
     found               : word;
     loop                : word;
     DT                  : DateTime;
     s_date              : longint;
     working             : longint;
     running_count       : longint;
     FileNumber          : Word;
     Crud                : LongInt;
     Timer               : EventTimer;
     OldValue            : String;
LABEL                      QuitSearch,SkipIt;

     PROCEDURE Redraw;
     VAR  Poop : Word;
     BEGIN
          WRITECHAR(#08);
          FOR Poop := 1 TO (LENGTH(OldValue)+1) DO WRITECHAR(#08);
          OldValue := _String(Found);
          WRITEANSI(OldValue+' ',False,False);
          RedrawToggle;
     END;

BEGIN
     REPEAT
           work := '';
           DisplayGraphicsFile('DATESRCH',false,false,True,True,False);
           GetADate('',False);
           SendCrLf(1);
           IF input_string='' THEN
           BEGIN
                search_date := 0;
                Exit;
           END;
           work := input_string;
           IF length(work)<>8 THEN work := '';
     UNTIL work<>'';
     FillChar(DT,SizeOf(DT),0);
     DT.Year  := _Numeric(_Mid(work,5,8));
     DT.Month := _Numeric(_Mid(work,1,2));
     DT.Day   := _Numeric(_Mid(work,3,4));
     PackTime(DT,s_date);
     CASE System_Info.DateFormat OF
     1:   bsWriteLog('File search [Date] : "'+ _Mid(work,1,2)+'/'+_Mid(work,3,4)+'/'+_Mid(work,5,8)+'"',False);
     2:   bsWriteLog('File search [Date] : "'+ _Mid(work,3,4)+'/'+_Mid(work,1,2)+'/'+_Mid(work,5,8)+'"',False);
     3:   bsWriteLog('File search [Date] : "'+ _Mid(work,5,8)+'/'+_Mid(work,1,2)+'/'+_Mid(work,3,4)+'"',False);
     END;
     SendCrLf(1);
     system_prompt('',16,false,True);
     found := 0;
     OldValue := '0';
     running_count := 0;
     RunningDescriptions := 1;
     Fore(Colours.SpinCursor);
     WRITECHAR('0');
     WRITECHAR(' ');
     WRITECHAR(' ');
     StartToggle(0);
     NewTimerSecs(Timer,1440*60);
     ASSIGN(FFileDefs2,NODE_Directory+'\SEARCH$$.FIL');
     ASSIGN(FFileDesc2,NODE_Directory+'\SEARCH$$.TXT');
     ASSIGN(FFileIndex,NODE_Directory+'\SEARCH$$.IDX');
     REWRITE(FFileDefs2);
     REWRITE(FFileDesc2);
     REWRITE(FFileIndex);
     ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(CurrentFileSub)+'.DAT');
     reset(FFileArea);
     REPEAT
           read(FFileArea,FileAreas);
           INC(running_count);
           CASE SearchType OF
           'C': IF (running_count<>CurrentFileArea) THEN GOTO SkipIt;
           'T': IF NOT(IsFileTagged(FileAreas.AreaId)) THEN GOTO SkipIt;
           'S': IF (running_count<>CurrentFileArea) THEN GOTO SkipIt;
           END;
           IF ((FileAreas.dl_access<=UserRecord.security) AND GotTheKeys(UserRecord.Tags,FileAreas.Tags)) THEN
           BEGIN
                IF ((FileAreas.CD_Rom<>0) AND (NOT(IsCDToggled(FileAreas.CD_Rom)))) THEN GOTO SkipIt;
                IF FileAreas.PassThrough THEN GOTO SkipIt;
                DoToggle;
                ASSIGN(FFileDefs,FileAreas.dos_name+'.FIL');
                {$I-}RESET(FFileDefs);{$I+}
                IF IOResult = 0 THEN
                BEGIN
                     IF NOT(EOF(FFileDefs)) THEN
                     BEGIN
                          FileNumber := 0;
                          REPEAT
                                READ(FFileDefs,FileDefs);
                                INC(FileNumber);
                                IF (FileDefs.file_date>=s_date) THEN
                                BEGIN
                                     INC(found);
                                     ASSIGN(FFileDesc,FileAreas.dos_name+'.TXT');
                                     RESET(FFileDesc);
                                     SEEK(FFileDesc,FileDefs.First_Desc-1);
                                     FOR Crud := 1 TO FileDefs.Desc_Lines DO
                                         READ(FFileDesc,FileDesc[Crud]);
                                     CLOSE(FFileDesc);
                                     {ADJUST VARIABLES}
                                     FileIndex.path := FileAreas.area_path;
                                     FileIndex.cd_rom := FileAreas.cd_rom;
                                     FileIndex.area_num := running_count;
                                     FileIndex.area_name := FileAreas.area_name;
                                     FileIndex.area_Sub  := CurrentFileSub;
                                     FileDefs.First_Desc := RunningDescriptions;
                                     {WRITE OUT THE temp FILES}
                                     WRITE(FFileDefs2,FileDefs);
                                     WRITE(FFileIndex,FileIndex);
                                     FOR Crud := 1 TO FileDefs.Desc_Lines DO
                                         WRITE(FFileDesc2,FileDesc[Crud]);
                                     RunningDescriptions := RunningDescriptions+FileDefs.Desc_Lines;
                                     Redraw;
                                END;
                          UNTIL ((EOF(FFileDefs)) OR (Found=1000));
                     END;
                     CLOSE(FFileDefs);
                END;
                IF CommLookAhead=#27 THEN GOTO QuitSearch;
           END;
           SkipIt:
     UNTIL ((EOF(FFileArea)) OR (Found=1000));
     QuitSearch:
     CLOSE(FFileArea);
     CLOSE(FFileDefs2);
     CLOSE(FFileDesc2);
     CLOSE(FFileIndex);
     EndToggle;
     SendCrLf(2);
     bsWriteLog('Search complete : '+_String(Found)+' matches in '+_String(ElapsedTimeInSecs(Timer))+' seconds',False);
     system_prompt(_String(Found),17,true,False);
     GET_ENTER;
     search_date := found;
END;


FUNCTION search_file(SearchType: Char): longint;
VAR  RunningDescriptions : Longint;
     work                : string;
     found               : word;
     loop                : word;
     running_count       : longint;
     FileNumber          : Word;
     Crud                : Longint;
     Timer               : EventTimer;
     IsAWildCard         : Boolean;
     OldValue            : String;
LABEL                      QuitSearch,SkipIt;

     PROCEDURE Redraw;
     VAR  Poop : Word;
     BEGIN
          WRITECHAR(#08);
          FOR Poop := 1 TO (LENGTH(OldValue)+1) DO WRITECHAR(#08);
          OldValue := _String(Found);
          WRITEANSI(OldValue+' ',False,False);
          RedrawToggle;
     END;

     FUNCTION dos_cmp(match_str,in_str: String): Boolean;
     VAR  Match : Boolean;
          i     : Byte;
     BEGIN
          i := 1;
          Match := True;
          WHILE (i<=length(match_str)) AND match DO
          BEGIN
               CASE match_str[i] OF
               '?' :
               ELSE IF match_str[i]<>in_str[i] THEN Match := False;
               END;
               Inc(i);
          END;
          Dos_Cmp := Match;
     END;

     FUNCTION ppadright(st: String;ch:char;l:integer): String;
     VAR  i       : Integer;
          tempstr : String;
     BEGIN
          tempstr := st;
          IF length(tempstr)>l THEN tempstr[0] := chr(l);
          IF length(tempstr)<l THEN
          BEGIN
               FOR i := length(tempstr)+1 TO l DO tempstr[i] := ch;
               tempstr[0] := chr(l);
          END;
          ppadright := tempstr;
     END;

     FUNCTION DosMatch(MatchStr: String; InStr: String): Boolean;
     VAR  i              : BYTE;
          in_pathname    : dirstr;
          match_pathname : dirstr;
          in_filename    : namestr;
          match_filename : namestr;
          in_ext         : extstr;
          match_ext      : extstr;
     BEGIN
          IF IsAWildCard THEN
          BEGIN
               DosMatch := False;
               FSplit(matchstr,match_pathname,match_filename,match_ext);
               FSplit(instr,in_pathname,in_filename,in_ext);
               IF Pos('*',Match_FileName)>0 THEN
               BEGIN
                    Match_FileName := Copy(Match_FileName,1,Pos('*',Match_FileName)-1);
                    Match_FileName := PPadRight(Match_FileName,'?',8);
               END;
               IF Pos('*',Match_Ext)>0 THEN
               BEGIN
                    Match_Ext := Copy(Match_Ext,1,Pos('*',Match_Ext)-1);
                    Match_Ext := PPadRight(Match_Ext,'?',4);
               END;
               IF ((Length(Match_FileName)<Length(In_FileName)) OR (Length(Match_Ext)<Length(In_Ext)))
                  THEN DosMatch := False
                  ELSE DosMatch := dos_cmp(match_filename,in_filename) AND Dos_Cmp(match_ext,in_ext);
          END
          ELSE
          BEGIN
               IF (Pos(MatchStr,InStr)<>0) THEN DosMatch := True
                                           ELSE DosMatch := False;

          END;
     END;

BEGIN
     DisplayGraphicsFile('FILESRCH',false,false,True,True,False);
     Fore(15);   Get_String(12,'',true,false,true,False);
     SendCrLf(1);
     IF input_string='' THEN
     BEGIN
          search_file := 0;
          Exit;
     END;
     work := _UpperCase(input_string);
     bsWriteLog('File search [File] : "'+Work+'"',False);

     IsAWildCard := False;
     IF (Pos('*',Work)<>0) THEN IsAWildCard := True;
     IF (Pos('?',Work)<>0) THEN IsAWildCard := True;

     SendCrLf(1);
     system_prompt('',16,false,True);
     found := 0;
     OldValue := '0';
     running_count := 0;
     RunningDescriptions := 1;
     Fore(Colours.SpinCursor);
     WRITECHAR('0');
     WRITECHAR(' ');
     WRITECHAR(' ');
     StartToggle(0);
     NewTimerSecs(Timer,1440*60);
     ASSIGN(FFileDefs2,NODE_Directory+'\SEARCH$$.FIL');
     ASSIGN(FFileDesc2,NODE_Directory+'\SEARCH$$.TXT');
     ASSIGN(FFileIndex,NODE_Directory+'\SEARCH$$.IDX');
     REWRITE(FFileDefs2);
     REWRITE(FFileDesc2);
     REWRITE(FFileIndex);
     ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(CurrentFileSub)+'.DAT');
     reset(FFileArea);
     REPEAT
           read(FFileArea,FileAreas);
           INC(running_count);
           CASE SearchType OF
           'C': IF (running_count<>CurrentFileArea) THEN GOTO SkipIt;
           'T': IF NOT(IsFileTagged(FileAreas.AreaId)) THEN GOTO SkipIt;
           'S': IF (running_count<>CurrentFileArea) THEN GOTO SkipIt;
           END;
           IF ((FileAreas.dl_access<=UserRecord.security) AND GotTheKeys(UserRecord.Tags,FileAreas.Tags)) THEN
           BEGIN
                IF ((FileAreas.CD_Rom<>0) AND (NOT(IsCDToggled(FileAreas.CD_Rom)))) THEN GOTO SkipIt;
                IF FileAreas.PassThrough THEN GOTO SkipIt;
                DoToggle;
                ASSIGN(FFileDefs,FileAreas.dos_name+'.FIL');
                {$I-}RESET(FFileDefs);{$I+}
                IF IOResult=0 THEN
                BEGIN
                     IF NOT(EOF(FFileDefs)) THEN
                     BEGIN
                          FileNumber := 0;
                          REPEAT
                                READ(FFileDefs,FileDefs);
                                INC(FileNumber);
                                IF DosMatch(Work,_UpperCase(FileDefs.file_name)) THEN
                                BEGIN
                                     INC(found);
                                     ASSIGN(FFileDesc,FileAreas.dos_name+'.TXT');
                                     RESET(FFileDesc);
                                     SEEK(FFileDesc,FileDefs.First_Desc-1);
                                     FOR Crud := 1 TO FileDefs.Desc_Lines DO
                                         READ(FFileDesc,FileDesc[Crud]);
                                     CLOSE(FFileDesc);
                                     {ADJUST VARIABLES}
                                     FileIndex.path := FileAreas.area_path;
                                     FileIndex.cd_rom := FileAreas.cd_rom;
                                     FileIndex.area_num := running_count;
                                     FileIndex.area_name := FileAreas.area_name;
                                     FileIndex.area_Sub  := CurrentFileSub;
                                     FileDefs.First_Desc := RunningDescriptions;
                                     {WRITE OUT THE temp FILES}
                                     WRITE(FFileDefs2,FileDefs);
                                     WRITE(FFileIndex,FileIndex);
                                     FOR Crud := 1 TO FileDefs.Desc_Lines DO
                                         WRITE(FFileDesc2,FileDesc[Crud]);
                                     RunningDescriptions := RunningDescriptions+FileDefs.Desc_Lines;
                                     Redraw;
                                END;
                          UNTIL ((EOF(FFileDefs)) OR (Found=1000));
                     END;
                     CLOSE(FFileDefs);
                END;
                IF CommLookAhead=#27 THEN GOTO QuitSearch;
           END;
           SkipIt:
     UNTIL ((EOF(FFileArea)) OR (Found=1000));
     QuitSearch:
     CLOSE(FFileArea);
     CLOSE(FFileDefs2);
     CLOSE(FFileDesc2);
     CLOSE(FFileIndex);
     EndToggle;
     SendCrLf(2);
     bsWriteLog('Search complete : '+_String(Found)+' matches in '+_String(ElapsedTimeInSecs(Timer))+' seconds',False);
     system_prompt(_String(Found),17,true,False);
     GET_ENTER;
     search_file := found;
END;


FUNCTION search_new(Logon: Boolean): longint;
VAR  RunningDescriptions : Longint;
     work                : string;
     found               : word;
     loop                : word;
     running_count       : longint;
     FileNumber          : Word;
     Crud                : Longint;
     Timer               : EventTimer;
     GotIt               : Boolean;
     ScanGroups          : Array[1..2048] Of Word;
     NumGroups           : Word;
     OldValue            : String;
LABEL                      QuitSearch;

     PROCEDURE Redraw;
     VAR  Poop : Word;
     BEGIN
          WRITECHAR(#08);
          FOR Poop := 1 TO (LENGTH(OldValue)+1) DO WRITECHAR(#08);
          OldValue := _String(Found);
          WRITEANSI(OldValue+' ',False,False);
          RedrawToggle;
     END;

BEGIN
     system_prompt('',18,false,True);
     found := 0;
     OldValue := '0';
     running_count := 0;
     RunningDescriptions := 1;
     bsWriteLog('File search [NEW]',False);

     NumGroups  := 0;
     ASSIGN(FFileSubs,DATA_Directory+'\FILEAREA.SUB');
     RESET(FFileSubs);
     REPEAT
           READ(FFileSubs,FileSubs);
           IF FileSubs.ScanAtLogon THEN
           BEGIN
                INC(NumGroups);
                ScanGroups[NumGroups] := FileSubs.Sub_Num;
           END;
     UNTIL EOF(FFileSubs);
     CLOSE(FFileSubs);

     NewTimerSecs(Timer,1440*60);
     ASSIGN(FFileDefs2,NODE_Directory+'\SEARCH$$.FIL');
     ASSIGN(FFileDesc2,NODE_Directory+'\SEARCH$$.TXT');
     ASSIGN(FFileIndex,NODE_Directory+'\SEARCH$$.IDX');
     REWRITE(FFileDefs2);
     REWRITE(FFileDesc2);
     REWRITE(FFileIndex);
     ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(CurrentFileSub)+'.DAT');
     reset(FFileArea);
     Fore(Colours.SpinCursor);
     WRITECHAR('0');
     WRITECHAR(' ');
     WRITECHAR(' ');
     StartToggle(0);
     REPEAT
           read(FFileArea,FileAreas);
           INC(running_count);
           IF FileAreas.cd_rom=0 THEN
           BEGIN
                GotIt := False;
                IF Logon THEN
                BEGIN
                     FOR Loop := 1 TO NumGroups DO
                     BEGIN
                          IF ScanGroups[Loop]=FileAreas.Sub THEN GotIt := True;
                     END;
                END
                ELSE GotIt := True;
                IF FileAreas.PassThrough THEN GotIt := False;
                IF ((GotIt) AND (FileAreas.dl_access<=UserRecord.security) AND GotTheKeys(UserRecord.Tags,FileAreas.Tags)) THEN
                BEGIN
                     DoToggle;
                     ASSIGN(FFileDefs,FileAreas.dos_name+'.FIL');
                     {$I-}RESET(FFileDefs);{$I+}
                     IF IOResult=0 THEN
                     BEGIN
                          IF NOT(EOF(FFileDefs)) THEN
                          BEGIN
                               FileNumber := 0;
                               REPEAT
                                     READ(FFileDefs,FileDefs);
                                     INC(FileNumber);
                                     IF (FileDefs.added_date>UserRecord.last_logoff) THEN
                                     BEGIN
                                          INC(found);
                                          ASSIGN(FFileDesc,FileAreas.dos_name+'.TXT');
                                          RESET(FFileDesc);
                                          SEEK(FFileDesc,FileDefs.First_Desc-1);
                                          FOR Crud := 1 TO FileDefs.Desc_Lines DO
                                              READ(FFileDesc,FileDesc[Crud]);
                                          CLOSE(FFileDesc);
                                          {ADJUST VARIABLES}
                                          FileIndex.path := FileAreas.area_path;
                                          FileIndex.cd_rom := FileAreas.cd_rom;
                                          FileIndex.area_num := running_count;
                                          FileIndex.area_name := FileAreas.area_name;
                                          FileIndex.area_Sub  := CurrentFileSub;
                                          FileDefs.First_Desc := RunningDescriptions;
                                          {WRITE OUT THE temp FILES}
                                          WRITE(FFileDefs2,FileDefs);
                                          WRITE(FFileIndex,FileIndex);
                                          FOR Crud := 1 TO FileDefs.Desc_Lines DO
                                              WRITE(FFileDesc2,FileDesc[Crud]);
                                          RunningDescriptions := RunningDescriptions+FileDefs.Desc_Lines;
                                          Redraw;
                                     END;
                               UNTIL ((EOF(FFileDefs)) OR (Found=1000));
                          END;
                          CLOSE(FFileDefs);
                     END;
                     IF CommLookAhead=#27 THEN GOTO QuitSearch;
                END;
           END;
     UNTIL ((EOF(FFileArea)) OR (Found=1000));
     QuitSearch:
     CLOSE(FFileArea);
     CLOSE(FFileDefs2);
     CLOSE(FFileDesc2);
     CLOSE(FFileIndex);
     EndToggle;
     SendCrLf(2);
     search_new := found;
     bsWriteLog('Search complete : '+_String(found)+' matches in '+_String(ElapsedTimeInSecs(Timer))+' seconds',False);
     IF found=0 THEN system_prompt('',19,true,False)
                ELSE system_prompt(_String(Found),17,true,False);
     Get_Enter;
END;


END.
