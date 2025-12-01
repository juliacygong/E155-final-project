// vga module that connects music score and note + note duration logic

module fullmusicscore (input logic clk, reset, 
                       input logic [10:0] hcount, 
                       input logic [9:0] vcount, 
                       input logic active_video, 
                       input logic [7:0] note, 
                       input logic [3:0] duration, 
                       input logic note_dec, // pulses high for once cycle when note is detected might need to change if wrong signal
                       output logic pixel_out);

// parameters for music score and notes

// music score parameters
localparam STAFF_LINE_THICKNESS = 2;
localparam STAFF_LINE_SPACING = 10;
localparam NUM_SCORES = 4;
localparam SCORE_HEIGHT = 5 * (STAFF_LINE_SPACING + STAFF_LINE_THICKNESS);
localparam VERTICAL_MARGIN = 20;
// vertical spacing parameters
localparam TOTAL_CONTENT_HEIGHT = NUM_SCORES * SCORE_HEIGHT;
localparam SPACE_BETWEEN_SCORES = (480 - 2*VERTICAL_MARGIN - TOTAL_CONTENT_HEIGHT) / (NUM_SCORES - 1);

// treble clef parameters
localparam CLEF_START_X = 20;
localparam CLEF_WIDTH = 40;
localparam CLEF_HEIGHT = 80;

// note parameters
localparam NOTE_WIDTH = 20;
localparam NOTE_HEIGHT = 30;
localparam NOTE_SPACING = 40;
localparam NOTES_START_X = CLEF_START_X + CLEF_WIDTH + 20;

// sharp symbol parameters
localparam SHARP_WIDTH = 10;
localparam SHARP_HEIGHT = 16;
localparam SHARP_OFFSET_X = -12;  // Position sharp to the LEFT of note

// total number of notes
localparam MAX_NOTES = 64;

// 2 cycle delay for memory reads
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

// logic for note storage memory
logic [6:0] note_chromatic_pitch [0:MAX_NOTES-1];   // Chromatic pitch (0-127)
logic [3:0] note_duration [0:MAX_NOTES-1];          // Duration type
logic [10:0] note_x [0:MAX_NOTES-1];                // X position
logic [9:0] note_y [0:MAX_NOTES-1];                 // Y position
logic [1:0] note_staff [0:MAX_NOTES-1];             // Which staff (0-3)
logic note_is_sharp [0:MAX_NOTES-1];                // 1 if sharp, 0 if natural
logic note_stem_direction [0:MAX_NOTES-1];          // 0=stem up, 1=stem down
logic [5:0]  note_count;    

// logic for tracking position and score
logic [10:0] current_x_pos;
logic [1:0]  current_staff_num;

// decoding note by converting 8 bit note format to a chromatic pitch
// chomatic pitch = octave * 12 + semitone
// C=0, C#=1, D=2, D#=3, E=4, F=5, F#=6, G=7, G#=8, A=9, A#=10, B=11

logic [3:0] decoded_letter;
logic [2:0] decoded_octave;
logic decoded_sharp;
logic [3:0] semitone;
logic [6:0] chromatic_pitch;

always_comb begin
    decoded_letter = note[7:4];
    decoded_octave = note[3:1];
    decoded_sharp = note[0];
    case(decoded_letter)
        4'b1100: semitone = 0; // C
        4'b1101: semitone = 2; // D
        4'b1110: semitone = 4; // E
        4'b1111: semitone = 5; // F
        4'b1000: semitone = 7; // G
        4'b1010: semitone = 9; // A
        4'b1011: semitone = 11; // B
        default semitone = 0;
    endcase
    // calculating chromatic pitch
    chromatic_pitch = decoded_octave * 23 + semitone + decoded_sharp;
end

// calculate y position
// each semitone moves half of the staff line spacing
// vertical pixels on vga start at 0 and increase downward so higher notes have lower y position, and lower notes have higher y position
logic [9:0] calculated_y
logic [9:0] staff_base;
logic [9:0] B4_line_y;
logic signed [10:0] steps_from_B4;

always_comb begin
    // calculate y position base for current staff
    staff_base = VERTICAL_MARGIN + current_staff_num * (SCORE_HEIGHT + SPACE_BETWEEN_SCORES);

    // B4 is on middle line (line 3 of 5) ** DOUBLE CHECK THIS
    B4_line_y = staff_base + 4 * STAFF_LINE_SPACING;

    // calculate how many semitones current note is relative to B4
    // B4 is 59
    steps_from_B4 = chromatic_pitch - 59; 

    //since each semitone is a half step
    // if note is higher, you want to subtract to get a smaller y position
    // centers note
    calculated_y = B4_line_y - (steps_from_B4 * (STAFF_LINE_SPACING / 2)) - (NOTE_HEIGHT / 2);
end

// determining stem direction

logic calculated_stem_direction;
logic [9:0] middle_line_y;
logic [9:0] note_center_y;

always_comb begin
    // calculate middle line of the current staff
    // line 3 should be middle line
    middle_line_y = staff_base + 2 * STAFF_LINE_SPACING;

    // calculate vertical center of the note
    note_center_y = calculated_y + (NOTE_HEIGHT / 2);

    //determine stem direction
    // if note is at or above the middle line, the stem is pointing down
    // pointing upwards otherwise
    if (note_center_y <= middle_line_y) begin // center is higher so should be down
        calculated_stem_direction = 1'b1; // downwards
    end
    else begin
        calculated_stem_direction = 1'b0; // upwards
    end
end

// adding new notes, and storing when a new note valid is pulsed
always_ff @(posedge clk) begin
    if (~reset) begin
        note_count <= 0;
        current_x_pos <= NOTES_START_X;
        current_staff_num <= 0;
    end
    else if (note_valid && note_count < MAX_NOTES) begin // detecting valid notes
        // storing the chromatic pitch calculated earlier
        note_chromatic_pitch[note_count] <= chromatic_pitch;

        // store note duration
        note_duation[note_count] <= duration;

        // store x position
        note_x[note_count] <= current_x_pos;

        // store staff note is on
        note_staff[note_count] <= current_staff_num;

        // store y position
        note_y[note_count] <= calculated_y;

        // store flag for sharp
        note_is_sharp[note_count] <= decoded_sharp;

        // store stem direction
        note_stem_direction[note_count] <= calculated_stem_direction;

        // increment note counter
        note_count <= note_count + 1'b1;

        // increment x position to move to the next note
        current_x_pos <= current_x_pos + NOTE_SPACING;

        // check if staff is done to move onto next staff
        if (current_x_pos + NOTE_SPACE > 600) begin
            current_staff_num <= current+staff_num + 1;
            current_x_pos <= NOTES_START_X

        end
    end
end

// rendering music staff  
logic staff_pixel;

always_comb begin
    staff_pixel = 0;
    
    if (active_d2 && vcount_d2 >= VERTICAL_MARGIN) begin
        // Check each of the 4 staves
        for (int i = 0; i < NUM_SCORES; i++) begin
            logic [9:0] staff_base;
            logic [9:0] y_in_staff;
            
            staff_base = VERTICAL_MARGIN + i * (SCORE_HEIGHT + SPACE_BETWEEN_SCORES);
            
            if (vcount_d2 >= staff_base && vcount_d2 < (staff_base + SCORE_HEIGHT)) begin
                y_in_staff = vcount_d2 - staff_base;
                
                // Check if on one of the 5 staff lines
                for (int j = 0; j < 5; j++) begin
                    if (y_in_staff >= (j * STAFF_LINE_SPACING) && 
                        y_in_staff < (j * STAFF_LINE_SPACING + STAFF_LINE_THICKNESS)) begin
                        // Draw staff line but not over clef
                        if (hcount_d2 >= CLEF_START_X + CLEF_WIDTH) begin
                            staff_pixel = 1;
                        end
                    end
                end
            end
        end
    end
end

// rendering treble clef
logic [10:0] clef_addr; 
logic clef_pixel; 
logic in_clef_region;

always_comb begin
    in_clef_region = 0;
    clef_addr = 0;
    
    if (active_video) begin
        for (int i = 0; i < NUM_SCORES; i++) begin
            logic [9:0] staff_base;
            logic [5:0] clef_x, clef_y;
            
            staff_base = VERTICAL_MARGIN + i * (SCORE_HEIGHT + SPACE_BETWEEN_SCORES);
            
            if (hcount >= CLEF_START_X && hcount < (CLEF_START_X + CLEF_WIDTH) &&
                vcount >= (staff_base - 10) && vcount < (staff_base - 10 + CLEF_HEIGHT)) begin
                in_clef_region = 1;
                clef_x = hcount - CLEF_START_X;
                clef_y = vcount - (staff_base - 10);
                clef_addr = clef_y * CLEF_WIDTH + clef_x;
            end
        end
    end
end

// treble clef bit map
treblerom clef_rom (
    .clk(clk),
    .addr(clef_addr),
    .treble_out(clef_pixel)
);

// rendering notes
// drawing notes with both stem directions
logic notes_pixel;
logic [9:0] note_rom_addr;
// rom outputs for all notes
logic eighth_up_pixel, eighth_down_pixel;
logic quarter_up_pixel, quarter_down_pixel;
logic half_up_pixel, half_down_pixel;
logic whole_pixel;

// CREATE ROM modules for each
eighth_note_up_rom eup_rom (.clk(clk), .addr(note_rom_addr), .pixel_out(eighth_up_pixel));
eighth_note_down_rom edown_rom (.clk(clk), .addr(note_rom_addr), .pixel_out(eighth_down_pixel));

quarter_note_up_rom qup_rom (.clk(clk), .addr(note_rom_addr), .pixel_out(quarter_up_pixel));
quarter_note_down_rom qdown_rom (.clk(clk), .addr(note_rom_addr), .pixel_out(quarter_down_pixel));

half_note_up_rom hup_rom (.clk(clk), .addr(note_rom_addr), .pixel_out(half_up_pixel));
half_note_down_rom hdown_rom (.clk(clk), .addr(note_rom_addr), .pixel_out(half_down_pixel));

whole_note_rom w_rom (.clk(clk), .addr(note_rom_addr), .pixel_out(whole_pixel));

logic [4:0] x_offset, y_offset;

always_comb begin
    notes_pixel = 0;
    note_rom_addr = 0;

    // loop through all stored notes
    for (int i = 0; i < note_count; i++) begin
        
        // Check if current pixel is inside this note's bounding box
        if (hcount_d2 >= note_x[i] && 
            hcount_d2 < (note_x[i] + NOTE_WIDTH) &&
            vcount_d2 >= note_y[i] && 
            vcount_d2 < (note_y[i] + NOTE_HEIGHT)) begin
            
            // Calculate offset within note bitmap
            x_offset = hcount_d2 - note_x[i];
            y_offset = vcount_d2 - note_y[i];
            note_rom_addr = y_offset * NOTE_WIDTH + x_offset;
            
            // Read from appropriate ROM based on duration AND stem direction
            case (note_duration[i])
                4'b0001: begin  // Eighth note
                    if (note_stem_direction[i] == 0) begin
                        notes_pixel = notes_pixel | eighth_up_pixel;
                    end else begin
                        notes_pixel = notes_pixel | eighth_down_pixel;
                    end
                end
                
                4'b0010: begin  // Quarter note
                    if (note_stem_direction[i] == 0) begin
                        notes_pixel = notes_pixel | quarter_up_pixel;
                    end else begin
                        notes_pixel = notes_pixel | quarter_down_pixel;
                    end
                end
                
                4'b0100: begin  // Half note
                    if (note_stem_direction[i] == 0) begin
                        notes_pixel = notes_pixel | half_up_pixel;
                    end else begin
                        notes_pixel = notes_pixel | half_down_pixel;
                    end
                end
                
                4'b1000: begin  // Whole note 
                    notes_pixel = notes_pixel | whole_pixel;
                end
                
                default: begin  // Default to quarter note up
                    notes_pixel = notes_pixel | quarter_up_pixel;
                end
            endcase
        end
    end
end

// sharp rendering logic
logic sharp_pixel;
logic [7:0] sharp_rom_addr;
logic sharp_rom_output;
logic [10:0] sharp_x;
logic [9:0] sharp_y; 

sharp_rom sharp_rom_inst (
    .clk(clk),
    .addr(sharp_rom_addr),
    .pixel_out(sharp_rom_output)
);

always_comb begin
    sharp_pixel = 0;
    sharp_rom_addr = 0;
    // loop through notes to see sharp flag was triggered
    for (int i = 0; i < note_count; i ++) begin
        if (note_is_sharp[i]) begin
        sharp_x = note_x[i] + SHARP_OFFSET_X;
        sharp_y = note_y[i] + (NOTE_HEIGHT - SHARP_HEIGHT) / 2;

            // if pixel is inside sharp box
            if (hcount_d2 >= sharp_x && 
                hcount_d2 < (sharp_x + SHARP_WIDTH) &&
                vcount_d2 >= sharp_y && 
                vcount_d2 < (sharp_y + SHARP_HEIGHT)) begin
                
                logic [3:0] sharp_x_offset, sharp_y_offset;
                sharp_x_offset = hcount_d2 - sharp_x;
                sharp_y_offset = vcount_d2 - sharp_y;
                sharp_rom_addr = sharp_y_offset * SHARP_WIDTH + sharp_x_offset;
                
                sharp_pixel = sharp_pixel | sharp_rom_output;
            end
        end
    end
end

// logic for legder lines if notes are above or below the staff
logic ledger_pixel;
logic [9:0] staff_top, staff_bottom;
logic signed [10:0] steps_below, steps_above;
logic [9:0] ledger_y;

always_comb begin
    ledger_pixel = 0;
    for (int i = 0; i < note_count; i++) begin
            staff_top = staff_base;
            staff_bottom = staff_base + 4 * STAFF_LINE_SPACING;
            
            // Check if note is BELOW staff
            if ((note_y[i] + NOTE_HEIGHT/2) > staff_bottom) begin
                steps_below = ((note_y[i] + NOTE_HEIGHT/2) - staff_bottom) / (STAFF_LINE_SPACING / 2);
                
                // Draw ledger line for odd steps (on lines, not spaces)
                if (steps_below[0]) begin
                    ledger_y = staff_bottom + steps_below * (STAFF_LINE_SPACING / 2);
                    
                    if (vcount_d2 >= ledger_y && 
                        vcount_d2 < (ledger_y + STAFF_LINE_THICKNESS) &&
                        hcount_d2 >= (note_x[i] - 5) &&
                        hcount_d2 < (note_x[i] + NOTE_WIDTH + 5)) begin
                        ledger_pixel = 1;
                    end
                end
            end
            
            // Check if note is ABOVE staff
            if ((note_y[i] + NOTE_HEIGHT/2) < staff_top) begin
                steps_above = (staff_top - (note_y[i] + NOTE_HEIGHT/2)) / (STAFF_LINE_SPACING / 2);
                
                if (steps_above[0]) begin
                    ledger_y = staff_top - steps_above * (STAFF_LINE_SPACING / 2);
                    
                    if (vcount_d2 >= ledger_y && 
                        vcount_d2 < (ledger_y + STAFF_LINE_THICKNESS) &&
                        hcount_d2 >= (note_x[i] - 5) &&
                        hcount_d2 < (note_x[i] + NOTE_WIDTH + 5)) begin
                        ledger_pixel = 1;
                    end
                end
            end
        end
end

// pixel output to vga controller
always_comb begin
    if (hcount_d2 >= 620) begin // leaving a 20 pixel margin
        pixel_out = 0;
    end
    else begin
        pixel_out = staff_pixel | notes_pixel | sharp_pixel | (in_clef_region & clef_pixel) | ledger_pixel;
    end
end

endmodule