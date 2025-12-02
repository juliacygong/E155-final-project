// sharp symbol 
// 10 x 16

module sharp_rom (
    input logic clk,
    input logic [7:0] addr,
    output logic pixel_out
);

 logic rom [0:159];
    
    initial begin
        // Initialize all to 0
        for (int i = 0; i < 160; i++) begin
            rom[i] = 0;
        end
        
        // Sharp symbol: two vertical lines and two horizontal lines
        // Vertical lines at columns 3 and 6 (rows 0-15)
        for (int y = 0; y < 16; y++) begin
            rom[y * 10 + 3] = 1;
            rom[y * 10 + 6] = 1;
        end
        
        // Top horizontal line (slightly slanted): row 4-5
        // Row 4: columns 1-8
        for (int x = 1; x <= 8; x++) begin
            rom[4 * 10 + x] = 1;
        end
        // Row 5: columns 2-9
        for (int x = 2; x <= 9; x++) begin
            rom[5 * 10 + x] = 1;
        end
        
        // Bottom horizontal line (slightly slanted): row 10-11
        // Row 10: columns 0-7
        for (int x = 0; x <= 7; x++) begin
            rom[10 * 10 + x] = 1;
        end
        // Row 11: columns 1-8
        for (int x = 1; x <= 8; x++) begin
            rom[11 * 10 + x] = 1;
        end
    end
    
    always_ff @(posedge clk) begin
        pixel_out <= rom[addr];
    end

endmodule