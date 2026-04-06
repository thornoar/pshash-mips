.data
l1: .word 0x0f000000
l2: .word 0xffffffff

.text
.globl __start
__start:
    lw $t0, l1
    lw $t1, l2
    and $t2, $t0, $t1
    xori $t3, $t1, 0xffff
    srl $t2, $t2, 12

    move $t0, $zero
    lui $t0, 0x0f00
    andi $t0, 0x0000

    li $v0, 10
    syscall
