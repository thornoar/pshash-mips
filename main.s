.data
sourceLower: .asciiz "ckapzfitqdxnwehrolmbyvsujg"
sourceUpper: .asciiz "RQLIANBKJYVWPTEMCZSFDOGUHX"
sourceSpecial: .asciiz "=!*@?$%#&-+^"
sourceNumbers: .asciiz "1952074386"
newline_str: .asciiz "/\n"
colon_str: .asciiz ":"

# Big integers are stored as blocks of words in memory,
# where each byte is one digit of a number in base-2^31.
# This allows performing addition without worrying about
# overflow. The terminator of the number is the value
# 0xffffffff

.text
.globl main
.globl test2

# Instruction to jump to the return address
return:
    jr $ra

# Arguments:
#   $a0: address of the source number
#   $a1: address of the destination number
big_copy:
    li $t1, 0xffffffff # Loading the terminal value
copy_loop:
    lw $t0, 0($a0) # Load the current digit
    sw $t0, 0($a1) # Copy the current digit
    beq $t0, $t1, return # Check if all the digits have already been copied
    addi $a0, $a0, 4 # Move to the next digit
    addi $a1, $a1, 4 # Move to the next digit
    j copy_loop # Next iteration

# Arguments:
#   $a0: address of number to increment
#   $a1: address of number to store the result to
big_increment:
    lw $t0, 0($a0) # Load the first digit into $t0
    addi $t0, $t0, 1 # Increment the first digit
    move $t1, $zero
    lui $t1, 0x8000 # Put the value 2^31 into $t1
    bgeu $t0, $t1, inc_if_carryover # Check if there is carry-over
    sw $t0, 0($a1) # There is no carryover, so store the incremented digit
    addi $a0, $a0, 4 # Move to the next digit
    addi $a1, $a1, 4 # Move to the next digit
    j big_copy # Copy the remaining digits
inc_if_carryover:
    sw $zero, 0($a1) # The first digit is now zero
    addi $a0, $a0, 4
    addi $a1, $a1, 4 # Move to the next digit
    j big_increment # Increment

# Arguments:
#   $a0: address of the first summand
#   $a1: address of the second summand
#   $a2: address of the result
big_sum:
    lw $t0, 0($a0) # Load the first digit of $a0
    lw $t1, 0($a1) # Load the first digit of $a1
    li $t2, 0xffffffff # Load the terminal value
    beq $t1, $t2, copy_rest_fst # Check if it's the end of $a1
    beq $t0, $t2, copy_rest_snd # Check if it's the end of $a0
    addu $t2, $t0, $t1 # Add the first digits, store them in $t2
    xor $t3, $t3, $t3 # Set $t3 to zero
    lui $t3, 0x8000 # Load the binary value 2^31 in $t3
    bgeu $t2, $t3, sum_if_carryover
    sw $t2, 0($a2) # No carryover, so store the sum of digits
    addi $a0, $a0, 4 # Move to the next digit
    addi $a1, $a1, 4 # Move to the next digit
    addi $a2, $a2, 4 # Move to the next digit
    j big_sum # Recursive call
sum_if_carryover:
    subu $t2, $t2, $t3 # Subtract 2^31 from $t2
    sw $t2, 0($a2) # Store the sum of digits
    addi $a0, $a0, 4 # Move to the next digit
    addi $a1, $a1, 4 # Move to the next digit
    addi $a2, $a2, 4 # Move to the next digit
    addi $sp, $sp, -4 # Allocate 4 bytes on the stack
    sw $ra, 0($sp) # Store the return address
    addi $sp, $sp, -4 # Allocate 4 bytes on the stack
    sw $a0, 0($sp) # Store $a0 on the stack
    addi $sp, $sp, -4 # Allocate 4 bytes on the stack
    sw $a1, 0($sp) # Store $a1 on the stack
    addi $sp, $sp, -4 # Allocate 4 bytes on the stack
    sw $a2, 0($sp) # Store $a2 on the stack
    jal big_sum # Recursive call
    lw $a2, 0($sp) # Load back $a2
    addi $sp, $sp, 4 # Move the stack pointer up 
    lw $a1, 0($sp) # Load back $a1
    addi $sp, $sp, 4 # Move the stack pointer up 
    lw $a0, 0($sp) # Load back $a0
    addi $sp, $sp, 4 # Move the stack pointer up
    lw $ra, 0($sp) # Load back the return address
    addi $sp, $sp, 4 # Move the stack pointer up
    move $a1, $a0 # $a1 := $a0
    j big_increment # Increment due to carryover

# Arguments:
#   $a0: address of the multiplicand
#   $a1: the multiplier
#   $a2: address of the result
big_mult_digit:
    

# Arguments:
#   $a0: address of the multiplicand
#   $a1: address of the multiplier
#   $a2: address of the result
big_mult:
    lw $t0, 0($a0) # Load the first digit of $a0
    lw $t1, 0($a1) # Load the first digit of $a1
    li $t2, 0xffffffff # Load the terminal value
    beq $t1, $t2, copy_rest_fst # Check if it's the end of $a1
    beq $t0, $t2, copy_rest_snd # Check if it's the end of $a0

copy_rest_snd:
    move $a0, $a1
copy_rest_fst:
    move $a1, $a2
    j big_copy
    

# Arguments:
#   $a0: number of words to allocate
#   $a1: the initial word
# Returns:
#   $v0: the address of the allocated and initialized number
big_alloc:
    sll $a0, $a0, 2 # Multiplying by 4 to get the number of bytes
    li $v0, 9 # Memory allocation syscall
    syscall
    move $t0, $v0 # Save the current address
    add $t1, $v0, $a0
    addi $t1, $t1, -4 # Save the final address
    sw $a1, 0($t0) # Store the first word of the number
alloc_loop:
    addi $t0, $t0, 4 # Move the address to the next word
    beq $t0, $t1, alloc_break
    sw $zero, 0($t0)
    j alloc_loop
alloc_break:
    li $t0, 0xffffffff # Load the terminator value
    sw $t0, 0($t1) # Store the value at the last address
    jr $ra

# Arguments:
#   $a0: the address of the big number to print
big_print:
    li $v0, 1 # Print int syscall
    li $t0, 0xffffffff # Terminator value
    move $t1, $a0 # Save the current address
print_loop:
    lw $a0, 0($t1) # Load the current digit
    beq $a0, $t0, print_break
    li $v0, 1 # Print int syscall
    syscall # Print the current digit
    li $v0, 4 # Print string syscall
    la $a0, colon_str
    syscall # Print a colon separator
    addi $t1, $t1, 4 # Move to the next digit
    j print_loop # Next loop iteration
print_break:
    la $a0, newline_str
    syscall # Print the endline
    jr $ra

main:
    li $t0, 0x7fffffff
    li $t1, 0x7fffffff
    mult $t0, $t1
    mflo $t2
    mfhi $t3

    li $a0, 8 # number of bytes to allocate
    li $a1, 165 # Initial value
    jal big_alloc
    move $s0, $v0 # Save the address of the first number

    li $a0, 8 # number of bytes to allocate
    li $a1, 0 # Initial value
    jal big_alloc
    move $s1, $v0 # Save the address of the second number

    # li $a0, 8 # number of bytes to allocate
    # li $a1, 0 # Initial value
    # jal big_alloc
    # move $s2, $v0 # Save the address of the third number

    move $a0, $s0
    jal big_print

    # move $a0, $s1
    # jal big_print

# test:
#     # Calculate the sum
#     move $a0, $s0
#     move $a1, $s1
#     move $a2, $s2
#     jal big_sum

test2:
    li $t5, 0
    li $t6, 60
loop:
    bge $t5, $t6, exit
    move $a0, $s0
    move $a1, $s0
    move $a2, $s1
    jal big_sum
    move $a0, $s0
    move $a1, $s1
    move $a2, $s0
    jal big_sum

    move $a0, $s0
    jal big_print
    addi $t5, 1
    j loop

exit:
    # Exit
    li $v0, 10
    syscall
