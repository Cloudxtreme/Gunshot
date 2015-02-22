{$I DEFINES.INC}
UNIT FileSrch;


INTERFACE


PROCEDURE file_search  (SearchType: Char);
FUNCTION  search_file  (SearchType: Char): longint;
FUNCTION  search_date  (SearchType: Char): longint;
FUNCTION  search_text  (SearchType: Char): longint;
FUNCTION  search_new   (Logon: Boolean)  : longint;


IMPLEMENTATION


USES Screens,Globals,KeyInput,ChangeFA,ListFile,ApTimer,BsString,
     BsLog,Toggle,MiscStr,TagArea,GotKeys,Dos,Gfx,CDS,Time;


PROCEDURE file_search(SearchType: Char);
VAR  c            : char;
     number_files : word;
BEGIN
     DisplayGraphicFile('SEARCHES',False,True,True);
     c := UpCase(Get_Menu_Selection('CATSQ',#0));
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
LABEL                      QuitSearch,SkipIt;
BEGIN
     DisplayGraphicFile('TEXTSRCH',False,True,True);
     Get_Enter;
     IF Fields[1].Text='' THEN
     BEGIN
          search_text := 0;
          Exit;
     END;
     work := _UpperCase(Fields[1].Text);
     bsWriteLog('File search [Text] : "'+work+'"',True);
     system_prompt('',16);
     found               := 0;
     running_count       := 0;
     RunningDescriptions := 1;
     NewTimerSecs(Timer,1440*60);
     ASSIGN(FFileDefs2,NODE_Directory+'\SEARCH$$.FIL');
     ASSIGN(FFileDesc2,NODE_Directory+'\SEARCH$$.TXT');
     ASSIGN(FFileIndex,NODE_Directory+'\SEARCH$$.IDX');
     REWRITE(FFileDefs2);
     REWRITE(FFileDesc2);
     REWRITE(FFileIndex);
     ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(CurrentFileSub)+'.DAT');
     RESET(FFileArea);
     StartToggle(FileSize(FFileArea));
     REPEAT
           DoToggle;
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
                ASSIGN(FFileDesc,FileAreas.dos_name+'.TXT');
                {$I-}
                RESET(FFileDesc);
                {$I+}
                IF IOResult = 0 THEN
                BEGIN
                     ASSIGN(FFileDefs,FileAreas.dos_name+'.FIL');
                     RESET(FFileDefs);
                     IF NOT(EOF(FFileDesc)) THEN
                     BEGIN
                          REPEAT
                                READ(FFileDefs,FileDefs);
                                FOR Crud := 1 TO FileDefs.Desc_Lines DO
                                    READ(FFileDesc,FileDesc[Crud]);
                                FoundIt := False;
                                FOR Loop := 1 TO FileDefs.Desc_Lines DO
                                BEGIN
                                     IF NOT(FoundIt) THEN
                                     IF (Pos(work,_UpperCase(FileDesc[Loop].desc))<>0) THEN FoundIt := True;
                                END;
                                IF FoundIt=True THEN
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
                                     FOR Crud := 1 TO FileDefs.Desc_Lines DO
                                         WRITE(FFileDesc2,FileDesc[Crud]);
                                     RunningDescriptions := RunningDescriptions+FileDefs.Desc_Lines;
                                END;
                          UNTIL ((EOF(FFileDesc)) OR (Found=1000));
                     END;
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
     bsWriteLog('Search complete : '+_String(Found)+' matches in '+_String(ElapsedTimeInSecs(Timer))+' seconds',True);
     system_prompt(_String(Found),17);
     Get_Enter;
     search_text := found;
END;


FUNCTION search_date(SearchType: Char): longint;
VAR  RunningDescriptions : Longint;
     found               : word;
     loop                : word;
     DT                  : DateTime;
     s_date              : longint;
     working             : longint;
     running_count       : longint;
     FileNumber          : Word;
     Crud                : LongInt;
     Timer               : EventTimer;
     Temp                : String;
LABEL                      QuitSearch,SkipIt;
BEGIN
     DisplayGraphicFile('DATESRCH',False,True,True);
     Get_Enter;
     IF Fields[1].Text='  /  /  ' THEN
     BEGIN
          search_date := 0;
          Exit;
     END;
     FillChar(DT,SizeOf(DT),0);
     CASE System_Info.DateFormat OF
     1:   BEGIN {MM/DD/YY}
               DT.Year  := _Numeric(_Mid(Fields[1].Text,7,8))+1900;
               DT.Month := _Numeric(_Mid(Fields[1].Text,1,2));
               DT.Day   := _Numeric(_Mid(Fields[1].Text,4,5));
          END;
     2:   BEGIN {DD/MM/YY}
               DT.Year  := _Numeric(_Mid(Fields[1].Text,7,8))+1900;
               DT.Month := _Numeric(_Mid(Fields[1].Text,4,5));
               DT.Day   := _Numeric(_Mid(Fields[1].Text,1,2));
          END;
     3:   BEGIN {YY/MM/DD}
               DT.Year  := _Numeric(_Mid(Fields[1].Text,1,2))+1900;
               DT.Month := _Numeric(_Mid(Fields[1].Text,4,5));
               DT.Day   := _Numeric(_Mid(Fields[1].Text,7,8));
          END;
     END;
     PackTime(DT,s_date);
     Temp := _Mid(Fields[1].Text,1,2)+'/'+
             _Mid(Fields[1].Text,4,5)+'/'+
             _Mid(Fields[1].Text,7,8);
     bsWriteLog('File search [Date] : "'+Temp+'"',True);
     system_prompt('',16);
     found       := 0;
     running_count := 0;
     RunningDescriptions := 1;
     NewTimerSecs(Timer,1440*60);
     ASSIGN(FFileDefs2,NODE_Directory+'\SEARCH$$.FIL');
     ASSIGN(FFileDesc2,NODE_Directory+'\SEARCH$$.TXT');
     ASSIGN(FFileIndex,NODE_Directory+'\SEARCH$$.IDX');
     REWRITE(FFileDefs2);
     REWRITE(FFileDesc2);
     REWRITE(FFileIndex);
     ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(CurrentFileSub)+'.DAT');
     RESET(FFileArea);
     StartToggle(FileSize(FFileArea));
     REPEAT
           DoToggle;
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
                ASSIGN(FFileDefs,FileAreas.dos_name+'.FIL');
                {$I-}
                RESET(FFileDefs);
                {$I+}
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
     bsWriteLog('Search complete : '+_String(Found)+' matches in '+_String(ElapsedTimeInSecs(Timer))+' seconds',True);
     system_prompt(_String(Found),17);
     Get_Enter;
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
LABEL                      QuitSearch,SkipIt;

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
     DisplayGraphicFile('FILESRCH',False,True,True);
     Get_Enter;
     IF Fields[1].Text='' THEN
     BEGIN
          search_file := 0;
          Exit;
     END;
     work := _UpperCase(Fields[1].Text);
     bsWriteLog('File search [File] : "'+Work+'"',True);

     IsAWildCard := False;
     IF (Pos('*',Work)<>0) THEN IsAWildCard := True;
     IF (Pos('?',Work)<>0) THEN IsAWildCard := True;

     system_prompt('',16);
     found       := 0;
     running_count := 0;
     RunningDescriptions := 1;
     NewTimerSecs(Timer,1440*60);
     ASSIGN(FFileDefs2,NODE_Directory+'\SEARCH$$.FIL');
     ASSIGN(FFileDesc2,NODE_Directory+'\SEARCH$$.TXT');
     ASSIGN(FFileIndex,NODE_Directory+'\SEARCH$$.IDX');
     REWRITE(FFileDefs2);
     REWRITE(FFileDesc2);
     REWRITE(FFileIndex);
     ASSIGN(FFileArea,DATA_Directory+'\FA'+ZeroPadded(CurrentFileSub)+'.DAT');
     RESET(FFileArea);
     StartToggle(FileSize(FFileArea));
     REPEAT
           DoToggle;
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
                ASSIGN(FFileDefs,FileAreas.dos_name+'.FIL');
                {$I-}
                RESET(FFileDefs);
                {$I+}
                IF IOResult = 0 THEN
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
     bsWriteLog('Search complete : '+_String(Found)+' matches in '+_String(ElapsedTimeInSecs(Timer))+' seconds',True);
     system_prompt(_String(Found),17);
     Get_Enter;
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
LABEL                      QuitSearch;
BEGIN
     system_prompt('',18);
     RunningDescriptions := 1;
     running_count       := 0;
     found               := 0;
     bsWriteLog('File search [NEW]',True);

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
     StartToggle(FileSize(FFileArea));
     REPEAT
           DoToggle;
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
                     ASSIGN(FFileDefs,FileAreas.dos_name+'.FIL');
                     {$I-}
                     RESET(FFileDefs);
                     {$I+}
                     IF IOResult = 0 THEN
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
     search_new := found;
     bsWriteLog('Search complete : '+_String(found)+' matches in '+_String(ElapsedTimeInSecs(Timer))+' seconds',True);
     IF found=0 THEN system_prompt('',19)
                ELSE system_prompt(_String(Found),17);
     Get_Enter;
END;


END.
