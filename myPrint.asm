section 	.text

global _start

_start:
			mov rax, 0x3C
			xor rdi, rdi
			syscall

section 	.data
buffer	db 52 dup(128)