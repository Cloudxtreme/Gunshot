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
     1   : BEGIN O.N := 1;   O.V := 'System컴컴컫� Load Menu                 '; END;
     2   : BEGIN O.N := 2;   O.V := '           쳐 Page The Sysop            '; END;
     3   : BEGIN O.N := 102; O.V := '           쳐 Comment To Sysop          '; END;
     4   : BEGIN O.N := 3;   O.V := '           쳐 Quick Logoff              '; END;
     5   : BEGIN O.N := 4;   O.V := '           쳐 Logoff With Goodbye       '; END;
     6   : BEGIN O.N := 112; O.V := '           쳐 Translated Text File      '; END;
     7   : BEGIN O.N := 8;   O.V := '           쳐 Run DOS Door (ANSI)       '; END;
     8   : BEGIN O.N := 115; O.V := '           쳐 Run SVGA Door (SVGA)      '; END;
     9   : BEGIN O.N := 40;  O.V := '           쳐 Show Last Callers         '; END;
     10  : BEGIN O.N := 43;  O.V := '           쳐 Show News Screens         '; END;
     11  : BEGIN O.N := 6;   O.V := '           쳐 Show ANSI/ASC/SG          '; END;
     12  : BEGIN O.N := 44;  O.V := '           쳐 Show Text File (Reader)   '; END;
     13  : BEGIN O.N := 103; O.V := '           쳐 Show User List            '; END;
     14  : BEGIN O.N := 46;  O.V := '           쳐 Execute Call Back Verifier'; END;
     15  : BEGIN O.N := 133; O.V := '           쳐 Execute CD Rom Manager    '; END;
     16  : BEGIN O.N := 110; O.V := '           쳐 Execute Data Entry Screen '; END;
     17  : BEGIN O.N := 111; O.V := '           쳐 Execute Dial Through      '; END;
     18  : BEGIN O.N := 108; O.V := '           쳐 Play VOC File (SVGA)      '; END;
     19  : BEGIN O.N := 113; O.V := '           쳐 Play FLI File (SVGA)      '; END;
     20  : BEGIN O.N := 122; O.V := '           읕 GIP Directory (SVGA)      '; END;
     21  : BEGIN O.N := 52;  O.V := 'User컴컴컴컫� Time Bank Deposit         '; END;
     22  : BEGIN O.N := 53;  O.V := '           쳐 Time Bank Withdraw        '; END;
     23  : BEGIN O.N := 54;  O.V := '           쳐 Byte Bank Deposit         '; END;
     24  : BEGIN O.N := 55;  O.V := '           쳐 Byte Bank Withdraw        '; END;
     25  : BEGIN O.N := 5;   O.V := '           쳐 Comment To Next Caller    '; END;
     26  : BEGIN O.N := 106; O.V := '           쳐 User FileBox              '; END;
     27  : BEGIN O.N := 88;  O.V := '           읕 Upload ANSI Signature     '; END;
     28  : BEGIN O.N := 63;  O.V := 'User Info컴쩡 Users Real Name           '; END;
     29  : BEGIN O.N := 64;  O.V := '           쳐 Users Alias Name          '; END;
     30  : BEGIN O.N := 65;  O.V := '           쳐 Users Password            '; END;
     31  : BEGIN O.N := 66;  O.V := '           쳐 Users Voice Number        '; END;
     32  : BEGIN O.N := 67;  O.V := '           쳐 Users Data Number         '; END;
     33  : BEGIN O.N := 68;  O.V := '           쳐 Users Street Address      '; END;
     34  : BEGIN O.N := 69;  O.V := '           쳐 Users City                '; END;
     35  : BEGIN O.N := 70;  O.V := '           쳐 Users Province/State      '; END;
     36  : BEGIN O.N := 71;  O.V := '           쳐 Users Country             '; END;
     37  : BEGIN O.N := 72;  O.V := '           쳐 Users Postal/ZIP Code     '; END;
     38  : BEGIN O.N := 73;  O.V := '           쳐 Users BBS Name            '; END;
     39  : BEGIN O.N := 74;  O.V := '           쳐 Users BBS Network Number  '; END;
     40  : BEGIN O.N := 75;  O.V := '           쳐 Users BBS Phone Number    '; END;
     41  : BEGIN O.N := 76;  O.V := '           쳐 Users Birthday            '; END;
     42  : BEGIN O.N := 97;  O.V := '           쳐 Users Note/Comment        '; END;
     43  : BEGIN O.N := 77;  O.V := '           쳐 Toggle Users Gender       '; END;
     44  : BEGIN O.N := 78;  O.V := '           쳐 Toggle IBM Characters     '; END;
     45  : BEGIN O.N := 79;  O.V := '           쳐 Toggle ANSI Graphics      '; END;
     46  : BEGIN O.N := 80;  O.V := '           쳐 Toggle Clear Screen Codes '; END;
     47  : BEGIN O.N := 81;  O.V := '           쳐 Toggle Message Editor     '; END;
     48  : BEGIN O.N := 82;  O.V := '           쳐 Toggle "In Userlist"      '; END;
     49  : BEGIN O.N := 84;  O.V := '           쳐 Toggle File Seperator     '; END;
     50  : BEGIN O.N := 101; O.V := '           쳐 Toggle Users Page Flag    '; END;
     51  : BEGIN O.N := 123; O.V := '           쳐 Select Protocol (ANSI)    '; END;
     52  : BEGIN O.N := 124; O.V := '           쳐 Select Archiver           '; END;
     53  : BEGIN O.N := 134; O.V := '           쳐 Select Quoting Option     '; END;
     54  : BEGIN O.N := 83;  O.V := '           읕 Number Of File Desc Lines '; END;
     55  : BEGIN O.N := 60;  O.V := 'Chat Mode컴쩡 List Users Online         '; END;
     56  : BEGIN O.N := 62;  O.V := '           쳐 Page Another User         '; END;
     57  : BEGIN O.N := 61;  O.V := '           읕 Enter Chat Mode           '; END;
     58  : BEGIN O.N := 25;  O.V := 'MSG Areas컴쩡 Write MSG  - Current Area '; END;
     59  : BEGIN O.N := 28;  O.V := '           쳐 Write MSG  - Select Area  '; END;
     60  : BEGIN O.N := 35;  O.V := '           쳐 Write MSG  - Fixed Area   '; END;
     61  : BEGIN O.N := 114; O.V := '           쳐 Write MSG  - Fixed User   '; END;
     62  : BEGIN O.N := 104; O.V := '           쳐 Group MSG  - Current Area '; END;
     63  : BEGIN O.N := 105; O.V := '           쳐 Group MSG  - Select Area  '; END;
     64  : BEGIN O.N := 26;  O.V := '           쳐 Read MSG   - Current Area '; END;
     65  : BEGIN O.N := 27;  O.V := '           쳐 Read MSG   - Select Area  '; END;
     66  : BEGIN O.N := 85;  O.V := '           쳐 List MSG   - Current Area '; END;
     67  : BEGIN O.N := 45;  O.V := '           쳐 List MSG   - Select Area  '; END;
     68  : BEGIN O.N := 86;  O.V := '           쳐 Goto MSG   - Current Area '; END;
     69  : BEGIN O.N := 36;  O.V := '           쳐 Goto MSG   - Select Area  '; END;
     70  : BEGIN O.N := 37;  O.V := '           쳐 Upload MSG - Current Area '; END;
     71  : BEGIN O.N := 87;  O.V := '           쳐 Upload MSG - Select Area  '; END;
     72  : BEGIN O.N := 22;  O.V := '           쳐 Change Message Area (Next)'; END;
     73  : BEGIN O.N := 23;  O.V := '           쳐 Change Message Area (Prev)'; END;
     74  : BEGIN O.N := 24;  O.V := '           쳐 Change Message Area (List)'; END;
     75  : BEGIN O.N := 31;  O.V := '           쳐 Mail Scan - New Personal  '; END;
     76  : BEGIN O.N := 32;  O.V := '           쳐 Mail Scan - All Personal  '; END;
     77  : BEGIN O.N := 20;  O.V := '           쳐 Mail Scan - All New       '; END;
     78  : BEGIN O.N := 21;  O.V := '           쳐 Mail Scan - All           '; END;
     79  : BEGIN O.N := 107; O.V := '           쳐 Mail Scan - Search String '; END;
     80  : BEGIN O.N := 96;  O.V := '           쳐 Set MSG Sub Group         '; END;
     81  : BEGIN O.N := 116; O.V := '           쳐 Change MSG Group (Next)   '; END;
     82  : BEGIN O.N := 117; O.V := '           쳐 Change MSG Group (Prev)   '; END;
     83  : BEGIN O.N := 118; O.V := '           쳐 Change MSG Group (List)   '; END;
     84  : BEGIN O.N := 90;  O.V := '           쳐 Reset LRPs - End Of Base  '; END;
     85  : BEGIN O.N := 109; O.V := '           쳐 Reset LRPs - Start Of Base'; END;
     86  : BEGIN O.N := 125; O.V := '           쳐 Reset LRPs - Last xxx Msgs'; END;
     87  : BEGIN O.N := 126; O.V := '           쳐 Reset LRPs - Skip xxx Msgs'; END;
     88  : BEGIN O.N := 29;  O.V := '           읕 Delete Old Mail           '; END;
     89  : BEGIN O.N := 91;  O.V := 'QWK Mail컴컫� Pack QWK - New Personal   '; END;
     90  : BEGIN O.N := 92;  O.V := '           쳐 Pack QWK - All Personal   '; END;
     91  : BEGIN O.N := 93;  O.V := '           쳐 Pack QWK - All New        '; END;
     92  : BEGIN O.N := 94;  O.V := '           쳐 Pack QWK - All            '; END;
     93  : BEGIN O.N := 98;  O.V := '           읕 UL/Toss REP Replies       '; END;
     94  : BEGIN O.N := 34;  O.V := 'File Areas컫� List Files - Current Area '; END;
     95  : BEGIN O.N := 33;  O.V := '           쳐 List Files - Select Area  '; END;
     96  : BEGIN O.N := 10;  O.V := '           쳐 Change File Area (Next)   '; END;
     97  : BEGIN O.N := 11;  O.V := '           쳐 Change File Area (Prev)   '; END;
     98  : BEGIN O.N := 12;  O.V := '           쳐 Change File Area (List)   '; END;
     99  : BEGIN O.N := 13;  O.V := '           쳐 Download File Queue       '; END;
     100 : BEGIN O.N := 18;  O.V := '           쳐 Download File With Path   '; END;
     101 : BEGIN O.N := 15;  O.V := '           쳐 UL File(s) - Fixed Area   '; END;
     102 : BEGIN O.N := 16;  O.V := '           쳐 UL File(s) - Current Area '; END;
     103 : BEGIN O.N := 17;  O.V := '           쳐 UL File(s) - Select Area  '; END;
     104 : BEGIN O.N := 39;  O.V := '           쳐 Private Upload To Sysop   '; END;
     105 : BEGIN O.N := 42;  O.V := '           쳐 New Files Scan            '; END;
     106 : BEGIN O.N := 47;  O.V := '           쳐 File Search - File Name   '; END;
     107 : BEGIN O.N := 48;  O.V := '           쳐 File Search - File Date   '; END;
     108 : BEGIN O.N := 49;  O.V := '           쳐 File Search - Text Search '; END;
     109 : BEGIN O.N := 95;  O.V := '           쳐 Set File Sub Group        '; END;
     110 : BEGIN O.N := 119; O.V := '           쳐 Change File Group (Next)  '; END;
     111 : BEGIN O.N := 120; O.V := '           쳐 Change File Group (Prev)  '; END;
     112 : BEGIN O.N := 121; O.V := '           쳐 Change File Group (List)  '; END;
     113 : BEGIN O.N := 50;  O.V := '           읕 Generate File List        '; END;
     114 : BEGIN O.N := 127; O.V := 'Save/Load 컫� Save MSG Group/Area       '; END;
     115 : BEGIN O.N := 128; O.V := '           쳐 Load MSG Group/Area       '; END;
     116 : BEGIN O.N := 129; O.V := '           쳐 Save File Group/Area      '; END;
     117 : BEGIN O.N := 130; O.V := '           쳐 Load File Group/Area      '; END;
     118 : BEGIN O.N := 131; O.V := '           쳐 Save Menu                 '; END;
     119 : BEGIN O.N := 132; O.V := '           읕 Load Menu                 '; END;
     ELSE  BEGIN O.N := 0;   O.V := ''                                        ; END;
     END;
END;


END.