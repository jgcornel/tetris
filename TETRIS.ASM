IDEAL
P386
MODEL FLAT, C
ASSUME CS:_TEXT,DS:FLAT,ES:FLAT,FS:FLAT,GS:FLAT

INCLUDE "KEYB.INC"
INCLUDE "HELPERS.INC"

TIMER_PERIOD    EQU 64

MACRO MEXIT @@CODE
        MOV     AL, @@CODE
        MOV     AH, 4CH
        INT     21H
ENDM MEXIT


CODESEG


PROC INITBOARD
        USES    EAX, ECX, EDI

        LEA     EDI, [BOARD]
        MOV     AX, 03FFCH
        STOSW
        MOV     AX, 0E007H
        MOV     ECX, 23
        REP     STOSW
        MOV     AX, 03FFCH
        STOSW
        RET
ENDP INITBOARD


PROC GETNEXTTETRO
        ARG     @@DROT:BYTE

        MOV     AX, [WORD PTR TETRO]
        ADD     AH, [@@DROT]
        AND     AH, 011B
        SHL     AL, 3
        SHL     AH, 1
        OR      AL, AH
        AND     EAX, 0FFH
        MOV     AX, [CODES + EAX]
        RET
ENDP GETNEXTTETRO


PROC GETNEXTSQUARE
        ARG     @@DCOL:DWORD, @@DROW:DWORD
        USES    EAX, ECX, ESI

        MOV     EAX, [@@DCOL]
        MOV     EBX, [@@DROW]
        MOV     CX, [WORD PTR LOC]
        ADD     CH, BL
        MOVZX   EBX, CH
        LEA     ESI, [BOARD + 2*EBX]
        ADD     CL, AL
        NEG     CL
        ADD     CL, 12
        MOV     CH, 4
@@L1:   SHL     BX, 4
        LODSW
        SHR     AX, CL
        AND     AX, 0FH
        OR      BX, AX
        DEC     CH
        JNZ     @@L1
        RET
ENDP GETNEXTSQUARE


PROC FREEZETETRO
        USES    EAX, EBX, ECX, EDX, EDI

        CALL    GETNEXTTETRO, 0
        MOVZX   EBX, [LOC + 1]
        LEA     EDI, [BOARD + 2*EBX]
        MOV     CL, [LOC]
        MOV     BX, 0F000H
        SHR     BX, CL
        MOV     CH, 4
@@L1:   MOV     DX, AX
        SHR     DX, CL
        AND     DX, BX
        OR      [EDI], DX
        SHL     AX, 4
        ADD     EDI, 2
        DEC     CH
        JNZ     @@L1
        RET
ENDP FREEZETETRO


PROC REMOVELINES
        USES    EAX, EBX, ECX, EDX, EDI, ESI

        STD
        MOV     EBX, 4
        MOV     EDX, 32
        MOVZX   EAX, [LOC + 1]
@@L1:   LEA     EDI, [BOARD + 2*EAX]
        LEA     ESI, [BOARD + 2*EAX - 2]
        CMP     [WORD PTR EDI], 0FFFFH
        JNE     @@L2
        INC     [LINES]
        ADD     [SCORE], EDX
        SHL     EDX, 1
        MOV     ECX, EAX
        DEC     ECX
        REP     MOVSW
@@L2:   INC     EAX
        DEC     EBX
        JNZ     @@L1
        CLD
        RET
ENDP REMOVELINES


PROC HANDLELEVEL
        USES    EAX

        MOV     EAX, [LEVEL]
        SHL     EAX, 2
        CMP     [LINES], EAX
        JL      @@L1
        CMP     [LEVEL], 8
        JE      @@L1
        INC     [LEVEL]
        SUB     [PERIOD], 8
        MOV     EAX, [LEVEL]
        AND     EAX, 111B
        MOVZX   EAX, [COLORS + EAX]
        CALL    GENERATESTRIPES, EAX
@@L1:   LEA     EAX, [LINESSTR + 7]
        CALL    ITODECSTR, EAX, [LINES]
        LEA     EAX, [SCORESTR + 7]
        CALL    ITODECSTR, EAX, [SCORE]
        LEA     EAX, [LEVELSTR + 7]
        CALL    ITODECSTR, EAX, [LEVEL]
        RET
ENDP HANDLELEVEL


PROC SPAWNTETRO
        USES    EAX

        CALL    RAND
        AND     AX, 0111B
        MOV     [WORD PTR TETRO], AX
        MOV     [WORD PTR LOC], 6
        CALL    GETNEXTTETRO, 0
        CALL    GETNEXTSQUARE, 0, 0
        TEST    EAX, EBX
        JZ      @@L1
        INC     [DEAD]
@@L1:   RET
ENDP SPAWNTETRO


PROC MOVE
        ARG     @@DCOL:DWORD, @@DROW:DWORD, @@DROT:DWORD
        USES    EAX, EBX

        CALL    GETNEXTTETRO, [@@DROT]
        CALL    GETNEXTSQUARE, [@@DCOL], [@@DROW]
        AND     AX, BX
        JNZ     @@L1
        MOV     EAX, [@@DCOL]
        MOV     EBX, [@@DROW]
        ADD     [LOC], AL
        ADD     [LOC+1], BL
        MOVZX   EAX, [TETRO+1]
        ADD     EAX, [@@DROT]
        AND     AL, 11b
        MOV     [TETRO+1], AL
        JMP     @@L2
@@L1:   CMP     [@@DROW], 1
        JNE     @@L2
        CALL    FREEZETETRO
        CALL    REMOVELINES
        CALL    HANDLELEVEL
        CALL    SPAWNTETRO
@@L2:   RET
ENDP MOVE


MACRO UPDATESCREEN
        CALL    WAITFORSYNC
        CALL    CLEARSCREEN
        CALL    COPYBUFFER
        CALL    PRINT, OFFSET LEVELSTR, 1, 15
        CALL    PRINT, OFFSET LINESSTR, 3, 15
        CALL    PRINT, OFFSET SCORESTR, 5, 15
ENDM UPDATESCREEN


MACRO INITGAME
        MOV     [DEAD], 0
        MOV     [LEVEL], 1
        MOV     [SCORE], 0
        MOV     [LINES], 0
        MOV     [PERIOD], TIMER_PERIOD
        CALL    RANDINIT
        CALL    SPAWNTETRO
        CALL    GENERATESTRIPES, 0FH
        CALL    INITBOARD
        CALL    SETVIDEOMODE, 13H
        CALL    __keyb_installKeyboardHandler
ENDM INITGAME


MACRO GODOWN
        CALL    MOVE, 0, 1, 0
ENDM GODOWN

MACRO GOLEFT
        CALL    MOVE, -1, 0, 0
ENDM GOLEFT
        
MACRO GORIGHT
        CALL    MOVE, 1, 0, 0
ENDM GORIGHT

MACRO ROTATE
        CALL    MOVE, 0, 0, 1
ENDM ROTATE


PROC MAIN
        STI
        CLD
        PUSH    DS
        POP     ES
BEGIN:  INITGAME
REPEAT: CMP     [DEAD], 0
        JNE     DONE
        MOV     [__keyb_rawScanCode], 0
        CALL    PAINTBOARD, OFFSET BOARD
        CALL    GETNEXTTETRO, 0
        CALL    PAINTTETRO, OFFSET LOC, AX
        UPDATESCREEN
        DEC     [TICS]
        JNZ     INPUT
        GODOWN
        MOV     ESI, OFFSET PERIOD
        MOV     EDI, OFFSET TICS
        MOVSW
        INPUT:  MOV     AL, [__keyb_rawScanCode]
        MOV     ECX, 6
        LEA     EDI, [KEYS]
        REPNE   SCASB
        JMP     [LABELS + 4*ECX]
ROT:    ROTATE
        JMP     REPEAT
DOWN:   GODOWN
        JMP     REPEAT
LEFT:   GOLEFT
        JMP     REPEAT
RIGHT:  GORIGHT
        JMP     REPEAT
DONE:   CALL    WAITFORSYNC
        CALL    CLEARSCREEN
        CALL    PRINT, OFFSET MESSAGE, 11, 0
        CMP     [__keyb_rawScanCode], 31H
        JE      BEGIN
        CMP     [__keyb_rawScanCode], 01H
        JE     EXIT
        JMP     DONE
EXIT:   CALL    __keyb_uninstallKeyboardHandler
        CALL    SETVIDEOMODE, 03H
        MEXIT   0
ENDP MAIN


STACK 100H


DATASEG


CODES       DW      0660H, 0660H, 0660H, 0660H
            DW      0F00H, 2222H, 0F00H, 2222H
            DW      0360H, 2310H, 0360H, 2310H
            DW      0630H, 1320H, 0630H, 1320H
            DW      0740H, 2230H, 1700H, 6220H
            DW      0710H, 3220H, 4700H, 2260H
            DW      0720H, 2320H, 2700H, 2620H
            DW      0750H, 0323H, 5700H, 6260H
TETRO       DB      0
            DB      0
LOC         DB      6
            DB      0
TICS        DW      TIMER_PERIOD
PERIOD      DW      TIMER_PERIOD
KEYS        DB      01H, 50H, 48H, 4BH, 4DH, 00H
LABELS      DD      REPEAT, RIGHT, LEFT, ROT, DOWN, EXIT
DEAD        DD      0
COLORS      DB      08H, 09H, 0AH, 0BH, 0CH, 0DH, 0EH, 0FH
SCORE       DD      0
LEVEL       DD      1
LINES       DD      0    
SCORESTR    DB      "SCORE: 0", 32 DUP('$')
LEVELSTR    DB      "LEVEL: 1", 32 DUP('$')
LINESSTR    DB      "LINES: 0", 32 DUP('$')
MESSAGE     DB      "YOU LOST!", 13, 10
            DB      "PRESS ESC TO EXIT", 13, 10
            DB      "PRESS N+N TO CONTINUE$"

UDATASEG


BOARD   DW      25 DUP(?)
STRING  DB      33 DUP(?)


END MAIN
