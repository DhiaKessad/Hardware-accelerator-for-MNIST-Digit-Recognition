`include "config.v"

module layer1 (
    input clk,
    input rst, 
    input [`inputWidth-1:0] pixel_in, //Feeding one pixel at a time 
    input [9:0] addr, // Address to access weights (0 to 783 for 28x28 image)
    output reg [`numNeuronLayer1 * `DataWidth - 1 : 0] layer_out //Output Layer 1 
);

    reg signed [`weightWidth-1:0] weight_matrix [0:(`numWeightLayer1 * `numNeuronLayer1)-1]; // Weight matrix for Layer 1
    reg signed [`DataWidth-1:0] accumulators [0:`numNeuronLayer1-1]; // Accumulators for each neuron
    reg signed [`DataWidth-1:0] bias_mem [0:`numNeuronLayer1-1];
    initial begin
    $readmemh("fc1_weight.hex", weight_matrix);
    $readmemh("fc1_bias.hex", bias_mem);
    end
    integer n;
    always @(posedge clk)  begin
        if (rst) begin
            for (n = 0; n < `numNeuronLayer1; n = n + 1) begin
                accumulators[n] <= bias_mem[n];
            end
        end else begin
            for (n = 0; n < `numNeuronLayer1; n = n + 1) begin
                accumulators[n] <= accumulators[n] + ($signed({1'b0, pixel_in}) * weight_matrix[(n * `numWeightLayer1) + addr]);
            end
        end
    end

    integer k;
    always @(*) begin
        for (k = 0; k < `numNeuronLayer1; k = k + 1) begin
            if (accumulators[k][`DataWidth-1] == 1'b1)
                layer_out[k*`DataWidth +: `DataWidth] = 0;
            else
                layer_out[k*`DataWidth +: `DataWidth] = accumulators[k];
        end
    end

endmodule