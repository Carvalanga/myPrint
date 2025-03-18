;----------------------------------------------------------------------------
;===================================MyPrint==================================
;----------------------------------------------------------------------------
;							      DESCRIPTION
;----------------------------------------------------------------------------
;
;----------------------------------------------------------------------------


;----------------------------------------------------------------------------
;								  CONSTANTS
;----------------------------------------------------------------------------
BUF_SIZE 	  equ 4d


;----------------------------------------------------------------------------
;=====================================MACRO==================================
;----------------------------------------------------------------------------
%macro putchar 0
		cmp rdi, BUFFER + BUF_SIZE
		jne .no_overflow

		call printBuffer

	.no_overflow:
		inc rdx
		stosb

%endmacro


;----------------------------------------------------------------------------
;									CODE
;----------------------------------------------------------------------------

section 	.note.GNU-stack
global myPrint								;for linker and C code
section 	.text


;----------------------------------------------------------------------------
;myPrint:
;		print symbols to console with format (check description)
;
;Entry:
;		rdi = current position of buffer string address
;		rsi = current position of format string address
;		rdx = cnt of printed symbol
;
;Exit:
;		rax cnt of printed symbol
;
;Destr:
;		rcx; r8(ret addres);
;----------------------------------------------------------------------------
myPrint:
		cld

		pop rax

		push r9 					;|push argumets in stack
		push r8 					;|
		push rcx					;|
		push rdx					;|
		push rsi 					;|

		push rbp					;set_new base point
		mov  rbp, rsp
		add  rbp, 8

		push rbx
		push r12

		mov  r8, rax
		xor  rdx, rdx						;writen sybmols

		mov  rsi, BUFFER
		xchg rsi, rdi

	bufferisation:
		cmp byte [rsi], 0
		je end_of_bufferisation

		cmp byte [rsi], '%'
		jne no_percent

		call percentHandler
		jmp bufferisation

	no_percent:				;to a new function
		lodsb
		putchar
		jmp bufferisation

	end_of_bufferisation:
		push rdx
		mov rdx, rdi
		sub rdx, BUF_SIZE
		call printBuffer
		pop rax

		pop r12
		pop rbx
		pop rbp
		add rsp, 40

		push r8 			;arexit ???
		ret


;----------------------------------------------------------------------------
;printBuffer:
;
;Entry:
;	rax = size to print
;
;----------------------------------------------------------------------------
printBuffer:
		push rax
		push rdx
		push rsi 				;|
		push rcx

		mov rdx, rdi
		sub rdx, BUFFER

		mov rax, 1				;|print string
		mov rdi, 1				;|to stdout
		mov rsi, BUFFER			;|started in BUFFER

		syscall					;|

		mov rdi, BUFFER			;reset rdi to start of BUFFER

		pop rcx
		pop rsi 				;|recover regs
		pop rdx
		pop rax
		ret


;----------------------------------------------------------------------------
;percentHandler:
;		%c = 99, %s = 115, %o = 111, %x = 120, %% = 37, %d = 100, %b = 98,
;
;Entry:
;		rdi = data
;		rsi = buffer
;
;Destr:
;
;----------------------------------------------------------------------------
percentHandler:
		xor rcx, rcx
		inc rsi
		mov byte cl, [rsi]
		sub cl, '%'
		cmp cl, 0
		jb SWITCH_END
		cmp cl, 'z' - '%'
		ja SWITCH_END

		jmp [JMP_TABLE + rcx * 8]

	SWITCH_END:
		inc rsi
		ret

JMP_TABLE:
	dq CASE_PERCENT
	times ('b' - '%' - 1) dq SWITCH_END
	dq CASE_b
	dq CASE_c
	dq CASE_d
	times ('o' - 'd' - 1) dq SWITCH_END
	dq CASE_o
	times ('s' - 'o' - 1) dq SWITCH_END
	dq CASE_s
	times ('x' - 's' - 1) dq SWITCH_END
	dq CASE_x
	times ('z' - 'x' - 1) dq SWITCH_END

CASE_PERCENT:
		mov rax, '%'
		putchar
		jmp SWITCH_END
CASE_b:
		mov bl, 32
		mov rcx, 1
		mov r9, 10000000000000000000000000000000b
		mov rax, [rbp]
		add rbp, 8
		call processTwoDegree
		jmp SWITCH_END

CASE_c:
		call process_ascii
		jmp  SWITCH_END
CASE_d:
		mov  r9, 10
		call processNumber
		jmp  SWITCH_END

CASE_o:
		mov bl, 33
		mov rcx, 3
		mov r9, 111000000000000000000000000000000b
		mov rax, [rbp]
		add rbp, 8
		call processTwoDegree
		jmp SWITCH_END

CASE_s:
		call processStr
		jmp  SWITCH_END

CASE_x:
		mov bl, 32
		mov rcx, 4
		mov r9, 11110000000000000000000000000000b
		mov rax, [rbp]
		add rbp, 8
		call processTwoDegree
		jmp SWITCH_END

process_ascii:
		mov rax, [rbp]
		add rbp, 8
		putchar
		ret

printNumberToBuffer:
		pop r10

	.printNumber:
		pop rax
		putchar
		loop .printNumber

		push r10
		ret

processNumber:
		mov  r10, rdx
		xor  rax, rax
		xor  rdx, rdx
		xor  rcx, rcx

		mov qword rax, [rbp]		;|rax = mem[argumet++]
		add rbp, 8

	nextNum:
		div r9
 		mov rdx, [NUM_TABLE + rdx]
		inc rcx
		push rdx
 		xor rdx, rdx
		cmp rax, 0
		jne nextNum

		mov  rdx, r10
		call printNumberToBuffer

		ret

processStr:
		push rsi
		mov  rsi, [rbp]
		add  rbp, 8
	copy:
		lodsb
		cmp al, 0
		je end_of_copy

		putchar
		jmp copy

	end_of_copy:
		pop rsi

		ret

;rax = number to print
;r10 = mask
;rbx = 32
;cl = num of 1

;example: r10 = 111 << 31
processTwoDegree:
	.set_mask:
		mov r10, rax
		and rax, r9
		xchg rax, r10
		cmp r10, 0
		jne .nextNum
		shr r9, cl
		sub bl, cl
		jmp .set_mask

	.nextNum:
		mov  r10, rax
		and  rax, r9
		sub  rbx, rcx

		xchg rbx, rcx
		shr  rax, cl
		xchg rbx, rcx

		mov rax, [NUM_TABLE + rax]
		putchar

		shr  r9, cl
		xchg r10, rax
		cmp  r9, 0
		jne .nextNum

		ret

; checkSign:
; 		and  rax, 10000000000000000000000000000000b
; 		cmp  rax, 0
; 		je .positive

; 		mov r9

; 	.positive:
; 		ret

section 	.data
NUM_TABLE: db "0123456789ABCDEF"
BUFFER:		times BUF_SIZE db 0