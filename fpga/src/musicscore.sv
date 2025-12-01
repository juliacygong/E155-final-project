// Music score rendering module
module musicscore (input logic clk,
                   input logic reset,
                   input logic [10:0] hcount,
                   input logic [9:0] vcount,
                   input logic active_video,
                   input logic [7:0] note,
                   input logic [3:0] duration, 
                   input logic note_dec, // need a signal to indicate note valid for note value and duration might need to change signal later
                   output logic pixel_out);

    // Score layout parameters
    localparam STAFF_LINE_THICKNESS = 2;
    localparam STAFF_LINE_SPACING = 10;  // pixels between staff lines
    localparam NUM_SCORES = 4;
    localparam SCORE_HEIGHT = 5 * (STAFF_LINE_SPACING + STAFF_LINE_THICKNESS);
    localparam VERTICAL_MARGIN = 20;
    
    // Calculate spacing for 4 scores
    localparam TOTAL_CONTENT_HEIGHT = NUM_SCORES * SCORE_HEIGHT;
    localparam SPACE_BETWEEN_SCORES = (480 - 2*VERTICAL_MARGIN - TOTAL_CONTENT_HEIGHT) / (NUM_SCORES - 1);
    
    // Treble clef position and size
    localparam CLEF_START_X = 20;
    localparam CLEF_WIDTH = 40;
    localparam CLEF_HEIGHT = 80;
    
    // Pipeline stages for 2-cycle memory delay
    logic [10:0] hcount_d1, hcount_d2;
    logic [9:0] vcount_d1, vcount_d2;
    logic active_d1, active_d2;
    
    always_ff @(posedge clk) begin
        if (~reset) begin
            hcount_d1 <= 0;
            hcount_d2 <= 0;
            vcount_d1 <= 0;
            vcount_d2 <= 0;
            active_d1 <= 0;
            active_d2 <= 0;
        end else begin
            hcount_d1 <= hcount;
            hcount_d2 <= hcount_d1;
            vcount_d1 <= vcount;
            vcount_d2 <= vcount_d1;
            active_d1 <= active_video;
            active_d2 <= active_d1;
        end
    end
    
    // Staff line rendering
    logic staff_pixel;
    logic [1:0] current_score;
    logic [9:0] score_base_y;
    logic [9:0] y_in_score;
    logic [3:0] line_num;
    logic on_staff_line;
    
    always_comb begin
        staff_pixel = 0;
        current_score = 0;
        score_base_y = 0;
        y_in_score = 0;
        line_num = 0;
        on_staff_line = 0;
        
        if (active_d2 && vcount_d2 >= VERTICAL_MARGIN) begin
            // Determine which score we're in
            for (int i = 0; i < NUM_SCORES; i++) begin
                score_base_y = VERTICAL_MARGIN + i * (SCORE_HEIGHT + SPACE_BETWEEN_SCORES);
                if (vcount_d2 >= score_base_y && vcount_d2 < (score_base_y + SCORE_HEIGHT)) begin
                    current_score = i;
                    y_in_score = vcount_d2 - score_base_y;
                    
                    // Check if on a staff line (5 lines)
                    for (int j = 0; j < 5; j++) begin
                        if (y_in_score >= (j * STAFF_LINE_SPACING) && 
                            y_in_score < (j * STAFF_LINE_SPACING + STAFF_LINE_THICKNESS)) begin
                            on_staff_line = 1;
                        end
                    end
                    
                    if (on_staff_line && hcount_d2 >= CLEF_START_X + CLEF_WIDTH) begin
                        staff_pixel = 1;
                    end
                end
            end
        end
    end
    
    // Treble clef ROM interface
    logic [10:0] clef_addr;
    logic clef_pixel;
    logic in_clef_region;
    logic [5:0] clef_x, clef_y;
    
    always_comb begin
        in_clef_region = 0;
        clef_x = 0;
        clef_y = 0;
        clef_addr = 0;
        
        if (active_video) begin
            for (int i = 0; i < NUM_SCORES; i++) begin
                score_base_y = VERTICAL_MARGIN + i * (SCORE_HEIGHT + SPACE_BETWEEN_SCORES);
                
                if (hcount >= CLEF_START_X && hcount < (CLEF_START_X + CLEF_WIDTH) &&
                    vcount >= (score_base_y - 10) && vcount < (score_base_y - 10 + CLEF_HEIGHT)) begin
                    in_clef_region = 1;
                    clef_x = hcount - CLEF_START_X;
                    clef_y = vcount - (score_base_y - 10);
                    clef_addr = clef_y * CLEF_WIDTH + clef_x;
                end
            end
        end
    end
    
    // load bit map
    treblerom clef_rom (
        .clk(clk),
        .addr(clef_addr),
        .treble_out(clef_pixel)
    );
    
    // Combine all pixels
    always_comb begin
        if (hcount_d2 >= 620) begin
            pixel_out = 1'b0;
        end
        else begin
            pixel_out = staff_pixel || (in_clef_region && clef_pixel);
        end
    end

endmodule