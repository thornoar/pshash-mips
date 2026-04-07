.data
sourceLower: .asciiz "ckapzfitqdxnwehrolmbyvsujg"
sourceUpper: .asciiz "RQLIANBKJYVWPTEMCZSFDOGUHX"
sourceSpecial: .asciiz "=!*@?$%#&-+^"
sourceNumbers: .asciiz "1952074386"
newline_str: .asciiz "\n"

# Big integers are stored as blocks of words in memory,
# where each byte is one digit of a number in base-2^31.
# This allows performing addition without worrying about
# overflow. The terminator of the number is the value
# 0xffffffff

.text
.globl __start
.globl test

# # Arguments:
# #   $a0: address of the number to initialize
# #   $a1: the integer value to initialize with
# big_init:
#     li $t0, 64
#     bgeu $a3, $t0, return # Check if all the digits have already been initialized
#     sw $a1, 0($a0) # Initialize the first digit
#     addi $a0, $a0, 4 # Moving to the next digit
#     addi $a3, $a3, 1 # Increasing the counter
#     move $a1, $zero # Setting all other digits to zero
#     j big_init # Recursive call

# Arguments:
#   $a0: address of the source number
#   $a1: address of the destination number
#   $a3: digit counter
big_copy:
    li $t0, 64
    bgeu $a3, $t0, return # Check if all the digits have already been copied
    lw $t0, 0($a0) # Load the current digit
    sw $t0, 0($a1) # Copy the current digit
    addi $a0, $a0, 4 # Moving to the next digit
    addi $a1, $a1, 4 # Moving to the next digit
    addi $a3, $a3, 1 # Increasing the counter
    j big_copy # Recursive call

# Arguments:
#   $a0: address of number to increment
#   $a1: address of number to store the result to
#   $a3: digit counter
big_increment:
    lw $t0, 0($a0) # Load the first digit into $t0
    addi $t0, $t0, 1 # Increment the first digit
    move $t1, $zero
    lui $t1, 0x8000 # Put the value 2^31 into $t1
    bgeu $t0, $t1, inc_if_carryover # Check if there is carry-over
    sw $t0, 0($a1) # There is no carryover, so store the incremented digit
    addi $a0, $a0, 4
    addi $a1, $a1, 4 # Move to the next digit
    addi $a3, $a3, 1 # Increase the counter
    j big_copy # Copy the remaining digits
inc_if_carryover:
    sw $zero, 0($a1) # The first digit is now zero
    addi $a0, $a0, 4
    addi $a1, $a1, 4 # Move to the next digit
    addi $a3, $a3, 1 # Increase the counter
    j big_increment # Recursive call

# Arguments:
#   $a0: address of the first summand
#   $a1: address of the second summand
#   $a2: address of the result
#   $a3: digit counter
big_sum:
    li $t0, 64
    bgeu $a3, $t0, return # Check if all the digits have already been copied
    lw $t0, 0($a0) # Load the first digit of $a0
    lw $t1, 0($a1) # Load the first digit of $a1
    addu $t2, $t0, $t1 # Add the first digits, store them in $t2
    lui $t3, 0x8000
    bgeu $t2, $t3, sum_if_carryover
    sw $t2, 0($a2) # Store the sum of digits
    addi $a0, $a0, 4
    addi $a1, $a1, 4 # Move to the next digit
    addi $a2, $a2, 4 # Move to the next digit
    addi $a3, $a3, 1 # Increase the counter
    move $a1, $a2
    j big_increment
sum_if_carryover:
    subu $t2, $t2, $t3
    sw $t2, 0($a2) # Store the sum of digits
    addi $a0, $a0, 4
    addi $a1, $a1, 4 # Move to the next digit
    addi $a2, $a2, 4 # Move to the next digit
    addi $a3, $a3, 1 # Increase the counter
    j big_sum # Recursive call
    
return:
    jr $ra

# Arguments:
#   $a0: number of bytes to allocate
# Returns:
#   $v0: the address of the allocated and initialized number
big_alloc:
    li $v0, 9
    syscall
    jr $ra

# Arguments:
#   $a0: the address of the big number to print
#   $a3: the final address
big_print:
    

__start:
    li $a0, 256 # number of bytes to allocate
    jal big_alloc
    move $s0, $v0 # Save the address of the first number
    jal big_alloc
    move $s1, $v0 # Save the address of the second number
    jal big_alloc
    move $s2, $v0 # Save the address of the third number

test:

    # Initialize the first number
    move $a0, $s0
    li $a1, 45
    move $a3, $zero
    jal big_init

    # Initialize the second number
    move $a0, $s1
    li $a1, 100
    move $a3, $zero
    jal big_init

    li $v0, 1
    lw $a0, 0($s1)
    syscall


    # Calculate the sum
    move $a0, $s0
    move $a1, $s1
    move $a2, $s2
    move $a3, $zero
    jal big_sum

    lw $a0, 0($s2)
    li $v0, 1
    syscall

    # Exit
    li $v0, 10
    syscall
