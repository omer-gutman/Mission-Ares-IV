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

# --- Text section -------------------------------------------
.text
.globl main
main
    jal update_sensors   # advance stub to next reading
    jal print_status     # redraw crew display
    j   main             # poll forever

# ------------------------------------------------------------
# print_status
# Input  none
# Output none
# Description TODO
# ------------------------------------------------------------
print_status
    # TODO
    jr $ra

# ------------------------------------------------------------
# push_o2_sample
# Input  $a0 = new O2 byte
# Output none
# Description maintains a circular biffer of the last 8 oxygen readings
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
    andi  $t1, $t1, 0x07           # bitwise AND immediate, if the index reaches 8 we want to wrap back to 0. 1000 AND 0111 = 0000
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
# Description TODO
# ------------------------------------------------------------
compute_o2_avg
    # TODO
    jr $ra