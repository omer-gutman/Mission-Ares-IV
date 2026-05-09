# ============================================================
# Mission Ares IV — Student Scaffold
# Name Omer Gutman
# ID 214289209
# ============================================================

# --- MMIO Addresses -----------------------------------------
.eqv O2_LEVEL         0xFFFF0010
.eqv PRESSURE_LEVEL   0xFFFF0011
.eqv TEMP_LEVEL       0xFFFF0012
.eqv RADIATION_LEVEL  0xFFFF0013
.eqv FAULT_FLAGS      0xFFFF0014
.eqv ALERT_FLAGS      0xFFFF0015

# --- Fault thresholds (match your Part 1 chip design) -------
.eqv THRESH_O2        50
.eqv THRESH_PRESSURE  80
.eqv THRESH_TEMP      60
.eqv THRESH_RADIATION 180

# --- Data section -------------------------------------------
.data
o2_buf:    .byte 0:8          # 8-byte circular buffer
buf_idx:   .word 0
buf_count: .word 0

# --- Data section -  string literals for panel output -------------------------------------------
str_newline:    .asciiz "\n"
str_header:     .asciiz "ARES IV -- HABITAT STATUS\n"
str_eq:         .asciiz "========================================\n"
str_dash:       .asciiz "----------------------------------------\n"

# sensor labels each is 11 chars wide so ": " aligns
str_o2_lbl:     .asciiz "O2         : "
str_press_lbl:  .asciiz "Pressure   : "
str_temp_lbl:   .asciiz "Temp       : "
str_rad_lbl:    .asciiz "Radiation  : "
str_alarm_lbl:  .asciiz "ALARM      : "
str_evac_lbl:   .asciiz "EVACUATE   : "
str_log_lbl:    .asciiz "LOG        : "
str_o2avg_lbl:  .asciiz "O2 avg (8) : "

# status / value strings
str_ok:         .asciiz "[OK]\n"       # no leading spaces print_padded addes them
str_fault:      .asciiz "[FAULT]\n"
str_yes:        .asciiz "YES\n"
str_no:         .asciiz "NO\n"
str_not_enough: .asciiz "not enough data\n"
str_event_rec:  .asciiz "event recorded\n"
str_evac_msg:   .asciiz "EVACUATE -- CREW TO ESCAPE PODS\n"

# trailing space pads used by print_padded to right fill the value column
str_2sp:        .asciiz "  "
str_3sp:        .asciiz "   "
str_4sp:        .asciiz "    "

# --- Text section -------------------------------------------
.text
.globl main
main:
    jal update_sensors   # advance stub to next reading
    jal print_status     # redraw crew display
    j   main             # poll forever

# ------------------------------------------------------------
# print_status
# Input  none
# Output none
# Description: 
#   Reads all MMIO sensors and updates the O2 buffer. 
#   Prints the formatted status panel to the console, 
#   checking bit flags to show faults and alerts. 
#   Also prints an evacuate warning if needed.
# ------------------------------------------------------------
print_status:
    # prologue, addhereing to calling convenyion saves $ra and all $s registers used 
    addiu $sp, $sp, -32       # makes room on the stack for 8 words (32 bytes)
    sw    $ra, 28($sp)        # save return address
    sw    $s6, 24($sp)        # save space for O2 Average
    sw    $s5, 20($sp)        # save space for ALERT_FLAGS
    sw    $s4, 16($sp)        # save space for FAULT_FLAGS
    sw    $s3, 12($sp)        # save space for RADIATION_LEVEL
    sw    $s2,  8($sp)        # save space for TEMP_LEVEL
    sw    $s1,  4($sp)        # save space for PRESSURE_LEVEL
    sw    $s0,  0($sp)        # save space for O2_LEVEL

    # read O2_LEVEL and proccess
    li    $t0, O2_LEVEL       # load MMIO adress pointer from main memmory
    lbu   $s0, 0($t0)         # read byte from O2_LEVEL   

    move  $a0, $s0            # put O2 reading into argument register
    jal   push_o2_sample      # call push_o2_sample function to save to buffer

    jal   compute_o2_avg      # call compute_o2_avg function to calculate average
    move  $s6, $v0            # save results saflty in $s6

    # read remaining MMIO sensors 
    li    $t0, PRESSURE_LEVEL
    lbu   $s1, 0($t0)         # read byte from PRESSURE_LEVEL 

    li    $t0, TEMP_LEVEL
    lbu   $s2, 0($t0)         # read byte from TEMP_LEVEL     

    li    $t0, RADIATION_LEVEL
    lbu   $s3, 0($t0)         # read byte from RADIATION_LEVEL

    li    $t0, FAULT_FLAGS
    lbu   $s4, 0($t0)         # read byte from FAULT_FLAGS    

    li    $t0, ALERT_FLAGS
    lbu   $s5, 0($t0)         # read byte from ALERT_FLAGS    

    # ===================== HEADER =====================
    la    $a0, str_newline    # print new line to visually separate each panel
    li    $v0, 4
    syscall
    la    $a0, str_eq         # Print top ======
    li    $v0, 4
    syscall
    la    $a0, str_header     # print "ARES IV HABITAT STATUS\n"
    li    $v0, 4
    syscall
    la    $a0, str_eq         # Print bottom ======
    li    $v0, 4
    syscall

    # ===================== O2 LINE =====================
    # FAULT_FLAGS bits 3-0: Fr Ft Fp Fo
    # Fo (O2 fault) = bit 0
    la    $a0, str_o2_lbl         # print string "O2         : "
    li    $v0, 4
    syscall
    move  $a0, $s0                 # move raw O2 value into argument register
    jal   print_padded             # jump to custom padding function
    andi  $t0, $s4, 0x01           # isolate Fo (O2 fault) bit
    bne   $t0, $zero, ps_o2_fault  # if fault ON jump to print fault
    la    $a0, str_ok              # print string "[OK]\n"
    li    $v0, 4
    syscall
    j     ps_pressure              # jump over to next sensor printing block
ps_o2_fault:
    la    $a0, str_fault           # print string "[FAULT]\n"
    li    $v0, 4
    syscall

    # ===================== PRESSURE LINE =====================
    # Fp (Pressure fault) = bit 1
ps_pressure:
    la    $a0, str_press_lbl       # print string "Pressure   : "
    li    $v0, 4
    syscall
    move  $a0, $s1                 # move raw pressure value into argument register
    jal   print_padded
    andi  $t0, $s4, 0x02           # isolate Fp (Pressure fault) bit
    bne   $t0, $zero, ps_press_fault
    la    $a0, str_ok
    li    $v0, 4
    syscall
    j     ps_temp                  # jump over to next sensor printing block
ps_press_fault:
    la    $a0, str_fault
    li    $v0, 4
    syscall

    # ===================== TEMP LINE =====================
    #   Ft (Temp fault) = bit 2
ps_temp:
    la    $a0, str_temp_lbl        # print string "Temp       : "
    li    $v0, 4
    syscall
    move  $a0, $s2                 # move raw temp value into argument register
    jal   print_padded
    andi  $t0, $s4, 0x04           # isolate Ft (Temp fault) bit
    bne   $t0, $zero, ps_temp_fault
    la    $a0, str_ok
    li    $v0, 4
    syscall
    j     ps_radiation             # jump over to next sensor printing block
ps_temp_fault:
    la    $a0, str_fault
    li    $v0, 4
    syscall

    # ===================== RADIATION LINE =====================
    #   Fr (Radiation fault) = bit 3
ps_radiation:
    la    $a0, str_rad_lbl         # print string "Radiation  : "
    li    $v0, 4
    syscall
    move  $a0, $s3                 # move raw radiation value into argument register
    jal   print_padded          
    andi  $t0, $s4, 0x08           # isolate Fr (Radiation fault) bit
    bne   $t0, $zero, ps_rad_fault
    la    $a0, str_ok
    li    $v0, 4
    syscall
    j     ps_alarm
ps_rad_fault:
    la    $a0, str_fault           # jump over to alert printing block
    li    $v0, 4
    syscall

    # ===================== ALARM LINE =====================
    # ALERT_FLAGS bits 2-0: L E A
    # A (Alarm) = bit 0
ps_alarm:
    la    $a0, str_dash            # Print mid --------
    li    $v0, 4
    syscall
    la    $a0, str_alarm_lbl      # print string "ALARM      : "
    li    $v0, 4
    syscall
    andi  $t0, $s5, 0x01           # isolate A (Alarm) bit
    beq   $t0, $zero, ps_alarm_no  # if alert OFF jump to print no
    la    $a0, str_yes             # print string "YES\n"
    li    $v0, 4
    syscall
    la    $a0, str_event_rec       # extra message whenever alarm is active
    li    $v0, 4
    syscall
    j     ps_evacuate_lbl          # jump over to next alert printing block
ps_alarm_no:
    la    $a0, str_no              # print string "NO\n"
    li    $v0, 4
    syscall

    # ===================== EVACUATE LINE =====================
    #   E (Evacuate) = bit 1
ps_evacuate_lbl:
    la    $a0, str_evac_lbl        # print string "EVACUATE   : "
    li    $v0, 4
    syscall
    andi  $t0, $s5, 0x02           # isolate E (Evacuate) bit
    beq   $t0, $zero, ps_evac_no
    la    $a0, str_yes
    li    $v0, 4
    syscall
    j     ps_log                   # jump over to next alert printing block
ps_evac_no:
    la    $a0, str_no
    li    $v0, 4
    syscall

    # ===================== LOG LINE =====================
    #   L (Log) = bit 2
ps_log:
    la    $a0, str_log_lbl         # print string "LOG        : "
    li    $v0, 4
    syscall
    andi  $t0, $s5, 0x04           # isolate L (Log) bit
    beq   $t0, $zero, ps_log_no
    la    $a0, str_yes
    li    $v0, 4
    syscall
    j     ps_o2avg                 # jump over to O2 average printing block
ps_log_no:
    la    $a0, str_no
    li    $v0, 4
    syscall

    # ===================== O2 AVG LINE =====================
ps_o2avg:
    la    $a0, str_dash            # Print lower --------
    li    $v0, 4
    syscall
    la    $a0, str_o2avg_lbl       # print string "O2 avg (8) : "
    li    $v0, 4
    syscall
    li    $t0, -1                  # check if average is NOT -1, if so jump to print it
    bne   $s6, $t0, ps_avg_num     
    la    $a0, str_not_enough      # print string "not enough data\n"
    li    $v0, 4
    syscall
    j     ps_print_bottom          # jump over to post panel printing block 
ps_avg_num:
    move  $a0, $s6                 
    li    $v0, 1
    syscall                        # print integer average
    la    $a0, str_newline         # print newline
    li    $v0, 4
    syscall
ps_print_bottom:
    la    $a0, str_eq              # Print very bottom ======
    li    $v0, 4
    syscall

    # ===================== POST-PANEL =====================
    # if EVACUATE bit is set, print the emergency message after the panel
ps_post_panel:
    andi  $t0, $s5, 0x02           # re check E (bit 1) in ALERT_FLAGS
    beq   $t0, $zero, ps_done      # if 0 skip to the end
    la    $a0, str_evac_msg        # print string "EVACUATE -- CREW TO ESCAPE PODS\n"
    li    $v0, 4
    syscall

ps_done:
    # epilogue restore all saved registers
    lw    $s0,  0($sp)
    lw    $s1,  4($sp)
    lw    $s2,  8($sp)
    lw    $s3, 12($sp)
    lw    $s4, 16($sp)
    lw    $s5, 20($sp)
    lw    $s6, 24($sp)
    lw    $ra, 28($sp)
    addiu $sp, $sp, 32
    jr    $ra


print_padded:
    move  $t9, $a0                 # save a copy of the sensor value
    li    $v0, 1
    syscall                        # print the integer

    # Decide how many trailing spaces are needed
    li    $t0, 100
    slt   $t1, $t9, $t0            # 3 digit check
    beq   $t1, $zero, pp_2sp     
    li    $t0, 10
    slt   $t1, $t9, $t0            # 2 digit check
    beq   $t1, $zero, pp_3sp       
    la    $a0, str_4sp             # 1 digit, print a string of 4 spces ("    ")
    li    $v0, 4
    syscall
    jr    $ra
pp_3sp:
    la    $a0, str_3sp             # print a string of 3 spaces ("   ")
    li    $v0, 4
    syscall
    jr    $ra
pp_2sp:
    la    $a0, str_2sp             # print a string of 2 spaces ("  ")
    li    $v0, 4
    syscall
    jr    $ra



# ------------------------------------------------------------
# push_o2_sample
# Input  $a0 = new O2 byte
# Output none
# Description: 
#   Saves a new O2 reading into the circular buffer. 
#   Updates the index and wraps it around using modulo. 
#   Also increases the sample count up to a max of 8.
# ------------------------------------------------------------
push_o2_sample:
    # store the new sample
    la    $t0, buf_idx
    lw    $t1, 0($t0)              # get current index (0,1,..,7) from memmory

    la    $t2, o2_buf              # get the base starting address of our array
    add   $t3, $t2, $t1            # base address + index = exact target address
    sb    $a0, 0($t3)              # save the sensor reading ($a0) into main memmory at target

    # advancing the index
    addi  $t1, $t1, 1              # advance our current index
    andi  $t1, $t1, 0x07           # modulo 8 wrap around for index
    sw    $t1, 0($t0)              # update the current index to buf_idx spot in main memmory so its ready for next cycle

    # increment buf_count only while it is still below 8
    la    $t4, buf_count
    lw    $t5, 0($t4)              # grab the current count from memmory
    slti  $t6, $t5, 8              # check if count < 8 
    beq   $t6, $zero, pos_done     # skip increment
    addi  $t5, $t5, 1
    sw    $t5, 0($t4)              # save the updated buf_count in main memmory
pos_done:
    jr    $ra

# ------------------------------------------------------------
# compute_o2_avg
# Input  none
# Output $v0 = average, or -1 if buffer not full
# Description:
#   Returns -1 if we don't have 8 samples yet. 
#   If the buffer is full, it sums up the 8 bytes 
#   and divides by 8 using a bit shift (srl) to get the average.
# ------------------------------------------------------------
compute_o2_avg:
    # the gatekeeper
    la    $t0, buf_count
    lw    $t1, 0($t0)              # get the current count from main memmory
    slti  $t2, $t1, 8              # check if count < 8
    beq   $t2, $zero, coa_sum      # jump to increment
    li    $v0, -1                  # not enough data, return -1 in $v0
    jr    $ra

coa_sum:
    # the unrolled load, load all 8 bytes from the circular buffer
    la    $t0, o2_buf
    lbu   $t1, 0($t0)              # adding a offset to the base address to not change the adress pointer
    lbu   $t2, 1($t0)             
    lbu   $t3, 2($t0)            
    lbu   $t4, 3($t0)            
    lbu   $t5, 4($t0)           
    lbu   $t6, 5($t0)              
    lbu   $t7, 6($t0)             
    lbu   $t8, 7($t0)              

    # the casading sum, sum all 8 values 
    add   $v0, $t1, $t2
    add   $v0, $v0, $t3
    add   $v0, $v0, $t4
    add   $v0, $v0, $t5
    add   $v0, $v0, $t6
    add   $v0, $v0, $t7
    add   $v0, $v0, $t8            # now holds the total sum (max 2040, so no overflow risk in 32 bit register)

    # integer divide by 8 using logical right shift 
    srl   $v0, $v0, 3              # divide sum by 8 (shift right 3) to get floor average
    jr    $ra
