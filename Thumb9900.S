.syntax unified // ARM unified syntax
.thumb_func     // Code uses Thumb instructions

.section .data  // In RAM Please

.global run9900 // Entry point
.global instscnt // Global instruction counter

.extern F18A_PIX

// *********************************************************************************************
//.extern debug_print
//        BL   sav9900
//        BLX  debug_print
//        BL   res9900
// *********************************************************************************************
/*
sav9900: // Save simulator state and restore GCC registers except R0-R3
        PUSH {R0-R7} // 8 ... PUSHes in reverse: R7..R0
        MOV  R4,R8
        MOV  R5,R9
        MOV  R6,R10
        MOV  R7,R11
        PUSH {R4-R7} // +4 = 12 ... R11..R8
        MOV  R4,R12
        PUSH {R4}    // +1 = 13

        LDR  R4,[SP,#52] // 13 * 4
        MOV  R12,R4

        MOV  PC,LR
// *********************************************************************************************
res9900: // Restore simulator state
        POP  {R0}
        MOV  R12,R0
        POP  {R0-R3}
        MOV  R8,R0
        MOV  R9,R1
        MOV  R10,R2
        MOV  R11,R3
        POP  {R0-R7} // POPs in order: R0..R7
        MOV  PC,LR
*/
// *********************************************************************************************

// Instructions

// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567 (Format 5)
//CCCCWWWW00001000
I_SRA:  LSLS R5,R0,#20
        LSRS R5,#27 // Get Register x 2
        ADD  R5,R11 // Add WP
        UXTH R5,R5
        ADD  R5,R8
        
        LSRS R2,R0,#12 // Get Shift Count
        BNE  I_SRA_nr0 // Result not 0 - got it, else
        MOV  R2,R11
        ADD  R2,R8
        LDRB R2,[R2,#1] // Get R0 low byte
        MOVS R4,#0x0F  // Mask lower nibble
        ANDS R2,R4
        BNE  I_SRA_nr0 // Result not 0 - got it, else
        MOVS R2,#16
I_SRA_nr0:
        LDRH R0,[R5,#0]
        REVSH R0,R0 // Signed

        MOV  R1,R12
        MOVS R4,#0x0E // Get initialised ST
        ANDS R1,R4
        
        ASRS R0,R2
        BCC  I_SRA_st // Carry Clear?
        ADDS R1,#0x10 // Carry Bit
I_SRA_st:
        REV16 R2,R0
        STRH R2,[R5,#0]
        B    OP_COMP_W
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567 (Format 5)
//CCCCWWWW00001001
I_SRL:  LSLS R5,R0,#20
        LSRS R5,#27 // Get Register x 2
        ADD  R5,R11 // Add WP
        UXTH R5,R5
        ADD  R5,R8

        LSRS R2,R0,#12 // Get Shift Count
        BNE  I_SRL_nr0 // Result not 0 - got it, else
        MOV  R2,R11
        ADD  R2,R8
        LDRB R2,[R2,#1] // Get R0 low byte
        MOVS R4,#0x0F  // Mask lower nibble
        ANDS R2,R4
        BNE  I_SRL_nr0 // Result not 0 - got it, else
        MOVS R2,#16
I_SRL_nr0:
        LDRH R0,[R5,#0]
        REV16 R0,R0 // Unsigned

        MOV  R1,R12
        MOVS R4,#0x0E // Get initialised ST
        ANDS R1,R4
        
        LSRS R0,R2
        BCC  I_SRL_st // Carry Clear?
        ADDS R1,#0x10 // Carry Bit
I_SRL_st:
        REV16 R2,R0
        STRH R2,[R5,#0]
        B    OP_COMP_W
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567 (Format 5)
//CCCCWWWW00001010
I_SLA:  LSLS R5,R0,#20
        LSRS R5,#27 // Get Register x 2
        ADD  R5,R11 // Add WP
        UXTH R5,R5
        ADD  R5,R8

        MOV  R1,R12
        MOVS R4,#0x06 // Get initialised ST
        ANDS R1,R4

        LSRS R2,R0,#12 // Get Shift Count
        BNE  I_SLA_nr0 // Result not 0 - got it, else
        MOV  R2,R11
        ADD  R2,R8
        LDRB R2,[R2,#1] // Get R0 low byte
        MOVS R4,#0x0F  // Mask lower nibble
        ANDS R2,R4
        BNE  I_SLA_nr0 // Result not 0 - got it, else
        MOVS R2,#16

        LDRH R0,[R5,#0]
        REV16 R0,R0 // Unsigned
        LSLS R4,R0,#16
        ORRS R0,R4 // Copy lower halfword to high halfword

        // Set Overflow if sign changes
        BNE  I_SLA_ov // Result was not zero
        B    I_SLA_nov
I_SLA_nr0:
        LDRH R0,[R5,#0]
        REV16 R0,R0 // Unsigned
        LSLS R4,R0,#16
        ORRS R0,R4 // Copy lower halfword to high halfword

        // Set Overflow if sign changes
        ADR  R4,I_SLA_M
        LSLS R6,R2,#2
        LDR  R3,[R4,R6] // Get correct mask

        LSRS R4,R0,#16 // Top bit into Carry
        BCS  I_SLA_neg // Result was not zero

        // Positive number test
        TST  R0,R3
        BNE  I_SLA_ov // Result was not zero
        B    I_SLA_nov
I_SLA_neg:
        // Negative number test
        MOV  R4,R0
        ANDS R4,R3
        CMP  R4,R3
        BEQ  I_SLA_nov // Sign bit never changes
I_SLA_ov:
        ADDS R1,#0x08 // Overflow Bit
I_SLA_nov:
        LSLS R0,R2
        BCC  I_SLA_st // Carry Clear?
        ADDS R1,#0x10 // Carry Bit
I_SLA_st:
        REV16 R2,R0
        STRH R2,[R5,#0]
        B    OP_COMP_W
.align 4
I_SLA_M: .WORD 0x0000, 0x4000, 0x6000, 0x7000, 0x7800, 0x7C00, 0x7E00, 0x7F00
         .WORD 0x7F80, 0x7FC0, 0x7FE0, 0x7FF0, 0x7FF8, 0x7FFC, 0x7FFE, 0x7FFF
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567 (Format 5)
//CCCCWWWW00001011
I_SRC:  LSLS R5,R0,#20
        LSRS R5,#27 // Get Register x 2
        ADD  R5,R11 // Add WP
        UXTH R5,R5
        ADD  R5,R8

        LSRS R2,R0,#12 // Get Shift Count
        BNE  I_SRC_nr0 // Result not 0 - got it, else
        MOV  R2,R11
        ADD  R2,R8
        LDRB R2,[R2,#1] // Get R0 low byte
        MOVS R4,#0x0F  // Mask lower nibble
        ANDS R2,R4
        BNE  I_SRC_nr0 // Result not 0 - got it, else
        MOVS R2,#16
I_SRC_nr0:
        LDRH R0,[R5,#0]
        REV16 R0,R0 // Unsigned
        LSLS R4,R0,#16
        ORRS R0,R4 // Copy lower halfword to high halfword

        MOV  R1,R12
        MOVS R4,#0x0E // Get initialised ST
        ANDS R1,R4
        
        RORS R0,R2
        BCC  I_SRC_st // Carry Clear?
        ADDS R1,#0x10 // Carry Bit
I_SRC_st:
        REV16 R2,R0
        STRH R2,[R5,#0]
        B    OP_COMP_W

// *********************************************************************************************
I_LI:   ADDS R2,R3,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R3,R8
        LDRH R0,[R3,#0]
        STRH R0,[R6,#0]
        REV16 R0,R0
        MOV  R1,R12
        MOVS R4,#0x1E // Get initialised ST
        ANDS R1,R4
        B    OP_COMP_W
// *********************************************************************************************
I_AI:   ADDS R2,R3,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R3,R8
        LDRH R5,[R3,#0]
        REV16 R5,R5
        B    I_A
// *********************************************************************************************
I_RTWP: MOV  R3,R11  // Get address of WP
        ADDS R3,#26   // R13 - start position for restoring return details
        ADDS R2,R3,#2 // R14
        ADDS R4,R3,#4 // R15
        UXTH R3,R3
        UXTH R2,R2
        UXTH R4,R4
        ADD  R3,R8
        ADD  R2,R8
        ADD  R4,R8

        LDRB R1,[R4,#0] // R15 high byte
        MOV  R12,R1

        LDRH R1,[R2,#0] // R14..
        REV16 R1,R1
        LSRS R1,#1
        LSLS R1,#1 // R1 &= 0xFFFE
        MOV  R10,R1

        LDRH R1,[R3,#0] // R13..
        REV16 R1,R1
        LSRS R1,#1
        LSLS R1,#1 // R1 &= 0xFFFE
        MOV  R11,R1
        B    start
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567
//ooo.WWWW00000011
I_LIMI: ADDS R3,#2    // Skip LIMI's 2nd WORD
        UXTH R3,R3
        MOV  R10,R3
        B    start
// *********************************************************************************************
I_ANDI: ADDS R2,R3,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R3,R8
        LDRH R0,[R3,#0]
        LDRH R3,[R6,#0] // R6=DEST
        ANDS R0,R3
        STRH R0,[R6,#0] // R6=DEST
        REV16 R0,R0
        MOV  R1,R12
        MOVS R4,#0x1E // Get initialised ST
        ANDS R1,R4
        B    OP_COMP_W
// *********************************************************************************************
I_ORI:  ADDS R2,R3,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R3,R8
        LDRH R0,[R3,#0]
        LDRH R3,[R6,#0] // R6=DEST
        ORRS R0,R3
        STRH R0,[R6,#0] // R6=DEST
        REV16 R0,R0
        MOV  R1,R12
        MOVS R4,#0x1E // Get initialised ST
        ANDS R1,R4
        B    OP_COMP_W
// *********************************************************************************************
I_CI:   ADDS R2,R3,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R3,R8
        LDRH R5,[R3,#0]
        REV16 R5,R5

        LDRH R2,[R6,#0] // R6=DEST
        REV16 R2,R2

        MOV  R1,R12
        MOVS R4,#0x1E // Get initialised ST
        ANDS R1,R4

        CMP  R2,R5
        BNE  I_CI_l
        ADDS R1,#0x20 // Equal bit
        MOV  R12,R1
        B    start
I_CI_l:
        BLO  I_CI_a
        ADDS R1,#0x80 // Logic > bit
I_CI_a:
        SXTH R5,R5
        SXTH R2,R2
        CMP  R2,R5 // Redo flags
        BLT  I_CI_e
        ADDS R1,#0x40 // Arith > bit
I_CI_e:
        MOV  R12,R1
        B    start
// *********************************************************************************************
I_LWPI: ADDS R2,R3,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R3,R8
        LDRH R0,[R3,#0]
        REV16 R0,R0
        LSRS R0,#1
        LSLS R0,#1 // R0 &= 0xFFFE
        MOV  R11,R0
        B    start

// *********************************************************************************************
I_STWP: MOV  R0,R11
        REV16 R0,R0
        STRH R0,[R6,#0]
        B    start
// *********************************************************************************************
I_STST: MOV  R0,R12 // Don't need to swap low bytes here
        STRH R0,[R6,#0]
        B    start

// *********************************************************************************************
I_BLWP: LDRH R0,[R5,#0] // R5=SRCE
        REV16 R0,R0
        LSRS R0,#1
        LSLS R0,#1 // R0 &= 0xFFFE
        MOV  R1,R11 // WP
        MOV  R11,R0
        ADDS R0,#26   // R13 - start position for storing return details
        ADDS R3,R0,#2 // R14
        ADDS R4,R0,#4 // R15
        UXTH R0,R0
        UXTH R3,R3
        UXTH R4,R4
        ADD  R0,R8
        ADD  R3,R8
        ADD  R4,R8

        REV16 R1,R1
        STRH R1,[R0,#0] // R13

        MOV  R1,R10 // PC
        REV16 R1,R1
        STRH R1,[R3,#0] // R14

        MOV  R1,R12 // Don't need to swap low bytes here
        STRH R1,[R4,#0] // R15 High Byte = ST

        LDRH R0,[R5,#2] // R5=SRCE *** TODO: Possible overrun of the 64KB address space
        REV16 R0,R0
        LSRS R0,#1
        LSLS R0,#1 // R0 &= 0xFFFE
        MOV  R10,R0 // PC
        B    start
// *********************************************************************************************
I_B:    MOV  R0,R8
        SUBS R5,R0 // Normalise
        MOV  R10,R5
        B    start
// *********************************************************************************************
I_X:    LDRH R0,[R5,#0] // R5=SRCE
        MOV  R3,R10 // R3 has lost its PC+2 value by now
        B    startX
// *********************************************************************************************
I_CLR:  MOVS R0,#0
        STRH R0,[R5,#0]
        B    start
// *********************************************************************************************
I_NEG:  LDRH R0,[R5,#0] // R5=SRCE/DEST
        REV16 R0,R0

        MOV  R1,R12
        MOVS R4,#0x06 // Get initialised ST
        ANDS R1,R4

        MOVS R4,#0x80
        LSLS R4,#8 // -> #0x8000
        CMP  R0,R4
        BNE  I_NEG_no_ov
        ADDS R1,#0x08 // Overflow bit
        B    OP_COMP_W
I_NEG_no_ov:
        RSBS R0,#0 // R0=0-R0
        BNE  I_NEG_nc
        ADDS R1,#0x10 // Carry bit
I_NEG_nc:
        REV16 R2,R0
        STRH R2,[R5,#0]
        B    OP_COMP_W
// *********************************************************************************************
I_INV:  LDRH R0,[R5,#0] // R5=SRCE/DEST
        MVNS R0,R0
        STRH R0,[R5,#0]
        REV16 R0,R0
        MOV  R1,R12
        MOVS R4,#0x1E // Get initialised ST
        ANDS R1,R4
        B    OP_COMP_W
// *********************************************************************************************
I_INC:  LDRH R2,[R5,#0] // R5=SRCE/DEST
        REV16 R2,R2

        ADDS R3,R2,#1

        UXTH R0,R3 // Keep a clean copy
        REV16 R3,R3
        STRH R3,[R5,#0]

        MOV  R1,R12
        MOVS R4,#0x06 // Get initialised ST
        ANDS R1,R4

        CMP  R2,R0
        BLO  I_INC_nc
        ADDS R1,#0x10 // Carry bit
I_INC_nc:
        LSRS R2,#15
        BNE  I_INC_e
        LSRS R4,R0,#15
        CMP  R2,R4
        BEQ  I_INC_e
        ADDS R1,#0x08 // Overflow bit
I_INC_e:
        B    OP_COMP_W
// *********************************************************************************************
I_INCT: LDRH R2,[R5,#0] // R5=SRCE/DEST
        REV16 R2,R2

        ADDS R3,R2,#2

        UXTH R0,R3 // Keep a clean copy
        REV16 R3,R3
        STRH R3,[R5,#0]

        MOV  R1,R12
        MOVS R4,#0x06 // Get initialised ST
        ANDS R1,R4

        CMP  R2,R0
        BLO  I_INCT_nc
        ADDS R1,#0x10 // Carry bit
I_INCT_nc:
        LSRS R2,#15
        BNE  I_INCT_e
        LSRS R4,R0,#15
        CMP  R2,R4
        BEQ  I_INCT_e
        ADDS R1,#0x08 // Overflow bit
I_INCT_e:
        B    OP_COMP_W
// *********************************************************************************************
I_DEC:  LDRH R2,[R5,#0] // R5=SRCE/DEST
        REV16 R2,R2
        SUBS R3,R2,#1

        UXTH R0,R3 // Keep a clean copy
        REV16 R3,R3
        STRH R3,[R5,#0]

        MOV  R1,R12
        MOVS R4,#0x06 // Get initialised ST
        ANDS R1,R4

        CMP  R2,R0
        BLO  I_DEC_nc
        ADDS R1,#0x10 // Carry bit
I_DEC_nc:
        LSRS R2,#15
        BEQ  I_DEC_e
        LSRS R4,R0,#15
        CMP  R2,R4
        BEQ  I_DEC_e
        ADDS R1,#0x08 // Overflow bit
I_DEC_e:
        B    OP_COMP_W
// *********************************************************************************************
I_DECT: LDRH R2,[R5,#0] // R5=SRCE/DEST
        REV16 R2,R2

        SUBS R3,R2,#2

        UXTH R0,R3 // Keep a copy
        REV16 R3,R3
        STRH R3,[R5,#0]

        MOV  R1,R12
        MOVS R4,#0x06 // Get initialised ST
        ANDS R1,R4

        CMP  R2,R0
        BLO  I_DECT_nc
        ADDS R1,#0x10 // Carry bit
I_DECT_nc:
        LSRS R2,#15
        BEQ  I_DECT_e
        LSRS R4,R0,#15
        CMP  R2,R4
        BEQ  I_DECT_e
        ADDS R1,#0x08 // Overflow bit
I_DECT_e:
        B    OP_COMP_W
// *********************************************************************************************
I_BL:   MOV  R0,R10
        REV16 R0,R0
        MOV  R1,R11
        ADDS R1,#22 // R11
        UXTH R1,R1
        MOV  R2,R8
        ADDS R1,R2
        STRH R0,[R1,#0]
        SUBS R5,R2 // Normalise
        MOV  R10,R5
        B    start
// *********************************************************************************************
I_SWPB: LDRH R0,[R5,#0] // R5=SRCE
        REV16 R0,R0
        STRH R0,[R5,#0]
        B    start
// *********************************************************************************************
I_SETO: MOVS R0,0xFF
        SXTB R0,R0
        STRH R0,[R5,#0]
        B    start
// *********************************************************************************************
I_ABS:  LDRH R0,[R5,#0] // R5=SRCE
        REV16 R0,R0

        MOV  R1,R12
        MOVS R4,#0x06 // Get initialised ST
        ANDS R1,R4

        MOVS R4,#0x80
        LSLS R4,#8 // -> #0x8000
        TST  R0,R4 // pos check...
        BEQ  I_ABS_e
        CMP  R0,R4
        BNE  I_ABS_no_ov
        ADDS R1,#0x08 // Overflow bit
        B    OP_COMP_W
I_ABS_no_ov:
        RSBS R2,R0,#0 // R2=0-R0
        REV16 R2,R2
        STRH R2,[R5,#0]
I_ABS_e:
        B    OP_COMP_W
// *********************************************************************************************
I_JMP:  MOVS R1,#0xFE
        SXTB R1,R1
        CMP  R0,R1   // Does this jump to itself?
        BEQ  I_IDLE  // Then quit the emulation
I_JMP_g:
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
        B    start
// *********************************************************************************************
I_IDLE: ADR  R0,RETCODE
        MOV  R1,R10 // PC
        STR  R1,[R0,#0]

        POP  {R0}
        MOV  R12,R0
        POP  {R0-R3}
        MOV  R8,R0
        MOV  R9,R1
        MOV  R10,R2
        MOV  R11,R3
        POP  {R0-R3}
        MOV  R4,R0
        MOV  R5,R1
        MOV  R6,R2
        MOV  R7,R3
        ADR  R0,RETCODE
        LDR  R0,[R0,#0]
        POP {PC}
.align 4
RETCODE: .WORD 0
// *********************************************************************************************
I_JLT:  MOVS R1,#0x60 // AG|EQ
        TST  R2,R1
        BNE  I_JLT_e  // At least one of them was not zero
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JLT_e:
        B    start
// *********************************************************************************************
I_JLE:  LSRS R3,R2,#6 // EQ -> Carry
        BCS  I_JLE_j
        LSRS R3,R2,#8 // LG -> Carry
        BCS  I_JLE_e
I_JLE_j:
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JLE_e:
        B    start
// *********************************************************************************************
I_JEQ:  LSRS R3,R2,#6 // EQ -> Carry
        BCC  I_JEQ_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JEQ_e:
        B    start
// *********************************************************************************************
I_JHE:  LSRS R3,R2,#6 // EQ -> Carry
        BCS  I_JHE_j
        LSRS R3,R2,#8 // LG -> Carry
        BCC  I_JHE_e
I_JHE_j:
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JHE_e:
        B    start
// *********************************************************************************************
I_JGT:  LSRS R3,R2,#7 // AG -> Carry
        BCC  I_JGT_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JGT_e:
        B    start
// *********************************************************************************************
I_JNE:  LSRS R3,R2,#6 // EQ -> Carry
        BCS  I_JNE_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JNE_e:
        B    start
// *********************************************************************************************
I_JNC:  LSRS R3,R2,#5 // C -> Carry
        BCS  I_JNC_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JNC_e:
        B    start
// *********************************************************************************************
I_JOC:  LSRS R3,R2,#5 // C -> Carry
        BCC  I_JOC_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JOC_e:
        B    start
// *********************************************************************************************
I_JNO:  LSRS R3,R2,#4 // O -> Carry
        BCS  I_JNO_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JNO_e:
        B    start
// *********************************************************************************************
I_JL:   MOVS R1,#0xA0 // LG|EQ
        TST  R2,R1
        BNE  I_JL_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JL_e:
        B    start
// *********************************************************************************************
I_JH:   LSRS R3,R2,#6 // EQ -> Carry
        BCS  I_JH_e
        LSRS R3,R2,#8 // LG -> Carry
        BCC  I_JH_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JH_e:
        B    start
// *********************************************************************************************
I_JOP:  LSRS R3,R2,#3 // P -> Carry
        BCC  I_JOP_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JOP_e:
        B    start
// *********************************************************************************************
I_SBO: // SBO - Not Implemented
I_SBZ: // SBZ - Not Implemented
        B    start
I_TB:  // TB  - Not Implemented
        MOV  R1,R12
        MOVS R4,#0xDF // ~EQ
        ANDS R1,R4
        MOV  R12,R1
        B    start
// *********************************************************************************************
I_C:    LDRH R2,[R6,#0] // R6=DEST
        REV16 R2,R2

        MOV  R1,R12
        MOVS R4,#0x1E // Get initialised ST
        ANDS R1,R4

        CMP  R5,R2
        BNE  I_C_l
        ADDS R1,#0x20 // Equal bit
        MOV  R12,R1
        B    start
I_C_l:
        BLO  I_C_a
        ADDS R1,#0x80 // Logic > bit
I_C_a:
        SXTH R5,R5
        SXTH R2,R2
        CMP  R5,R2 // Redo flags
        BLT  I_C_e
        ADDS R1,#0x40 // Arith > bit
I_C_e:
        MOV  R12,R1
        B    start
// *********************************************************************************************
I_CB:   LDRB R2,[R6,#0] // R6=DEST

        MOV  R1,R12
        MOVS R4,#0x1A // Get initialised ST
        ANDS R1,R4

        ADR  R3,PARITY
        LDRB R3,[R3,R5]
        ORRS R1,R3

        CMP  R5,R2
        BNE  I_CB_l
        ADDS R1,#0x20 // Equal bit
        MOV  R12,R1
        B    start
I_CB_l:
        BLO  I_CB_a
        ADDS R1,#0x80 // Logic > bit
I_CB_a:
        SXTB R5,R5
        SXTB R2,R2
        CMP  R5,R2 // Redo flags
        BLT  I_CB_e
        ADDS R1,#0x40 // Arith > bit
I_CB_e:
        MOV  R12,R1
        B    start
// *********************************************************************************************
I_COC:  ANDS R4,R5
        MOV  R1,R12
        CMP  R4,R5
        BNE  I_COC_ne
        MOVS R4,#0x20 // EQ
        ORRS R1,R4
        MOV  R12,R1
        B    start
I_COC_ne:
        MOVS R4,#0xDF // ~EQ
        ANDS R1,R4
        MOV  R12,R1
        B    start
// *********************************************************************************************
I_CZC:  ANDS R4,R5
        MOV  R1,R12
        CMP  R4,#0
        BNE  I_CZC_ne
        MOVS R4,#0x20 // EQ
        ORRS R1,R4
        MOV  R12,R1
        B    start
I_CZC_ne:
        MOVS R4,#0xDF // ~EQ
        ANDS R1,R4
        MOV  R12,R1
        B    start
// *********************************************************************************************
I_XOR:  EORS R4,R5 // R4=TEMP, R5=*SRCE
        REV16 R4,R4
        STRH R4,[R6,#0] // R6=DEST
        REV16 R0,R4
        MOV  R1,R12
        MOVS R4,#0x1E // Get initialised ST
        ANDS R1,R4
        B    OP_COMP_W
// *********************************************************************************************
I_SZC:  LDRH R0,[R6,#0] // R6=DEST
        REV16 R5,R5
        BICS R0, R5
        STRH R0,[R6,#0]
        REV16 R0,R0
        MOV  R1,R12
        MOVS R4,#0x1E // Get initialised ST
        ANDS R1,R4
        B    OP_COMP_W
// *********************************************************************************************
I_SZCB: LDRB R0,[R6,#0] // R6=DEST
        BICS R0, R5
        STRB R0,[R6,#0]
        MOV  R1,R12
        MOVS R4,#0x1A // Get initialised ST
        ANDS R1,R4
        B    OP_COMP_B
// *********************************************************************************************
I_S:    LDRH R2,[R6,#0] // R6=DEST
        REV16 R2,R2

        SUBS R3,R2,R5

        UXTH R0,R3 // Keep a copy
        REV16 R3,R3
        STRH R3,[R6,#0]

        MOV  R1,R12
        MOVS R4,#0x06 // Get initialised ST
        ANDS R1,R4

        CMP  R5,#0
        BEQ  I_S_c // Zero sets Carry
        CMP  R2,R0
        BLO  I_S_nc
I_S_c:
        ADDS R1,#0x10 // Carry bit
I_S_nc:
        LSRS R5,#15
        LSRS R2,#15
        CMP  R2,R5
        BEQ  OP_COMP_W
        LSRS R4,R0,#15
        CMP  R2,R4
        BEQ  OP_COMP_W
        ADDS R1,#0x08 // Overflow bit
        B    OP_COMP_W
// *********************************************************************************************
I_SB:   LDRB R2,[R6,#0] // R6=DEST

        SUBS R3,R2,R5

        UXTB R0,R3 // Keep a copy
        STRB R3,[R6,#0]

        MOV  R1,R12
        MOVS R4,#0x02 // Get initialised ST
        ANDS R1,R4

        CMP  R5,#0
        BEQ  I_SB_c // Zero sets Carry
        CMP  R2,R0
        BLO  I_SB_nc
I_SB_c:
        ADDS R1,#0x10 // Carry bit
I_SB_nc:
        LSRS R5,#7
        LSRS R2,#7
        CMP  R2,R5
        BEQ  OP_COMP_B
        LSRS R4,R0,#7
        CMP  R2,R4
        BEQ  OP_COMP_B
        ADDS R1,#0x08 // Overflow bit
        B    OP_COMP_B
// *********************************************************************************************
I_A:    LDRH R2,[R6,#0] // R6=DEST
        REV16 R2,R2

        ADDS R3,R2,R5

        MOV  R1,R12
        MOVS R4,#0x06 // Get initialised ST
        ANDS R1,R4

        LSRS R4,R3,#16
        BEQ  I_A_nc
        ADDS R1,#0x10 // Carry bit
I_A_nc:
        UXTH R0,R3 // Keep a copy
        REV16 R3,R3
        STRH R3,[R6,#0]

        LSRS R5,#15
        LSRS R2,#15
        CMP  R2,R5
        BNE  OP_COMP_W
        LSRS R4,R0,#15
        CMP  R2,R4
        BEQ  OP_COMP_W
        ADDS R1,#0x08 // Overflow bit
        B    OP_COMP_W
// *********************************************************************************************
I_AB:   LDRB R2,[R6,#0] // R6=DEST

        ADDS R0,R2,R5

        MOV  R1,R12
        MOVS R4,#0x02 // Get initialised ST
        ANDS R1,R4

        LSRS R4,R0,#8
        BEQ  I_AB_nc
        ADDS R1,#0x10 // Carry bit
        UXTB R0,R0
I_AB_nc:
        STRB R0,[R6,#0]

        LSRS R5,#7
        LSRS R2,#7
        CMP  R2,R5
        BNE  OP_COMP_B
        LSRS R4,R0,#7
        CMP  R2,R4
        BEQ  OP_COMP_B
        ADDS R1,#0x08 // Overflow bit
        B    OP_COMP_B
// *********************************************************************************************
I_MOV:  REV16 R5,R5
        STRH R5,[R6,#0]
        REV16 R0,R5
        MOV  R1,R12
        MOVS R4,#0x1E // Get initialised ST
        ANDS R1,R4
// *********************************************************************************************
OP_COMP_W:
        SXTH R0,R0
        CMP  R0,#0
        BNE  OP_COMP_W_l
        ADDS R1,#0x20 // Equal bit
        MOV  R12,R1
        B    start
OP_COMP_W_l:
        BGT  OP_COMP_W_a
        ADDS R1,#0x80 // L >
        MOV  R12,R1
        B    start
OP_COMP_W_a:
        ADDS R1,#0xC0 // LA >
        MOV  R12,R1
        B    start
// *********************************************************************************************
I_MOVB: STRB R5,[R6,#0]
        MOV  R0,R5
        MOV  R1,R12
        MOVS R4,#0x1A // Get initialised ST
        ANDS R1,R4
// ***************************************** DEBUG *********************************************

        CMP  R0,#32 // space
        BLO  OP_COMP_B
        CMP  R0,#127 // '~'
        BHI  OP_COMP_B
        MOV  R3,R8
        SUBS R6,R3 // Normalise
        MOVS R3,#0x8C
        LSLS R3,#8 // -> 0x8C00
        CMP  R6,R3
        BNE  OP_COMP_B
        MOV  R5,R9
        STRB R0,[R5,#0]
        ADDS R5,#1
        MOV  R9,R5

// *********************************************************************************************
OP_COMP_B:
        ADR  R3,PARITY0
        LDRB R3,[R3,R0]
        ORRS R1,R3
        MOV  R12,R1
        B    start
// *********************************************************************************************
I_SOC:  LDRH R0,[R6,#0]
        REV16 R5,R5
        ORRS R0,R5
        STRH R0,[R6,#0]
        REV16 R0,R0
        MOV  R1,R12
        MOVS R4,#0x1E // Get initialised ST
        ANDS R1,R4
        B    OP_COMP_W
// *********************************************************************************************
I_SOCB: LDRB R0,[R6,#0]
        ORRS R0,R5
        STRB R0,[R6,#0]
        MOV  R1,R12
        MOVS R4,#0x1A // Get initialised ST
        ANDS R1,R4
        B    OP_COMP_B

// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567
//DDTsSSSS00111xDD
I_MUL:  LDRH R5,[R5,#0] // R5=SRCE
        REV16 R5,R5

        LSRS R6,R0,#13
        LSLS R1,R0,#3
        ORRS R6,R1
        MOVS R2,#0x1E
        ANDS R6,R2 // Got D << 1
        ADD  R6,R11 // DEST = WP + D;
        UXTH R6,R6
        ADD  R6,R8

        LDRH R0,[R6,#0]
        REV16 R0,R0
        MULS R0,R5
        REV16 R0,R0
        STRH R0,[R6,#2] // *** TODO: Possible overrun of the 64KB address space
        LSRS R0,16
        STRH R0,[R6,#0]
        B    start
// *********************************************************************************************
I_DIV:  LDRH R5,[R5,#0] // R5=SRCE
        REV16 R5,R5

        LSRS R6,R0,#13
        LSLS R1,R0,#3
        ORRS R6,R1
        MOVS R2,#0x1E
        ANDS R6,R2 // Got D << 1
        ADD  R6,R11 // DEST = WP + D;
        UXTH R6,R6
        ADD  R6,R8

        LDRH R0,[R6,#0]
        REV16 R0,R0
        CMP   R5,R0
        BLS   I_DIV_ov // Equal also overflows

        LSLS  R0,16
        LDRH R1,[R6,#2] // *** TODO: Possible overrun of the 64KB address space
        REV16 R1,R1
        ORRS  R0,R1

        MOVS R2,#0xD0
        LSLS R2,#24 // -> 0xD0000000 = SIO_BASE
        STR  R0,[R2, #0x60] // SIO_DIV_UDIVIDEND_OFFSET
        STR  R5,[R2, #0x64] // SIO_DIV_UDIVISOR_OFFSET
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        LDR  R1,[R2, #0x74] // SIO_DIV_REMAINDER_OFFSET
        LDR  R0,[R2, #0x70] // SIO_DIV_QUOTIENT_OFFSET

        REV16 R0,R0
        STRH R0,[R6,#0]
        REV16 R1,R1
        STRH R1,[R6,#2] // *** TODO: Possible overrun of the 64KB address space

        MOV  R1,R12
        MOVS R4,#0xF7 // ~OV
        ANDS R1,R4
        MOV  R12,R1
        B    start
I_DIV_ov:
        MOV  R1,R12
        MOVS R4,#0x08 // OV
        ORRS R1,R4
        MOV  R12,R1
        B    start

// *********************************************************************************************
.align 4
PARITY:
    .BYTE 0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0
    .BYTE 4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4
    .BYTE 4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4
    .BYTE 0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0
    .BYTE 4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4
    .BYTE 0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0
    .BYTE 0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0
    .BYTE 4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4
    .BYTE 4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4
    .BYTE 0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0
    .BYTE 0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0
    .BYTE 4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4
    .BYTE 0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0
    .BYTE 4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4
    .BYTE 4, 0, 0, 4, 0, 4, 4, 0, 0, 4, 4, 0, 4, 0, 0, 4
    .BYTE 0, 4, 4, 0, 4, 0, 0, 4, 4, 0, 0, 4, 0, 4, 4, 0
PARITY0: // Compare to 0 status result
    .BYTE 0x20, 0xC4, 0xC4, 0xC0, 0xC4, 0xC0, 0xC0, 0xC4, 0xC4, 0xC0, 0xC0, 0xC4, 0xC0, 0xC4, 0xC4, 0xC0
    .BYTE 0xC4, 0xC0, 0xC0, 0xC4, 0xC0, 0xC4, 0xC4, 0xC0, 0xC0, 0xC4, 0xC4, 0xC0, 0xC4, 0xC0, 0xC0, 0xC4
    .BYTE 0xC4, 0xC0, 0xC0, 0xC4, 0xC0, 0xC4, 0xC4, 0xC0, 0xC0, 0xC4, 0xC4, 0xC0, 0xC4, 0xC0, 0xC0, 0xC4
    .BYTE 0xC0, 0xC4, 0xC4, 0xC0, 0xC4, 0xC0, 0xC0, 0xC4, 0xC4, 0xC0, 0xC0, 0xC4, 0xC0, 0xC4, 0xC4, 0xC0
    .BYTE 0xC4, 0xC0, 0xC0, 0xC4, 0xC0, 0xC4, 0xC4, 0xC0, 0xC0, 0xC4, 0xC4, 0xC0, 0xC4, 0xC0, 0xC0, 0xC4
    .BYTE 0xC0, 0xC4, 0xC4, 0xC0, 0xC4, 0xC0, 0xC0, 0xC4, 0xC4, 0xC0, 0xC0, 0xC4, 0xC0, 0xC4, 0xC4, 0xC0
    .BYTE 0xC0, 0xC4, 0xC4, 0xC0, 0xC4, 0xC0, 0xC0, 0xC4, 0xC4, 0xC0, 0xC0, 0xC4, 0xC0, 0xC4, 0xC4, 0xC0
    .BYTE 0xC4, 0xC0, 0xC0, 0xC4, 0xC0, 0xC4, 0xC4, 0xC0, 0xC0, 0xC4, 0xC4, 0xC0, 0xC4, 0xC0, 0xC0, 0xC4
    .BYTE 0x84, 0x80, 0x80, 0x84, 0x80, 0x84, 0x84, 0x80, 0x80, 0x84, 0x84, 0x80, 0x84, 0x80, 0x80, 0x84
    .BYTE 0x80, 0x84, 0x84, 0x80, 0x84, 0x80, 0x80, 0x84, 0x84, 0x80, 0x80, 0x84, 0x80, 0x84, 0x84, 0x80
    .BYTE 0x80, 0x84, 0x84, 0x80, 0x84, 0x80, 0x80, 0x84, 0x84, 0x80, 0x80, 0x84, 0x80, 0x84, 0x84, 0x80
    .BYTE 0x84, 0x80, 0x80, 0x84, 0x80, 0x84, 0x84, 0x80, 0x80, 0x84, 0x84, 0x80, 0x84, 0x80, 0x80, 0x84
    .BYTE 0x80, 0x84, 0x84, 0x80, 0x84, 0x80, 0x80, 0x84, 0x84, 0x80, 0x80, 0x84, 0x80, 0x84, 0x84, 0x80
    .BYTE 0x84, 0x80, 0x80, 0x84, 0x80, 0x84, 0x84, 0x80, 0x80, 0x84, 0x84, 0x80, 0x84, 0x80, 0x80, 0x84
    .BYTE 0x84, 0x80, 0x80, 0x84, 0x80, 0x84, 0x84, 0x80, 0x80, 0x84, 0x84, 0x80, 0x84, 0x80, 0x80, 0x84
    .BYTE 0x80, 0x84, 0x84, 0x80, 0x84, 0x80, 0x80, 0x84, 0x84, 0x80, 0x80, 0x84, 0x80, 0x84, 0x84, 0x80

// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567
//ooo.WWWW00000010
FMT_8:  LSLS R6,R0,#20
        LSRS R6,#27
        ADD  R6,R11 // DEST = WP + ((BYTE & 0x0F) << 1);
        UXTH R6,R6
        ADD  R6,R8
        MOV  PC,R7
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567 (Format 2)
//dddddddd0001oooo
OP_1:   LSRS R0,#8
        SXTB R0,R0 // R0 now has a signed offset
        LSLS R0,#1 // Word offset
        MOV  R2,R12 // Need a working copy of ST
        MOV  PC,R7
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567 (Format 9)
//DDTsSSSS00110oDD
OP_3LO: LSRS R1,R0,#13 // if ((BYTE & 0x30) == 0x20) Ts==2 (already checked Ts high bit is 1)
        BCS  OP_3NoINC // Carry Set - then it's not == 0x20
        ADDS R3,#2 // PC += 2; // Skip CRU's 2nd word address
        UXTH R3,R3
        MOV  R10,R3
OP_3NoINC:
        B    start
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567
//ooTsSSSS000000oo
// *********************************************************************************************
sdecode2a: // calculate S & SRCE
        LSLS R1,R0,#20 // Using the fact that the opcode never has the high bit set
        LSRS R1,#27 // Got S << 1
        LSRS R2,R0,#10
        MOVS R4,#0x0C
        ANDS R2,R4 // Got TS * 4
        ADR  R4,COM_S2a
        LDR  R4,[R4,R2]
        MOV  PC,R4
.align 4
COM_S2a: .WORD COM_S2a_R, COM_S2a_I, COM_S2a_L, COM_S2a_II
COM_S2a_R:
        MOV  R5,R11
        ADD  R5,R1 // SRCE = WP + S;
        UXTH R5,R5
        LSRS R5,#1
        LSLS R5,#1 // SRCE &= 0xFFFE
        ADD  R5,R8
        MOV  PC,R7
COM_S2a_L:
        ADDS R2,R3,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R3,R8
        LDRH R5,[R3,#0] // SRCE = (memory [PC + 0] << 8) | memory [PC + 1];
        REV16 R5,R5
        CMP  R1,#0  // if (S) // Not R0?
        BEQ  COM_S2a_F
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R2,[R1,#0] // SRCE += (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R2,R2
        ADD  R5,R2
        UXTH R5,R5
COM_S2a_F:
        LSRS R5,#1
        LSLS R5,#1 // SRCE &= 0xFFFE
        ADD  R5,R8
        MOV  PC,R7
COM_S2a_II:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R5,[R1,#0] // SRCE = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R5,R5
        ADDS R2,R5,#2
        REV16 R2,R2
        STRH R2,[R1,#0]
        LSRS R5,#1
        LSLS R5,#1 // SRCE &= 0xFFFE
        ADD  R5,R8
        MOV  PC,R7
COM_S2a_I:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R5,[R1,#0] // SRCE = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R5,R5
        LSRS R5,#1
        LSLS R5,#1 // SRCE &= 0xFFFE
        ADD  R5,R8
        MOV  PC,R7
// *********************************************************************************************

// Sticking this in the middle of the code, so we can get back to "start" from anywhere easily

// void run9900 (unsigned char * memory, unsigned short pc, unsigned short wp, unsigned char * buf);
// R0 =BYTE|INST
// R1 =INST|BYTE
// R2 =SPARE
// R3 =PC+2 (initially)
// R4 =TEMP (in some cases)
// R5 =SRCE
// R6 =DEST
// R7 =2nd JUMP location
// R8 =memory
// R9 =buf
// R10=PC
// R11=WP
// R12=ST

// *********************************************************************************************
run9900:
        PUSH {LR}
        PUSH {R4-R7} // R7..R4
        MOV  R4,R8
        MOV  R5,R9
        MOV  R6,R10
        MOV  R7,R11
        PUSH {R4-R7} // R11..R8
        MOV  R4,R12
        PUSH {R4}    // R12

        MOV  R8,R0  // memory
        MOV  R9,R3  // buf
        MOV  R10,R1 // PC
        MOV  R11,R2 // WP
        MOVS R0,#0
        MOV  R12,R0 // ST=0
// *********************************************************************************************
start:  ADR  R0,instscnt
        LDR  R1,[R0,#0]
        ADDS R1,#1
        STR  R1,[R0,#0]

        MOV  R0,R10
        ADDS R3,R0,2 // Using R3 to optimise immediate instructions that also INCT PC
        UXTH R3,R3
        MOV  R10,R3
        ADD  R0,R8
        LDRH R0,[R0,#0] // Get instruction BYTE|INST (LE format)

startX: REV16 R1,R0    // R1=INST|BYTE
        LSRS R2,R1,#5  // Get opcode
        LSLS R2,#3     // x8
        ADR  R4,JMPTBL // This is just in reach
        ADDS R4,R2
        LDM  R4,{R4,R7} // Get 1st and 2nd branch location (if it's needed)
        MOV  PC,R4
.align 4
instscnt: .WORD 0

// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567 (Format 3)
//DDTsSSSS0010ooDD
//R1 (BE)
//0123456789ABCDEF
//0010ooDDDDTsSSSS
// *********************************************************************************************
sdecode2b: // calculate S & SRCE
        LSLS R6,R1,#22 // Calculate D before we lose R1
        LSRS R6,#28
        LSLS R1,R0,#20 // Using the fact that the opcode never has the high bit set
        LSRS R1,#27 // Got S << 1
        LSRS R2,R0,#10
        MOVS R4,#0x0C
        ANDS R2,R4 // Got TS * 4
        ADR  R4,COM_S2b
        LDR  R4,[R4,R2]
        MOV  PC,R4
.align 4
COM_S2b: .WORD COM_S2b_R, COM_S2b_I, COM_S2b_L, COM_S2b_II
COM_S2b_R:
        MOV  R5,R11
        ADD  R5,R1 // SRCE = WP + S;
        UXTH R5,R5
        B    COM_S2b_F
COM_S2b_L:
        ADDS R2,R3,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R3,R8
        LDRH R5,[R3,#0] // SRCE = (memory [PC + 0] << 8) | memory [PC + 1];
        REV16 R5,R5
        CMP  R1,#0  // if (S) // Not R0?
        BEQ  COM_S2b_F
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R2,[R1,#0] // SRCE += (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R2,R2
        ADD  R5,R2
        UXTH R5,R5
        B    COM_S2b_F
COM_S2b_II:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R5,[R1,#0] // SRCE = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R5,R5
        ADDS R2,R5,#2
        REV16 R2,R2
        STRH R2,[R1,#0]
        B    COM_S2b_F
COM_S2b_I:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R5,[R1,#0] // SRCE = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R5,R5
COM_S2b_F:
        LSRS R5,#1
        LSLS R5,#1 // SRCE &= 0xFFFE
        ADD  R5,R8
// *********************************************************************************************
        LSLS R6,#1  // Got D << 1
        ADD  R6,R11 // DEST = WP + D;
        UXTH R6,R6
        ADD  R6,R8
        LDRH R5,[R5,#0]
        REV16 R5,R5 // SRCE = (memory [SRCE + 0] << 8) | memory [SRCE + 1];
        LDRH R4,[R6,#0]
        REV16 R4,R4 // TEMP = (memory [DEST + 0] << 8) | memory [DEST + 1];
        MOV  PC,R7
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567
//DDTsSSSSoooBTdDD
//R1 (BE)
//0123456789ABCDEF
//oooBTdDDDDTsSSSS
sdecode2d: // calculate S & SRCE
        LSLS R6,R1,#22 // Calculate D before we lose R1
        LSRS R6,#28
        LSLS R1,#28
        LSRS R1,#27 // Got S << 1
        LSRS R2,R0,#10
        MOVS R4,#0x0C
        ANDS R2,R4 // Got TS * 4
        ADR  R5,COM_S2d
        LDR  R5,[R5,R2]
        MOV  PC,R5
.align 4
COM_S2d: .WORD COM_S2d_R, COM_S2d_I, COM_S2d_L, COM_S2d_II
COM_S2d_R:
        MOV  R5,R11
        ADD  R5,R1 // SRCE = WP + S;
        UXTH R5,R5
        B    COM_S2d_F
COM_S2d_L:
        ADDS R2,R3,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R3,R8
        LDRH R5,[R3,#0] // SRCE = (memory [PC + 0] << 8) | memory [PC + 1];
        REV16 R5,R5
        CMP  R1,#0  // if (S) // Not R0?
        BEQ  COM_S2d_F
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R2,[R1,#0] // SRCE += (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R2,R2
        ADD  R5,R2
        UXTH R5,R5
        B    COM_S2d_F
COM_S2d_II:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R5,[R1,#0] // SRCE = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R5,R5
        ADDS R2,R5,#2
        REV16 R2,R2
        STRH R2,[R1,#0]
        B    COM_S2d_F
COM_S2d_I:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R5,[R1,#0] // SRCE = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R5,R5
COM_S2d_F:
        LSRS R5,#1
        LSLS R5,#1 // SRCE &= 0xFFFE
        ADD  R5,R8
// *********************************************************************************************
        LDRH R5,[R5,#0] // R5=SRCE
        REV16 R5,R5
// *********************************************************************************************
        LSLS R1,R6,#1 // Got D << 1
        ANDS R0,R4 // Got TD * 4
        ADR  R4,COM_D2
        LDR  R4,[R4,R0]
        MOV  PC,R4
.align 4
COM_D2: .WORD COM_D2_R, COM_D2_I, COM_D2_L, COM_D2_II
COM_D2_R:
        MOV  R6,R11
        ADD  R6,R1 // DEST = WP + D;
        UXTH R6,R6
        LSRS R6,#1
        LSLS R6,#1 // DEST &= 0xFFFE
        ADD  R6,R8
        MOV  PC,R7
COM_D2_L:
        MOV  R3,R10 // R3 has lost its PC+2 value by now
        ADDS R2,R3,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R3,R8
        LDRH R6,[R3,#0] // DEST = (memory [PC + 0] << 8) | memory [PC + 1];
        REV16 R6,R6
        CMP  R1,#0  // if (S) // Not R0?
        BEQ  COM_D2_F
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R2,[R1,#0] // DEST += (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R2,R2
        ADD  R6,R2
        UXTH R6,R6
COM_D2_F:
        LSRS R6,#1
        LSLS R6,#1 // DEST &= 0xFFFE
        ADD  R6,R8
        MOV  PC,R7
COM_D2_II:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R6,[R1,#0] // DEST = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R6,R6
        ADDS R2,R6,#2
        REV16 R2,R2
        STRH R2,[R1,#0]
        LSRS R6,#1
        LSLS R6,#1 // DEST &= 0xFFFE
        ADD  R6,R8
        MOV  PC,R7
COM_D2_I:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R6,[R1,#0] // DEST = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R6,R6
        LSRS R6,#1
        LSLS R6,#1 // DEST &= 0xFFFE
        ADD  R6,R8
        MOV  PC,R7

// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567
//DDTsSSSSOOOBTdDD
//R1 (BE)
//0123456789ABCDEF
//oooBTdDDDDTsSSSS
sdecode1d: // calculate S & SRCE
        LSLS R6,R1,#22 // Calculate D before we lose R1
        LSRS R6,#28
        LSLS R1,#28
        LSRS R1,#27 // Got S << 1
        LSRS R2,R0,#10
        MOVS R4,#0x0C
        ANDS R2,R4 // Got TS * 4
        ADR  R5,COM_S1
        LDR  R5,[R5,R2]
        MOV  PC,R5
.align 4
COM_S1: .WORD COM_S1_R, COM_S1_I, COM_S1_L, COM_S1_II
COM_S1_R:
        MOV  R5,R11
        ADD  R5,R1 // SRCE = WP + S;
        UXTH R5,R5
        B    COM_S1_F
COM_S1_L:
        ADDS R2,R3,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R3,R8
        LDRH R5,[R3,#0] // SRCE = (memory [PC + 0] << 8) | memory [PC + 1];
        rev16 R5,R5
        CMP  R1,#0  // if (S) // Not R0?
        BEQ  COM_S1_F
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R2,[R1,#0] // SRCE += (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R2,R2
        ADD  R5,R2
        UXTH R5,R5
        B    COM_S1_F
COM_S1_II:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R5,[R1,#0] // SRCE = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R5,R5
        ADDS R2,R5,#1
        REV16 R2,R2
        STRH R2,[R1,#0]
        B    COM_S1_F
COM_S1_I:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R5,[R1,#0] // SRCE = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R5,R5
COM_S1_F:
        ADD  R5,R8
// *********************************************************************************************
        LDRB R5,[R5,#0] // R5=SRCE
// *********************************************************************************************
        LSLS R1,R6,#1 // Got D << 1
        ANDS R0,R4 // Got TD * 4
        ADR  R4,COM_D1
        LDR  R4,[R4,R0]
        MOV  PC,R4
.align 4
COM_D1: .WORD COM_D1_R, COM_D1_I, COM_D1_L, COM_D1_II
COM_D1_R:
        MOV  R6,R11
        ADD  R6,R1 // DEST = WP + D;
        UXTH R6,R6
        ADD  R6,R8
        MOV  PC,R7
COM_D1_L:
        MOV  R3,R10 // R3 has lost its PC+2 value by now
        ADDS R2,R3,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R3,R8
        LDRH R6,[R3,#0] // DEST = (memory [PC + 0] << 8) | memory [PC + 1];
        REV16 R6,R6
        CMP  R1,#0  // if (S) // Not R0?
        BEQ  COM_D1_F
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R2,[R1,#0] // DEST += (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R2,R2
        ADD  R6,R2
        UXTH R6,R6
COM_D1_F:
        ADD  R6,R8
        MOV  PC,R7
COM_D1_II:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R6,[R1,#0] // DEST = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R6,R6
        ADDS R2,R6,#1
        REV16 R2,R2
        STRH R2,[R1,#0]
        ADD  R6,R8
        MOV  PC,R7
COM_D1_I:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R6,[R1,#0] // DEST = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R6,R6
        ADD  R6,R8
        MOV  PC,R7

// *********************************************************************************************

// F18A Instructions

// *********************************************************************************************
I_XOP: // F18A PIX instruction - return to C code function: F18A_PIX for BL mode
        LSLS R3,R4,#17  // Move leftmost bit (M) into the Carry flag
        BCC  I_XOP_BL   // Not a BM calculation, goto BL code instead

        UXTB R1,R5      // R1=00000000 yyyyyyyy (E/A 336)
        LSLS R2,R1,#5   // R2=000yyyyy yyy00000
        ORRS R2,R1      // R2=000yyyyy zzzyyyyy
        MOVS R3,#0xF8
        BICS R2,R3      // R2=000yyyyy 00000yyy

        LSRS R1,R5,#8   // R1=00000000 xxxxxxxx
        ADDS R2,R1      // R2=000yyyyy xxxxxzzz
        MOVS R3,#7
        ANDS R1,R3      // R1=00000000 00000xxx (bit offset)
        SUBS R2,R1      // R2=000yyyyy xxxxxyyy (byte offset)

        ADR  R3,VREGS
        LDR  R3,[R3,#0] // Get offset
        ADD  R3,R8      // Within the 64KB memory area
        LDRB R1,[R3,#4] // Get VR04
        MOVS R3,#0x04   // BM Pattern Table Location
        ANDS R1,R3      // Can only be >0000 or >2000 (E/A 335)
        LSLS R1,#11     // Move bit into position
        ORRS R2,R1

        REV16 R2,R2
        STRH R2,[R6,#0] // *DEST=R2
        B    start
.align 4
VREGS:  .WORD 0x6000 // Video Registers map point

I_XOP_BL:
        MOVS R1,R5    // R1=SRCE
        MOV  R2,R4    // R2=TEMP (*DEST)
        MOV  R3,R6    // R3=DEST (pointer into memory [])
        MOV  R5,R12   // Save R12 / ST
        LDR  R4,[SP,#0] // GCC should preserve R4-R11 in function calls
        MOV  R12,R4   // Restore GCC's R12
        BLX  F18A_PIX // R0 has the reversed opcode: BYTE|INST
        MOV  R12,R5   // Restore R12 / ST
        B    start
// *********************************************************************************************
// Format 6 or 7 ... Need to check some more bits
//R0 (LE)
//89ABCDEF01234567 (Format 7)
//oo00000000001100
I_RET:  MOV  R0,R11 // WP
        ADDS R0,#30 // R15
        UXTH R0,R0
        ADD  R0,R8

        LDRH R1,[R0,#0] // R15
        REV16 R1,R1
        LSRS R1,#1
        LSLS R1,#1 // R1 &= 0xFFFE

        ADDS R1,#2
        UXTH R1,R1
        REV16 R2,R1
        STRH R2,[R0,#0] // R15
        ADD  R1,R8

        LDRH R1,[R1,#0] // Get the value off the stack
        REV16 R1,R1
        LSRS R1,#1
        LSLS R1,#1 // R1 &= 0xFFFE
        MOV  R10,R1 // PC
I_RET_e:
        B    start
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567 (Format 6)
//10TsSSSS00001100
I_CALL: MOV  R0,R11 // WP
        ADDS R0,#30 // R15
        UXTH R0,R0
        ADD  R0,R8

        LDRH R1,[R0,#0] // Get R15
        REV16 R1,R1
        LSRS R1,#1
        LSLS R1,#1 // R1 &= 0xFFFE

        SUBS R2,R1,#2 // Stack word has been consumed
        REV16 R2,R2
        STRH R2,[R0,#0] // Store new R15
        ADD  R1,R8

        MOV  R2,R10 // PC
        REV16 R2,R2
        STRH R2,[R1,#0] // Old *R15

        MOV  R0,R8
        SUBS R5,R0 // Normalise
        MOV  R10,R5 // PC
        B    start
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567 (Format 6)
//00TsSSSS00001101
I_PUSH: LDRH R5,[R5,#0] // R5=SRCE

        MOV  R0,R11 // WP
        ADDS R0,#30 // R15
        UXTH R0,R0
        ADD  R0,R8

        LDRH R1,[R0,#0] // Get R15
        REV16 R1,R1
        LSRS R1,#1
        LSLS R1,#1 // R1 &= 0xFFFE

        SUBS R2,R1,#2 // Stack word has been consumed
        REV16 R2,R2
        STRH R2,[R0,#0] // Store new R15
        ADD  R1,R8

        STRH R5,[R1,#0] // Old *R15
        B    start
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567 (Format 6)
//00TsSSSS00001111
I_POP:  MOV  R0,R11 // WP
        ADDS R0,#30 // R15
        UXTH R0,R0
        ADD  R0,R8

        LDRH R1,[R0,#0] // Get R15
        REV16 R1,R1
        LSRS R1,#1
        LSLS R1,#1 // R1 &= 0xFFFE

        ADDS R1,R1,#2 // Stack word has been consumed
        REV16 R2,R1
        STRH R2,[R0,#0] // Store new R15
        ADD  R1,R8

        LDRH R0,[R1,#0] // *R15
        STRH R0,[R5,#0] // R5=DEST
        B    start
// *********************************************************************************************
I_SLC:
//R0 (LE)
//89ABCDEF01234567 (Format 5)
//CCCCWWWW00001110
I_SLC:  LSLS R5,R0,#20
        LSRS R5,#27 // Get Register x 2
        ADD  R5,R11 // Add WP
        UXTH R5,R5
        ADD  R5,R8

        LSRS R2,R0,#12 // Get Shift Count
        BNE  I_SLC_nr0 // Result not 0 - got it, else
        MOV  R2,R11
        ADD  R2,R8
        LDRB R2,[R2,#1] // Get R0 low byte
        MOVS R4,#0x0F  // Mask lower nibble
        ANDS R2,R4
        BNE  I_SLC_nr0 // Result not 0 - got it, else
        MOVS R2,#16
I_SLC_nr0:
        LDRH R0,[R5,#0]
        REV16 R0,R0 // Unsigned
        LSLS R4,R0,#16
        ORRS R0,R4 // Copy lower halfword to high halfword

        MOV  R1,R12
        MOVS R4,#0x0E // Get initialised ST
        ANDS R1,R4

        MOVS R3,#16 // Simulate Rotate Left
        SUBS R3,R2  // R2 = 1..16, R3 -> 15..0
        RORS R0,R3
        LSRS R2,R0,#1 // Calculate Carry
        BCC  I_SLC_st // Carry Clear?
        ADDS R1,#0x10 // Carry Bit
I_SLC_st:
        UXTH  R0,R0 // Throw away any high bits
        REV16 R2,R0
        STRH R2,[R5,#0]
        B    OP_COMP_W
// *********************************************************************************************
.align 4
JMPTBL: .WORD start    , 0     , start    , 0     , start    , 0     , start    , 0     , start    , 0     , start    , 0     , start    , 0     , start    , 0        // >0000
        .WORD start    , 0     , start    , 0     , start    , 0     , start    , 0     , start    , 0     , start    , 0     , start    , 0     , start    , 0        // >0100
        .WORD FMT_8    , I_LI  , FMT_8    , I_AI  , FMT_8    , I_ANDI, FMT_8    , I_ORI , FMT_8    , I_CI  , FMT_8    , I_STWP, FMT_8    , I_STST, FMT_8    , I_LWPI   // >0200
        .WORD I_LIMI   , 0     , start    , 0     , I_IDLE   , 0     , start    , 0     , I_RTWP   , 0     , start    , 0     , start    , 0     , start    , 0        // >0300
        .WORD sdecode2a, I_BLWP, sdecode2a, I_BLWP, sdecode2a, I_B   , sdecode2a, I_B   , sdecode2a, I_X   , sdecode2a, I_X   , sdecode2a, I_CLR , sdecode2a, I_CLR    // >0400
        .WORD sdecode2a, I_NEG , sdecode2a, I_NEG , sdecode2a, I_INV , sdecode2a, I_INV , sdecode2a, I_INC , sdecode2a, I_INC , sdecode2a, I_INCT, sdecode2a, I_INCT   // >0500
        .WORD sdecode2a, I_DEC , sdecode2a, I_DEC , sdecode2a, I_DECT, sdecode2a, I_DECT, sdecode2a, I_BL  , sdecode2a, I_BL  , sdecode2a, I_SWPB, sdecode2a, I_SWPB   // >0600
        .WORD sdecode2a, I_SETO, sdecode2a, I_SETO, sdecode2a, I_ABS , sdecode2a, I_ABS , start    , 0     , start    , 0     , start    , 0     , start    , 0        // >0700
        .WORD I_SRA    , 0     , I_SRA    , 0     , I_SRA    , 0     , I_SRA    , 0     , I_SRA    , 0     , I_SRA    , 0     , I_SRA    , 0     , I_SRA    , 0        // >0800
        .WORD I_SRL    , 0     , I_SRL    , 0     , I_SRL    , 0     , I_SRL    , 0     , I_SRL    , 0     , I_SRL    , 0     , I_SRL    , 0     , I_SRL    , 0        // >0900
        .WORD I_SLA    , 0     , I_SLA    , 0     , I_SLA    , 0     , I_SLA    , 0     , I_SLA    , 0     , I_SLA    , 0     , I_SLA    , 0     , I_SLA    , 0        // >0A00
        .WORD I_SRC    , 0     , I_SRC    , 0     , I_SRC    , 0     , I_SRC    , 0     , I_SRC    , 0     , I_SRC    , 0     , I_SRC    , 0     , I_SRC    , 0        // >0B00
        .WORD I_RET    , 0     , start    , 0     , start    , 0     , start    , 0     , sdecode2a, I_CALL, sdecode2a, I_CALL, start    , 0     , start    , 0        // >0C00
        .WORD sdecode2a, I_PUSH, sdecode2a, I_PUSH, start    , 0     , start    , 0     , start    , 0     , start    , 0     , start    , 0     , start    , 0        // >0D00
        .WORD I_SLC    , 0     , I_SLC    , 0     , start    , 0     , start    , 0     , start    , 0     , start    , 0     , start    , 0     , start    , 0        // >0E00
        .WORD sdecode2a, I_POP , sdecode2a, I_POP , start    , 0     , start    , 0     , start    , 0     , start    , 0     , start    , 0     , start    , 0        // >0F00
        .WORD OP_1     , I_JMP , OP_1     , I_JMP , OP_1     , I_JMP , OP_1     , I_JMP , OP_1     , I_JMP , OP_1     , I_JMP , OP_1     , I_JMP , OP_1     , I_JMP    // >1000
        .WORD OP_1     , I_JLT , OP_1     , I_JLT , OP_1     , I_JLT , OP_1     , I_JLT , OP_1     , I_JLT , OP_1     , I_JLT , OP_1     , I_JLT , OP_1     , I_JLT    // >1100
        .WORD OP_1     , I_JLE , OP_1     , I_JLE , OP_1     , I_JLE , OP_1     , I_JLE , OP_1     , I_JLE , OP_1     , I_JLE , OP_1     , I_JLE , OP_1     , I_JLE    // >1200
        .WORD OP_1     , I_JEQ , OP_1     , I_JEQ , OP_1     , I_JEQ , OP_1     , I_JEQ , OP_1     , I_JEQ , OP_1     , I_JEQ , OP_1     , I_JEQ , OP_1     , I_JEQ    // >1300
        .WORD OP_1     , I_JHE , OP_1     , I_JHE , OP_1     , I_JHE , OP_1     , I_JHE , OP_1     , I_JHE , OP_1     , I_JHE , OP_1     , I_JHE , OP_1     , I_JHE    // >1400
        .WORD OP_1     , I_JGT , OP_1     , I_JGT , OP_1     , I_JGT , OP_1     , I_JGT , OP_1     , I_JGT , OP_1     , I_JGT , OP_1     , I_JGT , OP_1     , I_JGT    // >1500
        .WORD OP_1     , I_JNE , OP_1     , I_JNE , OP_1     , I_JNE , OP_1     , I_JNE , OP_1     , I_JNE , OP_1     , I_JNE , OP_1     , I_JNE , OP_1     , I_JNE    // >1600
        .WORD OP_1     , I_JNC , OP_1     , I_JNC , OP_1     , I_JNC , OP_1     , I_JNC , OP_1     , I_JNC , OP_1     , I_JNC , OP_1     , I_JNC , OP_1     , I_JNC    // >1700
        .WORD OP_1     , I_JOC , OP_1     , I_JOC , OP_1     , I_JOC , OP_1     , I_JOC , OP_1     , I_JOC , OP_1     , I_JOC , OP_1     , I_JOC , OP_1     , I_JOC    // >1800
        .WORD OP_1     , I_JNO , OP_1     , I_JNO , OP_1     , I_JNO , OP_1     , I_JNO , OP_1     , I_JNO , OP_1     , I_JNO , OP_1     , I_JNO , OP_1     , I_JNO    // >1900
        .WORD OP_1     , I_JL  , OP_1     , I_JL  , OP_1     , I_JL  , OP_1     , I_JL  , OP_1     , I_JL  , OP_1     , I_JL  , OP_1     , I_JL  , OP_1     , I_JL     // >1A00
        .WORD OP_1     , I_JH  , OP_1     , I_JH  , OP_1     , I_JH  , OP_1     , I_JH  , OP_1     , I_JH  , OP_1     , I_JH  , OP_1     , I_JH  , OP_1     , I_JH     // >1B00
        .WORD OP_1     , I_JOP , OP_1     , I_JOP , OP_1     , I_JOP , OP_1     , I_JOP , OP_1     , I_JOP , OP_1     , I_JOP , OP_1     , I_JOP , OP_1     , I_JOP    // >1C00
        .WORD OP_1     , I_SBO , OP_1     , I_SBO , OP_1     , I_SBO , OP_1     , I_SBO , OP_1     , I_SBO , OP_1     , I_SBO , OP_1     , I_SBO , OP_1     , I_SBO    // >1D00
        .WORD OP_1     , I_SBZ , OP_1     , I_SBZ , OP_1     , I_SBZ , OP_1     , I_SBZ , OP_1     , I_SBZ , OP_1     , I_SBZ , OP_1     , I_SBZ , OP_1     , I_SBZ    // >1E00
        .WORD OP_1     , I_TB  , OP_1     , I_TB  , OP_1     , I_TB  , OP_1     , I_TB  , OP_1     , I_TB  , OP_1     , I_TB  , OP_1     , I_TB  , OP_1     , I_TB     // >1F00
        .WORD sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC    // >2000
        .WORD sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC    // >2100
        .WORD sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC    // >2200
        .WORD sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC , sdecode2b, I_COC    // >2300
        .WORD sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC    // >2400
        .WORD sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC    // >2500
        .WORD sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC    // >2600
        .WORD sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC , sdecode2b, I_CZC    // >2700
        .WORD sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR    // >2800
        .WORD sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR    // >2900
        .WORD sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR    // >2A00
        .WORD sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR , sdecode2b, I_XOR    // >2B00
        .WORD sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP    // >2C00
        .WORD sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP    // >2D00
        .WORD sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP    // >2E00
        .WORD sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP , sdecode2b, I_XOP    // >2F00
        .WORD start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0        // >3000
        .WORD start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0        // >3100
        .WORD start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0        // >3200
        .WORD start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0        // >3300
        .WORD start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0        // >3400
        .WORD start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0        // >3500
        .WORD start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0        // >3600
        .WORD start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0     , start    , 0     , OP_3LO   , 0        // >3700
        .WORD sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL    // >3800
        .WORD sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL    // >3900
        .WORD sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL    // >3A00
        .WORD sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL , sdecode2a, I_MUL    // >3B00
        .WORD sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV    // >3C00
        .WORD sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV    // >3D00
        .WORD sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV    // >3E00
        .WORD sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV , sdecode2a, I_DIV    // >3F00
        .WORD sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC    // >4000
        .WORD sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC    // >4100
        .WORD sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC    // >4200
        .WORD sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC    // >4300
        .WORD sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC    // >4400
        .WORD sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC    // >4500
        .WORD sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC    // >4600
        .WORD sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC    // >4700
        .WORD sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC    // >4800
        .WORD sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC    // >4900
        .WORD sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC    // >4A00
        .WORD sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC    // >4B00
        .WORD sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC    // >4C00
        .WORD sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC    // >4D00
        .WORD sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC    // >4E00
        .WORD sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC , sdecode2d, I_SZC    // >4F00
        .WORD sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB   // >5000
        .WORD sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB   // >5100
        .WORD sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB   // >5200
        .WORD sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB   // >5300
        .WORD sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB   // >5400
        .WORD sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB   // >5500
        .WORD sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB   // >5600
        .WORD sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB   // >5700
        .WORD sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB   // >5800
        .WORD sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB   // >5900
        .WORD sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB   // >5A00
        .WORD sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB   // >5B00
        .WORD sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB   // >5C00
        .WORD sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB   // >5D00
        .WORD sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB   // >5E00
        .WORD sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB, sdecode1d, I_SZCB   // >5F00
        .WORD sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S      // >6000
        .WORD sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S      // >6100
        .WORD sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S      // >6200
        .WORD sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S      // >6300
        .WORD sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S      // >6400
        .WORD sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S      // >6500
        .WORD sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S      // >6600
        .WORD sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S      // >6700
        .WORD sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S      // >6800
        .WORD sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S      // >6900
        .WORD sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S      // >6A00
        .WORD sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S      // >6B00
        .WORD sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S      // >6C00
        .WORD sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S      // >6D00
        .WORD sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S      // >6E00
        .WORD sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S   , sdecode2d, I_S      // >6F00
        .WORD sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB     // >7000
        .WORD sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB     // >7100
        .WORD sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB     // >7200
        .WORD sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB     // >7300
        .WORD sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB     // >7400
        .WORD sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB     // >7500
        .WORD sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB     // >7600
        .WORD sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB     // >7700
        .WORD sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB     // >7800
        .WORD sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB     // >7900
        .WORD sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB     // >7A00
        .WORD sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB     // >7B00
        .WORD sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB     // >7C00
        .WORD sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB     // >7D00
        .WORD sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB     // >7E00
        .WORD sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB  , sdecode1d, I_SB     // >7F00
        .WORD sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C      // >8000
        .WORD sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C      // >8100
        .WORD sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C      // >8200
        .WORD sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C      // >8300
        .WORD sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C      // >8400
        .WORD sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C      // >8500
        .WORD sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C      // >8600
        .WORD sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C      // >8700
        .WORD sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C      // >8800
        .WORD sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C      // >8900
        .WORD sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C      // >8A00
        .WORD sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C      // >8B00
        .WORD sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C      // >8C00
        .WORD sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C      // >8D00
        .WORD sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C      // >8E00
        .WORD sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C   , sdecode2d, I_C      // >8F00
        .WORD sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB     // >9000
        .WORD sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB     // >9100
        .WORD sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB     // >9200
        .WORD sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB     // >9300
        .WORD sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB     // >9400
        .WORD sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB     // >9500
        .WORD sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB     // >9600
        .WORD sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB     // >9700
        .WORD sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB     // >9800
        .WORD sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB     // >9900
        .WORD sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB     // >9A00
        .WORD sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB     // >9B00
        .WORD sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB     // >9C00
        .WORD sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB     // >9D00
        .WORD sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB     // >9E00
        .WORD sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB  , sdecode1d, I_CB     // >9F00
        .WORD sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A      // >A000
        .WORD sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A      // >A100
        .WORD sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A      // >A200
        .WORD sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A      // >A300
        .WORD sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A      // >A400
        .WORD sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A      // >A500
        .WORD sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A      // >A600
        .WORD sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A      // >A700
        .WORD sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A      // >A800
        .WORD sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A      // >A900
        .WORD sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A      // >AA00
        .WORD sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A      // >AB00
        .WORD sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A      // >AC00
        .WORD sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A      // >AD00
        .WORD sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A      // >AE00
        .WORD sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A   , sdecode2d, I_A      // >AF00
        .WORD sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB     // >B000
        .WORD sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB     // >B100
        .WORD sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB     // >B200
        .WORD sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB     // >B300
        .WORD sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB     // >B400
        .WORD sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB     // >B500
        .WORD sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB     // >B600
        .WORD sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB     // >B700
        .WORD sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB     // >B800
        .WORD sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB     // >B900
        .WORD sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB     // >BA00
        .WORD sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB     // >BB00
        .WORD sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB     // >BC00
        .WORD sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB     // >BD00
        .WORD sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB     // >BE00
        .WORD sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB  , sdecode1d, I_AB     // >BF00
        .WORD sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV    // >C000
        .WORD sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV    // >C100
        .WORD sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV    // >C200
        .WORD sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV    // >C300
        .WORD sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV    // >C400
        .WORD sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV    // >C500
        .WORD sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV    // >C600
        .WORD sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV    // >C700
        .WORD sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV    // >C800
        .WORD sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV    // >C900
        .WORD sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV    // >CA00
        .WORD sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV    // >CB00
        .WORD sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV    // >CC00
        .WORD sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV    // >CD00
        .WORD sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV    // >CE00
        .WORD sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV , sdecode2d, I_MOV    // >CF00
        .WORD sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB   // >D000
        .WORD sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB   // >D100
        .WORD sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB   // >D200
        .WORD sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB   // >D300
        .WORD sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB   // >D400
        .WORD sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB   // >D500
        .WORD sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB   // >D600
        .WORD sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB   // >D700
        .WORD sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB   // >D800
        .WORD sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB   // >D900
        .WORD sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB   // >DA00
        .WORD sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB   // >DB00
        .WORD sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB   // >DC00
        .WORD sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB   // >DD00
        .WORD sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB   // >DE00
        .WORD sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB, sdecode1d, I_MOVB   // >DF00
        .WORD sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC    // >E000
        .WORD sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC    // >E100
        .WORD sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC    // >E200
        .WORD sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC    // >E300
        .WORD sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC    // >E400
        .WORD sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC    // >E500
        .WORD sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC    // >E600
        .WORD sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC    // >E700
        .WORD sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC    // >E800
        .WORD sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC    // >E900
        .WORD sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC    // >EA00
        .WORD sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC    // >EB00
        .WORD sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC    // >EC00
        .WORD sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC    // >ED00
        .WORD sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC    // >EE00
        .WORD sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC , sdecode2d, I_SOC    // >EF00
        .WORD sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB   // >F000
        .WORD sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB   // >F100
        .WORD sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB   // >F200
        .WORD sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB   // >F300
        .WORD sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB   // >F400
        .WORD sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB   // >F500
        .WORD sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB   // >F600
        .WORD sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB   // >F700
        .WORD sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB   // >F800
        .WORD sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB   // >F900
        .WORD sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB   // >FA00
        .WORD sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB   // >FB00
        .WORD sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB   // >FC00
        .WORD sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB   // >FD00
        .WORD sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB   // >FE00
        .WORD sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB, sdecode1d, I_SOCB   // >FF00
