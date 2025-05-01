/* Single bit data synchronizer */

module sync_data
  #(parameter N = 2)
   (input  wire clk,
    input  wire rst_n,
    input  wire data_i,
    output wire data_o);

   logic [N-1:0] q;

   always_ff @(posedge clk or negedge rst_n)
     if (!rst_n)
       q <= '0;
     else
       q <= {q[N-2:0], data_i};

   assign data_o = q[N-1];
endmodule
