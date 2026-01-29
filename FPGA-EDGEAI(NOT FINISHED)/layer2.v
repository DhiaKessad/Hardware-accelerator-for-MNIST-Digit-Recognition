`include "config.v"

module layer2 (
    input clk,
    input rst, 
    input active,
    input signed [`DataWidth-1:0] feature_in,
    input [6:0] addr, 
    output reg [`numNeuronLayer2 * 48 - 1 : 0] layer_out 
);
    wire [(`numNeuronLayer2 * `weightWidth)-1 : 0] wide_weight;
    reg signed [47:0] accumulators [0:`numNeuronLayer2-1]; 
    reg signed [`DataWidth-1:0] bias_mem [0:`numNeuronLayer2-1];

    weight_rom_layer2 weight_bram_inst (
        .clka(clk), .addra(addr), .wea(1'b0), .dina(1024'b0), .douta(wide_weight)
    );

    initial $readmemh("fc2_bias.hex", bias_mem);

    reg signed [`DataWidth-1:0] feature_delayed;
    always @(posedge clk) feature_delayed <= feature_in;

    integer n;
    always @(posedge clk) begin
        if (rst) begin
            for (n = 0; n < `numNeuronLayer2; n = n + 1)
                accumulators[n] <= bias_mem[n];
        end else if (active && addr <= 127) begin
            for (n = 0; n < `numNeuronLayer2; n = n + 1) begin
                accumulators[n] <= accumulators[n] + (feature_delayed * $signed(wide_weight[n*`weightWidth +: `weightWidth]));
            end
        end
    end

    integer k;
    always @(*) begin
        for (k = 0; k < `numNeuronLayer2; k = k + 1)
            layer_out[k*48 +: 48] = accumulators[k];
    end
endmodule