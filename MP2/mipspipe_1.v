// Incomplete behavioral model of MIPS pipeline

module mipspipe(clock);
   // in_out
   input clock;

   // Instruction opcodes
   parameter ADD = 6'b100000, OR = 6'b100101, LW = 6'b100011, SW = 6'b101011, BEQ = 6'b000100, nop = 32'b00000_100000, ALUop = 6'b0; // Code Modified
   reg [31:0] PC, // Program counter
		  Regs[0:31],  // Register file
			  IMemory[0:1023], DMemory[0:1023], // Instruction and data memories
              IFIDIR, IDEXA, IDEXB, IDEXIR, EXMEMIR, EXMEMB, // pipeline latches
              EXMEMALUOut, MEMWBValue, MEMWBIR; // pipeline latches

   wire [4:0] IDEXrs, IDEXrt, EXMEMrd, MEMWBrd, MEMWBrt; // fields of pipeline latches
   wire [5:0] EXMEMop, MEMWBop, IDEXop; // opcodes
   wire [31:0] Ain, Bin; // ALU inputs

   // Define fields of pipeline latches
   assign IDEXrs = IDEXIR[25:21]; // rs field
   assign IDEXrt = IDEXIR[20:16]; // rt field
   assign EXMEMrd = EXMEMIR[15:11]; // rd field
   assign MEMWBrd = MEMWBIR[15:11]; // rd field
   assign MEMWBrt = MEMWBIR[20:16]; // rt field -- for loads
   assign EXMEMop = EXMEMIR[31:26]; // opcode
   assign MEMWBop = MEMWBIR[31:26]; // opcode
   assign IDEXop = IDEXIR[31:26]; // opcode

   // Inputs to the ALU come directly from the ID/EX pipeline latches
   assign Ain = IDEXA;
   assign Bin = IDEXB;
   reg [5:0] i; //used to initialize registers
   reg [10:0] j,k; //used to initialize registers

   initial begin
      PC = 0;
      IFIDIR = nop;
      IDEXIR = nop;
      EXMEMIR = nop;
      MEMWBIR = nop; // no-ops placed in pipeline latches
      // test some instructions
	// R-format: op|rs|rt|rd|shmat|func
	// I-format: op|rs|rt|address
      /*
	      add $5,$2,$1 -> 32'b000000|00010|00001|00101|00000|100000
	      IMemory[0] = 32'h00412820

	      lw $3,4($5) -> 32'b100011|00101|00011|0000000000000100
	      IMemory[1] = 32'h8ca30004;

	      lw $2,0($2) -> 32'b100011|00010|00010|0000000000000000
	      IMemory[2] = 32'h8c420000;

	      or $3,$5,$3 -> 32'b000000|00101|00011|00011|00000|100101
	      IMemory[3] = 32'h00a31825;

	      sw $3,0($5) -> 32'b101011|00101|00011|000000000000000
	      IMemory[4] = 32'haca30000;
	      for (j=5;j<=1023;j=j+1) IMemory[j] = nop;
      */
      for (i=0;i<=31;i=i+1) Regs[i] = i; // initialize registers
        /*
	IMemory[0] = 32'h8c210003;
        IMemory[1] = 32'hac020000;
        IMemory[2] = 32'h00642820;
	*/
	// Code Modified
      IMemory[0] = 32'h00412820;//add $5,$2,$1
      IMemory[1] = nop;//insert bubble
      IMemory[2] = nop;//insert bubble
      IMemory[3] = 32'h8ca30004;//lw $3,4($5)
      IMemory[4] = 32'h8c420000;//lw $2,0($2)
      IMemory[5] = nop;//lw $2,0($2) has taken 1 lie, so only need 1 bubble here
      IMemory[6] = 32'h00a31825;//or $3,$5,$3
      IMemory[7] = nop;// insert bubble
      IMemory[8] = nop;// insert bubble
      IMemory[9] = 32'haca30000;//sw $3,0($5)
      for (j=10;j<=1023;j=j+1) IMemory[j] = nop;
      //DMemory[0] = 32'h00000000;
      //DMemory[1] = 32'hffffffff;
	// Code Modified
      for (k=0;k<=1023;k=k+1) DMemory[k] = 0;
      DMemory[2] = 32'hfffffff0; //0($2):32'hfffffff0
      DMemory[5] = 32'hffffffff; //4($5):32'hffffffff
   end

   always @ (posedge clock)
   begin
      // FETCH: Fetch instruction & update PC
      IFIDIR <= IMemory[PC>>2];
	  PC <= PC + 4;

      // DECODE: Read registers
      IDEXA <= Regs[IFIDIR[25:21]];
      IDEXB <= Regs[IFIDIR[20:16]]; // get two registers

	  IDEXIR <= IFIDIR; // pass along IR

      // EX: Address calculation or ALU operation
      if ((IDEXop==LW) |(IDEXop==SW)) // address calculation
         EXMEMALUOut <= IDEXA +{{16{IDEXIR[15]}}, IDEXIR[15:0]};
      else if (IDEXop==ALUop) begin // ALU operation
         case (IDEXIR[5:0]) // R-type instruction
           32: EXMEMALUOut <= Ain + Bin; // add operation
	   37: EXMEMALUOut <= Ain | Bin; // or operation, Code Modified
           default: ; // other R-type operations [to be implemented]
         endcase
      end

      EXMEMIR <= IDEXIR; EXMEMB <= IDEXB; //pass along the IR & B

      // MEM
      if (EXMEMop==ALUop) MEMWBValue <= EXMEMALUOut; //pass along ALU result
      else if (EXMEMop == LW) MEMWBValue <= DMemory[EXMEMALUOut>>2]; // load
      else if (EXMEMop == SW) DMemory[EXMEMALUOut>>2] <=EXMEMB; // store

      MEMWBIR <= EXMEMIR; //pass along IR

      // WB
      if ((MEMWBop==ALUop) & (MEMWBrd != 0)) // update registers if ALU operation and destination not 0
		Regs[MEMWBrd] <= MEMWBValue; // ALU operation
      else if ((MEMWBop == LW)& (MEMWBrt != 0)) // Update registers if load and destination not 0
		Regs[MEMWBrt] <= MEMWBValue;
    end

endmodule
