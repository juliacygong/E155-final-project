// Julia Gong
// 11/10/2025
// spi interface to communicate between FPGA and MCU

module spi #(parameter SPI_WIDTH = 8)
        (input logic sclk,
         input logic cs, // active low
         input logic mosi,
         output logic miso,
         output logic received_wd, // goes high when word is received
         output logic [SPI_WIDTH - 1:0] sample_in // input data for fft , only 16 bit real
        ); 

// for MISO transaction
logic [SPI_WIDTH - 1:0] data_captured; // 8 bits to acomodate for MOSI bit
logic [3:0] bits_captured; // indicates number of bits captured, used to check for 8


// SPI mode is set as cpol = 0 and cpha = 0
// SDI data sampled on first edge (rising edge)
always_ff @(posedge sclk)
    if (cs) bits_captured <= 0
            ;
    else begin
        bits_captured <= bits_captured + 1'b1;
        data_captured <= {data_captured[SPI_WIDTH - 1:0], mosi}; // shifts input, starting from the left, into data captured on every clk
            if (bits_captured == 4'd7) begin // captures 32 bits
                received_wd <= 1'b1; // received 2 bytes
                sample_in <= data_captured[SPI_WIDTH - 1: 0]; // only shift in data, leaving out MOSI bit
            end
            else begin
            // still receiving 2 bytes
                received_wd <= 0;
            end
    end
        
// SDO data output/change on falling edge
// only begin sending data when 
always_ff @(negedge sclk)
    if (cs) begin
        miso <= 0;
    end
    else if (play_back) begin
        miso <= data_sent[2*BIT_WIDTH - 1]; // send 1 bit at a time starting with MSB
        data_sent <= {data_sent[2*BIT_WIDTH - 2:0], 1'b0}; // shifting data every clock cycle to send
    end

endmodule
