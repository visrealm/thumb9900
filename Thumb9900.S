.syntax unified // ARM unified syntax
.thumb_func     // Code uses Thumb instructions

.section .data  // In RAM Please

.global run9900 // Entry point
.global instscnt // Global instruction counter

.extern debug_print
//        BL   sav9900
//        BLX  debug_print
//        BL   res9900

// void run9900 (unsigned char * memory, unsigned short pc, unsigned short wp, unsigned char * buf);
// R5 =SRCE
// R6 =DEST
// R7 =JUMP-MASK
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

        MOVS R7,#0x3C
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
        ADD  R0,R8
        LDRH R0,[R0,#0] // Get instruction BYTE|INST (LE format)

        MOVS R1,#2
        ADD  R1,R10
        UXTH R1,R1
        MOV  R10,R1

startX: LSRS R1,R0,#2 // high nibble right
        ANDS R1,R7
        ADR  R4,OPCODE
        LDR  R4,[R4,R1] // goto *OPCODE [INST >> 4];
        MOV  PC,R4
.align 4
OPCODE: .WORD OP_0, OP_1, OP_2, OP_3, OP_COM, OP_COM, OP_COM, OP_COM, OP_COM, OP_COM, OP_COM, OP_COM, OP_COM, OP_COM, OP_COM, OP_COM
instscnt: .WORD 0
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567
//ooo.WWWW0000oooo
OP_0:   LSLS R1,R0,#2
        ANDS R1,R7
        ADR  R4,OP_00
        LDR  R4,[R4,R1] // goto *OP_00 [INST & 0x0F];
        MOV  PC,R4
.align 4
OP_00:  .WORD start, start, FMT_8, FMT_7, FMT_6, FMT_6, FMT_6, FMT_6, I_SRA, I_SRL, I_SLA, I_SRC, start, start, start, start
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567
//ooo.WWWW00000002
FMT_8:  lSRS R6,R0,#7
        MOVS R1,#0x1E
        ANDS R6,R1
        ADD  R6,R11 // DEST = WP + ((BYTE & 0x0F) << 1);
        UXTH R6,R6
        ADD  R6,R8
        LSRS R1,R0,#11 // Top 3 bits to low byte, shifted left by 2
        ANDS R1,R7     // Jump mask..
        ADR  R4,OP_08
        LDR  R4,[R4,R1] // goto *OP_08 [BYTE >> 5];
        MOV  PC,R4
.align 4
OP_08:  .WORD I_LI, I_AI, I_ANDI, I_ORI, I_CI, I_STWP, I_STST, I_LWPI
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567
//ooo.WWWW00000003
FMT_7:  LSRS R1,R0,#8 // BYTE
        BNE  FMT_7_c2 // if (BYTE == 0x00) // LIMI
        MOVS R1,#2    // Skip LIMI's 2nd WORD
        ADD  R1,R10
        UXTH R1,R1
        MOV  R10,R1
        B    start
FMT_7_c2:
        CMP  R1,#0x80
        BNE  FMT_7_e // if (BYTE == 0x80) // RTWP
        MOV  R3,R11 // Get address of WP *** TODO: Possible overrun of the 64KB address space
        ADD  R3,R8
        LDRB R1,[R3,#30] // R15 high byte
        MOV  R12,R1
        LDRH R1,[R3,#28]  // R14..
        REV16 R1,R1
        MOVS R4,#0xFE
        SXTB R4,R4
        ANDS R1,R4
        MOV  R10,R1
        LDRH R1,[R3,#26]  // R13..
        REV16 R1,R1
        ANDS R1,R4
        MOV  R11,R1
FMT_7_e:
        B    start
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567
//ooTsSSSS000000oo
FMT_6:  BL   sdecode2
        LSLS R1,R0,#4
        LSRS R2,R0,#12
        ORRS R1,R2
        ANDS R1,R7
        ADR  R4,OP_06
        LDR  R4,[R4,R1] // goto *OP_06 [((INST & 0x03) << 2) | (BYTE >> 6)];
        MOV  PC,R4
.align 4
OP_06:  .WORD I_BLWP, I_B, I_X, I_CLR, I_NEG, I_INV, I_INC, I_INCT, I_DEC, I_DECT, I_BL, I_SWPB, I_SETO, I_ABS, start, start
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567 (Format 2)
//dddddddd0001oooo
OP_1:   LSLS R1,R0,#2
        ANDS R1,R7
        LSRS R0,#8
        SXTB R0,R0 // R0 now has a signed offset
        LSLS R0,#1 // Word offset
        MOV  R2,R12 // Need a working copy of ST
        ADR  R4,JMPCRU
        LDR  R4,[R4,R1] // goto *JMPCRU [INST & 0x0F];
        MOV  PC,R4
.align 4
JMPCRU: .WORD I_JMP, I_JLT, I_JLE, I_JEQ, I_JHE, I_JGT, I_JNE, I_JNC, I_JOC, I_JNO, I_JL, I_JH, I_JOP, I_SBO, I_SBZ, I_TB
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567
//dddddddd0001oooo
OP_2:   BL   sdecode2
        LSLS R6,R0,#4 // D = (((INST & 0x03) << 2) | (BYTE >> 6)) << 1;
        LSRS R2,R0,#12
        ORRS R6,R2
        ANDS R6,R7 // Re-use mask (needs shift 2)
        LSRS R6,#1 // We were shifted 2 left, but we only wanted 1
        ADD  R6,R11 // DEST = WP + D;
        UXTH R6,R6
        ADD  R6,R8
        LDRH R5,[R5,#0]
        REV16 R5,R5 // SRCE = (memory [SRCE + 0] << 8) | memory [SRCE + 1];
        LDRH R4,[R6,#0]
        REV16 R4,R4 // TEMP = (memory [DEST + 0] << 8) | memory [DEST + 1];
        MOVS R2,#0x0C
        MOV  R1,R0
        ANDS R1,R2
        ADR  R3,OP_2X
        LDR  R3,[R3,R1] // goto *OP_2X [(INST & 0x0C) >> 2];
        MOV  PC,R3
.align 4
OP_2X:  .WORD I_COC, I_CZC, I_XOR, start // No I_XOP
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567 (Format 9)
//DDTsSSSSOO11ooDD
OP_3:   MOVS R1,#0x08 // if ((INST & 0x08) == 0) // LDCR or STCR?  We don't support them - but we will increase PC if needed
        TST  R0,R1
        BNE  OP_3GO // Bit was set
        LSRS R1,R0,#8
        MOVS R2,#0x30
        ANDS R1,R2
        CMP  R1,#0x20 // if ((BYTE & 0x30) == 0x20) Ts==2
        BEQ  OP_3INC
        B    start
OP_3INC:
        MOVS R1,#2 // PC += 2; // Skip CRU's 2nd word address
        ADD  R1,R10
        UXTH R1,R1
        MOV  R10,R1
        B    start

OP_3GO: BL   sdecode2
        LDRH R5,[R5,#0] // R5=SRCE
        REV16 R5,R5

        LSRS R6,R0,#13
        LSLS R1,R0,#3
        MOVS R2,#0x1E
        ORRS R6,R1
        ANDS R6,R2 // Got D << 1
        ADD  R6,R11 // DEST = WP + D;
        UXTH R6,R6
        ADD  R6,R8

        MOVS R1,#0x0C
        ANDS R0,R1
        CMP  R0,R1 // if ((INST & 0x0C) == 0x0C) // DIV
        BNE  I_MUL // else MUL
// *********************************************************************************************
I_DIV: // unreferenced, but searchable
        LDRH R0,[R6,#0]
        REV16 R0,R0
        CMP   R5,R0
        BLS   I_DEV_ov // Equal also overflows

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
I_DEV_ov:
        MOV  R1,R12
        MOVS R4,#0x08 // OV
        ORRS R1,R4
        MOV  R12,R1
        B    start
// *********************************************************************************************
I_MUL:
        LDRH R0,[R6,#0]
        REV16 R0,R0
        MULS R0,R5
        REV16 R0,R0
        STRH R0,[R6,#2] // *** TODO: Possible overrun of the 64KB address space
        LSRS R0,16
        STRH R0,[R6,#0]
        B    start
// *********************************************************************************************
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
// *********************************************************************************************
ret9900:
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
        //MOVS R0,#0
        ADR  R0,RETCODE
        LDR  R0,[R0,#0]
        POP {PC}
.align 4
RETCODE: .WORD 0
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567
//DDTsSSSSOOOBTdDD
OP_COM: MOVS R1,#0x10
        TST  R0,R1
        BEQ  wordop

        BL   sdecode1
        LDRB R5,[R5,#0] // R5=SRCE
        BL   ddecode1
        LSRS R1,R0,#2 // high nibble Right
        ANDS R1,R7
        ADR  R4,OPCOD2
        LDR  R4,[R4,R1] // goto *OPCODE [INST >> 4];
        MOV  PC,R4
wordop:
        BL   sdecode2
        LDRH R5,[R5,#0] // R5=SRCE
        REV16 R5,R5
        BL   ddecode2
        LSRS R1,R0,#2 // high nibble right
        ANDS R1,R7
        ADR  R4,OPCOD2
        LDR  R4,[R4,R1] // goto *OPCODE [INST >> 4];
        MOV  PC,R4
.align 4   // OP_0, OP_1, OP_2, OP_3 are ignored - they were handled earlier
OPCOD2: .WORD OP_0, OP_1, OP_2, OP_3, I_SZC, I_SZCB, I_S, I_SB, I_C, I_CB, I_A, I_AB, I_MOV, I_MOVB, I_SOC, I_SOCB
// *********************************************************************************************

// Instructions

// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567 (Format 5)
//CCCCWWWWOOOOOOOO
I_SRA:  LSRS R5,R0,#7 // Get Register x 2
        MOVS R4,#0x1E // Mask Register Address
        ANDS R5,R4
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
        MOVS R4,#0x10 // Carry Bit
        ORRS R1,R4
I_SRA_st:
        REV16 R2,R0
        STRH R2,[R5,#0]
        B    OP_COMP_WOA
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567 (Format 5)
//CCCCWWWWOOOOOOOO
I_SRL:  LSRS R5,R0,#7 // Get Register x 2
        MOVS R4,#0x1E // Mask Register Address
        ANDS R5,R4
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
        MOVS R4,#0x10 // Carry Bit
        ORRS R1,R4
I_SRL_st:
        REV16 R2,R0
        STRH R2,[R5,#0]
        B    OP_COMP_WOA
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567 (Format 5)
//CCCCWWWWOOOOOOOO
I_SLA:  LSRS R5,R0,#7 // Get Register x 2
        MOVS R4,#0x1E // Mask Register Address
        ANDS R5,R4
        ADD  R5,R11 // Add WP
        UXTH R5,R5
        ADD  R5,R8

        LSRS R2,R0,#12 // Get Shift Count
        BNE  I_SLA_nr0 // Result not 0 - got it, else
        MOV  R2,R11
        ADD  R2,R8
        LDRB R2,[R2,#1] // Get R0 low byte
        MOVS R4,#0x0F  // Mask lower nibble
        ANDS R2,R4
        BNE  I_SLA_nr0 // Result not 0 - got it, else
        MOVS R2,#16
I_SLA_nr0:
        LDRH R0,[R5,#0]
        REV16 R0,R0 // Unsigned
        LSLS R4,R0,#16
        ORRS R0,R4 // Copy lower hlafword to high halfword

        MOV  R1,R12
        MOVS R4,#0x06 // Get initialised ST
        ANDS R1,R4

        // Set Overflow if sign changes
        LSRS R4,R2,#4
        BEQ  I_SLA_n16 // Shift Count is not 16
        TST  R0,R0
        BNE  I_SLA_ov // Result was not zero
        B    I_SLA_nov
I_SLA_n16:
        ADR  R4,I_SLA_M
        LSLS R6,R2,#2
        LDR  R3,[R4,R6] // Get correct mask
        MOVS R4,#0x80
        LSLS R4,#8 // -> 0x8000
        TST  R0,R4
        BNE  I_SLA_neg // Result was not zero
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
        MOVS R4,#0x08 // Overflow Bit
        ORRS R1,R4
I_SLA_nov:
        LSLS R0,R2
        BCC  I_SLA_st // Carry Clear?
        MOVS R4,#0x10 // Carry Bit
        ORRS R1,R4
I_SLA_st:
        UXTH  R0,R0 // Throw away any high bits
        REV16 R2,R0
        STRH R2,[R5,#0]
        B    OP_COMP_WOA
.align 4
I_SLA_M: .WORD 0x0000, 0x4000, 0x6000, 0x7000, 0x7800, 0x7C00, 0x7E00, 0x7F00
         .WORD 0x7F80, 0x7FC0, 0x7FE0, 0x7FF0, 0x7FF8, 0x7FFC, 0x7FFE, 0x7FFF
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567 (Format 5)
//CCCCWWWWOOOOOOOO
I_SRC:  LSRS R5,R0,#7 // Get Register x 2
        MOVS R4,#0x1E // Mask Register Address
        ANDS R5,R4
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
        ORRS R0,R4 // Copy lower hlafword to high halfword

        MOV  R1,R12
        MOVS R4,#0x0E // Get initialised ST
        ANDS R1,R4
        
        RORS R0,R2
        BCC  I_SRC_st // Carry Clear?
        MOVS R4,#0x10 // Carry Bit
        ORRS R1,R4
I_SRC_st:
        UXTH  R0,R0 // Throw away any high bits
        REV16 R2,R0
        STRH R2,[R5,#0]
        B    OP_COMP_WOA

// *********************************************************************************************
I_LI:   MOV  R1,R10
        ADDS R2,R1,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R1,R8
        LDRH R0,[R1,#0] // R10=PC
        STRH R0,[R6,#0]
        B    OP_COMP_W
// *********************************************************************************************
I_AI:   MOV  R1,R10
        ADDS R2,R1,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R1,R8
        LDRH R5,[R1,#0] // R10=PC
        REV16 R5,R5
        B    I_A
// *********************************************************************************************
I_ANDI: MOV  R1,R10
        ADDS R2,R1,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R1,R8
        LDRH R0,[R1,#0] // R10=PC
        LDRH R3,[R6,#0] // R6=DEST
        ANDS R3,R0
        STRH R3,[R6,#0] // R6=DEST
        B    OP_COMP_W
// *********************************************************************************************
I_ORI:  MOV  R1,R10
        ADDS R2,R1,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R1,R8
        LDRH R0,[R1,#0] // R10=PC
        LDRH R3,[R6,#0] // R6=DEST
        ORRS R3,R0
        STRH R3,[R6,#0] // R6=DEST
        B    OP_COMP_W
// *********************************************************************************************
I_CI:   MOV  R1,R10
        ADDS R2,R1,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R1,R8
        LDRH R5,[R1,#0] // R10=PC
        REV16 R5,R5

        LDRH R2,[R6,#0] // R6=DEST
        REV16 R2,R2

        MOV  R1,R12
        MOVS R4,#0x1E // Get initialised ST
        ANDS R1,R4

        CMP  R2,R5
        BNE  I_CI_l
        MOVS R4,#0x20 // Equal bit
        ORRS R1,R4
        MOV  R12,R1
        BL   start
I_CI_l:
        BLO  I_CI_a
        MOVS R4,#0x80 // Logic > bit
        ORRS R1,R4
I_CI_a:
        SXTH R5,R5
        SXTH R2,R2
        CMP  R2,R5 // Redo flags
        BLT  I_CI_e
        MOVS R4,#0x40 // Arith > bit
        ORRS R1,R4
I_CI_e:
        MOV  R12,R1
        BL   start
// *********************************************************************************************
I_LWPI: MOV  R1,R10
        ADDS R2,R1,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R1,R8
        LDRH R0,[R1,#0] // R10=PC
        REV16 R0,R0
        MOVS R1,#0xFE
        SXTB R1,R1 // -> 0xFFFE
        ANDS R0,R1
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
I_BLWP: LDRB R0,[R5,#0] // R5=SRCE
        REV16 R0,R0
        MOVS R2,#0xFE
        SXTB R2,R2 // -> 0xFFFE
        ANDS R0,R2
        MOV  R1,R11 // WP
        MOV  R11,R0

        REV16 R1,R1
        STRH R1,[R0,#26]  // R13 *** TODO: Possible overrun of the 64KB address space

        MOV  R1,R10 // PC
        REV16 R1,R1
        STRH R1,[R0,#28]  // R14 *** TODO: Possible overrun of the 64KB address space

        MOV  R1,R12 // Don't need to swap low bytes here
        STRH R1,[R0,#30] // R15 High Byte = ST *** TODO: Possible overrun of the 64KB address space

        LDRH R0,[R5,#2] // R5=SRCE *** TODO: Possible overrun of the 64KB address space
        REV16 R0,R0
        ANDS R0,R2
        MOV  R10,R0
        B    start
// *********************************************************************************************
I_B:    MOV  R0,R8
        SUBS R5,R0 // Normalise
        MOV  R10,R5
        B    start
// *********************************************************************************************
I_X:    LDRH R0,[R5,#0] // R5=SRCE
        B    startX
// *********************************************************************************************
I_CLR:  MOVS R0,#0
        STRH R0,[R5,#0]
        B    start
// *********************************************************************************************
I_NEG:  LDRH R0,[R5,#0] // R5=SRCE
        REV16 R0,R0

        MOV  R1,R12
        MOVS R4,#0x06 // Get initialised ST
        ANDS R1,R4

        MOVS R4,#0x80
        LSLS R4,#8 // -> #0x8000
        CMP  R0,R4
        BNE  I_NEG_no_ov
        MOVS R4,#0x08 // Overflow bit
        ORRS R1,R4
        B    OP_COMP_WOA
I_NEG_no_ov:
        RSBS R0,#0 // R0=0-R0
        BNE  I_NEG_nc
        MOVS R4,#0x10 // Carry bit
        ORRS R1,R4
I_NEG_nc:
        UXTH R0,R0
        REV16 R2,R0
        STRH R2,[R5,#0]
        B    OP_COMP_WOA
// *********************************************************************************************
I_INV:  MOV  R6,R5
        LDRH R0,[R6,#0] // R6=DEST
        MVNS R0, R0
        STRH R0,[R6,#0]
        B    OP_COMP_W
// *********************************************************************************************
I_INC:  MOV  R6,R5
        LDRH R2,[R6,#0] // R6=DEST
        REV16 R2,R2

        ADDS R3,R2,#1

        UXTH R0,R3 // Keep a clean copy
        REV16 R3,R3
        STRH R3,[R6,#0]

        MOV  R1,R12
        MOVS R4,#0x06 // Get initialised ST
        ANDS R1,R4

        CMP  R2,R0
        BLO  I_INC_p
        MOVS R4,#0x10 // Carry bit
        ORRS R1,R4
I_INC_p:
        MOVS R4,#0x80
        LSLS R4,#8 // -> #0x8000
        ANDS R2,R4
        TST  R2,R4
        BNE  I_INC_e
        MOV  R5,R0
        ANDS R5,R4
        CMP  R2,R5
        BEQ  I_INC_e
        MOVS R4,#0x08 // Overflow bit
        ORRS R1,R4
I_INC_e:
        B    OP_COMP_WOA
// *********************************************************************************************
I_INCT: MOV  R6,R5
        LDRH R2,[R6,#0] // R6=DEST
        REV16 R2,R2

        ADDS R3,R2,#2

        UXTH R0,R3 // Keep a clean copy
        REV16 R3,R3
        STRH R3,[R6,#0]

        MOV  R1,R12
        MOVS R4,#0x06 // Get initialised ST
        ANDS R1,R4

        CMP  R2,R0
        BLO  I_INCT_p
        MOVS R4,#0x10 // Carry bit
        ORRS R1,R4
I_INCT_p:
        MOVS R4,#0x80
        LSLS R4,#8 // -> #0x8000
        ANDS R2,R4
        TST  R2,R4
        BNE  I_INCT_e
        MOV  R5,R0
        ANDS R5,R4
        CMP  R2,R5
        BEQ  I_INCT_e
        MOVS R4,#0x08 // Overflow bit
        ORRS R1,R4
I_INCT_e:
        B    OP_COMP_WOA
// *********************************************************************************************
I_DEC:  MOV  R6,R5
        LDRH R2,[R6,#0] // R6=DEST
        REV16 R2,R2

        SUBS R3,R2,#1

        UXTH R0,R3 // Keep a clean copy
        REV16 R3,R3
        STRH R3,[R6,#0]

        MOV  R1,R12
        MOVS R4,#0x06 // Get initialised ST
        ANDS R1,R4

        CMP  R2,R0
        BLO  I_DEC_p
        MOVS R4,#0x10 // Carry bit
        ORRS R1,R4
I_DEC_p:
        MOVS R4,#0x80
        LSLS R4,#8 // -> #0x8000
        ANDS R2,R4
        TST  R2,R4
        BEQ  I_DEC_e
        MOV  R5,R0
        ANDS R5,R4
        CMP  R2,R5
        BEQ  I_DEC_e
        MOVS R4,#0x08 // Overflow bit
        ORRS R1,R4
I_DEC_e:
        B    OP_COMP_WOA
// *********************************************************************************************
I_DECT: MOV  R6,R5
        LDRH R2,[R6,#0] // R6=DEST
        REV16 R2,R2

        SUBS R3,R2,#2

        UXTH R0,R3 // Keep a copy
        REV16 R3,R3
        STRH R3,[R6,#0]

        MOV  R1,R12
        MOVS R4,#0x06 // Get initialised ST
        ANDS R1,R4

        CMP  R2,R0
        BLO  I_DECT_p
        MOVS R4,#0x10 // Carry bit
        ORRS R1,R4
I_DECT_p:
        MOVS R4,#0x80
        LSLS R4,#8 // -> #0x8000
        ANDS R2,R4
        TST  R2,R4
        BEQ  I_DECT_e
        MOV  R5,R0
        ANDS R5,R4
        CMP  R2,R5
        BEQ  I_DECT_e
        MOVS R4,#0x08 // Overflow bit
        ORRS R1,R4
I_DECT_e:
        B    OP_COMP_WOA
// *********************************************************************************************
I_BL:   MOV  R0,R10
        REV16 R0,R0
        MOV  R1,R11
        ADDS R1,#22 // R11
        UXTH R1,R1
        ADD  R1,R8
        STRH R0,[R1,#0]
        MOV  R0,R8
        SUBS R5,R0 // Normalise
        MOV  R10,R5
        B    start
// *********************************************************************************************
I_SWPB: LDRH R0,[R5,#0] // R5=SRCE
        REV16 R0,R0
        STRH R0,[R5,#0]
        B    start
// *********************************************************************************************
I_SETO: MOVS R0,0xFF
        STRB R0,[R5,#0]
        STRB R0,[R5,#1]
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
        MOVS R4,#0x08 // Overflow bit
        ORRS R1,R4
        B    OP_COMP_WOA
I_ABS_no_ov:
        MOV  R2,R0
        RSBS R2,#0 // R0=0-R0
        REV16 R2,R2
        STRH R2,[R5,#0]
I_ABS_e:
        B    OP_COMP_WOA
// *********************************************************************************************
I_JMP:  MOVS R1,#0xFE
        SXTB R1,R1
        CMP  R0,R1   // Does this jump to itself?
        BNE  I_JMP_g
        BL   ret9900 // Then quit the emulation
I_JMP_g:
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
        BL   start
// *********************************************************************************************
I_JLT:  MOVS R1,#0x60 // AG|EQ
        TST  R2,R1
        BNE  I_JLT_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JLT_e:
        BL   start
// *********************************************************************************************
I_JLE:  MOVS R1,#0x20 // EQ
        TST  R2,R1
        BNE  I_JLE_j
        MOVS R1,#0x80 // LG
        TST  R2,R1
        BNE  I_JLE_e
I_JLE_j:
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JLE_e:
        BL   start
// *********************************************************************************************
I_JEQ:  MOVS R1,#0x20 // EQ
        TST  R2,R1
        BEQ  I_JEQ_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JEQ_e:
        BL   start
// *********************************************************************************************
I_JHE:  MOVS R1,#0x20 // EQ
        TST  R2,R1
        BNE  I_JHE_j
        MOVS R1,#0x80 // LG
        TST  R2,R1
        BEQ  I_JHE_e
I_JHE_j:
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JHE_e:
        BL   start
// *********************************************************************************************
I_JGT:  MOVS R1,#0x40 // AG
        TST  R2,R1
        BEQ  I_JGT_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JGT_e:
        BL   start
// *********************************************************************************************
I_JNE:  MOVS R1,#0x20 // EQ
        TST  R2,R1
        BNE  I_JNE_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JNE_e:
        BL   start
// *********************************************************************************************
I_JNC:  MOVS R1,#0x10 // C
        TST  R2,R1
        BNE  I_JNC_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JNC_e:
        BL   start
// *********************************************************************************************
I_JOC:  MOVS R1,#0x10 // C
        TST  R2,R1
        BEQ  I_JOC_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JOC_e:
        BL   start
// *********************************************************************************************
I_JNO:  MOVS R1,#0x08 // OV
        TST  R2,R1
        BNE  I_JNO_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JNO_e:
        BL   start
// *********************************************************************************************
I_JL:   MOVS R1,#0xA0 // LG|EQ
        TST  R2,R1
        BNE  I_JL_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JL_e:
        BL   start
// *********************************************************************************************
I_JH:   MOVS R1,#0x20 // EQ
        TST  R2,R1
        BNE  I_JH_e
        MOVS R1,#0x80 // LG
        TST  R2,R1
        BEQ  I_JH_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JH_e:
        BL   start
// *********************************************************************************************
I_JOP:  MOVS R1,#0x04 // P
        TST  R2,R1
        BEQ  I_JOP_e
        ADD  R0,R10
        UXTH R0,R0 // Discard any extra
        MOV  R10,R0
I_JOP_e:
        BL   start
// *********************************************************************************************
I_SBO: // SBO - Not Implemented
I_SBZ: // SBZ - Not Implemented
        BL   start
I_TB:  // TB  - Not Implemented
        MOV  R1,R12
        MOVS R4,#0xDF // ~EQ
        ANDS R1,R4
        MOV  R12,R1
        BL   start
// *********************************************************************************************
I_COC:  ANDS R4,R5
        MOV  R1,R12
        CMP  R4,R5
        BNE  I_COC_ne
        MOVS R4,#0x20 // EQ
        ORRS R1,R4
        MOV  R12,R1
        BL   start
I_COC_ne:
        MOVS R4,#0xDF // ~EQ
        ANDS R1,R4
        MOV  R12,R1
        BL   start
// *********************************************************************************************
I_CZC:  ANDS R4,R5
        MOV  R1,R12
        CMP  R4,#0
        BNE  I_CZC_ne
        MOVS R4,#0x20 // EQ
        ORRS R1,R4
        MOV  R12,R1
        BL   start
I_CZC_ne:
        MOVS R4,#0xDF // ~EQ
        ANDS R1,R4
        MOV  R12,R1
        BL   start
// *********************************************************************************************
I_XOR:  EORS R4,R5 // R4=TEMP, R5=*SRCE
        REV16 R4,R4
        STRH R4,[R6,#0] // R6=DEST
        B    OP_COMP_W
// *********************************************************************************************
I_SZC:  LDRH R0,[R6,#0] // R6=DEST
        REV16 R5,R5
        BICS R0, R5
        STRH R0,[R6,#0]
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
        BLO  I_S_p
I_S_c:
        MOVS R4,#0x10 // Carry bit
        ORRS R1,R4
I_S_p:
        MOVS R4,#0x80
        LSLS R4,#8 // -> #0x8000
        ANDS R5,R4
        ANDS R2,R4
        CMP  R2,R5
        BEQ  I_S_e
        MOV  R5,R0
        ANDS R5,R4
        CMP  R2,R5
        BEQ  I_S_e
        MOVS R4,#0x08 // Overflow bit
        ORRS R1,R4
I_S_e:
        B    OP_COMP_WOA
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
        BLO  I_SB_p
I_SB_c:
        MOVS R4,#0x10 // Carry bit
        ORRS R1,R4
I_SB_p:
        MOVS R4,#0x80
        ANDS R5,R4
        ANDS R2,R4
        CMP  R2,R5
        BEQ  I_SB_e
        MOV  R5,R0
        ANDS R5,R4
        CMP  R2,R5
        BEQ  I_SB_e
        MOVS R4,#0x08 // Overflow bit
        ORRS R1,R4
I_SB_e:
        B    OP_COMP_B
// *********************************************************************************************
I_C:    LDRH R2,[R6,#0] // R6=DEST
        REV16 R2,R2

        MOV  R1,R12
        MOVS R4,#0x1E // Get initialised ST
        ANDS R1,R4

        CMP  R5,R2
        BNE  I_C_l
        MOVS R4,#0x20 // Equal bit
        ORRS R1,R4
        MOV  R12,R1
        BL   start
I_C_l:
        BLO  I_C_a
        MOVS R4,#0x80 // Logic > bit
        ORRS R1,R4
I_C_a:
        SXTH R5,R5
        SXTH R2,R2
        CMP  R5,R2 // Redo flags
        BLT  I_C_e
        MOVS R4,#0x40 // Arith > bit
        ORRS R1,R4
I_C_e:
        MOV  R12,R1
        BL   start
// *********************************************************************************************
I_CB:   LDRB R2,[R6,#0] // R6=DEST

        MOV  R1,R12
        MOVS R4,#0x1A // Get initialised ST
        ANDS R1,R4

        ADR  R3,PARITY
        LDRB R3,[R3,R5]
        ORRS R1,R3

        UXTB R5,R5
        UXTB R2,R2

        CMP  R5,R2
        BNE  I_CB_l
        MOVS R4,#0x20 // Equal bit
        ORRS R1,R4
        MOV  R12,R1
        BL   start
I_CB_l:
        BLO  I_CB_a
        MOVS R4,#0x80 // Logic > bit
        ORRS R1,R4
I_CB_a:
        SXTB R5,R5
        SXTB R2,R2
        CMP  R5,R2 // Redo flags
        BLT  I_CB_e
        MOVS R4,#0x40 // Arith > bit
        ORRS R1,R4
I_CB_e:
        MOV  R12,R1
        BL   start
// *********************************************************************************************
I_A:    LDRH R2,[R6,#0] // R6=DEST
        REV16 R2,R2

        ADDS R3,R2,R5

        MOV  R1,R12
        MOVS R4,#0x06 // Get initialised ST
        ANDS R1,R4

        LSRS R4,R3,#16
        BEQ  I_A_p
        MOVS R4,#0x10 // Carry bit
        ORRS R1,R4
I_A_p:
        UXTH R0,R3 // Keep a copy
        REV16 R3,R3
        STRH R3,[R6,#0]

        MOVS R4,#0x80
        LSLS R4,#8 // -> #0x8000
        ANDS R5,R4
        ANDS R2,R4
        CMP  R2,R5
        BNE  I_A_e
        MOV  R5,R0
        ANDS R5,R4
        CMP  R2,R5
        BEQ  I_A_e
        MOVS R4,#0x08 // Overflow bit
        ORRS R1,R4
I_A_e:
        B    OP_COMP_WOA
// *********************************************************************************************
I_AB:   LDRB R2,[R6,#0] // R6=DEST

        ADDS R3,R2,R5

        MOV  R1,R12
        MOVS R4,#0x02 // Get initialised ST
        ANDS R1,R4

        LSRS R4,R3,#8
        BEQ  I_AB_p
        MOVS R4,#0x10 // Carry bit
        ORRS R1,R4
I_AB_p:
        UXTB R0,R3 // Keep a copy
        STRB R3,[R6,#0]

        MOVS R4,#0x80
        ANDS R5,R4
        ANDS R2,R4
        CMP  R2,R5
        BNE  I_AB_e
        MOV  R5,R0
        ANDS R5,R4
        CMP  R2,R5
        BEQ  I_AB_e
        MOVS R4,#0x08 // Overflow bit
        ORRS R1,R4
I_AB_e:
        B    OP_COMP_B
// *********************************************************************************************
I_MOV:  REV16 R5,R5
        STRH R5,[R6,#0]
// *********************************************************************************************
OP_COMP_W:  // (R1) STH &= 0x1F;
        MOV  R1,R12
        MOVS R4,#0x1E // Get initialised ST
        ANDS R1,R4
OP_COMP_WO: // (R0) DEST = (memory [DEST] << 8) | memory [DEST + 1];
        LDRH R0,[R6,#0] // R6=DEST
        REV16 R0,R0
OP_COMP_WOA:
        SXTH R0,R0
OP_COMP_WOA2:
        CMP  R0,#0
        BNE  OP_COMP_l
        MOVS R3,#0x20 // Equal bit
        ORRS R1,R3
        MOV  R12,R1
        BL   start
OP_COMP_l:
        BGT  OP_COMP_p
        MOVS R3,#0x80 // L >
        ORRS R1,R3
        MOV  R12,R1
        BL   start
OP_COMP_p:
        MOVS R3,#0xC0 // LA >
        ORRS R1,R3
        MOV  R12,R1
        BL   start
// *********************************************************************************************
I_MOVB: STRB R5,[R6,#0]
        MOV  R1,R12
        MOVS R4,#0x1A // Get initialised ST
        ANDS R1,R4
// *********************************************************************************************
OP_COMP_B:
        LDRB R0,[R6,#0]

        //B    NOT_VIDEO

        MOV  R3,R8
        SUBS R6,R3 // Normalise
        MOVS R3,#0x8C
        LSLS R3,#8 // -> 0x8C00
        CMP  R6,R3
        BNE  NOT_VIDEO
        MOVS R3,#32 // space
        CMP  R0,R3
        BLO  NOT_VIDEO
        MOVS R3,#127 // '~'
        CMP  R0,R3
        BHI  NOT_VIDEO

        MOV  R5,R9
        STRB R0,[R5,#0]
        MOVS R4,#1
        ADD  R5,R4
        MOV  R9,R5
NOT_VIDEO:

        ADR  R3,PARITY
        LDRB R3,[R3,R0]
        ORRS R1,R3

        SXTB R0,R0
        B    OP_COMP_WOA2
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
// *********************************************************************************************
I_SOC:  LDRH R2,[R6,#0]
        REV16 R5,R5
        ORRS R2,R5
        STRH R2,[R6,#0]
        B    OP_COMP_W
// *********************************************************************************************
I_SOCB: LDRB R2,[R6,#0]
        ORRS R2,R5
        STRB R2,[R6,#0]
        MOV  R1,R12
        MOVS R4,#0x1A // Get initialised ST
        ANDS R1,R4
        B    OP_COMP_B
// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567
//DDTsSSSSOOOBTdDD
sdecode1: // calculate S & SRCE
        LSRS R1,R0,#7
        MOVS R2,#0x1E
        ANDS R1,R2 // Got S << 1
        LSRS R2,R0,#10
        MOVS R3,#0x0C
        ANDS R2,R3 // Got TS * 4
        ADR  R4,COM_S1
        LDR  R4,[R4,R2]
        MOV  PC,R4
.align 4
COM_S1: .WORD COM_S1_R, COM_S1_I, COM_S1_L, COM_S1_II
COM_S1_R:
        MOV  R5,R11
        ADD  R5,R1 // SRCE = WP + S;
        UXTH R5,R5
        ADD  R5,R8
        MOV  PC,LR
COM_S1_L:
        MOV  R4,R10
        ADDS R2,R4,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R4,R8
        LDRH R5,[R4,#0] // SRCE = (memory [PC + 0] << 8) | memory [PC + 1];
        rev16 R5,R5
        CMP  R1,#0  // if (S) // Not R0?
        BEQ  COM_S1_L_e
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R2,[R1,#0] // SRCE += (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R2,R2
        ADD  R5,R2
        UXTH R5,R5
COM_S1_L_e:
        ADD  R5,R8
        MOV  PC,LR
COM_S1_II:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R5,[R1,#0] // SRCE = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R5,R5
        MOV  R3,R5
        ADDS R3,#1
        REV16 R3,R3
        STRH R3,[R1,#0]
        ADD  R5,R8
        MOV  PC,LR
COM_S1_I:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R5,[R1,#0] // SRCE = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R5,R5
        ADD  R5,R8
        MOV  PC,LR

// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567
//DDTsSSSSOOOBTdDD
sdecode2: // calculate S & SRCE
        LSRS R1,R0,#7
        MOVS R2,#0x1E
        ANDS R1,R2 // Got S << 1
        LSRS R2,R0,#10
        MOVS R3,#0x0C
        ANDS R2,R3 // Got TS * 4
        ADR  R4,COM_S2
        LDR  R4,[R4,R2]
        MOV  PC,R4
.align 4
COM_S2: .WORD COM_S2_R, COM_S2_I, COM_S2_L, COM_S2_II
COM_S2_R:
        MOV  R5,R11
        ADD  R5,R1 // SRCE = WP + S;

        MOVS R2,#0xFE // SRCE &= 0xFFFE;
        SXTB R2,R2
        ANDS R5,R2
        UXTH R5,R5
        ADD  R5,R8
        MOV  PC,LR
COM_S2_L:
        MOV  R4,R10
        ADDS R2,R4,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R4,R8
        LDRH R5,[R4,#0] // SRCE = (memory [PC + 0] << 8) | memory [PC + 1];
        REV16 R5,R5
        CMP  R1,#0  // if (S) // Not R0?
        BEQ  COM_S2_F
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R2,[R1,#0] // SRCE += (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R2,R2
        ADD  R5,R2
COM_S2_F:
        MOVS R2,#0xFE // SRCE &= 0xFFFE;
        SXTB R2,R2
        ANDS R5,R2
        UXTH R5,R5
        ADD  R5,R8
        MOV  PC,LR
COM_S2_II:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R5,[R1,#0] // SRCE = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R5,R5
        ADDS R3,R5,#2
        REV16 R3,R3
        STRH R3,[R1,#0]

        MOVS R2,#0xFE // SRCE &= 0xFFFE;
        SXTB R2,R2
        ANDS R5,R2
        UXTH R5,R5
        ADD  R5,R8
        MOV  PC,LR
COM_S2_I:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R5,[R1,#0] // SRCE = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R5,R5

        MOVS R2,#0xFE // SRCE &= 0xFFFE;
        SXTB R2,R2
        ANDS R5,R2
        UXTH R5,R5
        ADD  R5,R8
        MOV  PC,LR

// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567
//DDTsSSSSOOOBTdDD
ddecode1: // calculate D & DEST
        LSRS R1,R0,#13
        LSLS R2,R0,#3
        ORRS R1,R2
        MOVS R3,#0x1E
        ANDS R1,R3 // Got D << 1
        MOV  R2,R0
        MOVS R3,#0x0C
        ANDS R2,R3 // Got TD * 4
        ADR  R4,COM_D1
        LDR  R4,[R4,R2]
        MOV  PC,R4
.align 4
COM_D1: .WORD COM_D1_R, COM_D1_I, COM_D1_L, COM_D1_II
COM_D1_R:
        MOV  R6,R11
        ADD  R6,R1 // DEST = WP + D;
        UXTH R6,R6
        ADD  R6,R8
        MOV  PC,LR
COM_D1_L:
        MOV  R4,R10
        ADDS R2,R4,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R4,R8
        LDRH R6,[R4,#0] // DEST = (memory [PC + 0] << 8) | memory [PC + 1];
        REV16 R6,R6
        CMP  R1,#0  // if (S) // Not R0?
        BEQ  COM_D1_L_e
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R2,[R1,#0] // DEST += (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R2,R2
        ADD  R6,R2
        UXTH R6,R6
COM_D1_L_e:
        ADD  R6,R8
        MOV  PC,LR
COM_D1_II:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R6,[R1,#0] // DEST = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R6,R6
        ADDS R3,R6,#1
        REV16 R3,R3
        STRH R3,[R1,#0]
        ADD  R6,R8
        MOV  PC,LR
COM_D1_I:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R6,[R1,#0] // DEST = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R6,R6
        ADD  R6,R8
        MOV  PC,LR

// *********************************************************************************************
//R0 (LE)
//89ABCDEF01234567
//DDTsSSSSOOOBTdDD
ddecode2: // calculate D & DEST
        LSRS R1,R0,#13
        LSLS R2,R0,#3
        ORRS R1,R2
        MOVS R3,#0x1E
        ANDS R1,R3 // Got D << 1
        MOV  R2,R0
        MOVS R3,#0x0C
        ANDS R2,R3 // Got TD * 4
        ADR  R4,COM_D2
        LDR  R4,[R4,R2]
        MOV  PC,R4
.align 4
COM_D2: .WORD COM_D2_R, COM_D2_I, COM_D2_L, COM_D2_II
COM_D2_R:
        MOV  R6,R11
        ADD  R6,R1 // DEST = WP + D;

        MOVS R2,#0xFE // DEST &= 0xFFFE;
        SXTB R2,R2
        ANDS R6,R2
        UXTH R6,R6
        ADD  R6,R8
        MOV  PC,LR
COM_D2_L:
        MOV  R4,R10
        ADDS R2,R4,#2
        UXTH R2,R2
        MOV  R10,R2
        ADD  R4,R8
        LDRH R6,[R4,#0] // DEST = (memory [PC + 0] << 8) | memory [PC + 1];
        REV16 R6,R6
        CMP  R1,#0  // if (S) // Not R0?
        BEQ  COM_D2_F
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R2,[R1,#0] // DEST += (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R2,R2
        ADD  R6,R2
COM_D2_F:
        MOVS R2,#0xFE // DEST &= 0xFFFE;
        SXTB R2,R2
        ANDS R6,R2
        UXTH R6,R6
        ADD  R6,R8
        MOV  PC,LR
COM_D2_II:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R6,[R1,#0] // DEST = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R6,R6
        ADDS R3,R6,#2
        REV16 R3,R3
        STRH R3,[R1,#0]

        MOVS R2,#0xFE // DEST &= 0xFFFE;
        SXTB R2,R2
        ANDS R6,R2
        UXTH R6,R6
        ADD  R6,R8
        MOV  PC,LR
COM_D2_I:
        ADD  R1,R11
        UXTH R1,R1
        ADD  R1,R8
        LDRH R6,[R1,#0] // DEST = (memory [WP + 0 + S] << 8) | memory [WP + 1 + S];
        REV16 R6,R6

        MOVS R2,#0xFE // DEST &= 0xFFFE;
        SXTB R2,R2
        ANDS R6,R2
        UXTH R6,R6
        ADD  R6,R8
        MOV  PC,LR
