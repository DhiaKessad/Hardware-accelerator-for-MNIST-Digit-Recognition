`define pretrained  // To trigger the $readmemh
`define numLayers 3  // 3 layes in the MLP

`define DataWidth 32 // 32 bit for precision
`define weightWidth 8
`define inputWidth 8

// LAYER 1
`define numWeightLayer1 784 
`define numNeuronLayer1 128   //Check !
`define Layer1ActType "relu" 

// LAYER 2 
`define numWeightLayer2 128
`define numNeuronLayer2 10   //Check !
`define Layer2ActType "hardmax" 

`define weightIntWidth 1  // 1 bit for integer part