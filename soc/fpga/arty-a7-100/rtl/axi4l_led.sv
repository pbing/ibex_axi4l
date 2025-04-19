/* LED driver (only word access) */

module axi4l_led
  #(parameter N = 4)
   (output logic [N-1:0] led,
    axi4l_if.slave       axi);

   import axi4l_pkg::*;

   localparam dw = $bits(data_t);

   addr_t awaddr_l; // latched write address
   logic  wselect;  // write select
   logic  bvalid;
   logic  rvalid;

   always_ff @(posedge axi.aclk or negedge axi.aresetn)
     if (!axi.aresetn)
       led <= '0;
     else
       if (wselect && axi.wvalid && axi.wready)
         led <= axi.wdata[N-1:0];

   always_comb
     if ((axi.awvalid && axi.wready) && (axi.wvalid && axi.wready))
       wselect = axi.awaddr[11:2] == 10'h000;
     else
       wselect = awaddr_l[11:2] == 10'h000;

   always_ff @(posedge axi.aclk)
     if (axi.awvalid && axi.awready)
       awaddr_l <= axi.awaddr;

   assign
     axi.awready = 1'b1,
     axi.wready  = 1'b1,
     axi.bvalid  = bvalid,
     axi.bresp   = OKAY,
     axi.arready = 1'b1,
     axi.rvalid  = rvalid,
     axi.rdata   = {{(dw-N){1'b0}}, led},
     axi.rresp   = OKAY;

   always_ff @(posedge axi.aclk or negedge axi.aresetn)
     if (!axi.aresetn)
       bvalid <= 1'b0;
     else
       if (axi.wvalid && axi.wready)
         bvalid <= 1'b1;
       else if (axi.bready)
         bvalid <= 1'b0;

   always_ff @(posedge axi.aclk or negedge axi.aresetn)
     if (!axi.aresetn)
       rvalid <= 1'b0;
     else
       if (axi.arvalid && axi.arready)
         rvalid <= 1'b1;
       else if (axi.rready)
         rvalid <= 1'b0;
endmodule
