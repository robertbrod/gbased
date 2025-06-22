# Notes

## Register Definitions

| bit 7     | bit 6     | bit 5 | bit 4     | bit 3      | bit 2      | bit 1 | bit 0 |
| --------- | --------- | ----- | --------- | ---------- | ---------- | ----- | ----- |
| R/W-0     | R/W-1     | U-1   | R-0       | R-1        | R-x        | W-1   | U-0   |
| VALUE <1> | VALUE <0> | N/A   | BIGVAL<7> | BIGVAL <6> | BIGVAL <5> | FLAG  | N/A   |

Legend:

| Symbol    | Meaning                                                        |
| --------- | -------------------------------------------------------------- |
| R         | Bit can be read                                                |
| W         | Bit can be written.                                            |
| U         | Unimplemented bit.                                             |
| -n        | Value after system reset                                       |
| 1         | Bit is set                                                     |
| 0         | Bit is cleared                                                 |
| x         | Bit is unknown (depends on external things such as user input) |
| VALUE<n>  | Bit n of VALUE                                                 |
| N/A       | Unimplemented bit                                              |
| BIGVAL<n> | Bit n of BIGVAL                                                |
| FLAG      | Single-bit value FLAG                                          |

Reading a bit that is unimplemented or cannot be read returns a constant value
defined in the bit list of the register in question.

## Introduction

The original Game Boy (code name Dot Matrix Game) architecture had a Sharp SM83
CPU core and 4-level grayscale graphics.

## Clocks

### System Clock

The system oscillator is the primary clock source in a Game Boy system, and it
generates the system clock. Almost all other clocks are derived from the system
clock, but there are some exceptions:

- If a GB is set up to do a serial transfer in secondary mode, the serial data
  register is directly clocked using the serial clock signal coming from the
  link port. Two GBs connected with a link cable never have precisely the same
  clock phase and frequency relative to each other, so the clock of the primary
  side has no direct relation to the system clock of the secondary side.
- The inserted game cartridge may use other clock(s) internally.

The GB SoC uses two pins for the system oscillator: XI and XO. These pins along
with some external components can be used to form a Pierce oscillator circuit.

#### System Clock Frequency

In DMG and MGB console the system oscillator circuit uses an external quartz
crystal with a nominal frequency of 4.194304 MHz to form a Pierce oscillator
circuit. This frequency is considered to be the standard frequency of a GB.

### Clock Periods, T-cycles, and M-cycles

In digital logic, a clock switches between low and high states and every
transition happens on a clock dege, which might be a rising edge (low -> high
transition) or a falling edge (high -> low transition). A single clock period is
measured between two edges of the same type, so that the clock goes through two
opposing edges and returns to its original state after the clock period.

In addition to the system clock and other clocks derived from it, GB systems
also use inverted clocks in some peripherals, which means the rising edge of an
inverted clock may happen at the same time as a falling edge of the original
clock.

## Sharp SM83 CPU Core - Introduction

The CPU core in the GB SoC is a custom Sharp design that hasn't been publicy
been given a name by either Sharp or Nintendo. However, using old Sharp
datasheets and databooks as evidence, the core has been identified as a SHarp
SM83 CPU core, or at least something that is 100% compatible with it.

SM83 is an 8-bit CPU core with a 16-bit address bus. The Instruction Set
Architecture (ISA) is based on both Z80 and 8080.

![SM83 CPU Chip Simple Diagram](./sm83_diagram_simple.png)

## Sources

[Game Boy: Complete Technical Reference](https://gekkio.fi/files/gb-docs/gbctr.pdf)
