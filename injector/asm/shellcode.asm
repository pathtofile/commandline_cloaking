; This shellcode is designed to run
; right at the start as the ELF entrypoint.

; Get location of argv string array
; from stack. At the entrypoint, with 1
; actual argument the stack looks like:
; rsp+0x00: argc
; rsp+0x08: pointer to argv[0] (program name)
; rsp+0x10: pointer to argv[1] (1st agument)
; rsp+0x18: NULL 
; rsp+0x20: pointer to envp[0] 
; ...
mov  rax, [rsp+0x10]

; Set first arg to "BBBB\0"
; which in hex is: 42 42 42 42 00
mov [rax],   dword 0x42424242
mov [rax+4], byte 0x00

; Reset rax to 0
xor rax, rax
