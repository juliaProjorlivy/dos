.model tiny
.286
.code
org 100h

Start:
    mov AL, 08h;                SAVE OLD TIMER INT AND SET UP NEW ONE
    LEA SI, oldTimer
    LEA DX, MyTimer

    call SetUpInt

    mov AL, 09h;                SAVE OLD KB INT AND SET UP NEW ONE
    LEA SI, oldKb
    LEA DX, MyKb

    call SetUpInt

    mov AX, 3100h;              MAKE PROGRAM RESIDENT AND TERMINATE
    mov DX, offset EOP
    shr DX, 4
    inc DX
    int 21h

;-----------------SET UP INTERRUPTER-----------------------
;   SAVE OLD INT IN [SI] AND SET UP NEW ONE FROM [DI]
;ASSUME:SI - address of old interrupter 
;       DX - address of code for new interrupter
;       AL - number of interrupter
;DESTROY:BX, ES, DX, SI, DI, AL
;----------------------------------------------------------
SetUpInt:
    mov AH, 35h;                GET ADDRESS OF OLD TIMER
    int 21h

    mov [SI], BX;               SAVE OLD TIMER ADDRESS
    mov [SI+2], ES

    push DS;                    save DS

    mov AH, 25h;                SET NEW TIMER
    push CS;                    in 25h offset relevant DS
    pop DS
    int 21h

    pop DS;                     save DS
    ret

;------------------NEW KEYBOARD INTERRUPTER-----------------------
;   SET FRAME FLAG 1 IF ',' WAS PRESSED AND O IF '.'
;-----------------------------------------------------------------
MyKb    PROC
    pushf
    call CS:[oldKb]

    push AX;                    save AX

    in AL, 60h;                 get scan code

    cmp AL, 34h;                if AL=='.' -> frame flag off
    je FrameOff

    cmp AL, 33h;                if AL==',' -> frmae flag on
    je FrameOn

endKbProc:
    in AL, 61h
    or AL, 80h
    out 61h, AL
    in AL, 61h
    and AL, not 80h
    out 61h, AL

    mov AL, 20h
    out 20h, AL

    pop AX;                     save AX

    iret
    oldKb DD ?

FrameOff:
    mov CS:[FrameFl], 0;        FRAME FLAG = 0
    jmp endKbProc

FrameOn:
    mov CS:[FrameFl], 1;        FRAME FLAG = 1
    jmp endKbProc

    ENDP

;---------------FROM HEX TO STRING----------------
;   CONVERT HEX NUMBERS TO STRING : HH?? -> CCCC
;ASSUME:SI - address hex number 
;       [SI, SI+3] - string result
;DESTROY:AX, BX, SI
;-------------------------------------------------
HexToStr:
    mov AX, WORD PTR CS:[SI];   AX - hex number
    mov WORD PTR CS:[SI], 3030h;fill them with zeros
    add SI, 3;                  set SI to the end of string

convert:
    cmp AX, 0;                  if AX==0 -> end of converting
    jne contConver
    ret

contConver:
    mov BX, 000Fh;              get last number 
    and BX, AX

    cmp BX, 9d;                 if BX is digit -> add 30h
    ja alpha;                   if not -> add 55d
    add BX, 30h

putchar:
    mov BYTE PTR CS:[SI], BL;   put char in memory
    dec SI
    shr AX, 4
    jmp convert;                do it 4 times or until AX=0

alpha:
    add BX, 55d;
    jmp putchar
    

MyTimer    PROC
    pushf;                      call old Timer
    call CS:[oldTimer]

    test CS:[FrameFl], 1;       if frame has already been set ->
    jne popoutFrame;            -> do next step, else print frame
    
    jmp next

popoutFrame:
    push SI;                    save SI value
    mov SI, offset CS:[regsVal];SI address part of mem with regs val

    mov CS:[SI], AX;            SAVE REGS VALUE IN MEMORY
    add SI, 4
    mov CS:[SI], BX
    add SI, 4
    mov CS:[SI], CX
    add SI, 4
    mov CS:[SI], DX
    add SI, 4

    pop CS:[SI]
    add SI, 4

    mov CS:[SI], DI
    add SI, 4
    mov CS:[SI], BP
    add SI, 4
    mov CS:[SI], SP
    add SI, 4
    mov CS:[SI], DS
    add SI, 4
    mov CS:[SI], ES
    add SI, 4
    mov CS:[SI], SS
    add SI, 4
    mov CS:[SI], CS

    push ES;                    SAVE REGS VAL 
    push DI
    push SI 
    push DX
    push CX
    push BX
    push AX 

    mov CS:[regs], SI
    mov CX, 12d;                CONVERT ALL REGISTERS VALS TO STRINGS
regsToStr:
    mov SI, CS:[regs];          SI - address of register
    call HexToStr;
    sub CS:[regs], 4;           regs - address of previous register
    LOOP regsToStr;             convert all regis into strings
    add CS:[regs], 4

    call FrameProg;             PRINT FRAME WITH REGS

    pop AX 
    pop BX
    pop CX
    pop DX
    pop SI 
    pop DI
    pop ES 

next:

    iret
    oldTimer DD ?

    regsVal DB 12*4 DUP(30h)
    regs DW ?
    regNames DB 'AXBXCXDXSIDIBPSPDSESSSCS'
    eqChar DB ' = '

    Color DB 5Ah
    Style DB 0DAh, 011h, 0BFh, 01Fh, 020h, 01Eh, 0C0h, 010h, 0D9h
    TitleText DB 'Registers'
    TitleLen DB 9
    TitleAdd DW ?
    Len DB 15d 
    Height DB 18d
    FrameFl DB 0 
    
    ENDP


;----------------FRAME PROGRAM-----------------
;   PRINT FRAME WITH REGISTERS AND THEIR VALUE
;DESTROY:AX, BX, CX, DX, SI, DI, ES
;----------------------------------------------
FrameProg   PROC

    StartOffset EQU 160d;       160 bytes in one string
    ShadowColor EQU 60h
    EmptyCell EQU 00h

    NEXTSTR MACRO;              shift to the next string
    add BX, StartOffset
    mov DI, BX
    ENDM

    mov CS:[TitleAdd], offset CS:[TitleText]

    COMMENT * FrameData:
        Len - frame length
        Height - frame height
        TextLen - length of Text
        Style - frame style
        Title - frame Title
        Color - frame Color *

    mov BX, 0B800h;             ES:[DI] - vmem address
    mov ES, BX

    mov BX, 80d;                CALCULATE START OF FRAME
    sub BL, CS:[Len]
    TEST BX, 1
    je letsPrint
    inc BX

letsPrint:
    add BX, 160*2
    mov DI, BX
    push BX
    call PrintFrame

    pop BX
    add BX, 6

    mov CX, 12d;
    lea DX, CS:[regsVal]
    lea SI, CS:[regNames]
    NEXTSTR
    NEXTSTR
    call InsertRegs

    ret 

;------------INSERT REGISTERS-------------------
;ASSUME:SI - regNames address
;       regs - regs values address
;       CX - number of regs
;       ES:[DI] - vmem address
;DESTROY:CX, ES, DI, SI, BX, DX
;------------------------------------------
InsertRegs:
    NEXTSTR
    mov AL, CS:[SI];           PRINT REG NAME
    STOSB
    inc SI
    inc DI

    mov AL, CS:[SI]
    STOSB
    inc SI 
    inc DI

    mov AL, CS:[eqChar];       PRINT EQUAL CHAR
    STOSB
    inc DI
    mov AL, CS:[eqChar+1]
    STOSB
    inc DI
    mov AL, CS:[eqChar+2]
    STOSB
    inc DI

    mov DX, SI
    mov SI, CS:[regs]

    mov AL, BYTE PTR CS:[SI];            PRINT REG VALUE
    STOSB
    inc SI
    inc DI
    mov AL, BYTE PTR CS:[SI]
    STOSB
    inc SI
    inc DI
    mov AL, BYTE PTR CS:[SI]
    STOSB
    inc SI
    inc DI
    mov AL, BYTE PTR CS:[SI]
    STOSB
    inc SI
    inc DI

    mov CS:[regs], SI
    mov SI, DX
    
    LOOP InsertRegs

    ret


;------------------PRINT FRAME---------------------
;
;--------------------------------------------------
PrintFrame:
    xor CX, CX

    mov CL, CS:[Len];           PRINT FIRST (EMPTY) STRING
    mov AH, CS:[Color]
    mov AL, EmptyCell
    rep STOSW

    NEXTSTR

    lea SI, CS:[Style];           PRINT SECOND (TITLE) STRING
    call PrintTitle

    NEXTSTR

    mov CL, CS:[Height];        PRINT MIDDLE PART
    sub CL, 4d;                 2 for empty strings, 2 for boarder

PrintMiddle:
    mov DH, CL;                 save CL
    mov CL, CS:[Len]
    call PrintLine

    NEXTSTR

    mov CL, DH
    sub SI, 3;                  SI(Style) is second part of Style
    LOOP PrintMiddle

                                ;PRINT ENDING BOARDER
    add SI, 3d;                 SI is third part of Style
    mov CL, CS:[Len]
    call PrintLine

    NEXTSTR

    mov CL, CS:[Len];           PRINT ENDING EMPTY LINE
    mov AL, EmptyCell
    rep STOSW

    NEXTSTR

    mov CL, CS:[Len];           PRINT SHADOW
    mov DH, CS:[Height]
    mov AL, ShadowColor
    mov DI, BX
    call DrawShadow

    ret

;--------------PRINT TITLE---------------------
;   PRINT FRAME STRING WITH TITLE
;ASSUME:AL - frame Color
;       TitletLen - length of Title
;       Len - length of frame
;       SI - address of style
;       ES:[DI] - vmem address
;       EmptyCell - outer frame symb
;RETURN:SI - next part of Style address
;       AH - frame Color
;USED:AX, CX, DH, SI, ES, DI
;-----------------------------------------------
PrintTitle:
    mov CL, CS:[Len];           CUT TITLE IF IT'S LENGTH IS TOO BIG
    sub CL, 6d;
    cmp CS:[TitleLen], CL
    jbe contPrintTitle
    mov CS:[TitleLen], CL

contPrintTitle:
    mov AL, EmptyCell;          PRINT FIRST EMPTY CHAR
    STOSW

    mov AL, BYTE PTR CS:[SI];   PRINT FIRST FRAME CHAR
    STOSW

    mov CL, CS:[Len];           GET LENGTH OF SECOND FRMAE CHAR(PART1)
    sub CL, CS:[TitleLen]
    sub CL, 6
    shr CL, 1
    mov DH, CL

    inc SI;                     si - second frmae char

    mov AL, BYTE PTR CS:[SI];   PRINT FIRST HALF OF SECOND FRAME CHAR
    rep STOSW

    mov AL, EmptyCell;          PRINT SPACE
    STOSW

    mov CL, CS:[TitleLen];       PRINT TITLE TEXT
    mov SI, offset TitleText
printText:
    mov AL, CS:[SI]
    STOSW
    inc SI
    LOOP printText

    mov AL, EmptyCell;          PRINT SPACE
    STOSW

    mov CL, CS:[Len];           GET LENGTH OF SECOND FRAME CHAR(PART2)
    sub CL, DH
    sub CL, 6
    sub CL, CS:[TitleLen]

    mov SI, offset Style
    inc SI

    mov AL, BYTE PTR CS:[SI];   PRINT SECOND HALF OF SECOND FRAME CHAR
    rep STOSW

    inc SI;                     SI - third frame CHAR

    mov AL, BYTE PTR CS:[SI];   PRINT THIRD FRAME CHAR
    STOSW

    inc SI 
    mov AL, EmptyCell
    STOSW

    ret

;----------PRINT FRAME LINE-------------------
;ASSUME:AL - frame Color
;       SI - frame style address
;       ES:[DI] - vmem address
;       EmptyCell - outer frame symb
;RETURN:SI - 
;USED:AX, SI, ES, DI
;---------------------------------------------
PrintLine:
    mov AL, EmptyCell;          PRINT FIRT SPACE CHAR
    STOSW

    mov AL, BYTE PTR CS:[SI];   PRINT FIRST STYLE CHAR
    STOSW

    inc SI

    sub CX, 4;                  PRINT SECOND STYLE CHARS
    mov AL, BYTE PTR CS:[SI]
    rep STOSW

    inc SI

    mov AL, BYTE PTR CS:[SI];   PRINT THIRD STYLE CHAR
    STOSW

    mov AL, EmptyCell;          PRINT LAST SPACE CHAR
    STOSW

    inc SI;                     SI NEXT PART OF FRAME STYLE
    ret

;-----------DRAW SHADOW-----------------------------
;ASSUME:AL - shadow Color
;       CL - frame length
;       DH - frame height
;DESTROY:CX, BX, ES, DI
;---------------------------------------------------
DrawShadow:
    add DI, 4d;                 shift from the edge

shadowLine:
    inc DI
    STOSB;                      PRINT FRAME LOWER SHADOW BOARDER
    LOOP shadowLine

    sub DI, 4d;                 BX - offset from the string start
    mov BX, DI

    mov CL, DH;                 CL - height
    dec CL

shadowLoop:;                    PRINT HORIZONTAL SHADOW BOARDER
    inc DI;
    STOSB
    inc DI;
    STOSB;
    sub BX, StartOffset
    mov DI, BX
    LOOP shadowLoop

    ret
    ENDP

EOP:
end Start
