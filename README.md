# Subleq
subleq verilog project for FPGA Tang Nano

Subleq is a kind of OISC one instruction, "SUBtract and branch if Less-than or EQual to zero".
The instruction has 3 memory operands.
A B C
[A] = [A] - [B]  goto C if [A] <= 0

Please refer below link for detail.

https://esolangs.org/wiki/Subleq

This Subleq has below specification.
- 8bit address
- 8bit data
- 256bytes full memory
- Using UART to access Subleq/Memory

# Instruction to run

This project uses Tang Nano board. Please setup environment with 
https://qiita.com/yoshiki9636/items/cabcd0c62ea97472b51c
After that, please do

(1) Make project with src/*.v and  syn/*

(2) Add OSC, PLL, and UART_MASTER with setting 50MHz clk.

(3) Synthesis, Place&Route, Write to Tang Nano

(4) Open Serial console like teraterm and connect with COM port.

Using with below command

w : write memory command

w XX DD DD ….q

Write data from address XX. The q command need to quit this command.


r : read memory command

r XX YY 

Dump out data from address XX to YY.


g : goto address and execution command

g XX …q

Run from XX address. The q command need to quit this command.


s : step execution command

Run only one step.

t : trash memory data

Clear all memory to 0x00

Author Yoshiki Kurokawa @yoshiki9636
