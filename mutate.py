#!/usr/bin/env python3
"""Mutation test: inject one fault at a time and check that a testbench fails."""
import pathlib, subprocess, sys, tempfile

ROOT = pathlib.Path(__file__).parent
RTL = ["fifo", "uart_rx", "uart_tx"]
# file, testbench, original text, faulty text
MUTANTS = [
    ("fifo", "tb_fifo", "wr_en && !full", "wr_en"),
    ("fifo", "tb_fifo", "rd_en && !empty", "rd_en"),
    ("fifo", "tb_fifo", "(wp[AW] != rp[AW]) && ", ""),
    ("fifo", "tb_fifo", "rp <= rp + 1'b1", "rp <= rp + 2'd2"),
    ("uart_tx", "tb_uart_tx", "bits  <= 4'd10", "bits  <= 4'd9"),
    ("uart_tx", "tb_uart_tx", "cnt == CLKS_PER_BIT-1", "cnt == CLKS_PER_BIT-2"),
    ("uart_tx", "tb_uart_tx", "{1'b1, data, 1'b0}", "{1'b0, data, 1'b0}"),
    ("uart_rx", "tb_uart_loop", "{rxs, sh[7:1]}", "{sh[6:0], rxs}"),
    ("uart_rx", "tb_uart_loop", "rxs ? IDLE : DATA", "DATA"),
    ("uart_rx", "tb_uart_loop", "idx == 3'd7", "idx == 3'd6"),
    ("uart_rx", "tb_uart_loop", "else frame_err <= 1'b1", "else frame_err <= 1'b0"),
]


def passes(tb, sources):
    with tempfile.TemporaryDirectory() as d:
        files = []
        for name, text in sources.items():
            p = pathlib.Path(d, name + ".v")
            p.write_text(text)
            files.append(str(p))
        out = pathlib.Path(d, "sim.vvp")
        subprocess.run(["iverilog", "-g2012", "-Wno-timescale", "-s", tb, "-o", str(out), *files,
                        str(ROOT / "tb" / (tb + ".v"))], check=True, capture_output=True)
        try:
            r = subprocess.run(["vvp", str(out)], capture_output=True, text=True, timeout=60)
        except subprocess.TimeoutExpired:
            return False
        return "PASS" in r.stdout and "FAIL" not in r.stdout


clean = {n: (ROOT / "rtl" / (n + ".v")).read_text() for n in RTL}
for tb in sorted({m[1] for m in MUTANTS}):
    if not passes(tb, clean):
        sys.exit(f"{tb} fails on the unmodified design")
caught = 0
for name, tb, old, new in MUTANTS:
    if clean[name].count(old) != 1:
        sys.exit(f"{name}: expected exactly one '{old}'")
    ok = not passes(tb, {**clean, name: clean[name].replace(old, new)})
    caught += ok
    print("caught  " if ok else "SURVIVED", f"{name}: {old} -> {new or '(removed)'}")
print(f"{caught} of {len(MUTANTS)} faults caught")
sys.exit(caught != len(MUTANTS))
