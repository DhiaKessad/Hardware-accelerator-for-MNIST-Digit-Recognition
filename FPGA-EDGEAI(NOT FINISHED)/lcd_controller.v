module lcd_controller (
    input  wire clk,
    input  wire rst,
    input  wire [3:0] digit,
    input  wire [15:0] cycles,
    output reg  LCD_RS,
    output wire LCD_RW,
    output reg  LCD_E,
    output reg  [3:0] LCD_DB
);
    assign LCD_RW = 1'b0;

    // Timer for 1ms at 50MHz
    reg [15:0] timer = 0;
    reg ms_tick = 0;
    always @(posedge clk) begin
        if (timer == 50000) begin timer <= 0; ms_tick <= 1; end
        else begin timer <= timer + 1; ms_tick <= 0; end
    end

    reg [7:0] state = 0;
    reg [7:0] wait_cnt = 0;
    reg [4:0] char_idx = 0;
    reg [7:0] current_byte = 0;
    reg [7:0] next_state = 0;

    // Standard ASCII Logic
    wire [7:0] digit_ascii = (digit < 10) ? (8'h30 + digit) : (8'h37 + digit);
    
    // Hex conversion for cycles
    wire [7:0] hex0 = (cycles[3:0]   < 10) ? (8'h30 + cycles[3:0])   : (8'h37 + cycles[3:0]);
    wire [7:0] hex1 = (cycles[7:4]   < 10) ? (8'h30 + cycles[7:4])   : (8'h37 + cycles[7:4]);
    wire [7:0] hex2 = (cycles[11:8]  < 10) ? (8'h30 + cycles[11:8])  : (8'h37 + cycles[11:8]);
    wire [7:0] hex3 = (cycles[15:12] < 10) ? (8'h30 + cycles[15:12]) : (8'h37 + cycles[15:12]);

    always @(posedge clk) begin
        if (rst) begin
            state <= 0;
            wait_cnt <= 0;
            char_idx <= 0;
        end else if (ms_tick) begin
            case (state)
                0: if (wait_cnt < 20) wait_cnt <= wait_cnt + 1; else begin state <= 10; wait_cnt <= 0; end
                
                // Initialization Sequence (4-bit mode)
                10: begin LCD_RS <= 0; LCD_DB <= 4'h3; LCD_E <= 1; state <= 11; end
                11: begin LCD_E <= 0; state <= 12; end
                12: if (wait_cnt < 5) wait_cnt <= wait_cnt + 1; else begin state <= 13; wait_cnt <= 0; end
                13: begin LCD_DB <= 4'h3; LCD_E <= 1; state <= 14; end
                14: begin LCD_E <= 0; state <= 15; end
                15: if (wait_cnt < 1) wait_cnt <= wait_cnt + 1; else begin state <= 16; wait_cnt <= 0; end
                16: begin LCD_DB <= 4'h3; LCD_E <= 1; state <= 17; end
                17: begin LCD_E <= 0; state <= 18; end
                18: begin LCD_DB <= 4'h2; LCD_E <= 1; state <= 19; end
                19: begin LCD_E <= 0; state <= 20; end
                
                // Setup Commands
                20: begin current_byte <= 8'h28; state <= 100; next_state <= 21; end
                21: begin current_byte <= 8'h0C; state <= 100; next_state <= 22; end
                22: begin current_byte <= 8'h06; state <= 100; next_state <= 23; end
                23: begin current_byte <= 8'h01; state <= 100; next_state <= 24; end
                24: if (wait_cnt < 2) wait_cnt <= wait_cnt + 1; else begin state <= 30; wait_cnt <= 0; end

                // Line 1: "Digit: X"
                30: begin 
                    LCD_RS <= 1; 
                    case(char_idx)
                        0:  current_byte <= "D"; 1:  current_byte <= "i";
                        2:  current_byte <= "g"; 3:  current_byte <= "i";
                        4:  current_byte <= "t"; 5:  current_byte <= ":";
                        6:  current_byte <= " "; 7:  current_byte <= digit_ascii;
                        default: current_byte <= " ";
                    endcase
                    if (char_idx < 8) begin char_idx <= char_idx + 1; state <= 100; next_state <= 30; end
                    else begin state <= 40; char_idx <= 0; end
                end

                // Move to Line 2
                40: begin LCD_RS <= 0; current_byte <= 8'hC0; state <= 100; next_state <= 41; end

                // Line 2: "Time: XXXX cyc"
                41: begin 
                    LCD_RS <= 1;
                    case(char_idx)
                        0:  current_byte <= "T"; 1:  current_byte <= "i";
                        2:  current_byte <= "m"; 3:  current_byte <= "e";
                        4:  current_byte <= ":"; 5:  current_byte <= hex3;
                        6:  current_byte <= hex2; 7: current_byte <= hex1;
                        8:  current_byte <= hex0; 9: current_byte <= " ";
                        10: current_byte <= "c"; 11: current_byte <= "y";
                        12: current_byte <= "c";
                        default: current_byte <= " ";
                    endcase
                    if (char_idx < 13) begin char_idx <= char_idx + 1; state <= 100; next_state <= 41; end
                    else state <= 50;
                end
                
                50: state <= 50; // Done

                // Subroutine: send byte (2 nibbles)
                100: begin LCD_DB <= current_byte[7:4]; LCD_E <= 1; state <= 101; end
                101: begin LCD_E <= 0; state <= 102; end
                102: begin LCD_DB <= current_byte[3:0]; LCD_E <= 1; state <= 103; end
                103: begin LCD_E <= 0; state <= next_state; end
                default: state <= 0;
            endcase
        end
    end
endmodule