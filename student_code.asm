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
# Description TODO
# ------------------------------------------------------------
push_o2_sample
    # TODO
    jr $ra

# ------------------------------------------------------------
# compute_o2_avg
# Input  none
# Output $v0 = average, or -1 if buffer not full
# Description TODO
# ------------------------------------------------------------
compute_o2_avg
    # TODO
    jr $ra