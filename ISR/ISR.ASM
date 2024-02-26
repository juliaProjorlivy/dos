.model tiny
.286;
.code
org 100h

Start:		push 05200h
		pop ES
	
		PUSH CS;			save registers
		PUSH SS
		PUSH ES
		PUSH DS
		PUSH SP
		PUSH BP
		PUSH DI
		PUSH SI
		PUSH DX
		PUSH CX
		PUSH BX
		PUSH AX
	
		MOV SI, offset cs:[RAX]
		mov CX, 12d;			12 registers
SaveRegs:	mov DX, CX;			save CX
		add SI, 5d;			first 5b 'reg = '
		POP AX
		CALL HexToStr
		MOV CX, DX	
		LOOP SaveRegs

		mov AX, 3509h;		get address of old isr
		int 21h

		MOV AH, 05H
		MOV AL, 0
		INT 10H

		MOV WORD PTR oldhandler, BX;	save address of old intrptr
		MOV WORD PTR oldhandler+2, ES

		cli;			set IF = 1
		push DS;		save DS

		mov AX, 2509h;		set new kb isr (my interrupter)
		mov DX, offset MyItrptr
		push CS
		pop DS
		int 21h

		pop DS;			save DS
		sti;			set IF = 0

endProg:	mov AX, 3100h;		terminate and make resident
		mov DX, offset EOP;	to the EOP
		shr DX, 4
		inc DX
		int 21h


MyItrptr	PROC

		pushf;			iret to sys interrupter
		call CS:oldhandler;	call old interrupter
	
		push AX;		save used registers
		push ES
		push DI

		in AL, 60h;		read symbol from port 60h
		cmp AL, 34h;		if '.'-> frame off
		je CloseFrame

		TEST cs:[FrameOn], 1h;	if frame has already been on->let it be
		jne PopoutFrame;	continue showing frame

		cmp AL, 33h;		if ',' -> frame on
		je PopoutFrame
	
		jmp Next;		continue

PopoutFrame:	mov AH, 05h;		active 1 vmem page
		mov AL, 0
		int 10h
		call FrameProg
		or cs:[FrameOn], 1h;	FrameOn flag on
		jmp Next;		continue

CloseFrame:	TEST cs:[FrameOn], 1
		je Next
		and cs:[FrameOn], 0h;	FrameOn flag off
		mov AH, 05h;		active 0 vmem page
		mov AL, 1
		int 10h

Next:		in AL, 61h
		or AL, 80h
		out 61h, AL
		in AL, 61h
		and AL, not 80h
		out 61h, AL

		mov AL, 20h
		out 20h, AL

		pop DI
 		pop ES
		pop AX

		iret

    	TitleText DB 'Registers'
	Style1 DB 0DAh, 011h, 0BFh, 01Fh, 020h, 01Eh, 0C0h, 010h, 0D9h	

	Style DW ?
	Color DB 5Ah
	Text DW ?
	TextLen DB 9d
	Len DB 17d
	Height DB 18d
	FrameOn DB 0h
	oldhandler DD ?	

	RAX DB 'AX = ', 4 DUP(?)
	RBX DB 'BX = ', 4 DUP(?)
	RCX DB 'CX = ', 4 DUP(?)
	RDX DB 'DX = ', 4 DUP(?)
	RSI DB 'SI = ', 4 DUP(?)
	RDI DB 'DI = ',	4 DUP(?)
	RBP DB 'BP = ', 4 DUP(?)
	RSP DB 'SP = ', 4 DUP(?)
	RDS DB 'DS = ', 4 DUP(?)
	RES DB 'ES = ', 4 DUP(?)
	RSS DB 'SS = ', 4 DUP(?)
	RCS DB 'CS = ', 4 DUP(?)
	
		ENDP

;------------HEX TO STRING(2 bytes)-----------
;ASSUME: AX - number,
;	CS:[SI] - address for result
;DESTROY: CX, BX, SI
;---------------------------------------------
HexToStr:	mov CX, 4d;			to 4 bytes string

ParseAX:	mov BX, 0F000h;	
		and BX, AX;			take fisrt number
		shr BX, 12d

		cmp BX, 9d;			if alpha->+55d
		ja alpha
		add BX, 30h;			if number->+30h
		jmp endHexToStr
alpha:		add BX, 55d

endHexToStr:	mov BYTE PTR CS:[SI], BL
		inc SI
		SHL AX, 4;			next number
		LOOP parseAX
		
		RET

FrameProg	PROC
		push ES
		push SI
		push DI
		push AX
		push BX
		push CX
		push DX

		StartOffset EQU 160d;		160 bytes in one string
		ShadowColor EQU 01100000b;	shade color	
		EmptyCell EQU 00h

		NEXTSTR MACRO ;			shift on next string
		add BX, StartOffset
		mov DI, BX
		ENDM

		mov cs:[Text], offset cs:[TitleText]
		mov cs:[Style], offset cs:[Style1]

		COMMENT * FrameData:
			Len - frame length
			Hight - frame hight
			TextLen - length of included text
			Style - address of the style
			Text - address of the text 
			Color - frame color *

		mov BX, 0B800h;
		mov ES, BX;		ES = B800h (address of text segment)
		mov BX, 80d;		BX = length of all string
		sub BL, cs:[Len];	BL -= frame length
		TEST BX, 1b;		Check whether BX is even
		je print;		no->go to print
		inc BX;			else->make it even (BX++)

print:		add BX, 160*2;		DI = BX += 160*2 (skip 2 strings above)
		mov DI, BX
		call PrintFrame;	go to PrintFrame

		pop DX
		POP CX
		POP BX
		POP AX
		POP DI	
		POP SI
		POP ES

		ret

;----------PrintFrame-----------------------
;ASSUME:Len - lenght,
;	Hight - hight,
;	Style - style,
;	Color - color,
;	Text - text;
;-------------------------------------------
PrintFrame:	push BX
		xor CX, CX;		CX = 0
		mov CL, cs:[Len];	CL = frame length
		mov AH, cs:[Color];	AH = frame color
		mov AL, EmptyCell;	AL = empty cell
		REP STOSW;		print emtpy line

		NEXTSTR		

		mov SI, cs:[Style];	SI = address of Style
		call PrintTitle;	print title
		
		NEXTSTR

		mov CL, cs:[Height];		print middle part
		sub CL, 4d
		
printMiddle:	mov DH, CL;		save CX
		mov CL, cs:[Len];		CL = frame length
		call PrintLine

		NEXTSTR

		mov CL, DH
		sub SI, 2d;		return SI
		LOOP printMiddle

		add SI, 3d;		SI = address of third Style
		mov CL, cs:[Len]
		
		call PrintLine;		print ending string

		NEXTSTR

		mov CL, cs:[Len];		print the last empty line
		mov AL, EmptyCell
		REP STOSW

		NEXTSTR

		mov CL, cs:[Len];		DRAW SHADOW
		mov DH, cs:[Height]
		mov AL, cs:[ShadowColor]		
		call DrawShadow;		BX - start of 2 line; ES-VMEM
		
		POP BX
		add BX, 3*StartOffset
		add BX, 8d
		mov DI, BX
		mov SI, offset cs:[RAX]
		mov CX, 12d
		mov AH, 9d
		call InsertRegs

		ret

;------------ INSERT TEXT -------------------
;ASSUME:CS:[SI] - address of text
;	ES:[DI] - address of vmem
;	CX - number of strings
;	AH - the length of each string
;DESTROY:SI, DI, AL, DX, CX 
;--------------------------------------------
InsertRegs:	mov DX, CX;			save CX
		MOV CL, AH;			for second loop
drawReg:	mov AL, cs:[SI];		print byte to vmem
		STOSB

		inc SI;				next byte
		inc DI;				skip color

		LOOP drawReg;			second loop

		NEXTSTR;			BX+160 -> DI
	
		mov CX, DX
		LOOP InsertRegs;		first loop

		ret
		
;------------ PRINT TITLE -------------------
;	PRINT FRAME LINE WITH TITLE
;ASSUME:AL - frame color
;	TextLen - the length of included text
;	Len - the length of frame
;	SI - address of Style
;	Style - address of Style
;	ES:[DI] - destination address
;	EmptyCell - outer frame symb
;DESTROY:AH, CX, DH
;RETURN:ES:[DI] - next destination address
;	SI - address of next 3 Style symb
;--------------------------------------------
PrintTitle:	mov CL, cs:[Len];		check if str length is too big
		sub CL, 6d;			if so -> cut it
		cmp cs:[TextLen], CL
		jbe notcutLen
		mov cs:[TextLen], CL

notcutLen:	mov AL, EmptyCell
		STOSW
	
		mov AL, BYTE PTR cs:[SI];	AH = firts Style symb
		STOSW

		mov CL, cs:[Len]
		sub CL, cs:[TextLen]
		sub CL, 6d;		2 empty, 2 first Style, 2 between Text
		shr CL, 1;		CL = 1/2 len of second Style symbs
		mov DH, CL;		save CL
		
		inc SI;			print second Style symb (1 part)
		mov AL, BYTE PTR cs:[SI];	AH = second Style symb
		REP STOSW

		mov AL, EmptyCell
		STOSW
	
		mov CL, cs:[TextLen];	CX = text length
		mov cs:[Style], SI;		Style update
		mov SI, cs:[Text];		SI = address of Text
		
printText:	mov AL, BYTE PTR cs:[SI]
		STOSW
		inc SI
		LOOP printText

		mov AL, EmptyCell;	after text space
		STOSW

		mov CL, cs:[Len];		CL = number of second Style symb
		sub CL, DH
		sub CL, 6d
		sub CL, cs:[TextLen]
		
		mov SI, cs:[Style];		print second Style symbs (2 part)
		mov AL, BYTE PTR cs:[SI]
		REP STOSW

		inc SI;			print third Style syb 
		mov AL, BYTE PTR cs:[SI]
		STOSW

		mov AL, EmptyCell;	print empty cell
		STOSW

		inc SI;
		ret

;-------------- PRINT LINE -------------------------------
;	PRINT CX IDENTICAL LINES
;ASSUME:CX = string length,
;	SI = Style address,
;	ES:[DI] = destination address,
;	AL = frame color,
;	EmptyCell = outer frame symb;
;	;DH = number of LOOPS (number of repeated lines),
;DESTROYS:AH (EmptyCell), CX
;----------------------------------------------------------
PrintLine:	mov AL, EmptyCell;	fisrt cell - the empty one
		STOSW

		mov AL, BYTE PTR cs:[SI]; second cell - fist sybm from Style
		STOSW
		
		inc SI;			SI = second Style symb
		sub CX, 4d;		CL -= 4 (2 empty and 2 end symb)
		mov AL, BYTE PTR cs:[SI];	AH = second Style symb
		REP STOSW;		fill inner part of the string

		inc SI;			SI = third Style symb
		mov AL, BYTE PTR cs:[SI];	AH = third Style symb
		STOSW

		mov AL, EmptyCell;	last frame cell - empty
		STOSW;

		ret

;---------- DRAW SHADOW --------------------
;ASSUME:AL - shadow color,
;	CL - frame length,
;	DH - frame hight
;
;DESTROY:CX(=0), DI, BX
;-------------------------------------------
DrawShadow:	add DI, 4d;		shift from the edge

shadowLine:	inc DI;			skip DI
		STOSB
		LOOP shadowLine;	print shadow line 

		sub DI, 4d
		mov BX, DI
		
		mov CL, DH;		CL = frame hight
		dec CL

loopShadow:	sub BX, 160d;	address of upper string
		mov DI, BX
		inc DI;			skip byte
		STOSB
		inc DI;			skip byte
		STOSB
		LOOP loopShadow;	fill shadow around the string
		
		ret
		ENDP
	

EOP:

end Start


	



