# UART and FIFO

Synchronous FIFO and 8N1 UART (transmitter and receiver) in Verilog, with self-checking testbenches.

- FIFO: directed overfill and overdrain, then 4,000 random cycles against a reference queue.
- UART TX: all 256 bytes back to back, every bit checked on every clock.
- UART loopback: all 256 bytes, start glitch, bad stop bit and recovery.

`make mutate` injects 11 faults one at a time; the testbenches catch all of them.

Run with `make` (Icarus Verilog). Known limit: the receiver takes a single mid-bit sample, so it has no noise voting.

Yosys ECP5 synthesis in CI: FIFO 18 flip-flops, transmitter 29, receiver 43.
