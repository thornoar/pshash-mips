.data
hello_string: .ascii "abcdefgh"
# hello_string_length: .word . - hello_string

.text
main:
    lw $t1, hello_string($zero)
    move $a0, $t0
    jal printint
    li $v0, 4
    la $a0, hello_string
    syscall
    jal exit

printint:
    li $v0, 1 # The print integer syscall code
    syscall
    jr $ra

exit:
    li $v0, 10
    syscall
