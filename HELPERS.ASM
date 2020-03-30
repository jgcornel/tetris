IDEAL
P386
MODEL FLAT, C
ASSUME CS:_TEXT,DS:FLAT,ES:FLAT,FS:FLAT,GS:FLAT

INCLUDE "HELPERS.INC"


CODESEG


PROC CLEARSCREEN
        USES    EAX, ECX, EDI

        MOV     EDI, 640*1024
        MOV     ECX, 16000
        MOV     EAX, 0
        REP     STOSD
        RET
ENDP CLEARSCREEN


PROC SETVIDEOMODE
        ARG     @@MODE:BYTE
        USES    EAX

        MOV     AL, [@@MODE]
        MOV     AH, 0H
        INT     10H
        RET
ENDP SETVIDEOMODE


PROC WAITFORSYNC
        USES    EAX, EDX

        MOV     DX, 03DAH
@@L1:   IN      AL, DX
        AND     AL, 1000B
        JNZ     @@L1
@@L2:   IN      AL, DX
        AND     AL, 1000B
        JZ      @@L2
        RET
ENDP WAITFORSYNC


PROC GENERATESTRIPES
        ARG     @@COLOR:BYTE
        USES    EAX, ECX, EDX, EDI

        XOR     DL, DL
        LEA     EDI, [STRIPES]
@@L1:   MOV     DH, 1000B
@@L2:   MOV     AL, 0
        TEST    DL, DH
        JZ      @@L3
        MOV     AL, [@@COLOR]
@@L3:   MOV     ECX, 8
        REP     STOSB
        SHR     DH, 1
        JNZ     @@L2
        INC     DL
        CMP     DL, 10H
        JL      @@L1
        RET
ENDP GENERATESTRIPES


PROC PAINTBOARD
        ARG     @@BOARD:DWORD
        USES    EAX, EBX, ECX, EDX, EDI, ESI

        LEA     EDI, [BUFFER]
        MOV     ESI, [@@BOARD]
        MOV     DH, 25
@@L1:   LODSW
        AND     AX, 03FFCH
        PUSH    ESI
        MOV     DL, 4
@@L2:   ROL     AX, 4
        MOVZX   EBX, AX 
        AND     EBX, 0FH
        SAL     EBX, 5
        LEA     ESI, [STRIPES + EBX]
        MOV     ECX, 8
        REP     MOVSD
        DEC     DL
        JNZ     @@L2
        MOV     DL, 7
@@L3:   ADD     EDI, 192
        MOV     ESI, EDI
        SUB     ESI, 320
        MOV     ECX, 32
        REP     MOVSD
        DEC     DL
        JNZ     @@L3
        ADD     EDI, 192
        POP     ESI
        DEC     DH
        JNZ     @@L1
        RET
ENDP PAINTBOARD


PROC PAINTCELL
        ARG     @@Y:DWORD, @@X:DWORD, @@COLOR:BYTE
        USES    EAX, EBX, ECX, EDX, EDI

        MOV     AL, [@@COLOR]
        MOV     EDX, [@@Y]
        SAL     EDX, 3
        MOV     EBX, EDX
        SAL     EDX, 8
        SAL     EBX, 6
        ADD     EDX, EBX
        MOV     EBX, [@@X]
        SAL     EBX, 3
        ADD     EDX, EBX
        LEA     EDI, [BUFFER + EDX]
        MOV     AH, 8
@@L1:   MOV     ECX, 8
        REP     STOSB
        ADD     EDI, 320 - 8
        DEC     AH
        JNZ     @@L1
        RET
ENDP PAINTCELL


PROC PAINTTETRO
        ARG     @@LOC:DWORD, @@TETRO:WORD
        
        MOV     EBX, [@@LOC]
        MOV     AX, [@@TETRO]
        MOV     BX, [WORD PTR EBX]
        MOV     CL, 4
        MOVZX   EDX, BH
@@L1:   MOVZX   EDI, BL
        MOV     BH, 01000B
        ROL     AX, 4
@@L2:   TEST    AL, BH
        JZ      @@L3
        CALL    PAINTCELL, EDX, EDI, 20H
@@L3:   INC     EDI
        SHR     BH, 1
        JNZ     @@L2
        INC     EDX
        DEC     CL
        JNZ     @@L1
        RET
ENDP PAINTTETRO


PROC COPYBUFFER
        USES   EBX, ECX, ESI, EDI

        LEA     ESI, [BUFFER]
        MOV     EDI, 640*1024
        MOV     ECX, 16000
        REP     MOVSD
        RET
ENDP COPYBUFFER


PROC RANDINIT
        ; based on Tim Bruylandts 2015
        ; modified by David Blinder 2017
        MOV     AH, 02CH
        INT     21H
        MOV     AX, DX
        SHL     EAX, 16
        MOV     AX, CX
        MOV     AH, 02AH
        INT     21H
        SHL     ECX, 16
        MOV     CX, DX
        XOR     EAX, ECX
        MOV     [RSEED], EAX
        RET
ENDP RANDINIT


PROC RAND
        ; based on Tim Bruylandts 2015
        ; modified by David Blinder 2017
        USES    EDX

        MOV     EAX, [RSEED]
        MOV     EDX, 1103515245
        MUL     EDX
        ADD     EAX, 12345
        MOV     [RSEED], EAX
        SHR     EAX, 24
        AND     EAX, 111B
        RET
ENDP RAND


PROC ITODECSTR
        ARG     @@OFFSET:DWORD, @@INTEGER:DWORD
        USES    EAX, EBX, ECX, EDX, EDI

        MOV     EDI, [@@OFFSET]
        MOV     EAX, [@@INTEGER]
        MOV     EBX, 10
        XOR     ECX, ECX
        CMP     EAX, 0
        JGE     @@L1
        NEG     EAX
        MOV     [BYTE PTR EDI], '-'
        INC     EDI
@@L1:   XOR     EDX, EDX
        DIV     EBX
        INC     ECX
        PUSH    DX
        TEST    EAX, EAX
        JNZ     @@L1
@@L2:   POP     AX
        ADD     AX, '0'
        STOSB
        LOOP    @@L2
        MOV     [BYTE PTR EDI], '$'
        RET
ENDP ITODECSTR


PROC PRINT
        ARG     @@OFFSET:DWORD, @@LINE:DWORD, @@POS:DWORD
        USES    EAX, EBX, EDX, EDI

        MOV     EDX, [@@LINE]
        MOV     EBX, [@@POS]
        MOV     AH, 02H
        SHL     EDX, 08H
        MOV     DL, BL
        MOV     BH, 0
        INT     10H
        MOV     EDX, [@@OFFSET]
        MOV     AH, 09H
        INT     21H
        RET
ENDP PRINT        


STACK 100H


DATASEG


UDATASEG


STRIPES DB      16  * 32  DUP(?)
BUFFER  DB      200 * 320 DUP(?)
STRING  DB      33 DUP(?)
RSEED   DD      ?


END
