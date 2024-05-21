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
    PUSH {r4-r7, lr}              // Save registers and return address

    // Load v1 and v2 based on element size (r2)
    ADD r3, r0, #4               // r3 = address of v2
    CMP r2, #1
    BEQ load_byte
    CMP r2, #2
    BEQ load_halfword
    CMP r2, #4
    BEQ load_word

load_byte:
    LDRB r4, [r0]                // Load v1 as byte
    LDRB r5, [r3]                // Load v2 as byte
    B check_zero

load_halfword:
    LDRH r4, [r0]                // Load v1 as halfword
    LDRH r5, [r3]                // Load v2 as halfword
    B check_zero

load_word:
    LDR r4, [r0]                 // Load v1 as word
    LDR r5, [r3]                 // Load v2 as word

check_zero:
    ORRS r6, r4, r5              // OR v1 and v2 to check if either is zero
    BEQ zero_exit                // Exit if zero found

    // Compare v1 and v2
    CMP r1, #0                   // Check if signed comparison
    BEQ compare_unsigned
    CMP r4, r5
    BGT swap_values
    B no_swap

compare_unsigned:
    CMP r4, r5
    BHI swap_values

no_swap:
    MOV r0, #0                   // Set return value to 0 (no swap)
    B exit

swap_values:
    MOV r6, r4                   // Swap r4 and r5
    MOV r4, r5
    MOV r5, r6
    CMP r2, #1
    BEQ store_byte
    CMP r2, #2
    BEQ store_halfword
    CMP r2, #4
    BEQ store_word

store_byte:
    STRB r4, [r0]                // Store v1 as byte
    STRB r5, [r3]                // Store v2 as byte
    MOV r0, #1                   // Set return value to 1 (swap made)
    B exit

store_halfword:
    STRH r4, [r0]                // Store v1 as halfword
    STRH r5, [r3]                // Store v2 as halfword
    MOV r0, #1                   // Set return value to 1 (swap made)
    B exit

store_word:
    STR r4, [r0]                 // Store v1 as word
    STR r5, [r3]                 // Store v2 as word
    MOV r0, #1                   // Set return value to 1 (swap made)
    B exit

zero_exit:
    MOV r0, #-1                  // Set return value to -1 (zero found)

exit:
    POP {r4-r7, pc}              // Restore registers and return

    bx lr
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
    PUSH {r4-r7, lr}               // Save registers and return address

    MOV r4, r0                     // r4 = startAddr (base address of the array)
    MOV r6, #0                     // r6 = swap count

start_sort:
    MOV r5, r4                     // r5 = pointer to current element (initialized to startAddr)
    MOV r7, #0                     // r7 = swapped (flag for detecting swaps in this pass)

    // Load the first element (assume it is not zero at start)
    LDR r8, [r5]                   // Load current element to r8
    CMP r8, #0                     // Check if the current element is zero (end of array)
    BEQ sort_done                  // If zero, sorting is done

next_element:
    ADD r3, r5, #4                 // r3 = address of next element
    LDR r8, [r3]                   // Load next element
    CMP r8, #0                     // Check if the next element is zero
    BEQ check_last_swap            // If zero, check if last pass had any swaps

    // Call asmSwap to potentially swap elements
    MOV r0, r5                     // Set r0 (inpAddr) for asmSwap
    MOV r1, r1                     // Pass signed flag
    MOV r2, r2                     // Pass elementSize
    BL asmSwap                     // Call asmSwap

    CMP r0, #1                     // Check if a swap was made
    BEQ update_swap_count
    
    //
    CMP r0, #-1			   // Check if zero was found during swap
    BEQ sort_done		   // End sort if zero encountered

    ADD r5, r5, #4                 // Move to next element
    B next_element

update_swap_count:
    ADD r6, r6, #1                 // Increment swap count
    MOV r7, #1                     // Set swapped flag
    ADD r5, r5, #4                 // Move to next element
    B next_element

check_last_swap:
    CMP r7, #1                     // Check if any swaps were made in this pass
    BEQ reset_for_next_pass        // If swaps were made, run another pass
    B sort_done                    // If no swaps, sorting is complete

reset_for_next_pass:
    MOV r5, r4                     // Reset pointer to start of the array
    B start_sort                   // Start new sort pass

sort_done:
    MOV r0, r6                     // Return total number of swaps
    POP {r4-r7, pc}                // Restore registers and return

    bx lr
    /* YOUR asmSort CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */

   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           




