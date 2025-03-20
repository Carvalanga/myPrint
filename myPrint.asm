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
BUF_SIZE       equ 32d
ONES_IN_MASK16 equ 4
ONES_IN_MASK8  equ 3
ONES_IN_MASK2  equ 1


MASK16 	  equ 1111b
MASK8     equ 111b
MASK2	  equ 1b
SIGN_MASK equ 1 << 31


BASE10 equ 10

;----------------------------------------------------------------------------
;=====================================MACRO==================================
;----------------------------------------------------------------------------
%macro putChar 0
		cmp rdi, BUFFER + BUF_SIZE
		jne .no_overflow

		call printBuffer

	.no_overflow:
		inc rbx
		stosb

%endmacro

%macro getArgument 0

		mov qword rax, [rbp]
		add rbp, 8

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
;
;
;Exit:
;		rbx = count of printed symbols
;
;Destr:
;		rcx; r8(ret addres);
;----------------------------------------------------------------------------------------------------------------------------------------------
myPrint:
;---------------------PREPARING-FOR-THE-FUNCTION-WORK------------------------

		cld 										;clear direction flag

		pop rax										;pop return address

		push r9 									;|TRAMPLINE
		push r8 									;|push argumets in stack
		push rcx									;|
		push rdx									;|
		push rsi 									;|

		push rbp									;|set bp to the first argument
		mov  rbp, rsp								;|
		add  rbp, 8	 								;|

		push r12 									;|save registers which don't have to be modified
		push r13 									;|
		push rbx 									;|

		xor rbx, rbx								;|prepare registers for work
		mov r8, rax 								;|
		mov rsi, rdi  		 						;|
		mov rdi, BUFFER								;|
		xor rax, rax								;|

;----------------------------------MAIN-BODY---------------------------------

	bufferisation:
		mov byte al, [rsi]							;get symbol

		cmp al, 0									;|if al == 0 (end of string)
		je end_of_bufferisation						;|						goto end

		cmp al, '%' 								;|if al != '%'
		jne no_percent	 							;|  		continue

		call percentHandler							;|
		jmp  bufferisation							;|

	no_percent:
		inc rsi 									;rsi++
		putChar 									;see MACRO
		jmp bufferisation 							;continue bufferisation

;------------------------PREPARING-TO-EXIT-FROM-FUNCTION---------------------

	end_of_bufferisation:

		call printBuffer 							;last buffer print

		mov rax, rbx 								;set return value to rax

		pop rbx 									;|recover regs values
		pop r13 									;|
		pop r12										;|
		pop rbp 									;|

		add rsp, 40 								;clear stack frame

		push r8 									;push return address
		ret

;----------------------------------------------------------------------------------------------------------------------------------------------


;----------------------------------------------------------------------------------------------------------------------------------------------
;printBuffer:
;		prints buffer from address of buffer start to address which
;		contains rdi
;
;Destr:	rcx, r11, rdx
;----------------------------------------------------------------------------------------------------------------------------------------------
printBuffer:
		push rax									;|save regs
		push rsi 									;|

		mov rdx, rdi 								;|set size to print
		sub rdx, BUFFER 							;|

		mov rax, 1									;|print string
		mov rdi, 1									;|to stdout
		mov rsi, BUFFER								;|started in BUFFER

		syscall										;call print

		mov rdi, BUFFER								;reset rdi to start of BUFFER

		pop rsi 									;|recover regs
		pop rax
		ret
;----------------------------------------------------------------------------------------------------------------------------------------------


;----------------------------------------------------------------------------------------------------------------------------------------------
;percentHandler:
;		checks symbol after percent and do something in accordance
;		with jump table
;
;Entry:
;		rsi = percent address
;		rdi = buffer
;
;Destr:
;		rax
;----------------------------------------------------------------------------------------------------------------------------------------------
percentHandler:
		inc rsi 									;skip %
		mov byte al, [rsi] 							;al = current sybmol after percent

		sub al, '%' 								;|calculations for jump table
		cmp al, 0 									;|check extreme cases
		jb SWITCH_END	 							;|
		cmp al, 'z' - '%'							;|
		ja SWITCH_END	 							;|

		jmp [JMP_TABLE + rax * 8] 					;JUMP!!! (to case)

	SWITCH_END:
		inc rsi 									;get next symbol
		ret


;----------------------------------------------------------------------------------------------------------------------------------------------


;----------------------------------------------------------------------------------------------------------------------------------------------
;															JMP TABLE AND CASES
;----------------------------------------------------------------------------------------------------------------------------------------------

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
						  dq SWITCH_END
						  dq CASE_u
	times ('x' - 'u' - 1) dq SWITCH_END
						  dq CASE_x
	times ('z' - 'x' - 1) dq SWITCH_END

		CASE_PERCENT:
				mov rax, '%' 						;|print %
				putChar 							;|
				jmp SWITCH_END 						;|

		CASE_b:
				mov rcx, ONES_IN_MASK2  			;rcx = 1
				mov r13, MASK2 						;r13 = 1b
				getArgument 						;rax = next argument
				call processTwoDegreeSigned
				jmp SWITCH_END

		CASE_c:
				getArgument							;rax = next argument
				putChar
				jmp  SWITCH_END

		CASE_d:
				mov  r9, BASE10 					;r9 = 10
				getArgument							;rax = next argument
				call processNumberSigned
				jmp  SWITCH_END

		CASE_o:
				mov rcx, ONES_IN_MASK8 				;rcx = 3
				mov r13, MASK8 						;r13 = 111b
				getArgument							;rax = next argument
				call processTwoDegreeSigned
				jmp SWITCH_END

		CASE_s:
				call processStr
				jmp  SWITCH_END

		CASE_u:
				mov  r9, BASE10						;r9 = 10
				getArgument							;rax = next argument
				call processNumberUnsigned
				jmp  SWITCH_END

		CASE_x:
				mov rcx, ONES_IN_MASK16 			;rcx = 4
				mov r13, MASK16 					;r13 = 1111b
				getArgument							;rax = next argument
				call processTwoDegreeSigned
				jmp SWITCH_END
;----------------------------------------------------------------------------------------------------------------------------------------------


;----------------------------------------------------------------------------------------------------------------------------------------------
;movNumberToBuffer:
;		moves symbol from stack to buffer (using in printing numbers)
;
;Entry:
;		r12 - count of pushed numbers
;
;Destr:
;		r10
;----------------------------------------------------------------------------------------------------------------------------------------------
movNumberToBuffer:
		pop r10 			;save return address

	.printNumber:
		pop rax				;get symbol from stack
		putChar 			;print sybmol
		dec r12 			;cnt_to_print--
		cmp r12, 0
		jne .printNumber

		push r10 			;push address
		ret
;----------------------------------------------------------------------------------------------------------------------------------------------


;----------------------------------------------------------------------------------------------------------------------------------------------
;processNumber(Un)Signed:
;		process number and pushes to stack in revers order and than call
;		printBuffer which prints number to buffer
;
;Entry:
;		rax = argument (number to print)
;		r9  = base of number to print
;
;Destr:
;		rdx, r12
;----------------------------------------------------------------------------------------------------------------------------------------------
processNumberSigned:
		call checkAndPrintSign 					;check sign if it is signed call
processNumberUnsigned:

		xor  rdx, rdx 				 			;|preparing register for work
		xor  r12, r12 							;|

	nextNum:
		div r9 									;|rdx = rax % 10
 		mov dl, [NUM_TABLE + rdx] 				;|dl  = ASCII code
		inc r12 								;|pushed_symbols++
		push rdx 								;|push ASCII code
 		xor rdx, rdx 							;|prepare rdx for next iteration
		cmp rax, 0 								;|check if rax == 0
		jne nextNum 							;|

		call movNumberToBuffer					;move number to buffer

		ret
;----------------------------------------------------------------------------------------------------------------------------------------------


;----------------------------------------------------------------------------------------------------------------------------------------------
;processStr:
;		moves symbols from inputted string to buffer
;
;Destr:
;		rax
;----------------------------------------------------------------------------------------------------------------------------------------------
processStr:
		push rsi 					;save rsi
		mov  rsi, [rbp] 			;|get address argument
		add  rbp, 8 				;|
	copy:
		lodsb 						;al = [rsi]
		cmp al, 0 					;if al == END_OF_STRING
		je end_of_copy

		putChar
		jmp copy

	end_of_copy:
		pop rsi 					;recover rsi

		ret
;----------------------------------------------------------------------------------------------------------------------------------------------


;----------------------------------------------------------------------------------------------------------------------------------------------
;processTwoDegree(Un)Signed:
;		pushes in stack 2 degree number in reversed order
;
;Entry:
;		r13 = mask
;		rax = number
;		cl  = count of ones in mask
;
;Destr:
;		r10, r12
;----------------------------------------------------------------------------------------------------------------------------------------------
processTwoDegreeSigned:
		push rcx 									;save rcx because syscall which called in putchar in checkSigh
		call checkAndPrintSign
		pop rcx 									;recover rcx
processTwoDegreeUnsigned:
		xor r12, r12 								;prepare reg for work
	.nextNum:
		mov  r10, rax 								;save rax
		and  r10, r13 								;get bytes by mask

		mov  byte r10b, [NUM_TABLE + r10]   		;get ASCII code
		push r10 									;push tos stack ASCII
		shr  rax, cl 								;get needed number
		inc  r12 									;cnt_of_pushed_symbols
		cmp  rax, 0 								;if (rax == 0) goto .endOfCalc
		jne .nextNum

	.endOfCalc:
		call movNumberToBuffer

		ret
;----------------------------------------------------------------------------------------------------------------------------------------------


;----------------------------------------------------------------------------------------------------------------------------------------------
;checkSign:
;		check if number is negative and print '-' if it is. also convert number to positive for print
;
;Entry:
;		rax = number
;
;Destr:
;		r10
;----------------------------------------------------------------------------------------------------------------------------------------------
checkAndPrintSign:
		mov r10, rax 				;save rax
		and rax, SIGN_MASK 			;check sign bit
		cmp rax, 0 					;|if bit == 1:
		je .positive  				;|		print sign
		mov byte al, '-' 		 	;|
		putChar						;|

		mov rax, r10 				;|set rax positive and return
		neg eax 					;|
		ret

	.positive:
		mov rax, r10 				;recover rax
		ret
;----------------------------------------------------------------------------------------------------------------------------------------------

section 	.data
NUM_TABLE: db "0123456789ABCDEF"
BUFFER:		times BUF_SIZE db 0