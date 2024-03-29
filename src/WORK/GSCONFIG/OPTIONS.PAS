{$I DEFINES.INC}
UNIT Options;


INTERFACE


USES CnfgVars;


CONST NumberOfOptions = 119;


PROCEDURE GetOption(Num: Word);


IMPLEMENTATION


PROCEDURE GetOption(Num: Word);
BEGIN
     CASE Num OF
     1   : BEGIN O.N := 1;   O.V := 'System������� Load Menu                 '; END;
     2   : BEGIN O.N := 2;   O.V := '           �� Page The Sysop            '; END;
     3   : BEGIN O.N := 102; O.V := '           �� Comment To Sysop          '; END;
     4   : BEGIN O.N := 3;   O.V := '           �� Quick Logoff              '; END;
     5   : BEGIN O.N := 4;   O.V := '           �� Logoff With Goodbye       '; END;
     6   : BEGIN O.N := 112; O.V := '           �� Translated Text File      '; END;
     7   : BEGIN O.N := 8;   O.V := '           �� Run DOS Door (ANSI)       '; END;
     8   : BEGIN O.N := 115; O.V := '           �� Run SVGA Door (SVGA)      '; END;
     9   : BEGIN O.N := 40;  O.V := '           �� Show Last Callers         '; END;
     10  : BEGIN O.N := 43;  O.V := '           �� Show News Screens         '; END;
     11  : BEGIN O.N := 6;   O.V := '           �� Show ANSI/ASC/SG          '; END;
     12  : BEGIN O.N := 44;  O.V := '           �� Show Text File (Reader)   '; END;
     13  : BEGIN O.N := 103; O.V := '           �� Show User List            '; END;
     14  : BEGIN O.N := 46;  O.V := '           �� Execute Call Back Verifier'; END;
     15  : BEGIN O.N := 133; O.V := '           �� Execute CD Rom Manager    '; END;
     16  : BEGIN O.N := 110; O.V := '           �� Execute Data Entry Screen '; END;
     17  : BEGIN O.N := 111; O.V := '           �� Execute Dial Through      '; END;
     18  : BEGIN O.N := 108; O.V := '           �� Play VOC File (SVGA)      '; END;
     19  : BEGIN O.N := 113; O.V := '           �� Play FLI File (SVGA)      '; END;
     20  : BEGIN O.N := 122; O.V := '           �� GIP Directory (SVGA)      '; END;
     21  : BEGIN O.N := 52;  O.V := 'User��������� Time Bank Deposit         '; END;
     22  : BEGIN O.N := 53;  O.V := '           �� Time Bank Withdraw        '; END;
     23  : BEGIN O.N := 54;  O.V := '           �� Byte Bank Deposit         '; END;
     24  : BEGIN O.N := 55;  O.V := '           �� Byte Bank Withdraw        '; END;
     25  : BEGIN O.N := 5;   O.V := '           �� Comment To Next Caller    '; END;
     26  : BEGIN O.N := 106; O.V := '           �� User FileBox              '; END;
     27  : BEGIN O.N := 88;  O.V := '           �� Upload ANSI Signature     '; END;
     28  : BEGIN O.N := 63;  O.V := 'User Info���� Users Real Name           '; END;
     29  : BEGIN O.N := 64;  O.V := '           �� Users Alias Name          '; END;
     30  : BEGIN O.N := 65;  O.V := '           �� Users Password            '; END;
     31  : BEGIN O.N := 66;  O.V := '           �� Users Voice Number        '; END;
     32  : BEGIN O.N := 67;  O.V := '           �� Users Data Number         '; END;
     33  : BEGIN O.N := 68;  O.V := '           �� Users Street Address      '; END;
     34  : BEGIN O.N := 69;  O.V := '           �� Users City                '; END;
     35  : BEGIN O.N := 70;  O.V := '           �� Users Province/State      '; END;
     36  : BEGIN O.N := 71;  O.V := '           �� Users Country             '; END;
     37  : BEGIN O.N := 72;  O.V := '           �� Users Postal/ZIP Code     '; END;
     38  : BEGIN O.N := 73;  O.V := '           �� Users BBS Name            '; END;
     39  : BEGIN O.N := 74;  O.V := '           �� Users BBS Network Number  '; END;
     40  : BEGIN O.N := 75;  O.V := '           �� Users BBS Phone Number    '; END;
     41  : BEGIN O.N := 76;  O.V := '           �� Users Birthday            '; END;
     42  : BEGIN O.N := 97;  O.V := '           �� Users Note/Comment        '; END;
     43  : BEGIN O.N := 77;  O.V := '           �� Toggle Users Gender       '; END;
     44  : BEGIN O.N := 78;  O.V := '           �� Toggle IBM Characters     '; END;
     45  : BEGIN O.N := 79;  O.V := '           �� Toggle ANSI Graphics      '; END;
     46  : BEGIN O.N := 80;  O.V := '           �� Toggle Clear Screen Codes '; END;
     47  : BEGIN O.N := 81;  O.V := '           �� Toggle Message Editor     '; END;
     48  : BEGIN O.N := 82;  O.V := '           �� Toggle "In Userlist"      '; END;
     49  : BEGIN O.N := 84;  O.V := '           �� Toggle File Seperator     '; END;
     50  : BEGIN O.N := 101; O.V := '           �� Toggle Users Page Flag    '; END;
     51  : BEGIN O.N := 123; O.V := '           �� Select Protocol (ANSI)    '; END;
     52  : BEGIN O.N := 124; O.V := '           �� Select Archiver           '; END;
     53  : BEGIN O.N := 134; O.V := '           �� Select Quoting Option     '; END;
     54  : BEGIN O.N := 83;  O.V := '           �� Number Of File Desc Lines '; END;
     55  : BEGIN O.N := 60;  O.V := 'Chat Mode���� List Users Online         '; END;
     56  : BEGIN O.N := 62;  O.V := '           �� Page Another User         '; END;
     57  : BEGIN O.N := 61;  O.V := '           �� Enter Chat Mode           '; END;
     58  : BEGIN O.N := 25;  O.V := 'MSG Areas���� Write MSG  - Current Area '; END;
     59  : BEGIN O.N := 28;  O.V := '           �� Write MSG  - Select Area  '; END;
     60  : BEGIN O.N := 35;  O.V := '           �� Write MSG  - Fixed Area   '; END;
     61  : BEGIN O.N := 114; O.V := '           �� Write MSG  - Fixed User   '; END;
     62  : BEGIN O.N := 104; O.V := '           �� Group MSG  - Current Area '; END;
     63  : BEGIN O.N := 105; O.V := '           �� Group MSG  - Select Area  '; END;
     64  : BEGIN O.N := 26;  O.V := '           �� Read MSG   - Current Area '; END;
     65  : BEGIN O.N := 27;  O.V := '           �� Read MSG   - Select Area  '; END;
     66  : BEGIN O.N := 85;  O.V := '           �� List MSG   - Current Area '; END;
     67  : BEGIN O.N := 45;  O.V := '           �� List MSG   - Select Area  '; END;
     68  : BEGIN O.N := 86;  O.V := '           �� Goto MSG   - Current Area '; END;
     69  : BEGIN O.N := 36;  O.V := '           �� Goto MSG   - Select Area  '; END;
     70  : BEGIN O.N := 37;  O.V := '           �� Upload MSG - Current Area '; END;
     71  : BEGIN O.N := 87;  O.V := '           �� Upload MSG - Select Area  '; END;
     72  : BEGIN O.N := 22;  O.V := '           �� Change Message Area (Next)'; END;
     73  : BEGIN O.N := 23;  O.V := '           �� Change Message Area (Prev)'; END;
     74  : BEGIN O.N := 24;  O.V := '           �� Change Message Area (List)'; END;
     75  : BEGIN O.N := 31;  O.V := '           �� Mail Scan - New Personal  '; END;
     76  : BEGIN O.N := 32;  O.V := '           �� Mail Scan - All Personal  '; END;
     77  : BEGIN O.N := 20;  O.V := '           �� Mail Scan - All New       '; END;
     78  : BEGIN O.N := 21;  O.V := '           �� Mail Scan - All           '; END;
     79  : BEGIN O.N := 107; O.V := '           �� Mail Scan - Search String '; END;
     80  : BEGIN O.N := 96;  O.V := '           �� Set MSG Sub Group         '; END;
     81  : BEGIN O.N := 116; O.V := '           �� Change MSG Group (Next)   '; END;
     82  : BEGIN O.N := 117; O.V := '           �� Change MSG Group (Prev)   '; END;
     83  : BEGIN O.N := 118; O.V := '           �� Change MSG Group (List)   '; END;
     84  : BEGIN O.N := 90;  O.V := '           �� Reset LRPs - End Of Base  '; END;
     85  : BEGIN O.N := 109; O.V := '           �� Reset LRPs - Start Of Base'; END;
     86  : BEGIN O.N := 125; O.V := '           �� Reset LRPs - Last xxx Msgs'; END;
     87  : BEGIN O.N := 126; O.V := '           �� Reset LRPs - Skip xxx Msgs'; END;
     88  : BEGIN O.N := 29;  O.V := '           �� Delete Old Mail           '; END;
     89  : BEGIN O.N := 91;  O.V := 'QWK Mail����� Pack QWK - New Personal   '; END;
     90  : BEGIN O.N := 92;  O.V := '           �� Pack QWK - All Personal   '; END;
     91  : BEGIN O.N := 93;  O.V := '           �� Pack QWK - All New        '; END;
     92  : BEGIN O.N := 94;  O.V := '           �� Pack QWK - All            '; END;
     93  : BEGIN O.N := 98;  O.V := '           �� UL/Toss REP Replies       '; END;
     94  : BEGIN O.N := 34;  O.V := 'File Areas��� List Files - Current Area '; END;
     95  : BEGIN O.N := 33;  O.V := '           �� List Files - Select Area  '; END;
     96  : BEGIN O.N := 10;  O.V := '           �� Change File Area (Next)   '; END;
     97  : BEGIN O.N := 11;  O.V := '           �� Change File Area (Prev)   '; END;
     98  : BEGIN O.N := 12;  O.V := '           �� Change File Area (List)   '; END;
     99  : BEGIN O.N := 13;  O.V := '           �� Download File Queue       '; END;
     100 : BEGIN O.N := 18;  O.V := '           �� Download File With Path   '; END;
     101 : BEGIN O.N := 15;  O.V := '           �� UL File(s) - Fixed Area   '; END;
     102 : BEGIN O.N := 16;  O.V := '           �� UL File(s) - Current Area '; END;
     103 : BEGIN O.N := 17;  O.V := '           �� UL File(s) - Select Area  '; END;
     104 : BEGIN O.N := 39;  O.V := '           �� Private Upload To Sysop   '; END;
     105 : BEGIN O.N := 42;  O.V := '           �� New Files Scan            '; END;
     106 : BEGIN O.N := 47;  O.V := '           �� File Search - File Name   '; END;
     107 : BEGIN O.N := 48;  O.V := '           �� File Search - File Date   '; END;
     108 : BEGIN O.N := 49;  O.V := '           �� File Search - Text Search '; END;
     109 : BEGIN O.N := 95;  O.V := '           �� Set File Sub Group        '; END;
     110 : BEGIN O.N := 119; O.V := '           �� Change File Group (Next)  '; END;
     111 : BEGIN O.N := 120; O.V := '           �� Change File Group (Prev)  '; END;
     112 : BEGIN O.N := 121; O.V := '           �� Change File Group (List)  '; END;
     113 : BEGIN O.N := 50;  O.V := '           �� Generate File List        '; END;
     114 : BEGIN O.N := 127; O.V := 'Save/Load ��� Save MSG Group/Area       '; END;
     115 : BEGIN O.N := 128; O.V := '           �� Load MSG Group/Area       '; END;
     116 : BEGIN O.N := 129; O.V := '           �� Save File Group/Area      '; END;
     117 : BEGIN O.N := 130; O.V := '           �� Load File Group/Area      '; END;
     118 : BEGIN O.N := 131; O.V := '           �� Save Menu                 '; END;
     119 : BEGIN O.N := 132; O.V := '           �� Load Menu                 '; END;
     ELSE  BEGIN O.N := 0;   O.V := ''                                        ; END;
     END;
END;


END.