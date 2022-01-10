module clk_div 
  #( parameter DIV = 5 )
  (  input clk_in, 
     input resetb,
     output clk ); 
   
   reg [5:0] cc_reg; 

   assign clk = cc_reg[DIV]; 
   
   always @(posedge clk_in , negedge resetb)
   begin
       if (!resetb)
         cc_reg <= 0;
       else
         cc_reg <= cc_reg + 6'h01;
   end
endmodule