.data
sourceLower: .asciiz "ckapzfitqdxnwehrolmbyvsujg"
sourceUpper: .asciiz "RQLIANBKJYVWPTEMCZSFDOGUHX"
sourceSpecial: .asciiz "=!*@?$%#&-+^"
sourceNumbers: .asciiz "1952074386"

# Big integers are stored as blocks of 64 words in memory,
# where each byte is one digit of a number in base-2^31.
# This allows performing addition without worrying about
# overflow.

.text
.globl __start

# Initialize the big number at address $a0 with the value 0.
# The counter and limit are stored in the arguments $a2 and $a3.
big_init:
    bgeu $a2, $a3, init_if_break # Check if all the digits have already been initialized
    sw $zero, 0($a0) # Initialize the first digit
    addi $a0, $a0, 4 # Moving to the next digit
    addi $a2, $a2, 1 # Increasing the counter
    j big_init # Recursive call
init_if_break:
    jr $ra # Leave the function

# Copy the big integer stored at address $a0 to address $a1.
# The counter is given in $a2. The limit is given in $a3.
big_copy:
    bgeu $a2, $a3, cpy_if_break # Check if all the digits have already been copied
    lw $t0, 0($a0) # Load the current digit
    sw $t0, 0($a1) # Copy the current digit
    addi $a0, $a0, 4 # Moving to the next digit
    addi $a1, $a1, 4 # Moving to the next digit
    addi $a2, $a2, 1 # Increasing the counter
    j big_copy # Recursive call
cpy_if_break:
    jr $ra # Leave the function

# Increment a big integer at address $a0, store the result at address $a1.
# The counter is given in $a2
big_increment:
    lw $t0, 0($a0) # Load the first digit into $t0
    addi $t0, $t0, 1 # Increment the first digit
    move $t1, $zero
    lui $t1, 0x8000 # Put the value 2^31 into $t1
    bgeu $t0, $t1, inc_if_carryover # Check if there is carry-over
    sw $t0, 0($a1) # There is no carryover, so store the incremented digit
    addi $a3, $zero, 64
    addi $a0, $a0, 4
    addi $a1, $a1, 4 # Move to the next digit
    addi $a2, $a2, 1 # Increase the counter
    j big_copy # Copy the remaining digits
    jr $ra # Leave the function
inc_if_carryover:
    sw $zero, 0($a1) # The first digit is now zero
    addi $a0, $a0, 4
    addi $a1, $a1, 4 # Move to the next digit
    addi $a2, $a2, 1 # Increase the counter
    j big_increment # Recursive call

__start:
    li $v0, 9 # memory allocation syscall
    li $a0, 256 # number of bytes to allocate
    syscall
    move $s0, $v0 # Save the address of the first number
    li $v0, 9 # memory allocation syscall
    syscall
    move $s1, $v0 # Save the address of the second number

    # Initialize the first number
    move $a0, $s0
    move $a2, $zero
    li $a3, 64
    jal big_init

    # # Initialize the second number
    # move $a0, $s1
    # move $a2, $zero
    # li $a3, 64
    # jal big_init

    # Exit
    li $v0, 10
    syscall
