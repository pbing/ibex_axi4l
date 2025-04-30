/* Dual port 32 bit RAM with AXI4_Lite interface
 *
 * https://zipcpu.com/blog/2019/01/12/demoaxilite.html
 * https://github.com/ZipCPU/wb2axip/blob/master/rtl/demoaxi.v
 */


module axi4l_dpramx32
  #(parameter size = 'h80)
   (
`ifndef FORMAL
    axi4l_if.slave axi
`else
    axi4l_if       axi
`endif
    );

   import axi4l_pkg::*;

   localparam ram_aw = $clog2(size) - 2;

   logic [ram_aw-1:0] ram_waddr;     // RAM write address
   logic [ram_aw-1:0] ram_raddr;     // RAM read address
   logic              ram_ce;
   logic [3:0]        ram_we;
   logic [31:0]       ram_data;
   logic [31:0]       ram_q;

   logic  valid_write_address;
   logic  valid_write_data;
   logic  write_response_stall;
   addr_t pre_waddr, waddr;
   addr_t pre_wdata, wdata;
   strb_t pre_wstrb, wstrb;

   logic  valid_read_address;
   logic  read_response_stall;
   addr_t pre_raddr, raddr;
   data_t buf_rdata;

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

   assign
     ram_waddr = waddr[ram_aw-1:2],
     ram_raddr = raddr[ram_aw-1:2],
     ram_ce    = 1'b1,
     ram_data  = wdata;

   // --------------------------------------------------------------------------
   // Write channels
   // --------------------------------------------------------------------------

   assign
     valid_write_address  = axi.awvalid || !axi.awready,
     valid_write_data     = axi.wvalid  || !axi.wready,
     write_response_stall = axi.bvalid  && !axi.bready;

   always_ff @(posedge axi.aclk)
     if (!axi.aresetn)
       axi.awready <= 1'b1;
     else if (write_response_stall)
       axi.awready <= !valid_write_address;
     else if (valid_write_data)
       axi.awready <= 1'b1;
     else
       axi.awready <= axi.awready && !axi.awvalid;

   always_ff @(posedge axi.aclk)
     if (!axi.aresetn)
       axi.wready <= 1'b1;
     else if (write_response_stall)
       axi.wready <= !valid_write_data;
     else if (valid_write_address)
       axi.wready <= 1'b1;
     else
       axi.wready <= axi.wready && !axi.wvalid;

   always_ff @(posedge axi.aclk)
     if (axi.awready)
       pre_waddr <= axi.awaddr;

   always_ff @(posedge axi.aclk)
     if (axi.wready)
       begin
          pre_wdata <= axi.wdata;
          pre_wstrb <= axi.wstrb;
       end

   always_comb
     if (!axi.awready)
       waddr = pre_waddr;
     else
       waddr = axi.awaddr;

   always_comb
     if (!axi.wready)
       begin
          wstrb = pre_wstrb;
          wdata = pre_wdata;
       end else begin
          wstrb = axi.wstrb;
          wdata = axi.wdata;
       end

   always_comb
     if (!write_response_stall && valid_write_address && valid_write_data)
       ram_we = wstrb;
     else
       ram_we = '0;

   always_ff @(posedge axi.aclk )
     if (!axi.aresetn)
       axi.bvalid <= 1'b0;
     else
       if (valid_write_address && valid_write_data)
         axi.bvalid <= 1'b1;
       else if (axi.bready)
         axi.bvalid <= 1'b0;

   assign axi.bresp = OKAY;

   // --------------------------------------------------------------------------
   // Read channels
   // --------------------------------------------------------------------------

   assign
     valid_read_address  = axi.arvalid || !axi.arready,
     read_response_stall = axi.rvalid && !axi.rready;

   always_ff @(posedge axi.aclk or negedge axi.aresetn)
     if (!axi.aresetn)
       axi.rvalid <= 1'b0;
     else
       if (read_response_stall)
         axi.rvalid <= 1'b1;
       else if (valid_read_address)
         axi.rvalid <= 1'b1;
       else
         axi.rvalid <= 1'b0;

   always_ff @(posedge axi.aclk)
     if (axi.arready)
       pre_raddr <= axi.araddr;

   always_comb
     if (!axi.arready)
       raddr = pre_raddr;
     else
       raddr = axi.araddr;

   always_ff @(posedge axi.aclk)
     if (!read_response_stall && valid_read_address)
       buf_rdata <= ram_q;

   always_comb
     if (axi.rready)
       axi.rdata = ram_q;
     else
       axi.rdata = buf_rdata;

   assign axi.rresp = OKAY;

   always_ff @(posedge axi.aclk)
     if (!axi.aresetn)
       axi.arready <= 1'b1;
     else
       if (read_response_stall)
         axi.arready <= !valid_read_address;
       else
         axi.arready <= 1'b1;
endmodule
