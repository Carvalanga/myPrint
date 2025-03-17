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
BUF_SIZE 	  equ 32d


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
;myPrint:								WARNING: ALL STRINGS HAVE TO HAVE 0 IN THE END
;
;arguments:
;		di = format string address
;----------------------------------------------------------------------------

;register to save rbx, rbp, r12, r13, r14, r15

;write symbol function - if buffer overflowed, syscall and recover rdi. rsi may be different

myPrint:
		cld

		pop rax

		push r9 					;|push argumets in stack
		push r8 					;|
		push rcx					;|
		push rdx					;|
		push rsi 					;|

		mov  r8, rax
		push rbp					;set_new base point
		mov  rbp, rsp
		add  rbp, 8
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

		pop rbp
		add rsp, 40

		push r8 			;arexit ???
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
;		rbx	<------------------------------------------------------------------------------MAYBE DANGER. BE CAREFUL
;----------------------------------------------------------------------------
percentHandler:
		inc rsi
		mov byte dl, [rsi]
		sub dl, '%'
		cmp dl, 0
		jb SWITCH_END
		cmp dl, 'z' - '%'
		ja SWITCH_END

		jmp [JMP_TABLE + rdx * 8]

	SWITCH_END:
		inc rsi
		ret

JMP_TABLE:
	dq CASE_PERCENT
	times ('b' - '%' - 1) dq SWITCH_END
	dq CASE_b	 			;98
	dq CASE_c				;99
	dq CASE_d				;100
	times ('o' - 'd' - 1) dq SWITCH_END
	dq CASE_o				;111
	times ('s' - 'o' - 1) dq SWITCH_END
	dq CASE_s				;115
	times ('x' - 's' - 1) dq SWITCH_END
	dq CASE_x				;120
	times ('z' - 'x' - 1) dq SWITCH_END

CASE_PERCENT:
		mov rax, '%'
		putchar
		jmp SWITCH_END
CASE_b:
		mov r9, 2
		call process_number
		jmp SWITCH_END

CASE_c:
		call process_ascii
		jmp  SWITCH_END
CASE_d:
		mov  r9, 10
		call process_number
		jmp  SWITCH_END

CASE_o:
		mov r9, 8
		call process_number
		jmp SWITCH_END

CASE_s:
		call process_str
		jmp  SWITCH_END

CASE_x:
		mov r9, 16
		call process_number
		jmp SWITCH_END

;----------------------------------------------------------------------------
;printBuffer:
;
;Entry:
;	rdx = size to print
;
;----------------------------------------------------------------------------
printBuffer:
		push rsi 				;|

		mov rax, 1				;|print string
		mov rdi, 1				;|to stdout
		mov rsi, BUFFER			;|started in BUFFER
		mov rdx, BUF_SIZE		;|with len BUF_SIZE

		push rcx
		syscall					;|
		pop rcx

		mov rdi, BUFFER			;reset rdi to start of BUFFER

		pop rsi 				;|recover regs

		ret

process_ascii:
		mov rax, [rbp]
		add rbp, 8
		inc rcx
		putchar
		ret

;r10 = base
printNumberToBuffer:
		pop r10

	.printNumber:
		pop rax
		putchar
		loop .printNumber

		push r10
		ret

process_number:
		push rcx
		xor  rax, rax
		xor  rdx, rdx
		xor  rcx, rcx

		mov qword rax, [rbp]		;|rax = mem[argumet++]
		add rbp, 8

	nextNum:
		div r9
 		add byte dl, '0'
		cmp dl, '0' + 10
		jb less10
		add dl, 7				;TODO: REMOVE MAGIC NUMBER

	less10:
		inc rcx
		push rdx
 		xor rdx, rdx
		cmp rax, 0
		jne nextNum

		call printNumberToBuffer

		pop rcx
		ret

process_str:
		cld

		push rsi
		mov  rsi, [rbp]
		add  rbp, 8
	copy:
		lodsb
		cmp al, 0
		je end_of_copy
		stosb
		inc rdx
		jmp copy

	end_of_copy:
		pop rsi

		ret

; %c = 99, %s = 115, %o = 111, %x = 120, %% = 37, %d = 100, %b = 98,


section 	.data
BUFFER:		db BUF_SIZE     dup(0)