@ adds the given bit to the end of the number

.cpu    cortex-a53
.fpu    neon-fp-armv8

.align  2
.text
.global add_bit
.type   add_bit, %function
@ param: v, bit
@ return (v << 1) | (bit & 1);
add_bit:
    lsl r0, r0, #1
    and r1, r1, #1
    orr r0, r0, r1
    bx lr
