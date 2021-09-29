SHELL := /bin/sh

ALL_OPCODES := opcodes-pseudo opcodes opcodes-rvc opcodes-rvc-pseudo opcodes-custom opcodes-ipu


inst.chisel: $(ALL_OPCODES) parse-opcodes
	cat opcodes opcodes-rvc opcodes-rvc-pseudo opcodes-custom opcodes-pseudo | ./parse-opcodes -chisel > $@

inst.go: opcodes opcodes-pseudo parse-opcodes
	cat opcodes opcodes-pseudo opcodes-pulp | ./parse-opcodes -go > $@

inst.c: opcodes opcodes-pseudo parse-opcodes
	cat opcodes opcodes-pseudo opcodes-rep opcodes-dma opcodes-pseudo opcodes-sflt opcodes-ipu | ./parse-opcodes -c > $@

inst.sv: opcodes opcodes-pseudo parse-opcodes
	cat opcodes opcodes-rvc opcodes-rvc-pseudo opcodes-pseudo opcodes-pulp opcodes-sflt opcodes-ipu | ./parse-opcodes -sv > $@

inst.py: opcodes opcodes-pseudo parse-opcodes
	cat opcodes opcodes-pseudo opcodes-pulp | ./parse-opcodes -py > $@

inst.rs: $(ALL_OPCODES) parse-opcodes
	cat opcodes opcodes-rvc opcodes-rvc-pseudo opcodes-pseudo opcodes-pulp opcodes-sflt | ./parse-opcodes -rust > $@
	rustfmt $@

inst.sverilog: opcodes opcodes-pseudo parse-opcodes opcodes-sflt opcodes-rep opcodes-dma
	cat opcodes opcodes-rvc opcodes-rvc-pseudo opcodes-rep opcodes-dma opcodes-pseudo opcodes-sflt opcodes-ipu | ./parse-opcodes -sverilog > $@

instr-table.tex: $(ALL_OPCODES) parse-opcodes
	cat opcodes opcodes-pseudo opcodes-pulp | ./parse-opcodes -tex > $@

priv-instr-table.tex: $(ALL_OPCODES) parse-opcodes
	cat opcodes opcodes-pseudo | ./parse-opcodes -privtex > $@
