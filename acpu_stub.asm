# ============================================================
# acpu_stub.asm  —  ACPU Hardware Simulator
# Mission Ares IV / Take-Home Final
#
# DO NOT MODIFY THIS FILE.
#
# This file simulates the Autonomous Crew Protection Unit chip.
# It exposes a single routine: update_sensors
#
# Your main loop must call:
#       jal update_sensors
# once per iteration. Each call advances an internal pointer
# to the next row in the scenario table and writes all six
# MMIO bytes accordingly.
#
# MMIO addresses written by this stub:
#   0xFFFF0010  O2_LEVEL        (0-255)
#   0xFFFF0011  PRESSURE_LEVEL  (0-255)
#   0xFFFF0012  TEMP_LEVEL      (0-255)
#   0xFFFF0013  RADIATION_LEVEL (0-255)
#   0xFFFF0014  FAULT_FLAGS     bits 3-0: Fr Ft Fp Fo
#   0xFFFF0015  ALERT_FLAGS     bits 2-0: L  E  A
#
# Fault thresholds (match Part 1 chip design):
#   Fo: O2        < 50
#   Fp: Pressure  < 80
#   Ft: Temp      < 60
#   Fr: Radiation > 180
#
# Alert logic (match Part 1 circuit):
#   A (ALARM)    = any fault EXCEPT radiation-only
#   E (EVACUATE) = two or more faults
#   L (LOG)      = any fault
#
# Scenario:
#   Rows   0-29  : all nominal, no faults
#   Rows  30-49  : O2 begins falling (slow leak)
#   Rows  50-59  : O2 below threshold -> Fo, A, L fire
#   Rows  60-69  : pressure also drops -> Fp added, E fires
#   Rows  70-79  : pressure recovers, O2 still critical
#   Rows  80-89  : radiation spike only -> L fires, A silent
#   Rows  90-99  : everything recovers, back to nominal
#   Row   100    : scenario loops back to row 0
# ============================================================

# ============================================================
# Scenario table layout (7 bytes per row, packed as words):
#
#   Each row is stored as two consecutive .word entries:
#     Word A (row*8+0): O2 | (Pressure<<8) | (Temp<<16) | (Radiation<<24)
#     Word B (row*8+4): FAULT_FLAGS | (ALERT_FLAGS<<8) | 0 | 0
#
#   We use .byte so each field is explicit and readable.
#   Format per row: .byte O2, Pressure, Temp, Radiation, Fault, Alert, 0, 0
#                         (pad to 8 bytes for easy word-aligned indexing)
# ============================================================

.data

# Internal state
stub_ptr:   .word 0          # current row index (0 to SCENARIO_LEN-1)

.eqv SCENARIO_LEN  101       # total number of rows (0..100, row 100 = sentinel/loop)
.eqv ROW_SIZE      8         # bytes per row

# ------------------------------------------------------------------
# Scenario table
# Columns: O2, Pressure, Temp, Radiation, FaultFlags, AlertFlags, pad, pad
#
# FaultFlags bits:  3=Fr  2=Ft  1=Fp  0=Fo
# AlertFlags bits:  2=L   1=E   0=A
#
# Examples:
#   FaultFlags=0x00  AlertFlags=0x00  -> all clear
#   FaultFlags=0x01  AlertFlags=0x05  -> Fo only     -> A=1 E=0 L=1 -> 0b101=0x05
#   FaultFlags=0x03  AlertFlags=0x07  -> Fo+Fp       -> A=1 E=1 L=1 -> 0b111=0x07
#   FaultFlags=0x08  AlertFlags=0x04  -> Fr only     -> A=0 E=0 L=1 -> 0b100=0x04
# ------------------------------------------------------------------

scenario:
# ---- Rows 0-9: fully nominal --------------------------------------
#      O2   Pres  Temp  Rad   Fault Alert pad  pad
.byte  220,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  221,  201,  181,   21,  0x00, 0x00,  0,   0
.byte  219,  199,  179,   19,  0x00, 0x00,  0,   0
.byte  220,  200,  180,   22,  0x00, 0x00,  0,   0
.byte  218,  202,  178,   20,  0x00, 0x00,  0,   0
.byte  221,  198,  182,   18,  0x00, 0x00,  0,   0
.byte  220,  200,  180,   21,  0x00, 0x00,  0,   0
.byte  219,  201,  179,   20,  0x00, 0x00,  0,   0
.byte  222,  200,  181,   19,  0x00, 0x00,  0,   0
.byte  220,  199,  180,   20,  0x00, 0x00,  0,   0

# ---- Rows 10-19: nominal (continued) ------------------------------
.byte  220,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  221,  201,  181,   21,  0x00, 0x00,  0,   0
.byte  219,  200,  179,   22,  0x00, 0x00,  0,   0
.byte  220,  202,  180,   20,  0x00, 0x00,  0,   0
.byte  218,  199,  178,   19,  0x00, 0x00,  0,   0
.byte  221,  200,  182,   21,  0x00, 0x00,  0,   0
.byte  220,  201,  180,   20,  0x00, 0x00,  0,   0
.byte  219,  200,  179,   18,  0x00, 0x00,  0,   0
.byte  222,  199,  181,   20,  0x00, 0x00,  0,   0
.byte  220,  200,  180,   20,  0x00, 0x00,  0,   0

# ---- Rows 20-29: nominal (continued) ------------------------------
.byte  220,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  221,  201,  181,   21,  0x00, 0x00,  0,   0
.byte  219,  200,  179,   22,  0x00, 0x00,  0,   0
.byte  220,  202,  180,   20,  0x00, 0x00,  0,   0
.byte  218,  199,  178,   19,  0x00, 0x00,  0,   0
.byte  221,  200,  182,   21,  0x00, 0x00,  0,   0
.byte  220,  201,  180,   20,  0x00, 0x00,  0,   0
.byte  219,  200,  179,   18,  0x00, 0x00,  0,   0
.byte  222,  199,  181,   20,  0x00, 0x00,  0,   0
.byte  220,  200,  180,   20,  0x00, 0x00,  0,   0

# ---- Rows 30-49: O2 slow leak begins, still above threshold -------
#      O2 drops ~9 per step from 220 down toward 50
#      No fault yet (Fo fires when O2 < 50)
.byte  210,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  200,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  190,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  180,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  170,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  160,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  150,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  140,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  130,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  120,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  110,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  100,  200,  180,   20,  0x00, 0x00,  0,   0
.byte   90,  200,  180,   20,  0x00, 0x00,  0,   0
.byte   80,  200,  180,   20,  0x00, 0x00,  0,   0
.byte   70,  200,  180,   20,  0x00, 0x00,  0,   0
.byte   60,  200,  180,   20,  0x00, 0x00,  0,   0
.byte   55,  200,  180,   20,  0x00, 0x00,  0,   0
.byte   53,  200,  180,   20,  0x00, 0x00,  0,   0
.byte   51,  200,  180,   20,  0x00, 0x00,  0,   0
.byte   50,  200,  180,   20,  0x00, 0x00,  0,   0

# ---- Rows 50-59: O2 crosses threshold -> Fo, A=1 L=1 -------------
#      FaultFlags=0x01 (Fo only)   AlertFlags=0x05 (A+L, no E)
.byte   45,  200,  180,   20,  0x01, 0x05,  0,   0
.byte   40,  200,  180,   20,  0x01, 0x05,  0,   0
.byte   35,  200,  180,   20,  0x01, 0x05,  0,   0
.byte   30,  200,  180,   20,  0x01, 0x05,  0,   0
.byte   25,  200,  180,   20,  0x01, 0x05,  0,   0
.byte   20,  200,  180,   20,  0x01, 0x05,  0,   0
.byte   15,  200,  180,   20,  0x01, 0x05,  0,   0
.byte   10,  200,  180,   20,  0x01, 0x05,  0,   0
.byte    5,  200,  180,   20,  0x01, 0x05,  0,   0
.byte    2,  200,  180,   20,  0x01, 0x05,  0,   0

# ---- Rows 60-69: pressure also drops -> Fo+Fp, E fires ------------
#      FaultFlags=0x03 (Fo+Fp)     AlertFlags=0x07 (A+E+L)
.byte    2,   70,  180,   20,  0x03, 0x07,  0,   0
.byte    2,   60,  180,   20,  0x03, 0x07,  0,   0
.byte    2,   50,  180,   20,  0x03, 0x07,  0,   0
.byte    2,   40,  180,   20,  0x03, 0x07,  0,   0
.byte    2,   30,  180,   20,  0x03, 0x07,  0,   0
.byte    2,   25,  180,   20,  0x03, 0x07,  0,   0
.byte    2,   20,  180,   20,  0x03, 0x07,  0,   0
.byte    2,   15,  180,   20,  0x03, 0x07,  0,   0
.byte    2,   10,  180,   20,  0x03, 0x07,  0,   0
.byte    2,    5,  180,   20,  0x03, 0x07,  0,   0

# ---- Rows 70-79: pressure recovers, O2 still critical -------------
#      FaultFlags=0x01 (Fo only)   AlertFlags=0x05 (A+L)
.byte    2,  100,  180,   20,  0x01, 0x05,  0,   0
.byte    2,  120,  180,   20,  0x01, 0x05,  0,   0
.byte    2,  140,  180,   20,  0x01, 0x05,  0,   0
.byte    2,  160,  180,   20,  0x01, 0x05,  0,   0
.byte    2,  180,  180,   20,  0x01, 0x05,  0,   0
.byte    2,  190,  180,   20,  0x01, 0x05,  0,   0
.byte    2,  195,  180,   20,  0x01, 0x05,  0,   0
.byte    2,  198,  180,   20,  0x01, 0x05,  0,   0
.byte    2,  199,  180,   20,  0x01, 0x05,  0,   0
.byte    2,  200,  180,   20,  0x01, 0x05,  0,   0

# ---- Rows 80-89: radiation spike only -> L fires, A silent --------
#      FaultFlags=0x08 (Fr only)   AlertFlags=0x04 (L only, no A)
.byte  220,  200,  180,  190,  0x08, 0x04,  0,   0
.byte  220,  200,  180,  200,  0x08, 0x04,  0,   0
.byte  220,  200,  180,  210,  0x08, 0x04,  0,   0
.byte  220,  200,  180,  220,  0x08, 0x04,  0,   0
.byte  220,  200,  180,  230,  0x08, 0x04,  0,   0
.byte  220,  200,  180,  240,  0x08, 0x04,  0,   0
.byte  220,  200,  180,  245,  0x08, 0x04,  0,   0
.byte  220,  200,  180,  248,  0x08, 0x04,  0,   0
.byte  220,  200,  180,  250,  0x08, 0x04,  0,   0
.byte  220,  200,  180,  255,  0x08, 0x04,  0,   0

# ---- Rows 90-99: full recovery, all nominal -----------------------
.byte  220,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  220,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  220,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  220,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  220,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  220,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  220,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  220,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  220,  200,  180,   20,  0x00, 0x00,  0,   0
.byte  220,  200,  180,   20,  0x00, 0x00,  0,   0

# ---- Row 100: sentinel — loop resets to row 0 --------------------
.byte    0,    0,    0,    0,  0x00, 0x00,  0,   0

# ============================================================
# update_sensors
#
# Called by the student's main loop every iteration.
# Reads the current row from the scenario table,
# writes each field to its MMIO address,
# then advances stub_ptr (wrapping at SCENARIO_LEN-1).
#
# Registers used (all saved and restored):
#   $t0  base address of scenario table
#   $t1  current row index (stub_ptr)
#   $t2  byte offset into table  (row * ROW_SIZE)
#   $t3  address of current row
#   $t4  scratch for reading/writing individual bytes
#   $t5  MMIO base scratch
#
# No input arguments. No return value.
# ============================================================

.text
.globl update_sensors
update_sensors:

    # --- save registers ---
    addiu $sp, $sp, -24
    sw    $t0,  0($sp)
    sw    $t1,  4($sp)
    sw    $t2,  8($sp)
    sw    $t3, 12($sp)
    sw    $t4, 16($sp)
    sw    $t5, 20($sp)

    # --- load current row index ---
    la    $t0, stub_ptr
    lw    $t1, 0($t0)          # $t1 = current row index

    # --- check sentinel: if index >= 100, reset to 0 ---
    slti  $t4, $t1, 100        # $t4 = 1 if index < 100
    bne   $t4, $zero, _no_wrap
    sw    $zero, 0($t0)        # reset index to 0
    li    $t1, 0               # also reset local copy
_no_wrap:

    # --- compute byte offset: offset = index * 8 (ROW_SIZE) ---
    # multiply by 8 = shift left by 3, no mul instruction needed
    sll   $t2, $t1, 3          # $t2 = index << 3 = index * 8

    # --- get address of current row in table ---
    la    $t3, scenario
    addu  $t3, $t3, $t2        # $t3 = &scenario[index]

    # --- read all 6 bytes from the row ---
    lbu   $t4, 0($t3)          # O2_LEVEL
    li    $t5, 0xFFFF0010
    sb    $t4, 0($t5)          # write to MMIO 0xFFFF0010

    lbu   $t4, 1($t3)          # PRESSURE_LEVEL
    sb    $t4, 1($t5)          # write to MMIO 0xFFFF0011

    lbu   $t4, 2($t3)          # TEMP_LEVEL
    sb    $t4, 2($t5)          # write to MMIO 0xFFFF0012

    lbu   $t4, 3($t3)          # RADIATION_LEVEL
    sb    $t4, 3($t5)          # write to MMIO 0xFFFF0013

    lbu   $t4, 4($t3)          # FAULT_FLAGS
    sb    $t4, 4($t5)          # write to MMIO 0xFFFF0014

    lbu   $t4, 5($t3)          # ALERT_FLAGS
    sb    $t4, 5($t5)          # write to MMIO 0xFFFF0015

    # --- advance pointer ---
    addiu $t1, $t1, 1
    la    $t0, stub_ptr
    sw    $t1, 0($t0)

    # --- restore registers ---
    lw    $t0,  0($sp)
    lw    $t1,  4($sp)
    lw    $t2,  8($sp)
    lw    $t3, 12($sp)
    lw    $t4, 16($sp)
    lw    $t5, 20($sp)
    addiu $sp, $sp, 24

    jr    $ra
