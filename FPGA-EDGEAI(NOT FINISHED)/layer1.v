`include "config.v"

module layer1 (
    input clk,
    input rst, 
    input active,
    input [`inputWidth-1:0] pixel_in, 
    input [9:0] addr, 
    output reg [`numNeuronLayer1 * `DataWidth - 1 : 0] layer_out 
);
    wire [(`numNeuronLayer1 * `weightWidth)-1 : 0] wide_weight;
    reg signed [`DataWidth-1:0] accumulators [0:`numNeuronLayer1-1]; 
    reg signed [`DataWidth-1:0] bias_mem [0:`numNeuronLayer1-1];

    weight_rom_layer1 weight_bram_inst (
        .clka(clk), .addra(addr), .wea(1'b0), .dina(1024'b0), .douta(wide_weight)
    );

    initial $readmemh("fc1_bias.hex", bias_mem);

    reg [7:0] pixel_delayed;
    always @(posedge clk) pixel_delayed <= pixel_in;

    integer n;
    always @(posedge clk)  begin
        if (rst) begin
            for (n = 0; n < `numNeuronLayer1; n = n + 1)
                accumulators[n] <= bias_mem[n];
        end else if (active && addr <= 783) begin
            for (n = 0; n < `numNeuronLayer1; n = n + 1) begin
               accumulators[n] <= accumulators[n] + ($signed({1'b0, pixel_delayed}) * $signed(wide_weight[n*`weightWidth +: `weightWidth]));
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