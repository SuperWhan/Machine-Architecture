# Machine-Architecture
Some Machine architecture design problems

# Method:
	Design pipeline, ALU to solving the data hazard, control hazard, load stalls, forwarding etc.
# Applied stills:
	verilog, pipeline design, different hazard solutions, lab report.
# Hardest part:
	When doing the different stage's forwarding, different forwarding will need different condition
check, and different value accessed. For example, if forwarding from ID/EX to EX/MEM for R-type instructions, then do not need
to calculate the memory address for the data. but for I-type instructions, like load and read, it is neccessary to get into MEM/WB
and get the memory address.
