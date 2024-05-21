/*** asmSort.s   ***/
#include <xc.h>
.syntax unified

@ Declare the following to be in data memory
.data
.align    

@ Define the globals so that the C code can access them

.if 0    
@ left these in as an example. Not used.
.global fMax
.type fMax,%gnu_unique_object
 fMax: .word 0
.endif 

@ Tell the assembler that what follows is in instruction memory    
.text
.align

/********************************************************************
function name: asmSwap(inpAddr,signed,elementSize)
function description:
    Checks magnitude of each of two input values 
    v1 and v2 that are stored in adjacent in 32bit memory words.
    v1 is located in memory location (inpAddr)
    v2 is located at mem location (inpAddr + M4 word dize)
    
    If v1 or v2 is 0, this function immediately
    places 0 in r0 and returns to the caller.
    
    Else, if v1 <= v2, this function 
    does not modify memory, and returns 0 in r0. 

    Else, if v1 > v2, this function 
    swaps the values and returns 1 in r0

Inputs: r0: inpAddr: Address of v1 to be examined. 
	             Address of v2 is: inpAddr + M4 word size
	r1: signed: 1 indicates values are signed, 
	            0 indicates values are unsigned
	r2: size: number of bytes for each input value.
                  Valid values: 1, 2, 4
                  The values v1 and v2 are stored in
                  the least significant bits at locations
                  inpAddr and (inpAddr + M4 word size).
                  Any bits not used in the word may be
                  set to random values. They should be ignored
                  and must not be modified.
Outputs: r0 returns: -1 If either v1 or v2 is 0
                      0 If neither v1 or v2 is 0, 
                        and a swap WAS NOT made
                      1 If neither v1 or v2 is 0, 
                        and a swap WAS made             
             
         Memory: if v1>v2:
			swap v1 and v2.
                 Else, if v1 == 0 OR v2 == 0 OR if v1 <= v2:
			DO NOT swap values in memory.

NOTE: definitions: "greater than" means most positive number
********************************************************************/     
.global asmSwap
.type asmSwap,%function     
asmSwap:

    push {r4-r11, LR}  // Save caller's registers

    mov r4, r0  // Store inpAddr in r4
    mov r5, r1  // Store signed in r5
    mov r6, r2  // Store elementSize in r6

    cmp r6, 1                 // Compare elementSize with 1
    beq check_size_1          // If elementSize is 1 byte, branch to check_size_1
    cmp r6, 2                 // Compare elementSize with 2
    beq check_size_2          // If elementSize is 2 bytes, branch to check_size_2
    b check_size_4            // If neither, assume 4 bytes and branch to check_size_4


check_size_1:
    ldrb r7, [r4]             // Load byte from address stored in r4 into r7
    ldrb r8, [r4, 4]          // Load byte from address r4 offset by 4 bytes into r8
    cmp r7, 0                 // Compare the loaded byte in r7 with 0
    beq zero_case_1           // If r7 is 0, branch to zero_case_1
    cmp r8, 0                 // Compare the loaded byte in r8 with 0
    beq zero_case_1           // If r8 is 0, also branch to zero_case_1

    cmp r5, 0                 // Compare the value in r5 (determines signed or unsigned comparison) with 0
    beq unsigned_case_1       // If r5 is 0, branch to handle as unsigned bytes
    b signed_case_1           // Otherwise, handle as signed bytes


unsigned_case_1:
    cmp r7, r8                // Compare the unsigned bytes in r7 and r8
    beq equal_case_1          // If r7 equals r8, branch to equal_case_1
    bhi swap_case_1           // If r7 is higher than r8, branch to swap_case_1
    bls no_swap_case_1        // If r7 is lower or equal to r8, branch to no_swap_case_1

signed_case_1:
    ldr r11, =0xFFFFFF00      // Load the sign extension mask for signed byte comparison
    mov r9, r7                // Move the value in r7 to r9
    mov r10, r8               // Move the value in r8 to r10

    lsls r9, r9, 24           // Left shift r9 by 24 bits (sign extension preparation)
    lsr r9, r9, 24            // Logical shift right r9 by 24 bits to restore original value with sign extension
    orrmi r9, r9, r11         // If negative, apply the sign extension mask

    lsls r10, r10, 24         // Left shift r10 by 24 bits (sign extension preparation)
    lsr r10, r10, 24          // Logical shift right r10 by 24 bits to restore original value with sign extension
    orrmi r10, r10, r11       // If negative, apply the sign extension mask

    cmp r9, r10               // Compare the sign-extended values
    beq equal_case_1          // If r9 equals r10, branch to equal_case_1
    bge swap_case_1           // If r9 is greater than or equal to r10, branch to swap_case_1
    blt no_swap_case_1        // If r9 is less than r10, branch to no_swap_case_1


zero_case_1:
    mov r0, -1              // Set return value to -1 indicating failure due to zero element
    b finish                // Branch to finish label to exit the function

equal_case_1:
    mov r0, 0               // Set return value to 0 indicating elements are equal, no swap needed
    b finish                // Branch to finish label to exit the function

swap_case_1:
    strb r8, [r4]           // Store the byte in r8 at the address pointed by r4 (swap elements)
    strb r7, [r4, 4]        // Store the byte in r7 at the address pointed by r4 + 4
    mov r0, 1               // Set return value to 1 indicating a successful swap
    b finish                // Branch to finish label to exit the function

no_swap_case_1:
    mov r0, 0               // Set return value to 0 indicating no swap was performed
    b finish                // Branch to finish label to exit the function


check_size_2:
    ldrh r7, [r4]             // Load halfword (2 bytes) from address stored in r4 into r7
    ldrh r8, [r4, 4]          // Load halfword (2 bytes) from address r4 offset by 4 bytes into r8
    cmp r7, 0                 // Compare the loaded halfword in r7 with 0
    beq zero_case_2           // If r7 is 0, branch to zero_case_2
    cmp r8, 0                 // Compare the loaded halfword in r8 with 0
    beq zero_case_2           // If r8 is 0, also branch to zero_case_2

    cmp r5, 0                 // Compare the value in r5 (determines signed or unsigned comparison) with 0
    beq unsigned_case_2       // If r5 is 0, branch to handle as unsigned halfwords
    b signed_case_2           // Otherwise, handle as signed halfwords

unsigned_case_2:
    cmp r7, r8                // Compare the unsigned halfwords in r7 and r8
    beq equal_case_2          // If r7 equals r8, branch to equal_case_2
    bhi swap_case_2           // If r7 is higher than r8, branch to swap_case_2
    bls no_swap_case_2        // If r7 is lower or equal to r8, branch to no_swap_case_2

signed_case_2:
    ldr r11, =0xFFFF0000      // Load the sign extension mask for signed halfword comparison
    mov r9, r7                // Move the value in r7 to r9
    mov r10, r8               // Move the value in r8 to r10

    lsls r9, r9, 16           // Left shift r9 by 16 bits (sign extension preparation)
    lsr r9, r9, 16            // Logical shift right r9 by 16 bits to restore original value with sign extension
    orrmi r9, r9, r11         // If negative, apply the sign extension mask

    lsls r10, r10, 16         // Left shift r10 by 16 bits (sign extension preparation)
    lsr r10, r10, 16          // Logical shift right r10 by 16 bits to restore original value with sign extension
    orrmi r10, r10, r11       // If negative, apply the sign extension mask

    cmp r9, r10               // Compare the sign-extended values
    beq equal_case_2          // If r9 equals r10, branch to equal_case_2
    bge swap_case_2           // If r9 is greater than or equal to r10, branch to swap_case_2
    blt no_swap_case_2        // If r9 is less than r10, branch to no_swap_case_2


zero_case_2:
    mov r0, -1              // Set return value to -1 indicating failure due to zero element
    b finish                // Branch to finish label to exit the function

equal_case_2:
    mov r0, 0               // Set return value to 0 indicating elements are equal, no swap needed
    b finish                // Branch to finish label to exit the function

swap_case_2:
    strh r8, [r4]           // Store the halfword in r8 at the address pointed by r4 (swap elements)
    strh r7, [r4, 4]        // Store the halfword in r7 at the address pointed by r4 + 4
    mov r0, 1               // Set return value to 1 indicating a successful swap
    b finish                // Branch to finish label to exit the function

no_swap_case_2:
    mov r0, 0               // Set return value to 0 indicating no swap was performed
    b finish                // Branch to finish label to exit the function

check_size_4:
    ldr r7, [r4]            // Load word (4 bytes) from address stored in r4 into r7
    ldr r8, [r4, 4]         // Load word (4 bytes) from address r4 offset by 4 bytes into r8
    cmp r7, 0               // Compare the loaded word in r7 with 0
    beq zero_case_4         // If r7 is 0, branch to zero_case_4
    cmp r8, 0               // Compare the loaded word in r8 with 0
    beq zero_case_4         // If r8 is 0, also branch to zero_case_4

    cmp r5, 0               // Compare the value in r5 (determines signed or unsigned comparison) with 0
    beq unsigned_case_4     // If r5 is 0, branch to handle as unsigned words
    b signed_case_4         // Otherwise, handle as signed words

unsigned_case_4:
    cmp r7, r8              // Compare the unsigned words in r7 and r8
    beq equal_case_4        // If r7 equals r8, branch to equal_case_4
    bhi swap_case_4         // If r7 is higher than r8, branch to swap_case_4
    bls no_swap_case_4      // If r7 is lower or equal to r8, branch to no_swap_case_4


signed_case_4:
    cmp r7, r8               // Compare the signed words in r7 and r8
    beq equal_case_4         // If r7 equals r8, branch to equal_case_4
    bge swap_case_4          // If r7 is greater than or equal to r8, branch to swap_case_4
    blt no_swap_case_4       // If r7 is less than r8, branch to no_swap_case_4

zero_case_4:
    mov r0, -1               // Set return value to -1 indicating failure due to zero element
    b finish                 // Branch to finish label to exit the function

equal_case_4:
    mov r0, 0                // Set return value to 0 indicating elements are equal, no swap needed
    b finish                 // Branch to finish label to exit the function

swap_case_4:
    str r8, [r4]             // Store the word in r8 at the address pointed by r4 (swap elements)
    str r7, [r4, 4]          // Store the word in r7 at the address pointed by r4 + 4
    mov r0, 1                // Set return value to 1 indicating a successful swap
    b finish                 // Branch to finish label to exit the function

no_swap_case_4:
    mov r0, 0                // Set return value to 0 indicating no swap was performed
    b finish                 // Branch to finish label to exit the function

finish:
    pop {r4-r11, LR}         // Restore caller's registers
    mov pc, lr               // Return to caller

    /* YOUR asmSwap CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */
    
    
/********************************************************************
function name: asmSort(startAddr,signed,elementSize)
function description:
    Sorts value in an array from lowest to highest.
    The end of the input array is marked by a value
    of 0.
    The values are sorted "in-place" (i.e. upon returning
    to the caller, the first element of the sorted array 
    is located at the original startAddr)
    The function returns the total number of swaps that were
    required to put the array in order in r0. 
    
         
Inputs: r0: startAddr: address of first value in array.
		      Next element will be located at:
                          inpAddr + M4 word size
	r1: signed: 1 indicates values are signed, 
	            0 indicates values are unsigned
	r2: elementSize: number of bytes for each input value.
                          Valid values: 1, 2, 4
Outputs: r0: number of swaps required to sort the array
         Memory: The original input values will be
                 sorted and stored in memory starting
		 at mem location startAddr
NOTE: definitions: "greater than" means most positive number    
********************************************************************/     
.global asmSort
.type asmSort,%function
asmSort:   

    push {r4-r11, LR}  // Save caller's registers

    mov r4, r0  // Store startAddr in r4 for looping
    mov r9, r0  // Store startAddr in r9 to reset after each pass
    mov r10, 0  // Initialize swap count
    mov r11, 0  // Initialize swap check

bubble_sort_loop:
    mov r0, r4
    BL asmSwap  // Call asmSwap

    cmp r0, -1
    beq check_loop

    add r10, r10, r0  // Increment swap count
    add r11, r11, r0  // Check if any swaps were made
    add r4, r4, 4     // Move to next element
    b bubble_sort_loop

check_loop:
    cmp r11, 0
    beq sort_done

    mov r4, r9  // Reset r4 to startAddr
    mov r11, 0  // Reset swap check
    b bubble_sort_loop

sort_done:
    mov r0, r10  // Move swap count to r0

    pop {r4-r11, LR}
    mov pc, lr  // Return to caller

    bx lr
    /* YOUR asmSort CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */

   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           




