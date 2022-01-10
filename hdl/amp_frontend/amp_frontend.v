//  O-Audio controller 
//  
//  Splits an audio single datastream to audio and controllogic 
//  Written by Jørgen Kragh Jakobsen, November 2021

module amp_frontend (
    `ifdef SIM
     //input clk,
    `endif
    input resetb, 
    
    input rx_in, 
    
    input nerror_in,
    input nclip_in,
    
    output i2s_bck, 
    output i2s_ws,
    output i2s_d0, 

    inout i2c_sda, 
    inout i2c_scl, 
   
    output rx_out,
    
    output nenable_out, 
    output nmute_out);  
    //output clk_out);

    /* synthesis GSR=“ENABLED” */;
    /*reg [24:0] rst_cnt = 25'h0;
    wire rst_n = rst_cnt[24];
    wire reset; 
    assign reset = ~rst_n;

    always @(posedge clk)
    if( !rst_n )
       rst_cnt <= rst_cnt + 25'h1;
    */ 

    // Clk system use internal 12.09 +/- 5% as ref to pll  
    wire clk ; 
    wire clk_osc ; 
    `ifndef FPGA 
       OSCH #(
         .NOM_FREQ("12.09")      //3.02
       ) int_clk (
         .STDBY(1'b0),
         .OSC(clk_osc)
       ); 
       GSR GSR_INST (.GSR(resetb));
       PUR #(.RST_PULSE(100)) int_pur (.PUR(resetb));
       
       pll_x4 pll (clk_osc, clk); 
    
    `endif  
    
    wire audio_locked;
    wire send_config;
    wire rx_out_tmp;

    spdif_decoder spdif(
      .clk_in(clk),
      .resetb(resetb),
      .rx_in(rx_in),
      .i2s_bck(i2s_bck_tmp),
      .i2s_ws(i2s_ws_tmp),
      .i2s_d0(i2s_d0_tmp),
      .edgedetect(rx_out_tmp)); 

    amp_i2s_interface i2s (
        .clk_in(clk),
        .resetb(resetb),
        .rx_in(rx_in),
        //.i2s_bck(i2s_bck_tmp),
        //.i2s_ws(i2s_ws_tmp),
        //.i2s_d0(i2s_d0_tmp),
        .audio_locked(audio_locked)); 

   // assign i2s_bck = clk;
    assign i2s_d0 = i2s_d0_tmp & nmute_out;
    assign i2s_ws = i2s_ws_tmp & nmute_out;
    assign i2s_bck = i2s_bck_tmp & nmute_out;
    
    assign rx_out = rx_out_tmp; 

    amp_state_control ctrl ( 
        .clk_in(clk),
        .resetb(resetb),
        .audio_locked_in(audio_locked),
        .nerror_in(nerror_in), 
        .nenable_out(nenable_out),
        .nmute_out(nmute_out),
        .send_config_out(send_config)); 
        
    amp_i2c_master i2c (
        .clk_in(clk),
        .resetb(resetb),
        .send_cfg(send_config),
        .sda(i2c_sda),
        .scl(i2c_scl)); 
    //assign nenable_out = send_config;  
endmodule