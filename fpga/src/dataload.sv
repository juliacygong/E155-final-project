// Julia Gong
// 11/28/2025
// module that loads SPI data into a buffer

module dataload #(parameter SPI_WIDTH = 8, BIT_WIDTH = 16, N = 9)
                (input logic sclk, reset,
                 input logic buf_en_rd,
                 input [N - 1:0] buf_add_rd,
                 output logic [SPI_WIDTH -1:0] buf_dout);

// spi logic
logic cs, mosi, fft_start_posedge, miso, received_wd;
logic [SPI_WIDTH - 1:0] sample_in;

// buffer logic
logic buf_en_wr;
logic [SPI_WIDTH - 1:0] buf_din;
logic [N - 1:0] buf_add_wr; 

// instantiate SPI module
spi spi #(.SPI_WIDTH(SPI_WIDTH))
         (.sclk(sclk),
          .cs(cs),
          .mosi(mosi),
          .fft_start_posedge(fft_start_posedge),
          .miso(miso),
          .received_wd(received_wd),
          .sample_in(sample_in)); // input into buffer


ramdualpt spibuffer(.wr_clk_i(sclk), 
        .rd_clk_i(sclk), 
        .rst_i(~reset), 
        .wr_clk_en_i (1'b1), // rising edge active
        .rd_en_i(buf_en_rd), 
        .rd_clk_en_i(1'b1), // rising edge active
        .wr_en_i(buf_en_wr), 
        .wr_data_i(buf_din), 
        .wr_addr_i(buf_add_wr), 
        .rd_addr_i(buf_add_rd), 
        .rd_data_o(buf_dout));


always_ff @(posedge sclk) begin
    if (~reset) begin
        buf_add_wr <= 9'b0;
        buf_en_wr <= 0;
        buf_din <= 8'b0;
    end
    else if (received_wd) begin
        buf_en_wr <= 1'b1;
        buf_din <= sample_in;
        if (buf_add_wr == 9'd511) begin
            buf_add_wr <= 9'b0;
        end
        else begin
            buf_add_wr <= buf_add_wr + 1'b1;
        end
    end
    else begin
        buf_en_wr <= 0;
    end
end

endmodule