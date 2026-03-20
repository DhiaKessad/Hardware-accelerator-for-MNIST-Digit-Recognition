`include "config.v"

module top(
    input wire clkp,
    input wire clkn,
    input rst,
    output [3:0] digit_out,
    output wire LCD_RS_LS,
    output wire LCD_RW_LS,
    output wire LCD_E_LS,
    output wire [3:0] LCD_DB_LS
);
    wire [7:0] pixel_in;
    wire [`numNeuronLayer1 * `DataWidth - 1 : 0] l1_parallel_out; 
    wire [479 : 0] l2_raw_out; 
    reg signed [`DataWidth-1:0] l1_serialized_feature;
    wire clk, locked, system_reset, l2_en;
    
    reg [9:0] l1_addr;    
    reg [6:0] l2_addr;    
    reg active; 
    reg [3:0] final_digit;
    reg [15:0] time_counter; // Measures cycles spent in math

    assign system_reset = rst | ~locked;
    assign l2_en = (l1_addr == 783);

    my_clk_wiz clk_gen (
        .CLK_IN1_P(clkp), .CLK_IN1_N(clkn),
        .CLK_OUT1(clk), .RESET(rst), .LOCKED(locked)
    );

    image_rom test_img_inst (
        .clka(clk), .addra(l1_addr), .douta(pixel_in)
    );

    always @(posedge clk) begin
        if (system_reset) begin
            l1_addr <= 0;
            l2_addr <= 0;
            active  <= 1;
            time_counter <= 0;
        end else if (active) begin
            time_counter <= time_counter + 1;
            if (l1_addr < 783) 
                l1_addr <= l1_addr + 1;
            else if (l2_addr < 127)
                l2_addr <= l2_addr + 1;
            else
                active <= 0; 
        end
    end
    
    layer1 uut1 (
        .clk(clk), .rst(system_reset), .active(active),
        .pixel_in(pixel_in), .addr(l1_addr),
        .layer_out(l1_parallel_out)
    );

    always @(*) begin
        l1_serialized_feature = l1_parallel_out[l2_addr * `DataWidth +: `DataWidth];
    end

    layer2 uut2 (
        .clk(clk), .rst(system_reset), .active(active && l2_en),
        .feature_in(l1_serialized_feature), .addr(l2_addr),
        .layer_out(l2_raw_out)
    );

    integer i;
    reg signed [47:0] max_val;
    reg [3:0] moving_digit;
    always @(*) begin
        max_val = $signed(l2_raw_out[0 +: 48]);
        moving_digit = 0;
        for (i = 1; i < 10; i = i + 1) begin
            if ($signed(l2_raw_out[i*48 +: 48]) > max_val) begin
                max_val = l2_raw_out[i*48 +: 48];
                moving_digit = i[3:0];
            end
        end
    end 

    always @(posedge clk) begin
        if (system_reset) final_digit <= 0;
        else if (!active) final_digit <= moving_digit;
    end
    assign digit_out = final_digit;

    // LCD Controller Instance
    lcd_controller lcd_inst (
        .clk(clk), // 50MHz from wizard
        .rst(system_reset),
        .digit(final_digit),
        .cycles(time_counter),
        .LCD_RS(LCD_RS_LS),
        .LCD_RW(LCD_RW_LS),
        .LCD_E(LCD_E_LS),
        .LCD_DB(LCD_DB_LS)
    );

endmodule