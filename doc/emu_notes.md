# Notes
An emulator is a program that runs on a specific platform (the host system) that allows you to run software written for a different platform (the target system). The emulator is basically a program that simulates the behavior of the target systems hardware which allows the host system to run software written specifically for the target system.

Every processor-based system has three major components:
- The processor
- Memory
- IO harware

## The Processor
The processor reads instructions from memory and does what these instructions tell it to do. The processor will execute these instructions sequentially.

There are many different types of processors and most are identified by a number. Each processor does the same basic things decribed above but each does it in a different way. We also sometimes refer to processor "families". These are groups of processors, usually made by the same company, which are all very similar.

## Processor Registers

Every processor has a series of internal registers that are used to store data, addresses, and to control the processor.

### Program Counter

The most common register that you will find on all processors is the Program Counter (PC). The PC holds the address where the next instruction will be loaded from memory. The PC is initialized to some known state when the processor is reset and increments as each byte of each instruction is read. The PC can also be changed using jump and branch type instructions.

### Working Registers
Processors have 1 or more "working registers" which are used to hold data that the processor needs to operate on.

### Stack Pointer
Most processors have a special area of memory called the stack. The processor accesses the stack using what is called the LIFO method, Last In First Out. Processors usually have instructions which allow the programmer to manually push and pull values from the stack.

The Stack Pointer (SP) is used to keep track of the current position of the stack.

### Status Register
The status register(s) usually serve two purposes. First, they allow you to control certain aspects of the processor. The other important part of the status register are the status flags.

## Memory
Memory is where the instructions that the processor executes and the data that these instructions act on is stored. There are 2 major types of memory, RAM and ROM. RAM can be written to and read from by the processor. ROM can only be read from, not written to.

## IO
IO is the hardware that allows the processor to access the outside world. IO includes things like sound circuitry, video circuits, controller inputs, and communication chips that communicate with external devices such as disk drives and printers. IO also includes things like timer circuits, which allow the processor to keep track of "real world" time.

## Buses
For the processor, memory, and IO to work together, there needs to be some sort of interconnection between them. Buses are basically a group of wires that connect the devices in a system together.

Each line in a bus carries 1 bit of information. So if a processor needs to mode data 8 bits at a time, it would need a bus that is 8 bits wide.

There are three types of buses in a processor-based system:
- The data bus
- The address bus
- The control bus

The data bus tells us what to move, the address bus tells us where to move it, and the control bus tells us how to move it.

# Sources
[How Do I Write an Emulator](https://www.atarihq.com/danb/files/emu_vol1.txt)
