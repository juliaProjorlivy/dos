.model tiny
.286
.code
org 100h

Start:		mov AX, 3506h
		int 21h
	
		mov oldOffset, BX
		mov BX, ES
		mov oldSeg, BX
	
		push 0
		pop ES
		mov BX, 4*09h

		cli;		IF = 0
		mov ES:[BX], offset MyItrptr
		push CS
		pop AX
		mov ES:[BX+2], AX
		sti

		mov AX, 3100h
		mov DX, offset EOP
		shr DX, 4
		inc DX
		int 21h

MyItrptr	PROC
		push AX
		push BX
		push ES
		
		mov BX, 0B800h
		mov ES, BX
		mov BX, 160*7+80

		
		mov AH, 4Eh
		in AL, 60h
		mov ES:[BX], AX
		
		in AL, 61h
		or AL, 80h
		out 61h, AL
		in AL, 61h
		and AL, not 80h
		out 61h, AL

		mov AL, 20h
		out 20h, AL

		pop ES
		pop BX
		pop AX 

		iret

		DW 0EAh
		oldOffset DW ?
		oldSeg DW ?
		
		;iret
		ENDP

		;DB 0EAh
		;jmp FAR DWORD PTR offset oldOffset
		;oldOffset DW ?
		;oldSeg DW ?

EOP:
	

end Start


	



