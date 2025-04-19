/* Dual port 32 bit RAM with AXI4_Lite interface */

module axi4l_dpramx32
  #(parameter size = 'h80)
   (axi4l_if.slave axi);

   import axi4l_pkg::*;

   localparam addr_width = $clog2(size) - 2;

   logic [addr_width - 1:0] ram_waddr;     // RAM write address
   logic [addr_width - 1:0] ram_raddr;     // RAM read address
   logic                    ram_ce;
   logic [3:0]              ram_we;
   logic [31:0]             ram_data;
   logic [31:0]             ram_q;
   logic                    bvalid;
   logic                    rvalid;
   addr_t                   awaddr_l;


   dpramx32
     #(.size(size))
   dpram
     (.clk   (axi.aclk),
      .waddr (ram_waddr),
      .raddr (ram_raddr),
      .ce    (ram_ce),
      .we    (ram_we),
      .d     (ram_data),
      .q     (ram_q));

   always_ff @(posedge axi.aclk)
     if (axi.awvalid && axi.awready)
       awaddr_l <= axi.awaddr;

   always_comb
     if ((axi.awvalid && axi.wready) && (axi.wvalid && axi.wready))
       ram_waddr = axi.awaddr[addr_width+1:2];
     else
       ram_waddr = awaddr_l[addr_width+1:2];

   assign ram_raddr = axi.araddr[addr_width+1:2];

   assign
     ram_ce   = 1'b1,
     ram_we   = {4{axi.wvalid & axi.wready}} & axi.wstrb,
     ram_data = axi.wdata;

   assign
     axi.awready = 1'b1,
     axi.wready  = 1'b1,
     axi.bvalid  = bvalid,
     axi.bresp   = OKAY,
     axi.arready = 1'b1,
     axi.rvalid  = rvalid,
     axi.rdata   = ram_q,
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
