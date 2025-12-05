// Julia Gong
// 11/30/2025
// SPI module for FPGA.

module spi #(parameter SPI_WIDTH = 8)
            (input  logic clk,           // System Clock
             input  logic reset,         // Active HIGH reset
             input  logic sclk,
             input  logic cs,
             input  logic mosi,
             input  logic fft_start_posedge,
             output logic miso,
             output logic received_wd,
             output logic [SPI_WIDTH - 1:0] sample_in
            );

    // Synchronizers
    logic [2:0] sclk_sync;
    logic [1:0] cs_sync;
    logic [1:0] mosi_sync;
    
    always_ff @(posedge clk) begin
        if (reset) begin  // Active HIGH
            sclk_sync <= 3'b000;
            cs_sync   <= 2'b11;
            mosi_sync <= 2'b00;
        end else begin
            sclk_sync <= {sclk_sync[1:0], sclk};
            cs_sync   <= {cs_sync[0],     cs};
            mosi_sync <= {mosi_sync[0],   mosi};
        end
    end
    
    // Clean signals
    logic sclk_rise, sclk_fall;
    logic cs_active;
    logic mosi_clean;
    
    assign cs_active  = ~cs_sync[1];
    assign mosi_clean = mosi_sync[1];
    assign sclk_rise = (sclk_sync[1] && !sclk_sync[2]);
    assign sclk_fall = (!sclk_sync[1] && sclk_sync[2]);
    
    // Data shifting
    logic [2:0] bits_captured;
    logic [SPI_WIDTH-1:0] shift_reg;
    
    always_ff @(posedge clk) begin
        if (reset) begin
            bits_captured <= 3'd0;
            received_wd   <= 1'b0;
            sample_in     <= '0;
            shift_reg     <= '0;
        end else if (!cs_active) begin
            bits_captured <= 3'd0;
            received_wd   <= 1'b0;
        end else begin
            received_wd <= 1'b0;
            
            if (sclk_rise) begin
                shift_reg <= {shift_reg[SPI_WIDTH-2:0], mosi_clean};
                
                if (bits_captured == 3'd7) begin
                    bits_captured <= 3'd0;
                    received_wd <= 1'b1;
                    sample_in <= {shift_reg[SPI_WIDTH-2:0], mosi_clean};
                end else begin
                    bits_captured <= bits_captured + 3'd1;
                end
            end
        end
    end
    
    // MISO output
    always_ff @(posedge clk) begin
        if (reset || !cs_active) begin
            miso <= 1'b0;
        end else if (sclk_fall) begin
            miso <= fft_start_posedge;
        end
    end
    
endmodule