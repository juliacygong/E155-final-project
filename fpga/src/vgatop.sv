// Julia Gong
// 11/29/2025
// top module for vga music score control

module vgatop (input  logic reset, clk_in,
               input  logic [7:0] note, // letter(4b)_octave(3b)_sharp/flat/normal(1b)
               input  logic [3:0] duration,
			   input  logic       new_note,
               output logic      hsync, 
               output logic      vsync, 
               output logic [2:0] vga_rgb);

// note duration
// Sampling at 5Khz for 512 samples is 0.1024s

// 8th note (0.25s) 0b0001
// 2-3 samples

// Quarter note (0.5) 0b0010
// 4-6 samples

// Half note (1s) 0b0100
// 9-12 samples

// Whole note (2s) 0b1000
// 19-22

// vga controller logic
logic [10:0] hcount;
logic [9:0] vcount;
logic active_video;

// Synchronizer Chain
logic [7:0] note1, note2, note3, note4;
logic [3:0] duration1, duration2, duration3;
logic new_note1, new_note2, new_note3;

// pll clock logic
logic pll_clk_internal, pll_lock;

// music score rendering signals
logic score_pixel;

// generating 25MHz for VGA
pllclk  #(.DIVR("2"),
		        .DIVF("24"),
		        .DIVQ("2")) 
    pllclk (.rst_n(reset), .clk_ref(clk_in),
            .clk_internal(pll_clk_internal),
            .locked(pll_lock));

// VGA control module
vgactrl vgactrl (.clk(pll_clk_internal),
                 .reset(reset & pll_lock),
                 .hsync(hsync),
                 .vsync(vsync),
                 .hcount(hcount),
                 .vcount(vcount),
                 .active_video(active_video));

// VGA music score display
musicscore score (.clk(pll_clk_internal),
                   .reset(reset & pll_lock),
                   .hcount(hcount),
                   .vcount(vcount),
                   .active_video(active_video),
                   .note(note4),
				    .duration(duration3),
					.note_dec(new_note3),
                   .pixel_out(score_pixel));
				   
// VGA input synchronization, minimize clock skew
always_ff @(posedge pll_clk_internal) begin
        note1 <= note;
        note2 <= note1;
		note3 <= note2;
		note4 <= note3;
		duration1 <= duration;
		duration2 <= duration1;
		duration3 <= duration2;
		new_note1 <= new_note;
		new_note2 <= new_note1;
		new_note3 <= new_note2;
    end

// RGB output white background and black drawings
assign vga_rgb = (active_video && ~score_pixel) ? 3'b111 : 3'b000;

endmodule