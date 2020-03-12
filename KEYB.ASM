IDEAL
P386
MODEL FLAT, C
ASSUME cs:_TEXT,ds:FLAT,es:FLAT,fs:FLAT,gs:FLAT

INCLUDE "KEYB.INC"


CODESEG


PROC __keyb_installKeyboardHandler
    USES EAX, EBX, ECX, EDX, EDI

    CLD
    MOV  ECX, 128/2 + 1
    MOV  EDI, OFFSET __keyb_keyboardState
    XOR  EAX, EAX
    REP  STOSW

    PUSH ES
    MOV  AH, 35H ; get interrupt vector
    MOV  AL, 09H ; interrupt number
    INT  21H
    MOV  [oldHandlerSelector], ES ; ES:BX -> current interrupt handler
    MOV  [oldHandlerOffset], EBX
    POP  ES

    PUSH DS
    MOV  AX, CS
    MOV  DS, AX
    MOV  EDX, OFFSET keyboardHandler ; DS:DX -> new interrupt handler
    MOV  AH, 25H ; set interrupt vector
    MOV  AL, 09H ; interrupt number
    INT  21H
    POP  DS
    RET
ENDP __keyb_installKeyboardHandler


PROC __keyb_uninstallKeyboardHandler
    USES EAX, EDX
    
    PUSH DS
    MOV  EDX, [oldHandlerOffset]
    MOV  DS, [oldHandlerSelector] ; DS:DX -> old interrupt handler
    MOV  AH, 25H ; set interrupt vector
    MOV  AL, 09H ; interrupt number
    INT  21H
    POP  DS
    RET
ENDP __keyb_uninstallKeyboardHandler


KEY_BUFFER  EQU 60h         ; the port of the keyboard buffer
KEY_CONTROL EQU 61h         ; the port of the keyboard controller
PIC_PORT    EQU 20h         ; the port of the peripheral

PROC keyboardHandler
    PUSH EAX
    PUSH EDX
    PUSH ESI
    PUSH DS
    MOV  AX, _DATA
    MOV  DS, AX
    STI
    IN   AL, KEY_BUFFER
    MOV  BL, AL
    MOV  [__keyb_rawScanCode], AL
    IN   AL, KEY_CONTROL
    OR   AL, 82H
    OUT  KEY_CONTROL, AL
    AND  AL, 7FH
    OUT  KEY_CONTROL, AL
    MOV  AL, 20H
    OUT  PIC_PORT, AL
    MOV  AL, BL
    SHL  AX, 1
    NOT  AH
    AND  AH, 1
    SHR  AL, 1
    XOR  EBX, EBX
    MOV  BL, AL
    LEA  ESI, [__keyb_keyboardState + EBX]
    MOV  AL, [ESI]
    NEG  AL
    ADD  AL, AH
    ADD  [__keyb_keysActive], AL
    MOV  AL, AH
    MOV  [ESI], AL
    POP  DS
    POP  ESI
    POP  EBX
    POP  EAX
    IRETD    
ENDP keyboardHandler

DATASEG

oldHandlerSelector  dw ?
oldHandlerOffset  dd ?

__keyb_keyboardState        db 128 dup(?)
__keyb_rawScanCode          db ?
__keyb_keysActive           db ?

END
