.model tiny
.286;
.code
org 100h

Start:		;mov AX, 3509h;			get interrupt vector	
		;int 21h
		
		;call MyNewProg
		;call MyNewProg
		;jmp endProg
		;mov oldOffset, BX;		save old ISR
		;mov BX, ES
		;mov oldSeg, BX
		
		mov [oldSeg], CS
		mov [oldOffset], offset MyNewProg

		
		mov AX, 3509h
		int 21h
		mov old09hofs, BX
		mov BX, ES
		mov old09hseg, BX

		cli;				set IF = 1
		push DS
		mov AX, 2509h
		mov DX, offset MyItrptr
		push CS
		pop DS
		int 21h
		pop DS

		sti

endProg:	mov AX, 3100h
		mov DX, offset EOP
		shr DX, 4
		inc DX
		int 21h

		oldOffset DW ?
		oldSeg DW ?

MyItrptr	PROC
		push AX
		push ES
		
		push 0B800h;		vMem
		pop ES
		mov DI, 160*5+80
		
		mov AH, 4Eh;		Color
		in AL, 60h;		read symbol from port 60h
		cmp AL, 33h
		je PopoutFrame
		STOSW;			ES:[DI+=2] = AX
		jmp Next

PopoutFrame:	call FRAMEPROG

Next:		in AL, 61h
		or AL, 80h
		out 61h, AL
		in AL, 61h
		and AL, not 80h
		out 61h, AL

		mov AL, 20h
		out 20h, AL

 		pop ES
		pop AX

		;iret

		call MyNewProg

		DB 0EAh
		old09hofs DW ?
		old09hseg DW ?
		
		iret

		heart db 03h

    TitleText DB 'Registers'
	Style1 DB 0DAh, 011h, 0BFh, 01Eh, 0B1h, 01Fh, 0C0h, 010h, 0D9h	

	Style DW ?
	Color DB 4Ah
	Text DW ?
	TextLen DB 9d
	Len DB 20d
	Height DB 20d

		ENDP

MyNewProg	PROC
		;EXTERN heart:BYTE
		push DI
		push AX
		push ES
		
		push 0B800h
		pop ES
		mov DI, 80*20
		mov AH, 4eh
		mov AL, cs:[heart]
		STOSW
		;inc AL
		;mov heart, AL

		pop ES
		pop AX
		pop DI
		ret

		ENDP

FRAMEPROG	PROC
		push ES
		push SI
		push DI
		push AX
		push BX
		push CX
		push DX

		xor AX, AX
		xor BX, BX
		xor CX, CX
		xor DX, DX
		xor DI, DI
		xor SI, SI

		StartOffset EQU 160d;		160 bytes in one string
		ShadowColor EQU 01100000b;	shade color	
		EmptyCell EQU 00h

		NEXTSTR MACRO ;			shift on next string
		add BX, StartOffset
		mov DI, BX
		ENDM

		mov cs:[Text], offset cs:[TitleText]
		mov cs:[Style], offset cs:[Style1]
		;MOV Text, offset cs:[TitleText]
		;MOV Style, offset cs:[Style1]			

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
PrintFrame:	xor CX, CX;		CX = 0
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
		call DrawShadow

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
PrintTitle:	mov CL, cs:[Len]
		sub CL, 6d
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


	



