;*******************************************************************
;                      ERRORS.ASM 2.03
;        Copyright (c) TurboPower Software 1987, 1989.
;                   All rights reserved.
;*******************************************************************

        IDEAL

MODEL   LARGE,PASCAL

CODESEG

PROC    ERROR_TABLE     FAR
PUBLIC  ERROR_TABLE

        DW      2
        DB      14,"File not found"
        DW      3
        DB      14,"Path not found"
        DW      4
        DB      19,"Too many open files"
        DW      5
        DB      13,"Access denied"
        DW      6
        DB      19,"Invalid file handle"
        DW      8
        DB      13,"Out of memory"
        DW      15
        DB      27,"Invalid drive specification"
        DW      100
        DB      22,"Unexpected end of file"
        DW      101
        DB      23,"Insufficient disk space"
        DW      150
        DB      23,"Disk is write protected"
        DW      151
        DB      17,"Unknown disk unit"
        DW      152
        DB      15,"Drive not ready"
        DW      154
        DB      30,"Data error while reading drive"
        DW      156
        DB      15,"Disk seek error"
        DW      157
        DB      18,"Unknown media type"
        DW      158
        DB      16,"Sector not found"
        DW      159
        DB      18,"Print out of paper"
        DW      160
        DB      18,"Device write error"
        DW      161
        DB      17,"Device read error"
        DW      162
        DB      40,"General failure error reading disk drive"
        DW      2901
        DB      43,"UART receiver overrun.  Data has been lost."
        DW      2902
        DB      26,"UART receiver parity error"
        DW      2903
        DB      27,"UART receiver framing error"
        DW      2910
        DB      22,"INT 14 transmit failed"
        DW      2911
        DB      21,"INT 14 receive failed"
        DW      2921
        DB      18,"Output buffer full"
        DW      2922
        DB      19,"Output buffer empty"
        DW      2923
        DB      32,"Timed out while waiting for data"
        DW      2926
        DB      15,"Aborted by user"
        DW      2950
        DB      27,"Fossil driver not installed"
        DW      2960
        DB      17,"Digiboard failure"
        DW      9970
        DB      19,"Bad fax file format"
        DW      9971
        DB      38,"Bad font format or unsupported feature"
        DW      9973
        DB      21,"Bad image file format"
        DW      9974
        DB      23,"Bad PCL escape sequence"
        DW      9802
        DB      19,"Fax number was busy"
        DW      9804
        DB      27,"No CAS manager is installed"
        DW      9805
        DB      43,"Unexpected modem initialization result code"
        DW      9806
        DB      33,"Unable to train with remote modem"
        DW      9807
        DB      24,"Error during fax session"
        DW      9808
        DB      36,"Unable to establish a fax connection"
        DW      9809
        DB      45,"Unable to send fax page after several retries"
        DW      2200
        DB      67,"Directory too large to fit in memory.  File list will be truncated."
        DW      7000
        DB      27,"That data field is required"
        DW      7001
        DB      15,"Bad data format"
        DW      7002
        DB      26,"That entry is out of range"
        DW      7003
        DB      33,"This field may not contain blanks"
        DW      7004
        DB      71,"This field is only partially entered.  Partial entries are not allowed."
        DW      7005
        DB      40,"This field contains an illegal character"
        DW      7110
        DB      43,"Edit buffer is full.  No more text allowed."
        DW      7111
        DB      59,"Line too long.  The line has been cleft in twain by a CRLF."
        DW      7112
        DB      45,"The maximum number of lines would be exceeded"
        DW      7113
        DB      46,"The maximum number of lines has been exceeded."
        DW      7114
        DB      47,"This file is too large.  It has been truncated."
        DW      8100
        DB      22,"Bad window coordinates"
        DW      8101
        DB      17,"Window not active"
        DW      8102
        DB      18,"Window not current"
        DW      8103
        DB      33,"Window is active and shouldn't be"
        DW      8105
        DB      28,"Can not zoom a zoomed window"
        DW      8106
        DB      20,"Invalid header index"
        DW      8107
        DB      28,"The window is not resizeable"
        DW      8108
        DB      25,"Missing command processor"
        DW      8109
        DB      35,"Invalid operating on a child window"
        DW      8300
        DB      22,"Too many edit controls"
        DW      8301
        DB      21,"Bad field coordinates"
        DW      8303
        DB      23,"The dialog box is empty"
        DW      8305
        DB      44,"Attempt to position on an invalid control ID"
        DW      8307
        DB      18,"Bad window control"
        DW      8400
        DB      20,"Invalid printer type"
        DW      8401
        DB      29,"Printer position out of range"
        DW      8500
        DB      52,"NIL pointer encountered where there shouldn't be one"
        DW      8501
        DB      13,"Bad parameter"
        DW      9997
        DB      30,"This file is not in APF format"
        DW      9998
        DB      43,"You must specify at least one outgoing file"
        DW      9999
        DB      45,"Your display adapter does not support mode 12"
                ; End of table
        DW      0

ENDP

        END
