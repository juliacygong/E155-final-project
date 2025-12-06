`timescale 1ns/1ps

module testbench_ctrlnew();

    // ------------------------------------------------------------
    // 1. Parameters & Signals
    // ------------------------------------------------------------
    parameter BIT_WIDTH = 16;
    parameter N = 9;
    parameter FFT_SIZE = 512;
    parameter FS = 5000;

    // Inputs to DUT
    logic reset;
    logic clk_in;        // 48 MHz Master Clock
    logic spi_tran_done; // Pulse from SPI module
    logic [7:0] din_spi; // Data from SPI module

    // Outputs from DUT
    logic [7:0] note;
    logic [3:0] note_dur;
    logic new_note;
    logic note_dec;

    // Testbench Variables
    integer i, frame;
    integer input_file;
    integer scan_res;
    logic [7:0] file_data [0:FFT_SIZE-1]; // Buffer to store file data

    // ------------------------------------------------------------
    // 2. DUT Instantiation
    // ------------------------------------------------------------
    fft_ctrl #(
        .BIT_WIDTH(BIT_WIDTH),
        .N(N),
        .FFT_SIZE(FFT_SIZE),
        .FS(FS)
    ) dut (
        .reset(reset),
        .clk_in(clk_in),
        .spi_tran_done(spi_tran_done),
        .din_spi(din_spi),
        .note(note),
        .note_dur(note_dur),
        .new_note(new_note),
        .note_dec(note_dec)
    );

    // ------------------------------------------------------------
    // 3. Clock Generation (48 MHz)
    // ------------------------------------------------------------
    // Period = ~20.83ns
    initial clk_in = 0;
    always #10.416 clk_in = ~clk_in;

    // ------------------------------------------------------------
    // 4. File Loading (Pre-load data)
    // ------------------------------------------------------------
    initial begin
        // Initialize buffer to 0
        for (i = 0; i < FFT_SIZE; i++) file_data[i] = 8'd0;

        // Open File
        input_file = $fopen("fft_inputsharp.txt", "r");
        if (input_file == 0) begin
            $display("Error: Could not open fft_inputsharp.txt. Using zeros.");
        end else begin
            i = 0;
            while (!$feof(input_file) && i < FFT_SIZE) begin
                scan_res = $fscanf(input_file, "%b\n", file_data[i]);
                i = i + 1;
            end
            $fclose(input_file);
            $display("File Loaded: %0d samples read.", i);
        end
    end

    // ------------------------------------------------------------
    // 5. SPI Simulation Task
    // ------------------------------------------------------------
    task send_spi_byte(input [7:0] data);
        begin
            din_spi = data;
            
            // Pulse High for 200ns (Guarantees 12MHz clock sees it)
            spi_tran_done = 1;
            #200; 
            
            // Pulse Low
            spi_tran_done = 0;
            
            // Wait to simulate transmission gap
            #1000; 
        end
    endtask

    // ------------------------------------------------------------
    // 6. Main Stimulus
    // ------------------------------------------------------------
    initial begin
        // Initialize
        reset = 0;
        spi_tran_done = 0;
        din_spi = 0;

        // Apply Reset
        $display("[%0t] System Reset", $time);
        #10000;
        reset = 1; // Release reset (Active Low)
        #100;

        $display("[%0t] Starting 11 Frame Burst (Holding Note)...", $time);

        // --- PHASE 1: PLAY NOTE (11 Frames) ---
        for (frame = 1; frame <= 11; frame = frame + 1) begin
            
            // Send Data
            for (i = 0; i < FFT_SIZE; i = i + 1) begin
                send_spi_byte(file_data[i]);
            end
            
            $display("[%0t] Frame %0d Data Sent. Processing...", $time, frame);

            // Wait for Processing to Finish
            wait(note_dec == 1);
            
            // Wait for note_dec to go low so we don't catch the same edge twice
            // (Since note_dec is a pulse, this usually happens naturally, 
            // but explicitly waiting for negedge is safer in loops)
            @(negedge note_dec);
            
            $display("[%0t] Frame %0d Complete. Current Note: %d", $time, frame, note);
            
            #5000; 
        end

        // --- PHASE 2: SILENCE (1 Frame) ---
        $display("========================================");
        $display(" ENDING NOTE (Sending Silence/Zeros)");
        $display("========================================");
		
		 for (frame = 1; frame <= 3; frame = frame + 1) begin
			 
			// Send 512 Zeros
			for (i = 0; i < FFT_SIZE; i = i + 1) begin
				send_spi_byte(8'd0);
			end

			$display("[%0t] Silence Frame Sent. Processing...", $time);

			// Wait for Processing
			wait(note_dec == 1);
			@(negedge note_dec);
			$display("[%0t] Frame %0d Complete. Current Note: %d", $time, frame, note);
            
            #5000; 
		end

        // --- CHECK RESULTS ---
        // At this exact moment, 'notedur' should have realized the note changed
        // from X to 0. It should pulse 'new_note'.
        
        #1000; // Wait a tiny bit for logic to propagate

        if (note == 0) 
            $display("SUCCESS: Note returned to 0 (Silence).");
        else 
            $display("FAILURE: Note is still %d (Expected 0).", note);

        // Note: In waveforms, check if 'new_note' pulsed high briefly right here.
        // Also check 'note_dur'. With 11 frames of holding, 
        // note_dur should output roughly 4'b0100 (Half Note) or 4'b1000 (Whole Note)
        // depending on your exact count ranges.

        $display("========================================");
        $display(" Simulation Completed.");
        $display("========================================");
        $stop;
    end

endmodule