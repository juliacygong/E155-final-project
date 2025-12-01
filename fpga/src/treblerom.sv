// Treble clef ROM with memory initialization
// Stores a 40x80 pixel bitmap (3200 bits total)
module treblerom (input logic clk,
                  input logic [11:0] addr,  // 12 bits for 40*80 = 3200 addresses
                  output logic treble_out
);
    
    // Memory array for treble clef bitmap
    // 40 pixels wide x 80 pixels tall = 3200 bits
    logic [3199:0] clef_bitmap;
    
    // Initialize from file - create this file using the Python script
    initial begin
        $readmemb("treble_clef.mem", clef_bitmap);
    end
    
    // Pipeline registers for 2-cycle delay
    logic [11:0] addr_d1, addr_d2;
    
    always_ff @(posedge clk) begin
        addr_d1 <= addr;
        addr_d2 <= addr_d1;
    end
    
    // Output the bit at the addressed location
    assign treble_out = (addr_d2 < 3200) ? clef_bitmap[addr_d2] : 1'b0;
    
endmodule