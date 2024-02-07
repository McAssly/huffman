@ determines the number of bits in the given number

.cpu    cortex-a53
.fpu    neon-fp-armv8

.align  2
.text
.global bit_length
.type   bit_length, %function

@ r0 = the number
bit_length:
    cmp r0, #0
    beq return_one
    mov r1, #0          @ the counter
counter_loop:
    cmp r0, #0
    beq exit_cloop
    lsr r0, r0, #1
    add r1, r1, #1
    b counter_loop
exit_cloop:
    mov r0, r1
    b finished_bl
return_one:
    mov r0, #1
finished_bl:
    bx lr
