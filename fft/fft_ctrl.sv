// fft_control

module fft_ctrl#(parameter BIT_WIDTH = 16, N = 9, FFT_SIZE = 512, FS = 5000)
			    (input logic reset,
				 input logic A_note,
				 input logic [BIT_WIDTH - 1:0] din,
				 output logic anode1, anode2,
				 output logic [6:0] seg,
				 output logic sharp
				);
				
logic [23:0] counter;
logic [3:0] s, note_name, octave;
logic clk, select;

// Internal high-speed oscillator (freq = 48 MHz)
	HSOSC #(.CLKHF_DIV(2'b00)) 
	      hf_osc (.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk));
		  
// counter
always_ff @(posedge clk) begin
		if(~reset) counter <= 1'b0;
		else counter <= counter + 24'd28;
end

assign select = counter[23];

// s1 
mux mux(select, note_name, octave, s, anode1, anode2);

seg_display disp(s, seg);

logic fft_load, fft_start, fft_done;
logic [N - 1:0] add_rd;
logic [7:0] note;

assign note_name = note[7:4];
assign octave = {1'b0, note[3:1]};
assign sharp = note[0];

always_ff @(posedge clk) begin
	if (~reset) begin
		add_rd <= 0;
	end
	else if (add_rd >= (FFT_SIZE -1)) begin
		add_rd <= 0;
	end
	else if (fft_load | A_note) begin
		add_rd <= add_rd + 1'b1;
	end
	else begin
		add_rd <= add_rd;
	end
end

always_ff @(posedge clk) begin
	if (~reset | fft_done) begin
		fft_load <= 1;
		fft_start <= 0;
	end
	else if (add_rd >= (FFT_SIZE -1)) begin
		fft_load <= 0;
		fft_start <= 1;
	end
	else begin
		fft_load <= fft_load;
		fft_start <= fft_start;
	end
end

afourLUT afourLUT(add_rd, din_out);
				
fftfull #(BIT_WIDTH, N, FFT_SIZE, FS)
     fftfull(clk, reset,
			 fft_load, fft_start,
			 din_out, 
			 add_rd, 
			 note,
			 fft_done);

endmodule