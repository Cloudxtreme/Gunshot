;   This is the source code for the replacement INT 21 handler EXTEND.PAS.
; This code is designed to be compiled by the TASM assembler and linked into
; the Pascal code.
;
;   This code was based upon earlier work by Randy Forgaard, Bela Lubkin and
; Kim Kokkonen.  The previous implementation was based on using the same
; technique only not using an interrupt handler.  See EXTEND.DOC for more
; information.
;
;   To compile with TASM:
;      TASM EXTEND
;
; Scott Bussinger
; Professional Practice Systems
; 110 South 131st
; Tacoma, WA  98444
; (206)531-8944
; Compuserve [72247,2671]
;
COMMENT ~
  ** Revision History **
  1 EXTEND.ASM 9-Mar-89,`SCOTT' First version using TLIB -- Based on 3.2
  ** Revision History **
~
; Version 3.2 --  9/25/1988 -- Changed EXTEND.ASM to compile under TASM (needed a few detail changes)
;         3.0 -- 10/26/1987 -- Reworked as a UNIT for use with Turbo Pascal 4
;                              EXTEND.ASM reworked to be compatible with A86 assembler
;         2.5 --  3/16/1987 -- EXTEND.ASM worked on by Kim Kokkonen and Brian Foley to work
;                                with Turbo Extender and whittle off a few clock cycles
;         2.4 -- 12/16/1986 -- Fixes problem with DUP function
;         2.3 -- 11/18/1986 -- EXTEND now only affects DOS calls made from
;                                same code segment it was installed from (fixes
;                                problems with EXEC and batch files and already
;                                resident TSR programs
;         2.2 -- 10/04/1986 -- Fixed problem with EXEC function destroying all
;                                registers including the stack
;                              Changed way that original handle number is kept
;                              Permit FORCEDUP to change a standard handle
;                              Improve some comments
;         2.1 -- 10/02/1986 -- Fixed problem of Turbo assuming registers valid
;                                after a call to DOS
;         2.0 -- 10/01/1986 -- Initial release of this inline code
;

        PUBLIC  ExtendInit,ExtendHandler

DSEG    SEGMENT WORD PUBLIC

        EXTRN   OldInt21:DWORD         ; Address of old INT 21 handler
        EXTRN   PrefixSeg:WORD         ; Segment address of Pascal program's PSP

DSEG    ENDS


CSEG    SEGMENT WORD PUBLIC

        ASSUME  CS:CSEG, DS:DSEG

; CS relative Data Storage

HandleTable    DD ?                    ; Pointer to standard handle table in PSP
IntVector      DD ?                    ; Provide CS relative storage for old INT 21 vector
SaveFunction   DB ?                    ; Save DOS function number
SaveHandle     DB ?                    ; Save original handle
SaveLastDCB    DB ?                    ; Save original handle slot

; Initialize a few CS relative variables

ExtendInit PROC NEAR
        LES   AX,[OldInt21]            ; Get the original INT 21 vector into CS relative storage
        MOV   WORD PTR CS:[IntVector],AX
        MOV   WORD PTR CS:[IntVector+2],ES

        MOV   WORD PTR CS:[HandleTable],0018H ; Create a pointer to handle table in PSP
        MOV   AX,[PrefixSeg]
        MOV   WORD PTR CS:[HandleTable+2],AX
        RET

ExtendInit ENDP


; Main replacement for INT 21 handler

ExtendHandler PROC FAR

        PUSH  BP                       ; Save BP

        MOV   BP,SP                    ; Make sure this call is from our program
        MOV   BP,[BP+4]                ; BP = caller's CS
        CMP   BP,WORD PTR CS:[HandleTable+2] ; Is the caller's CS < our PSP address
        JB    IgnoreExtend
        CMP   BP,DSEG                  ; Is the caller's CS < our data segment
        JAE   IgnoreExtend

        POP   BP                       ; Restore BP

        CMP   AH,4BH                   ; Skip the rest of this if an EXEC function
        JNE   NotEXEC

IgnoreExtend:
        POP   BP                       ; Restore BP
        JMP   CS:[IntVector]           ; Go to original handler

NotEXEC:
        CMP   AH,46H                   ; Function $46 is only partially supported
        JNE   ValidFunction
        CMP   CL,4                     ; Permit FORCEDUP if it's a standard handle
        JBE   ValidFunction

NotSupported:
        MOV   AX,6                     ; Tell the user it's an invalid handle
        STC                            ; Signal an error
        JMP   ReturnToTurbo

ValidFunction:
        PUSH  DS                       ; Set up pointer to handle table
        PUSH  CX
        PUSH  DI
        LDS   DI,CS:[HandleTable]
        MOV   CL,[DI+19]               ; Remember contents of last handle slot
        MOV   CS:[SaveLastDCB],CL
        MOV   CS:[SaveFunction],AH     ; Save function code for later

        CMP   AH,3EH                   ; Check for DOS functions that pass a handle
        JB    CallOldInt21

        CMP   AH,40H                   ; Convert functions $3E..$40 (Close,Read,Write)
        JBE   ConvertDCB

        CMP   AH,42H                   ; Convert function $42 (Seek)
        JE    ConvertDCB

        CMP   AH,44H                   ; Convert function $44..$46 (IOCTL,DUP,FORCEDUP)
        JB    CallOldInt21

        CMP   AH,46H
        JBE   ConvertDCB

        CMP   AH,57H                   ; Convert function $57 (File time/date)
        JE    ConvertDCB

        CMP   AH,5CH                   ; Convert function $5C (Lock/Unlock)
        JE    ConvertDCB

        CMP   AH,68H                   ; Convert function $68 (Commit File)
        JNE   CallOldInt21

ConvertDCB:
        MOV   CS:[SaveHandle],BL       ; Save the original handle
        CMP   BL,4                     ; Check for output to standard handle
        JBE   CallOldInt21             ; Let calls with standard handle pass through

        SUB   BL,5                     ; Account for an offset of 5 in DCB number
        MOV   [DI+19],BL               ; Stuff DCB into last handle slot
        MOV   BL,19                    ; Use number of last handle slot

CallOldInt21:
        POP   DI                       ; Restore the registers
        POP   CX
        POP   DS
        PUSHF
        CALL  CS:[IntVector]           ; Fake an INT21 to original handler
        STI                            ; Allow interrupts

        PUSH  DS                       ; Setup pointer to handle table
        PUSH  DI
        PUSH  BX
        LDS   DI,CS:[HandleTable]      ; Check if INT handler returned an error
        JC    Done                     ; Possibly needs to goto CheckForHandle??

        MOV   BL,CS:[SaveFunction]     ; Check for return handles
        CMP   BL,3CH                   ; Convert function $3C (Create)
        JE    ConvertHandle
        CMP   BL,3DH                   ; Convert function $3D (Open)
        JE    ConvertHandle
        CMP   BL,45H                   ; Convert function $45 (Dup)
        JE    ConvertHandle
        CMP   BL,5AH                   ; Convert function $5A (Create unique)
        JE    ConvertHandle
        CMP   BL,5BH                   ; Convert function $5B (Create new)
        JE    ConvertHandle
        CMP   BL,68H                   ; Convert function $68 (Commit file)
        JNE   CheckForHandle

ConvertHandle:
        MOV   BX,AX                    ; Use handle as offset into handle table
        MOV   AL,0FFH                  ; Show the handle as unused
        XCHG  AL,[DI+BX]               ; Return DCB as handle number
        ADD   AL,5                     ; Use offset of 5 to avoid standard handles

CheckForHandle:
        MOV   BL,CS:[SaveFunction]     ; Check for handles left in registers
        CMP   BL,3FH                   ; Convert function $3F (Read)
        JE    RestoreHandle
        CMP   BL,40H                   ; Convert function $40 (Write)
        JE    RestoreHandle
        CMP   BL,42H                   ; Convert function $42 (Seek)
        JE    RestoreHandle
        CMP   BL,44H                   ; Convert function $44..$46 (IOCTL,DUP,FORCEDUP)
        JB    Success
        CMP   BL,46H
        JBE   RestoreHandle
        CMP   BL,57H                   ; Convert function $57 (File time/date)
        JE    RestoreHandle
        CMP   BL,5CH                   ; Convert function $5C (Lock/Unlock)
        JNE   Success

RestoreHandle:
        POP   BX
        MOV   BL,CS:[SaveHandle]       ; Restore original handle in case calling
        PUSH  BX                       ; program assumes BX unchanged

Success:
        CLC                            ; Everything is fine so clear error flag

Done:
        MOV   BL,CS:[SaveLastDCB]      ; Restore contents of last handle slot
        MOV   [DI+19],BL
        POP   BX
        POP   DI
        POP   DS
ReturnToTurbo:
        RET   2                        ; Return to the calling program and cleanup stack

ExtendHandler ENDP

CSEG    ENDS

        END
