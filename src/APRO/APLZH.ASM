;******************************************************
;                     APLZH.ASM 2.03
;                 ASM routines for APLZH
;      Copyright (c) TurboPower Software 1990, 1993.
;                  All rights reserved.
;******************************************************

;****************************************************** Macros

DosCall         MACRO   DosFuncNum
                MOV     AH,DosFuncNum   ;AH = Function number
                INT     21h             ;Call DOS
                ENDM

SaveAllRegs     MACRO
                PUSH    ES              ;save all basic registers
                PUSH    DS
                PUSH    DI
                PUSH    SI
                PUSH    BP
                PUSH    DX
                PUSH    CX
                PUSH    BX
                PUSH    AX
                ENDM

;Restore all registers saved in order of SaveAllRegs
RestoreAllRegs  MACRO
                POP     AX              ;restore all basic registers
                POP     BX
                POP     CX
                POP     DX
                POP     BP
                POP     SI
                POP     DI
                POP     DS
                POP     ES
                ENDM

PushDWord       MACRO   Value
                PUSH    WORD PTR Value+2        ;push high word
                PUSH    WORD PTR Value          ;push low word
                ENDM

;****************************************************** Data

DATA    SEGMENT WORD PUBLIC

        EXTRN   CodeTable : BYTE                ;Lookup table for code
        EXTRN   LengthTable : BYTE              ;Lookup table for length
        EXTRN   CrcTable : WORD                 ;Lookup table for CRC calcs
        EXTRN   Son : WORD                      ;Frequency binary tree
        EXTRN   Parent : WORD                   ; "
        EXTRN   Freq : WORD                     ; "
        EXTRN   LzhHandle : WORD                ;File handle for input
        EXTRN   OutFileHandle : WORD            ;File handle for output
        EXTRN   Crc : WORD                      ;File's CRC value
        EXTRN   ArchiveStatus : WORD            ;Last LZH error
        EXTRN   ShowProg : BYTE                 ;Boolean for displaying dots
        EXTRN   InBuffer : DWORD                ;Input buffer
        EXTRN   OutBuffer : DWORD               ;Output buffer
        EXTRN   glSPF : DWORD                   ;Procedure to show progress
        EXTRN   BytesWritten : DWORD            ;Bytes written so far
        EXTRN   SaveBytesLeft : DWORD           ;Bytes in compressed file
        EXTRN   TextBuffer : DWORD              ;Sliding dictionary
        EXTRN   EDPtr : DWORD                   ;Pointer to extra seg

; LZSS constants
RingBufSize     =       4096                    ;= 10000h
RingBufSizeMask =       0FFFh                   ;= RingBufSize - 1
Threshold       =       2
LookAheadSize   =       60

; Huffman constants
NumChar         =       (256 - Threshold + LookAheadSize)
TableSize       =       (NumChar * 2 - 1)
Root            =       TableSize-1
MaxFreq         =       08000h

; LZSS RingBuffer
RingBuffer      DB      RingBufSize DUP(?)
RingBufPos      DW      (?)

; Input/Output buffering
InBufSize       =       4096
InBufPos        DW      (?)
OutBufSize      =       4096
OutBufLimit     =       OutBufSize + LookAheadSize
OutBufPos       DW      (?)
BitBuffer       DW      (?)                     ;Input bit buffer
BitBufferLen    DW      (?)
BytesLeft       DD      (?)                     ;Bytes left to make file
BytesRead       DW      (?)                     ;Bytes read from LZH file
EmptyNode       =       08192                   ;Denotes empty tree node
Zero            =       0                       ;Zero constant

;Extra data segment structure
ExtraData       STRUC
LeftSon         DW      InBufSize+1 DUP (?)
RightSon        DW      InBufSize+1+256 DUP (?)
Dad             DW      InBufSize+1 DUP (?)
MatchLen        DW      (?)
MatchPos        DW      (?)
                ENDS

; error codes
ecDiskFull      =       101
ecUserAbort     =       2926

DATA    ENDS

;****************************************************** Code

CODE    SEGMENT WORD PUBLIC

        ASSUME  CS:CODE,DS:DATA

        PUBLIC  MeltPrim, FlushOutBuffer, UpdateBinaryTree
        PUBLIC  InitTree, InsertNode, DeleteNode

        EXTRN   ReconstructTree : NEAR          ;Procedure for rebuilding tree

;****************************************************** InitTree

;InitTree
;  -Initializes the ecoding tree
;
;   Destroys AX,BX,CX,DI,ES
;
InitTree        PROC NEAR
         CLD
         MOV    AX,WORD PTR EDPtr+2             ;ES = tree segment
         MOV    ES,AX                           ;
         MOV    CX,256                          ;Fill 256 words
         MOV    AX,EmptyNode                    ;EmptyNode value
         MOV    BX,(InBufSize+1)*2              ;
         LEA    DI,RightSon[BX]                 ;ES:DI-> RightSon[InBufSize+1]
         REP    STOSW                           ;
         MOV    CX,4097                         ;Fill 4097 words
         MOV    DI, OFFSET Dad                  ;ES:DI -> RightSon[0]
         REP    STOSW                           ;
         RET                                    ;
InitTree        ENDP

;****************************************************** InsertNode

;InsertNode(R : Word);
;  -Inserts node R into binary tree
;
;        Destroys AX,BX,CX,DX,SI,DI,ES
;
InsertNode      PROC NEAR

;Stack setup and register saves
         PUSH   BP                              ;
         MOV    BP,SP                           ;Stack pointer
         MOV    BX,[BP+4]                       ;BX = R

;Load ES:DI, then set DS=extra data segment
         LES    DI,TextBuffer                   ;ES:DI -> TextBuffer^
         PUSH   DS                              ;Set DS = extra data segment
         MOV    AX,WORD PTR EDPtr+2             ;
         MOV    DS,AX                           ;

;Init RightSon/LeftSon of R
         MOV    SI,BX                           ;Save R in SI
         SHL    BX,1                            ;Make it an index
         MOV    AX, EmptyNode                   ;
         MOV    RightSon[BX],AX                 ;RightSon[R] := EmptyNode
         MOV    LeftSon[BX],AX                  ;LeftSon[R] := EmptyNode

;Get the current char and calculate the RightSon root slot
         ADD    DI,SI                           ;P := TextBuffer^ +
         MOV    BL,ES:[DI]                      ;  InBufSize
         XOR    BH,BH                           ;
         ADD    BX,InBufSize+1                  ;
         SHL    BX,1                            ;BX = P (an index)
         MOV    DS:MatchLen,Zero                ;MatchLen := 0

;If we've seen this char before then start comparing old strings
; else make a new node and exit
         CMP    RightSon[BX],EmptyNode          ;RightSon[BX] = EmptyNode?
         JE     IN1                             ;Yes, go insert node
         MOV    BX,RightSon[BX]                 ;No, BX := RightSon[P]
         JMP    IN2                             ;
IN1:     SHL    SI,1                            ;
         MOV    RightSon[BX],SI                 ;RightSon[P] := R
         MOV    [Dad+SI],BX                     ;Dad[R] := P
         JMP    IN99                            ;Exit

;Compare the current and old string
IN2:     CLD                                    ;
IN3:     MOV    SI,BX                           ;Get old string node
         SHR    SI,1                            ;Make a TextBuffer^ index
         MOV    DX,SI                           ;Save orignal index
         MOV    CX,LookAheadSize                ;Compare no more than 60 chars
         PUSH   DS                              ;Save DS
         MOV    AX,ES                           ;DS=ES
         MOV    DS,AX                           ;
         REPE   CMPS BYTE PTR [SI], BYTE PTR [DI] ;Compare old and new str
         POP    DS                              ;Restore DS
         LAHF                                   ;Save results for later
         JZ     IN10                            ;All equal, go replace node

;Update MatchLen and MatchPos if this was the longest compare yet
IN5:     SUB    SI,DX                           ;SI = equal char count
         DEC    SI                              ;Account for first char
         CMP    SI,DS:MatchLen                  ;Greater than previous?
         JLE    IN51                            ;No, skip
         MOV    DS:MatchLen,SI                  ;Yes, save length
         MOV    CX,DI                           ;Get ending R
         SUB    CX,SI                           ;  subtract out equal count
         DEC    CX                              ;  account for 1st char
         MOV    DX,BX                           ;Get P index
         SHR    DX,1                            ;Make a value
         SUB    CX,DX                           ;MatchPos := ((R - P) and
         AND    CX,InBufSize-1                  ;  InBufSize) - 1
         DEC    CX                              ;
         MOV    DS:MatchPos,CX                  ;

;If this MatchLen is the same as a previous, save the lower MatchPos
IN51:    CMP    SI,DS:MatchLen                  ;Same MatchLen?
         JNE    IN6                             ;No, skip
         MOV    CX,DI                           ;Yes, compute new MatchPos
         SUB    CX,SI                           ;  subtract out equal count
         DEC    CX                              ;  account for 1st char
         MOV    DX,BX                           ;Get P index
         SHR    DX,1                            ;Make a value
         SUB    CX,DX                           ;MatchPos := ((R - P) and
         AND    CX,InBufSize-1                  ;  InBufSize) - 1
         DEC    CX                              ;
         CMP    CX,DS:MatchPos                  ;New MatchPos < old
         JGE    IN6                             ;No, skip it
         MOV    DS:MatchPos,CX                  ;Yes, store it

;Restore ES:DI to TextBuffer^[R]. Go process CMPS results
IN6:     SUB    DI,SI                           ;Restore ES:DI
         DEC    DI                              ;Account for first char
         SAHF                                   ;Restore the compare results
         JA     IN7                             ;Lower string, go follow

;New string was higher sort, look for higher string to match
         CMP    RightSon[BX],EmptyNode          ;if RightSon[P] <> Empty
         JE     IN8                             ;
         MOV    BX,RightSon[BX]                 ;  P := RightSon[P]
         JMP    IN3                             ;Go compare this node

;No more higher strings, insert new right son node here
IN8:     SHL    DI,1                            ;Make an index
         MOV    RightSon[BX],DI                 ;RightSon[P] := R
         MOV    Dad[DI],BX                      ;Dad[R] := P
         JMP    IN99                            ;Exit

;New string was lower sort, look for lower node to match
IN7:     CMP    LeftSon[BX],EmptyNode           ;if LeftSon[P] = Empty
         JE     IN9                             ;
         MOV    BX,LeftSon[BX]                  ;  P := LeftSon[P]
         JMP    IN3                             ;Go compare this node

;No more lower strings, insert new left son node here
IN9:     SHL    DI,1                            ;Make an index
         MOV    LeftSon[BX],DI                  ;LeftSon[P] := R
         MOV    Dad[DI],BX                      ;Dad[R] := P
         JMP    IN99                            ;Exit

;Found exact match of LookAhead length
;Replace old node with current node (to speed subsequent searches)
IN10:    SUB    SI,DX                           ;SI = equal char count
         DEC    SI                              ;Account for first char
         MOV    CX,DI                           ;Get ending R
         SUB    CX,SI                           ;  subtract out equal count
         DEC    CX                              ;  account for 1st char
         MOV    DX,BX                           ;Get P index
         SHR    DX,1                            ;Make a value
         SUB    CX,DX                           ;MatchPos := ((R - P) and
         AND    CX,InBufSize-1                  ;  InBufSize) - 1
         DEC    CX                              ;
         MOV    DS:MatchPos,CX                  ;
         MOV    DS:MatchLen,LookAheadSize       ;
         SUB    DI,LookAheadSize                ;DI = R
         SHL    DI,1                            ;Make an index

;Set Dad, LeftSon and RightSon pointers of current node
         MOV    AX,[Dad+BX]                     ;Dad[R] := Dad[P]
         MOV    [Dad+DI],AX
         MOV    AX,[RightSon+BX]                ;RightSon[R] := RightSon[P]
         MOV    [RightSon+DI],AX
         MOV    AX,[LeftSon+BX]                 ;LeftSon[R] := LeftSon[P]
         MOV    [LeftSon+DI],AX

;Set new Dad pointers for children nodes
         MOV    SI,[LeftSon+BX]                 ;Dad[LeftSon[P]] := R;
         MOV    [Dad+SI],DI
         MOV    SI,[RightSon+BX]                ;Dad[RightSon[P]] : R
         MOV    [Dad+SI],DI

;Set child pointer (left or right) of parent node
         MOV    SI,[Dad+BX]                     ;if RightSon[Dad[P]] = P
         CMP    [RightSon+SI],BX
         JNE    IN11
         MOV    SI,[Dad+BX]                     ;RightSon[Dad[P]] := R
         MOV    [RightSon+SI],DI
         JMP    IN12
IN11:    MOV    SI,[Dad+BX]                     ;LeftSon[Dad[P]] := R
         MOV    [LeftSon+SI],DI

;Clear old node
IN12:    MOV    [Dad+BX],EmptyNode              ;Dad[P] := EmptyNode

;Clean up and exit
IN99:    POP    DS
         POP    BP
         RET    2
InsertNode      ENDP

;***************************************************** DeleteNode
;DeleteNode(P : Word);
;  -Deletes node P from binary tree
;
DeleteNode      PROC NEAR

;Stack setup and register saves
         PUSH   BP                              ;
         MOV    BP,SP                           ;Stack pointer
         MOV    BX,[BP+4]                       ;BX = P
         PUSH   DS                              ;Set DS=extra data segment
         MOV    AX,WORD PTR EDPtr+2             ;
         MOV    DS,AX                           ;

;If this node is empty just exit
         SHL    BX,1                            ;Make an index
         MOV    SI,BX                           ;Save P in SI
         CMP    [Dad+BX],EmptyNode              ;if Dad[P] = EmptyNode
         JNE    DN0                             ;No, keep going
         JMP    DN99                            ;Yes, finished

;if RightSon is empty then pull up left son
DN0:     CMP    [RightSon+BX], EmptyNode        ;if RightSon[P] = EmptyNode
         JNE    DN1                             ;
         MOV    BX,[LeftSon+BX]                 ;  Q := LeftSon[BX]
         JMP    DN2                             ;

;If LeftSon is empty then pull up right son
DN1:     CMP    [LeftSon+BX],EmptyNode          ;else if LeftSon[BX] = EmptyNode
         JNE    DN3
         MOV    BX,[RightSon+BX]                ;  Q := RightSon[BX]
         JMP    DN2                             ;

;Both children are active, find leftmost son of right tree
DN3:     MOV    BX,[LeftSon+BX]                 ;else Q := LeftSon[BX]
         CMP    [RightSon+BX], EmptyNode        ;if RightSon[Q] <> EmptyNode
         JE     DN5                             ;

;Traverse down right sons until right son is empty
DN6:     MOV    BX,RightSon[BX]                 ;repeat
         CMP    RightSon[BX],EmptyNode          ;  Q := RightSon[Q]
         JNE    DN6                             ;until RightSon[Q] = EmptyNode

;Attach Q's left son to P's left son
         MOV    DI,[Dad+BX]                     ;RightSon[Dad[Q]] := LeftSon[Q]
         MOV    AX,LeftSon[BX]                  ;
         MOV    [RightSon+DI],AX                ;
         MOV    DI,[LeftSon+BX]                 ;Dad[LeftSon[Q]] := Dad[Q]
         MOV    AX,[Dad+BX]                     ;
         MOV    [Dad+DI],AX                     ;

;Replace P with Q
         MOV    AX,[LeftSon+SI]                 ;LeftSon[Q] := LeftSon[P]
         MOV    [LeftSon+BX], AX                ;
         MOV    DI,[LeftSon+SI]                 ;Dad[LeftSon[P]] := Q
         MOV    [Dad+DI],BX                     ;

;Move it up
DN5:     MOV    AX,[RightSon+SI]                ;RightSon[Q] := RightSon[P]
         MOV    [RightSon+BX],AX                ;
         MOV    DI,[RightSon+SI]                ;Dad[RightSon[P]] := Q
         MOV    [Dad+DI],BX                     ;

;Make P's parent Q's parent
DN2:     MOV    AX,[Dad+SI]                     ;Dad[Q] := Dad[P]
         MOV    [Dad+BX],AX                     ;
         MOV    DI,[Dad+SI]                     ;RightSon[Dad[P]] := Q
         CMP    [RightSon+DI],SI                ;if RightSon[Dad[P]] = P then
         JNE    DN9                             ;
         MOV    [RightSon+DI],BX                ;  RightSon[Dad[P]] := Q
         JMP    DN10                            ;
DN9:     MOV    DI,[Dad+SI]                     ;  else LeftSon[Dad[P]] := Q
         MOV    [LeftSon+DI],BX                 ;

;Say this node is empty
DN10:    MOV    [Dad+SI],EmptyNode              ;Dad[P] := EmptyNode

;Clean up and return
DN99:    POP   DS
         POP   BP
         RET   2
DeleteNode      ENDP

;****************************************************** UpdateBinaryTree

;UpdateBinaryTree
;  -Updates the freq of this code and rearranges the binary tree
;        SI = Code (passed)
;        CX = NewFreq
;        DI = Index of last, lower freq
;        BX,DX = various temp values
;
;        Destroys AX,BX,CX,DX,SI,DI
;
UpdateBinaryTree        PROC NEAR

;Check for reconstruct
        OR      Freq[Root * 2],0                ;At max frequency?
        JNS     UBT1                            ;No, continue
        PUSH    SI
        PUSH    ES
        CALL    ReconstructTree                 ;Yes, reconstruct tree
        POP     ES
        POP     SI

;Increment this code's frequency
UBT1:   CLD                                     ;Clear the direction flag
        MOV     SI,Parent[SI]                   ;SI = Parent[Code]
UBT2:   MOV     AX,Freq[SI]                     ;AX = current freq
        LEA     DI,Freq[SI]                     ;ES:DI = @Freq[SI]
        ADD     DI,2                            ;Next
        SCASW                                   ;Search for greater
        JNE     UBT6                            ;No swap, go get parent

;Need swap, find first greater
        MOV     CX,0FFFFh                       ;Search all
        REPE    SCASW                           ; for first greater
        SUB     DI,4                            ;Back up to last lower
        SUB     DI,OFFSET Freq                  ;DI = index of last lower

;Found code with higher frequency, swap with the parent and son pointers
        MOV     BX,Son[SI]                      ;Get old Son index
        MOV     Parent[BX],DI                   ;Update with new index
        CMP     BX,TableSize*2                  ;Index < TableSize ?
        JAE     UBT4                            ;No, continue
        MOV     Parent[BX+2],DI                 ;Parent[BX+1] = new index

UBT4:   XCHG    BX,Son[DI]                      ;get old index, stuff new
        MOV     Parent[BX],SI                   ;Stuff old index
        CMP     BX,TableSize*2                  ;BX > TableSize ?
        JGE     UBT5                            ;No, continue
        MOV     Parent[BX+2],SI                 ;Stuff old index

UBT5:   MOV     Son[SI],BX                      ;Son[old index] := new ptr
        MOV     SI,DI                           ;Code := Next code

UBT6:   INC     Freq[SI]                        ;Increment freq of this code
        MOV     SI,Parent[SI]                   ;Get parent index
        OR      SI,SI                           ;Repeat up to Root
        JNZ     UBT2
        RET

UpdateBinaryTree        ENDP

;****************************************************** UpdateDisplay

UpdateDisplay   PROC NEAR

        SaveAllRegs
        PushDWord BytesWritten          ;push # of bytes written
        PushDWord SaveBytesLeft         ;push total # of bytes
        CALL    DWORD PTR glSPF
        OR      AL,AL                   ;did it return False?
        JNZ     udOK
        MOV     ArchiveStatus,ecUserAbort ;indicate that user asked to abort
udOK:   RestoreAllRegs
        RET

UpdateDisplay   ENDP

;****************************************************** FlushOutBuffer

;procedure FlushOutBuffer(BytesToWrite : Word);
;  {-Copies OutBuffer to disk}

;     Destroys AX,BX,CX,DX

FlushOutBuffer PROC NEAR

;Check buffer size
        MOV     BX,SP                   ;Set up stack frame
        MOV     CX,SS:[BX+2]            ;Get buffer count
        JCXZ    FOB2                    ;Just leave if empty

;Calculate Crc for this block
        PUSH    CX                      ;Save registers
        PUSH    ES
        PUSH    SI
        LES     SI,OutBuffer            ;ES:SI = OutBuffer
        MOV     AX,Crc                  ;AX holds current Crc

FOB1:   XOR     AL,ES:[SI]              ;Get next character from buffer
        XOR     BX,BX                   ;Zero out BX
        MOV     BL,AL                   ;Use as index...
        SHL     BX,1                    ;into array of words
        MOV     AL,AH                   ;Move hi(Crc) to lo
        XOR     AH,AH                   ;Clear hi
        XOR     AX,CrcTable[BX]         ;Lookup new CRC value
        INC     SI                      ;Next character
        LOOP    FOB1                    ;Repeat

        MOV     Crc,AX                  ;Update Crc
        POP     SI                      ;Restore registers
        POP     ES
        POP     CX

;Write buffer to disk
        ADD     WORD PTR BytesWritten,CX        ;Update count of bytes written
        ADC     WORD PTR BytesWritten+2,0
        MOV     BX,OutFileHandle        ;BX = file handle
        PUSH    DS                      ;Save DS
        LDS     DX,OutBuffer            ;DS:DX = OutBuffer
        DosCall 040h                    ;Write file
        POP     DS                      ;Restore DS
        JC      FOB4                    ;Exit on error
        CMP     CX,AX                   ;Did we write all bytes?
        JNE     FOB3                    ;No, disk must be full
        MOV     OutBufPos,0             ;Reset index

;Update the display
        CMP     ShowProg,0              ;Show dots?
        JE      FOB2                    ;No, just leave
        CALL    UpdateDisplay           ;update the display

;Normal exit
FOB2:   RET     2

;Error exit
FOB3:   MOV     AX,ecDiskFull           ;Disk is full
FOB4:   MOV     ArchiveStatus,AX        ;Save error code
        RET     2

FlushOutBuffer ENDP

;****************************************************** GetNextByte

;procedure GetNextByte;
;  {-Returns next byte from input stream in AL}

;  Destroys AX,BX

GetNextByte     PROC    NEAR

        PUSH    SI                      ;Save SI (for GetNextPosition)
        INC     InBufPos                ;Increment InBufPos
        MOV     BX,InBufPos             ;BX = InBufPos
        CMP     BX,BytesRead            ;InBufPos >= BytesRead ?
        JL      GNB1                    ;No, get next byte

;Replenish byte buffer
        PUSH    CX                      ;Save CX (for GetNextPosition)
        PUSH    DX                      ;Save DX (for GetNextCode)
        MOV     BX,LzhHandle            ;BX = file handle
        MOV     CX,InBufSize            ;CX = bytes to read
        PUSH    DS                      ;Save DS
        LDS     DX,InBuffer             ;DS:DX = InBuffer
        DosCall 03Fh                    ;Read file
        POP     DS                      ;Restore DS
        JC      GNB2                    ;Exit on error
        MOV     BytesRead,AX            ;Save BytesRead
        XOR     BX,BX                   ;Reset index
        MOV     InBufPos,BX             ;"
        POP     DX                      ;Restore DX (for GetNextCode)
        POP     CX                      ;Restore CX (for GetNextPosition)

;Return next byte in buffer
GNB1:   PUSH    DS                      ;Save DS
        LDS     SI,InBuffer             ;DS:SI = InBuffer
        MOV     AL,[SI+BX]              ;AL = next byte
        POP     DS                      ;Resore DS
        POP     SI                      ;Restore SI (for GetNextPosition)
        RET

;Error exit
GNB2:   MOV     ArchiveStatus,AX        ;Save the error code
        MOV     AL,00h                  ;Just return a nul
        MOV     BytesRead,CX            ;Prevent additional retries
        POP     DX                      ;Restore the stack
        POP     CX
        POP     SI
        RET                             ;MeltPrim will abort shortly

GetNextByte     ENDP

;****************************************************** GetNextPosition

;procedure GetNextPosition;
;  {-Returns ring buffer index of current <pos, len> code}

;       Destroys AX,BX,CX,DX,SI

GetNextPosition PROC NEAR

        CMP     BitBufferLen,8          ;Do we have at least 8 bits?
        JGE     GNP1                    ;Yes, continue

;Refill BitBuffer
        CALL    GetNextByte             ;Get next byte (in AL)
        XOR     AH,AH                   ;Zero out AH
        MOV     CX,8                    ;New bits
        SUB     CX,BitBufferLen         ;8 - BitBufferLen = shift count
        SHL     AX,CL                   ;Shift new byte over
        ADD     BitBuffer,AX            ;Merge old and new
        ADD     BitBufferLen,8          ;Set new bit count

GNP1:   MOV     SI,BitBuffer            ;Get next 8 bits
        MOV     CL,8                    ;Shift these bits to lower 8
        SHR     SI,CL                   ;Move to AL
        SHL     BitBuffer,CL            ;Adjust BitBuffer
        SUB     BitBufferLen,8          ;Calc new BitBuffer length
        JNZ     GNP2                    ;Continue

;Refill BitBuffer
        CALL    GetNextByte             ;Get next byte (in AL)
        XOR     AH,AH                   ;Zero out AH
        MOV     CX,8                    ;New bits
        SUB     CX,BitBufferLen         ;8 - BitBufferLen = shift count
        SHL     AX,CL                   ;Shift new byte over
        ADD     BitBuffer,AX            ;Merge old and new
        ADD     BitBufferLen,8          ;Set new bit count

;Recover upper 6 bits from the CodeTable
GNP2:   XOR     AX,AX                   ;Zero AX
        MOV     AL,CodeTable[SI]        ;Lookup code
        MOV     CL,6                    ;
        SHL     AX,CL                   ;Move bits over
        PUSH    AX                      ;Save this (Code)

;Prepare to read the rest of the bits
        MOV     DX,BitBuffer            ;DX = BitBuffer
        MOV     BX,BitBufferLen         ;BX = BitBuffer length
        XOR     CX,CX                   ;Zero out CX
        MOV     CL,LengthTable[SI]      ;Get length of position

;Shift new bits (left) into Position
GNP3:   SHL     SI,1                    ;Move existing bits over
        SHL     DX,1                    ;Shift next bit into Carry flag
        ADC     SI,0                    ;Add next bit to Position
        DEC     BX                      ;Decrement length of bit buffer
        JNZ     GNP4                    ;Skip if bits left in BitBuffer

;Replenish the BitBuffer
        CALL    GetNextByte             ;Get next byte (in AL)
        MOV     DH,AL                   ;Store high byte
        CALL    GetNextByte             ;Get next byte (in AL)
        MOV     DL,AL                   ;Store low byte
        MOV     BX,16                   ;16 fresh bits
GNP4:   LOOP    GNP3

;Clean up and exit
GNP5:   MOV     BitBuffer,DX            ;Update BitBuffer
        MOV     BitBufferLen,BX         ;Update BitBufferLen
        AND     SI,03Fh                 ;Mask
        POP     AX                      ;Restore Code
        OR      AX,SI                   ;Merge with index
        RET

GetNextPosition ENDP

;****************************************************** GetNextCode

;procedure GetNextCode;
;  {-Gets next Huffman code from input stream}

;       Destroys AX,BX,CX,DX,SI
;       Returns AX (Code)

GetNextCode     PROC NEAR

        MOV     SI,Son[Root * 2]        ;Start at Root
        MOV     DI,TableSize * 2        ;Use register for faster compares

;Move BitBuffer into registers
GNC0:   MOV     DX,BitBuffer            ;DX = current bit buffer
        MOV     CX,BitBufferLen         ;CX = length of bit buffer
        JMP     SHORT GNC2              ;Go compare

;Get next bit, 1 means go to right son, 0 means left
GNC1:
        SHR     SI,1                    ;Change from index to value
        SHL     DX,1                    ;Shift next bit into Carry flag
        ADC     SI,0                    ;Add next bit to current index
        SHL     SI,1                    ;Change back to index
        MOV     SI,Son[SI]              ;Get next Son index
        DEC     CX                      ;Decrement length of bit buffer
        JNZ     GNC2                    ;Skip if bits left

;See if the BitBuffer needs to be replenished
        CALL    GetNextByte             ;Get next byte (in AL)
        MOV     DH,AL                   ;Store high byte
        CALL    GetNextByte             ;Get next byte (in AL)
        MOV     DL,AL                   ;Store low byte
        MOV     CX,16                   ;16 fresh bits

;Continue traversing son indices until we get to a leaf
GNC2:   CMP     SI,DI                   ;Into leaf yet? (SI > TableSize*2)
        JB      GNC1                    ;No, get next index

;Store BitBuffer, Update binary tree, return function value
        MOV     BitBuffer,DX            ;Store new bit buffer
        MOV     BitBufferLen,CX         ;Store new bit buffer length
        PUSH    SI                      ;Save Code
        CALL    UpdateBinaryTree        ;Update the binary tree (Code in SI)
        POP     AX                      ;Restore Code to AX
        SUB     AX,TableSize*2          ;Code := Code - TableSize
        SHR     AX,1                    ;Change from index to value
        RET

GetNextCode     ENDP

;****************************************************** MeltPrim

;procedure MeltPrim(BytesLeft : LongInt);
;  {-Loop through frozen file, write melted file}

MeltPrim        PROC NEAR

;Get BytesLeft
        MOV     BX,SP                   ;Set up stack frame
        MOV     AX,SS:[BX+2]            ;AX = BytesLeft lo
        MOV     WORD PTR BytesLeft,AX   ;
        MOV     AX,SS:[BX+4]            ;AX = BytesLeft hi
        MOV     WORD PTR BytesLeft+2,AX ;

;Misc  initializations
        XOR     AX,AX
        MOV     InBufPos,AX             ;InBuffer index
        MOV     OutBufPos,AX            ;OutBuffer index
        MOV     BitBuffer,AX            ;Bits move from right to left
        MOV     BitBufferLen,AX         ;Number of valid bits in BitBuffer
        MOV     RingBufPos,RingBufSize - LookAheadSize  ;RingBuffer index
        MOV     Crc,AX                  ;Running CRC value
        MOV     BytesRead,AX            ;Number of bytes in buffer

;FillChar(RingBuffer, RingBufSize-LookAheadSize, ' ');
        CLD
        PUSH    DS                      ;ES = DS
        POP     ES
        MOV     DI,OFFSET RingBuffer    ;ES:DI => RingBuffer
        MOV     CX,RingBufSize-LookAheadSize    ;CX = RingBufSize-LookAheadSize
        MOV     AL,' '                  ;AL = space
        REP     STOSB                   ;Init RingBuffer to spaces

;Refill BitBuffer
        CALL    GetNextByte             ;Get next byte (in AL)
        XOR     AH,AH                   ;Zero out AH
        MOV     CX,8                    ;New bits
        SUB     CX,BitBufferLen         ;8 - BitBufferLen = shift count
        SHL     AX,CL                   ;Shift new byte over
        ADD     BitBuffer,AX            ;Merge old and new
        ADD     BitBufferLen,8          ;Set new bit count

;Major uncompress loop
MP1:    CALL    GetNextCode             ;AX = next code
        OR      AH,AH                   ;Code > 255?
        JNZ     MP3                     ;Yes, go decode <pos, len> code

;It's a single character, stuff it in the output buffer
        MOV     BX,OutBufPos            ;BX = OutBufPos
        PUSH    ES                      ;Save ES
        LES     DI,OutBuffer            ;ES:DI = OutBuffer
        MOV     ES:[DI+BX],AL           ;OutBuffer^[OutBufPos] := char
        POP     ES                      ;Restore ES
        INC     OutBufPos               ;Update OutBufPos
        MOV     BX,RingBufPos           ;BX = RingBufPos
        MOV     RingBuffer[BX],AL       ;RingBuffer[RingBufPos] := char
        INC     BX                      ;Next position in ring buffer
        AND     BX,RingBufSizeMask      ;Wrap around ring buffer
        MOV     RingBufPos,BX           ;Update RingBufPos var
        SUB     WORD PTR BytesLeft,1    ;Bytes left to go
        SBB     WORD PTR BytesLeft+2,0  ; (longint)
        JMP     SHORT MP5

;It's a position code, get the position in AX
MP3:    PUSH    AX                      ;Save Code
        CALL    GetNextPosition         ;Get position into AX
        MOV     BX,RingBufPos           ;BX = position in RingBuffer
        SUB     BX,AX                   ;Backwards from current position
        SUB     BX,2                    ;Two more

;Get the length
        POP     CX                      ;CX = Code
        SUB     CX,255 - Threshold      ;Convert to length

;Loop for length, retrieving chars from ring buffer
        CLD                             ;Go forward
        PUSH    ES                      ;Save ES
        LES     DI,OutBuffer            ;ES:DI = OutBuffer
        ADD     DI,OutBufPos            ;ES:DI = @OutBuffer[OutBufPos]
        MOV     SI,RingBufPos           ;SI = RingBuffer index

;Go ahead pre-update some variables now
        ADD     OutBufPos,CX            ;Update OutBufPos
        SUB     WORD PTR BytesLeft,CX   ;Update BytesLeft
        SBB     WORD PTR BytesLeft+2,0  ; (longint)

MP4:    INC     BX                      ;Increment Position
        AND     BX,RingBufSizeMask      ;Wrap around ring buffer
        MOV     AL,RingBuffer[BX]       ;AX = character code
        STOSB                           ;OutBuffer[OutBufPos] := char code
        MOV     RingBuffer[SI],AL       ;RingBuffer[RingBufPos] := char code
        INC     SI                      ;Next position in ring buffer
        AND     SI,RingBufSizeMask      ;Wrap around ring buffer
        LOOP    MP4                     ;Finished?

        POP     ES                      ;Restore ES

;Finished with repeat, update RingBufPos
        MOV     RingBufPos,SI           ;Update RingBufPos

;Found any errors?
        CMP     ArchiveStatus,0         ;any errors?
        JNE     MP10                    ;leave if so

;Output buffer full?
MP5:    CMP     OutBufPos,OutBufSize    ;OutBufPos >= OutBufSize
        JB      MP7                     ;No, continue
        PUSH    OutBufPos               ;Bytes to write
        CALL    FlushOutBuffer          ;Yes, go flush buffer
        CMP     ArchiveStatus,0         ;any errors?
        JNE     MP10                    ;leave if so

;Finished with extraction?
MP7:    MOV     AX,WORD PTR BytesLeft+2 ;Get high word of BytesLeft
        OR      AX,AX                   ;Finished?
        JS      MP9                     ;Yes, leave
        OR      AX,WORD PTR BytesLeft   ;Low word zero?
        JZ      MP9                     ;Yes, leave
        JMP     MP1                     ;No, get another code

;Finished, flush last buffer, calculate CRC
MP9:    PUSH    OutBufPos               ;Bytes to write
        CALL    FlushOutBuffer          ;write last buffer (if any)
MP10:   RET     4

MeltPrim ENDP

CODE    ENDS
        END
