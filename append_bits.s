@ appends the given bits to the end of the binary number

.cpu    cortex-a53
.fpu    neon-fp-armv8

.equ    LOCALS, 16
.equ    code, -8
.equ    added, -12

.align  2
.text
.global append_bits
.type   append_bits, %function

append_bits:
    push {fp, lr}
    add fp, sp, #4
    sub sp, sp, #LOCALS
    str r0, [fp, #code]
    str r1, [fp, #added]
@ determine the number of bits that will be added
    mov r0, r1
    bl bit_length           @ bit_length(added) r0
    ldr r1, [fp, #code]     @ code              r1
    ldr r2, [fp, #added]    @ added             r2
@ return (code << bit_length(added)) | added;
    lsl r3, r1, r0
    orr r0, r3, r2
    sub sp, fp, #4
    pop {fp, pc}
