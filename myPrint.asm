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
END_OF_STRING equ 0d
PERCENT_ASCII equ 37d
BUF_SIZE 	  equ 16d
DIV_BUF_SIZE  equ 64d

;----------------------------------------------------------------------------
;									CODE
;----------------------------------------------------------------------------

section 	.note.GNU-stack

section 	.text

global myPrint								;for linker and C code

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

		mov  rcx, 1					;argument offset
		xor  rax, rax				;writen sybmols

		mov  rsi, BUFFER
		xchg rsi, rdi

	bufferisation:
		cmp  byte [rsi], END_OF_STRING
		je end_of_bufferisation

		cmp byte [rsi], PERCENT_ASCII
		jne no_percent

		inc rsi
		call percentHandler
		jmp bufferisation

	no_percent:				;to a new function
		call putCharInBuffer
		jmp bufferisation

	end_of_bufferisation:
		push rax

		xor rdx, rdx
		mov r10, BUF_SIZE
		div r10

		mov rax, 1
		mov rdi, 1
		mov rsi, BUFFER
		syscall

		pop rax
		pop rbp
		add rsp, 8*5

		push r8
		ret


;----------------------------------------------------------------------------
;putChar
;
;Entry:
;		rdi = destination (BUFFER[0] --- BUFFER[BUF_SIZE])
;		rsi = symbol addr
;
;Destr:
;		r10
;----------------------------------------------------------------------------
putCharInBuffer:		;TODO(maybe useless): create variable in stack frame which will contains num of printed symbols
		cld 					;clear direction flag

		mov r10, BUFFER			;|check if buffer is overflowed
		add r10, BUF_SIZE		;|
		cmp rdi, r10 			;|
		jb not_overflow

		push rcx
		push rax				;|save regs
		push rsi 				;|

		mov rax, 1				;|print string
		mov rdi, 1				;|to stdout
		mov rsi, BUFFER			;|started in BUFFER
		mov rdx, BUF_SIZE		;|with len BUF_SIZE
		syscall					;|

		mov rdi, BUFFER			;reset rdi to start of BUFFER

		pop rsi 				;|recover regs
		pop rax 				;|
		pop rcx

	not_overflow:
		inc rax
		movsb					;rsi -> rdi
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
		xor rdx, rdx
		mov byte dl, [rsi]
		cmp byte dl, PERCENT_ASCII				;maybe pop address
		jne switcher

		inc rax
		mov byte [rdi], dl
		inc rdi
		inc rsi
		ret

	switcher:
		sub dl, 98					;TODO: replace magic nubber

		cmp dl, 0
		jb SWITCH_END
		cmp dl, 22
		ja SWITCH_END

		jmp [JMP_TABLE + rdx * 8]

	SWITCH_END:
		ret



process_ascii:
		push rsi
		lea  rsi, [rbp + rcx * 8]
		inc  rcx

		call putCharInBuffer

		pop rsi
		inc rsi
		ret

;r10 = base
process_number:
		push rax			;save rax
		xor  rax, rax
		xor  rdx, rdx

		mov qword rax, [rbp + rcx * 8]		;|rax = mem[argumet++]
		inc rcx

		mov r11, DIV_BUF 				;get div buffer address

	to_div:
		div r10
		mov byte [r11], dl 				;get ascii number in buffer
 		add byte [r11], '0'				;

		cmp dl, 10
		jb less_10
		add byte [r11], 7				;TODO: REMOVE MAGIC NUMBER
	less_10:
 		xor rdx, rdx
		inc r11
		cmp rax, 0
		jne to_div

		pop rax

		push rsi
		mov rsi, r11
		sub r11, DIV_BUF
		dec rsi

	reverse:
		push r11
		call putCharInBuffer
		pop  r11
		sub rsi, 2
		dec r11
		cmp r11, 0
		jne reverse

		pop rsi

		ret

process_str:
		cld

		push rsi
		mov  rsi, [rbp + rcx * 8]
		inc  rcx
	copy:
		cmp byte [rsi], END_OF_STRING
		je end_of_copy
		movsb
		inc rax
		jmp copy

	end_of_copy:
		pop rsi

		ret


;TODO: remove copypast
CASE_b:
		mov r10, 2
		call process_number
		inc rsi
		jmp SWITCH_END

CASE_c:
		call process_ascii
		jmp  SWITCH_END
CASE_d:
		mov  r10, 10
		call process_number
		inc  rsi
		jmp  SWITCH_END

CASE_o:
		mov r10, 8
		call process_number
		inc rsi
		jmp SWITCH_END

CASE_s:
		inc rsi
		call process_str
		jmp  SWITCH_END

CASE_x:
		mov r10, 16
		call process_number
		inc rsi
		jmp SWITCH_END

; %c = 99, %s = 115, %o = 111, %x = 120, %% = 37, %d = 100, %b = 98,
JMP_TABLE:
		dq CASE_b	 			;98
		dq CASE_c				;99
		dq CASE_d				;100
		dq SWITCH_END	 		;101
		dq SWITCH_END	 		;102
		dq SWITCH_END			;103
		dq SWITCH_END			;104
		dq SWITCH_END			;105
		dq SWITCH_END			;106
		dq SWITCH_END			;107
		dq SWITCH_END			;108
		dq SWITCH_END			;109
		dq SWITCH_END			;110
		dq CASE_o				;111
		dq SWITCH_END			;112
		dq SWITCH_END			;113
		dq SWITCH_END			;114
		dq CASE_s				;115
		dq SWITCH_END			;116
		dq SWITCH_END			;117
		dq SWITCH_END			;118
		dq SWITCH_END			;119
		dq CASE_x				;120
		dq SWITCH_END			;121
		dq SWITCH_END			;122


section 	.data
DIV_BUF:	db DIV_BUF_SIZE dup(0)
BUFFER:		db BUF_SIZE     dup(0)