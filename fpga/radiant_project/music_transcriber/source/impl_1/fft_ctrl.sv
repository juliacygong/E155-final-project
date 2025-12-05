// Julia Gong
// 11/28/2025
// FFT control module, integrating fft and note duration

module fft_ctrl#(parameter BIT_WIDTH = 16, N = 9, FFT_SIZE = 512, FS = 5000)
            (input  logic       reset, clk,
             input  logic       spi_tran_done,
             input  logic [7:0] din_spi,
             output logic [7:0] note,
             output logic [3:0] note_dur,
             output logic       new_note, note_dec
            );
                
//////////////////////////////////////////
// reset synchronizer
//////////////////////////////////////////
// create a new signal 'rst_n' that is synchronized to 'clk'
logic rst_n;
logic rst_sync_1, rst_sync_2;

always_ff @(posedge clk or negedge reset) begin
    if (~reset) begin
        rst_sync_1 <= 1'b0;
        rst_sync_2 <= 1'b0;
    end else begin
        rst_sync_1 <= 1'b1;
        rst_sync_2 <= rst_sync_1;
    end
end
assign rst_n = rst_sync_2; // Use this signal for all logic below

//////////////////////////////////////////
// State Machine & Signals
//////////////////////////////////////////

typedef enum {
    S0_SPI_WAIT, 
    S1_FFT_LOAD, 
    S2_FFT_CALC 
} state_t;

state_t state;

logic [N-1:0] adr_ram; 
logic [N-1:0] adr_fft; 

logic       ram_wr_en;
logic [7:0] din_ram;
logic [7:0] din_fft;
logic       note_dec_pre;
logic [7:0] note_raw;
logic [8:0] note_cnt;
logic       fft_start_negedge;
logic       spi_byte_valid;
logic       fft_load, fft_start, fft_done;

// Delayed signals
logic fft_load_d1, fft_load_d2;
logic fft_start_d1, fft_start_d2;
logic [N-1:0] adr_fft_d1, adr_fft_d2;
logic [7:0] note_hold;
logic locked; 

//////////////////////////////////////////
// SPI signal timing
//////////////////////////////////////////

logic spi_done_sync1, spi_done_sync2, spi_done_sync3;

always_ff @(posedge clk) begin
    if (~rst_n) begin 
        spi_done_sync1 <= 0;
        spi_done_sync2 <= 0;
        spi_done_sync3 <= 0;
    end else begin
        spi_done_sync1 <= spi_tran_done;
        spi_done_sync2 <= spi_done_sync1; 
        spi_done_sync3 <= spi_done_sync2;
    end
end

assign spi_byte_valid = spi_done_sync2 && !spi_done_sync3;


//////////////////////////////////////////
// Flag Logic
//////////////////////////////////////////

always_ff @(posedge clk) begin
    if (~rst_n) begin // Use synchronized reset
        state <= S0_SPI_WAIT;
        adr_ram <= 0;
        adr_fft <= 0;
        fft_load <= 0;
        fft_start <= 0;
        ram_wr_en <= 0;
    end else begin
        ram_wr_en <= 0;
        case (state)
            S0_SPI_WAIT: begin  // waiting for SPI to transfer data into data RAM
                fft_start <= 0;
                fft_load <= 0;
                if (spi_byte_valid) begin
                    ram_wr_en <= 1;
                    din_ram <= {~din_spi[7], din_spi[6:0]};
                    if (adr_ram >= FFT_SIZE - 1) begin
                        adr_ram <= 0;
                        state <= S1_FFT_LOAD;
                    end else begin
                        adr_ram <= adr_ram + 9'b1;
                    end
                end
            end
            S1_FFT_LOAD: begin  // load SPI data into FFT
                fft_load <= 1;
                if (adr_fft >= FFT_SIZE - 1) begin
                    adr_fft <= 0;
                    fft_load <= 0;
                    fft_start <= 1;
                    state <= S2_FFT_CALC;
                end else begin
                    adr_fft <= adr_fft + 9'b1;
                end
            end
            S2_FFT_CALC: begin  // calculation of FFT
                if (note_dec) begin
                    fft_start <= 0;
                    state <= S0_SPI_WAIT;
                end else begin
                    fft_start <= 1;
                end
            end
            default: state <= S0_SPI_WAIT;
        endcase
    end
end
  

//////////////////////////////////////////
// RAM / FFT / Display / Duration
//////////////////////////////////////////
// RAM to store transfered SPI data
ramdp8b ram_databuf(.wr_clk_i(clk), .rd_clk_i(clk), .rst_i(~rst_n),
                    .wr_clk_en_i(rst_n), .rd_clk_en_i(rst_n),
                    .wr_en_i(ram_wr_en), .rd_en_i(fft_load), 
                    .wr_addr_i(adr_ram), 
                    .wr_data_i(din_ram), 
                    .rd_addr_i(adr_fft), 
                    .rd_data_o(din_fft));

// delay control signals to account for reading from SPI data ram
always_ff @(posedge clk) begin
    if (~rst_n) begin // <--- FIX
        fft_load_d1 <= 0;
        fft_start_d1 <= 0;
        fft_load_d2 <= 0;
        fft_start_d2 <= 0;
        adr_fft_d1 <= 0;
        adr_fft_d2 <= 0;
    end else begin
        fft_load_d1 <= fft_load;
        fft_start_d1 <= fft_start;
        fft_load_d2 <= fft_load_d1;
        fft_start_d2 <= fft_start_d1;
        adr_fft_d1 <= adr_fft;
        adr_fft_d2 <= adr_fft_d1;
    end
end

// FFT calculation module
fftfull #(BIT_WIDTH, N, FFT_SIZE, FS)
    fftfull(.clk(clk), .reset(rst_n),
            .fft_load(fft_load_d2), 
            .fft_start(fft_start_d2),
            .din(din_fft), 
            .add_rd(adr_fft_d2), 
            .note(note_raw),
            .fft_done(fft_done),
             .fft_start_negedge(fft_start_negedge));

// output note hold
always_ff @(posedge clk) begin
    if (~rst_n) begin // <--- FIX
        note_hold <= 8'd0;
        locked <= 1'b0;
    end else if (fft_load_d2) begin
        locked <= 1'b0;
    end else if (note_dec && !locked) begin
        note_hold <= note_raw;
        locked <= 1'b1; 
    end
end

assign note = note_hold;

// note duration calculation
notedur notedur(.clk(clk), .reset(rst_n),
                .note(note),
                .fft_start_negedge(fft_start_negedge), 
                .note_dur(note_dur),
                .new_note(new_note));

endmodule