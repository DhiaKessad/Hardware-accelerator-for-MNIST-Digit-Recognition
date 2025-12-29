`include "config.v"

module layer2 (
    input clk,
    input rst, 
    input signed [`DataWidth-1:0] feature_in,
    input [6:0] addr, 
    output reg [`numNeuronLayer2 * 48 - 1 : 0] layer_out 
);

    reg signed [`weightWidth-1:0] weight_matrix [0:(`numWeightLayer2 * `numNeuronLayer2)-1]; // Weight matrix for Layer 1
    reg signed [48-1:0] accumulators [0:`numNeuronLayer2-1]; // Accumulators for each neuron
    reg signed [`DataWidth-1:0] bias_mem [0:`numNeuronLayer2-1];


    initial begin // Fixed: Wrapped in initial block
        $readmemh("weights/fc2_weight.hex", weight_matrix);
        $readmemh("weights/fc2_bias.hex", bias_mem);
    end

    integer n;
    always @(posedge clk) begin
        if (rst) begin
            for (n = 0; n < `numNeuronLayer2; n = n + 1) accumulators[n] <= bias_mem[n];;
        end else begin
            for (n = 0; n < `numNeuronLayer2; n = n + 1) begin
                accumulators[n] <= accumulators[n] + (feature_in * weight_matrix[(n * `numWeightLayer2) + addr]);
            end
        end
    end

    integer k;
    always @(*) begin
        for (k = 0; k < `numNeuronLayer2; k = k + 1) begin
            layer_out[k*48 +: 48] = accumulators[k];
        end
    end


endmodule