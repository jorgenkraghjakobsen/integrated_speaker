module spdif_decoder ( input clk,
    input resetb, 
    input rx_in,
    output i2s_bck, 
    output i2s_ws, 
    output i2s_d0,
    output audio_locked,
    output rxup,
    output rxdown   
);


  reg [15:0] correlator; 

  always @(posedge clk, negedge resetb) 
  begin  
    if (resetb == 0)
      correlator <= 16'h00; 
    else 
      correlator <= {correlator[15:1], rx_in};
  end     
  
  assign rxup   = rxedge & correlator[1];           // 100000
  assign rxdown = rxedge & !correlator[1];          // 011111 xxx not sign
  
  assign rxedge = (correlator[2] ^ correlator[1]);  // 100000 or 011111 

  
  // Measure length between edge and store length and bitvalue 
  // local variables 
  
  reg [7:0] bitcnt;
  reg [7:0] bitlength;
  reg bitvalue; 
  reg bitedge_detected; 

    always @(posedge clk, negedge resetb) 
  begin 
    if (resetb == 0)
    begin
      bitcnt    <= 8'h00;
      bitlength <= 8'h00;
      bitvalue  <= 1'b0;  
      bitedge_detected  <= 1'b0; 
    end
    else
    begin 
      if (rxedge == 1) 
      begin 
        bitvalue         <= correlator[4]; 
        bitlength        <= bitcnt; 
        bitcnt           <= 8'h00;
        bitedge_detected <= 1'b1;
      end 
      else 
      begin
        bitvalue  <= bitvalue; 
        bitlength <= bitlength;
        bitedge_detected <= 1'b0;   
        bitcnt    <= bitcnt + 8'h01;
      end
    end     
  end
  
  // Bucket list - Update a table of stats on bit lengths
   
  reg [7:0] bucket_mem [31:0];
  integer j; 
  always @(posedge clk, negedge resetb)
  begin
    if (~resetb) 
    begin 
      for (j=0; j < 32; j=j+1) begin
        bucket_mem[j] <= 8'h00; 
      end
    end
    else
    begin 
      if (bitedge_detected) 
      begin
        bucket_mem[bitlength[4:0]] <= bucket_mem[bitlength[4:0]] + 1;    
      end
    end     
  end

  // Code extractor 
  // 010      | 101      =>  0   
  // 001      | 110      =>  1
  // 00010111 | 11101000 => Sync B Left and new frame 
  // 00011011 | 11100100 => Sync W Right 
  // 00011101 | 11100010 => Sync M Left    

 localparam [3:0] // Code extrator  
    INIT_ST            = 4'b0000,
    SEARCH_ST          = 4'b0001,
    FOUND_0_0_ST       = 4'b0010,
    FOUND_0_1_ST       = 4'b0011,
    FOUND_1_ST         = 4'b0100,
    FOUND_SYNC_0_ST    = 4'b0101,
    FOUND_SYNC_1_ST    = 4'b0110,
    FOUND_SYNC_2_ST    = 4'b0111,
    FOUND_SYNC_3_ST    = 4'b1000; 
 
 reg [3:0] ext_state, ext_next; 
 reg i2s_ws; 
 reg i2s_data; 

 always @(posedge clk, negedge resetb)
 begin
   if (~resetb) 
     ext_stage <= INIT_ST; 
   else 
     ext_stage <= ext_next; 
 end    

 always @*
 begin
    ext_next = ext_state; 
    case(ext_state) 
      INIT_ST :     // Set up and enter search  
        begin
          i2s_ws   = 1'b0;
          i2s_data = 1'b0;
          ext_next = SEARCH_ST; 
        end     
      SEARCH_ST :   // Look for first syncword 
        begin 
          i2s_ws   = 1'b0;
          i2s_data = 1'b0;
          if (bitedge_detected & bitlength > 10 ) 
            ext_next =  FOUND_SYNC_0_ST; 
        end        
      FOUND_SYNC_0_ST : 
        begin 
          if (bitedge_detected & bitlength < 6 ) 
            ext_next = FOUND_SYNC_B_ST     // Left and new frame
          else if (bitedge_detected & bitlength < 10) 
            ext_next = FOUND_SYNC_W_ST     // Right 
          else if (bitedge_detected & bitlength > 10)
            ext_next = FOUND_SYNC_M_ST     // LEFT 
        end
      FOUND_SYNC_B_ST : 
        begin 
          if (bitedge_detected & bitlength < 6 )
            ext_next = FOUND_SYNC_B1_ST;
        end                   
      FOUND_SYNC_B1_ST : 
        begin 
          if (bitedge_detected & bitlength > 10 )
            ext_next = FOUND_SYNC_B2_ST;
        end 
      FOUND_SYNC_B2_ST :               
        begin 
          i2s_ws = 1'b1; 
          if (bitedge_detected & bitlength < 6 )
            ext_next = FOUND_0_0_ST; 
          else if (bitedge_detected & bitlength > 6 )
            ext_next = FOUND_1_ST; 
                  
 
 end    
endmodule