@ prints out the given number in binary

.cpu    cortex-a53
.fpu    neon-fp-armv8

@ constants
.equ    LOCALS, 12

@ parameters
.equ    value, -8

.data
number:     .asciz   "%u"

.align  2
.text
.global binary_out
.type   binary_out, %function

binary_out:
    push {fp, lr}
    add fp, sp, #4
    sub sp, sp, #LOCALS
    str r0, [fp, #value]
    cmp r0, #1
    bls print_
    lsr r0, r0, #1  @ shift over print the next bit
    bl binary_out
print_:
    ldr r1, [fp, #value]
    and r1, r1, #1
    ldr r0, =number
    bl printf
    @ return value
    ldr r0, [fp, #value]
    sub sp, fp, #4
    pop {fp, pc}
