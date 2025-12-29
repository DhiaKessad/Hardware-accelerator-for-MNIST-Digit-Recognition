//========================================
//Project: Hardware Accelerated Neural Network for 28x28 MNIST MLP
//GitHub: DhiaKessad
//========================================

`include "config.v"

module top(
    input wire clk,
    input rst,
    input [7:0] pixel_in,
    input [9:0] l1_addr,    // 0-783
    input [6:0] l2_addr,    // 0-127
    input l2_en,
    output reg [3:0] digit_out,
    output [479:0] final_out
);
    wire [`numNeuronLayer1 * `DataWidth - 1 : 0] l1_parallel_out; // 1D array for simplicity in serialization
    wire [479 : 0] l2_raw_out; // serial
    reg signed [`DataWidth-1:0] l1_serialized_feature;
    assign final_out = l2_raw_out;


//========================================
//28*28=784 pixels input to the 128 neuron layer 1 (total 28*28*784 weight)
//========================================

    layer1 uut1 (
        .clk(clk),
        .rst(rst),
        .pixel_in(pixel_in),
        .addr(l1_addr),
        .layer_out(l1_parallel_out)
    );

    //FSM: 32 bit output to 48 bit for layer 2
    always @(*) begin
        l1_serialized_feature = l1_parallel_out[l2_addr * `DataWidth +: `DataWidth];
    end

//========================================
//10 output neuron with 128 input for each
//========================================

    layer2 uut2 (
        .clk(clk),
        .rst(rst | !l2_en),
        .feature_in(l1_serialized_feature),
        .addr(l2_addr),
        .layer_out(l2_raw_out)
    );

    // Finding the neuron with the biggest value: The prediction of the model
    integer i;
    reg signed [47:0] max_val;
    always @(*) begin
        max_val = $signed(l2_raw_out[0 +: 48]);
        digit_out = 0;
        for (i = 1; i < 10; i = i + 1) begin
            if ($signed(l2_raw_out[i*48 +: 48]) > max_val) begin
                max_val = l2_raw_out[i*48 +: 48];
                digit_out = i;
            end
        end
    end

endmodule