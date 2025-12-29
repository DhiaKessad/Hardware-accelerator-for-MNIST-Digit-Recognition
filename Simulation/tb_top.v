`timescale 1ns/1ps
`include "config.v"

module tb_top();
    reg clk, rst, l2_en;
    reg [7:0] image_mem [0:783];
    reg [9:0] l1_addr;
    reg [6:0] l2_addr;
    wire [3:0] final_digit;

    // Instantiate the FULL system
    top uut (
        .clk(clk),
        .rst(rst),
        .pixel_in(image_mem[l1_addr]),
        .l1_addr(l1_addr),
        .l2_addr(l2_addr),
        .l2_en(l2_en),
        .digit_out(final_digit)
    );

    always #2.5 clk = ~clk; // 200MHz

    initial begin
        // 1. Load data
        $readmemh("tests/image.hex", image_mem);
        clk = 0; rst = 1; l2_en = 0; l1_addr = 0; l2_addr = 0;
        
        $dumpfile("simulation_full.vcd");
        $dumpvars(0, tb_top);

        // 2. RUN LAYER 1 (784 cycles)
        #20 rst = 0;
        repeat (783) begin
            @(posedge clk);
            l1_addr <= l1_addr + 1;
        end
        @(posedge clk); 
        l1_addr <= 783; // Hold last pixel

        // 3. RUN LAYER 2 (128 cycles)
        // We tell the top module to start feeding L1 results to L2
        l2_en = 1; 
        repeat (127) begin
            @(posedge clk);
            l2_addr <= l2_addr + 1;
        end
        @(posedge clk);
        l2_addr <= 127;

        // 4. Final Result
        #100;
        $display("--------------------------------------");
        $display("THE NETWORK PREDICTS THE DIGIT IS: %d", final_digit);
        $display("--------------------------------------");
        $finish;
    end
endmodule