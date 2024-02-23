.286
.model tiny
.code
org 100h

Start:		mov ah, 09h
		mov dx, offset HelloStr
		int 21h
		mov ah, 01h
		int 21h

		push cs
		pop RetSeg

		mov di, 0b800h
		mov es, di
		xor di, di
		xor si, si
		xor cx, cx
		dec cx
		cld
		rep movsb

		push es
		push offset Next
		retf
Next:		nop

		mov ax, (4eh shl 8) or '!'
		mov di, 80d*2 * 5
		mov cx, 80d
		push di
		rep stosw
	
		mov si, offset HelloVideo
		pop di
		mov cx, HelloVideoLen		
		rep movsb

		db 0eah
		dw offset Next2
RetSeg		dw 0
Next2:		nop

		mov ax, 4c00h
		int 21h

HelloStr	db '<<<   Hello meow, press a key...   >>>$' 
HelloVideo	db '< < <       H e l l o   f r o m   0 x b 8 0 0 h       > > > '
HelloVideoLen	equ $ - HelloVideo

end		Start
