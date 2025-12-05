// Julia Gong E155
// seg_display.sv
// jgong@g.hmc.edu
// Date created: 8/28/25
// This module creates a 7 segment display that displays a hexidecimal digital that is described by s[3:0]

module seg_display(input logic [3:0] s,
				   output logic [6:0] seg
	);

always_comb 
		case(s) // seg abc_defg
			4'b0000: 		 seg = 7'b100_0000;
			4'b0001: 		 seg = 7'b111_1001;
			4'b0010: 		 seg = 7'b010_0100;
			4'b0011: 		 seg = 7'b011_0000;
			4'b0100: 		 seg = 7'b001_1001;
			4'b0101: 		 seg = 7'b001_0010;
			4'b0110: 		 seg = 7'b000_0010;
			4'b0111:		 seg = 7'b111_1000;
			4'b1000:		 seg = 7'b000_0000;
			4'b1001: 		 seg = 7'b001_1000;
			4'b1010: 		 seg = 7'b000_1000;
			4'b1011:		 seg = 7'b000_0011;
			4'b1100: 		 seg = 7'b100_0110;
			4'b1101: 		 seg = 7'b010_0001;
			4'b1110: 		 seg = 7'b000_0100;
			4'b1111: 		 seg = 7'b000_1110;
			default: 		 seg = 7'b111_1111; 
	endcase

endmodule