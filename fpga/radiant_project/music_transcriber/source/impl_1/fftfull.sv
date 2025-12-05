// Julia Gong
// 11/14/2025
// module that does the full calculation
// takes sampled inputs into fft module
// determines frequency from maximum magnitude of fft outputs
// decodes the note from frequency

module fftfull #(parameter BIT_WIDTH = 16, N = 9, FFT_SIZE = 512, FS = 48000)
                (input logic clk, reset,
				 input logic fft_load, fft_start,
				 input logic [7:0] din,
                 input logic [N - 1:0] add_rd,
                 output logic [7:0] note,
				  output logic fft_done, 
				  output logic fft_start_negedge
				  );
				 
// fft logic
logic [2*BIT_WIDTH - 1:0] dout;

// fftdec logic
logic [11:0] frequency;
logic  note_dec, note_dec_pre;

// fft calculation module
fft #(.BIT_WIDTH(BIT_WIDTH), .N(N), .FFT_SIZE(FFT_SIZE))
    fft(.clk(clk),
        .reset(reset),
        .fft_start(fft_start),
        .fft_load(fft_load),
        .add_rd(add_rd),
        .din(din),
        .dout(dout),
        .fft_done(fft_done),
		.fft_start_negedge(fft_start_negedge));

// fft decoding module
fftdec #(.BIT_WIDTH(BIT_WIDTH), .N(N), .FFT_SIZE(FFT_SIZE), .FS(FS))
    fftdec(.clk(clk),
           .reset(reset),
           .fft_result(dout),
		   .fft_done(fft_done),
           .frequency(frequency),
           .note_dec(note_dec),
		   .note_dec_pre(note_dec_pre));

// note decoding module
freqLUT #(.BIT_WIDTH(BIT_WIDTH))
    freqLUT(.frequency(frequency),
            .note(note));

endmodule