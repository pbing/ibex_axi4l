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

   logic  valid_write_address;
   logic  valid_write_data;
   logic  write_response_stall;
   addr_t pre_waddr, waddr;
   addr_t pre_wdata, wdata;
   strb_t pre_wstrb, wstrb;

   logic  valid_read_address;
   logic  read_response_stall;
   addr_t pre_raddr, raddr;

   // --------------------------------------------------------------------------
   // RAM
   // --------------------------------------------------------------------------

   (* ram_style = "block" *) data_t mem[size>>2];

   initial
     $readmemh("dpramx32.vmem", mem);

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
     if (axi.wready) begin
        pre_wdata <= axi.wdata;
        pre_wstrb <= axi.wstrb;
     end

   always_comb
     if (!axi.awready)
       waddr = pre_waddr;
     else
       waddr = axi.awaddr;

   always_comb
     if (!axi.wready) begin
        wstrb = pre_wstrb;
        wdata = pre_wdata;
     end
     else begin
        wstrb = axi.wstrb;
        wdata = axi.wdata;
     end

   always @(posedge axi.aclk)
     if (!write_response_stall && valid_write_address && valid_write_data) begin
        if (wstrb[0]) mem[waddr[ram_aw-1:2]][7:0]   <= wdata[7:0];
        if (wstrb[1]) mem[waddr[ram_aw-1:2]][15:8]  <= wdata[15:8];
        if (wstrb[2]) mem[waddr[ram_aw-1:2]][23:16] <= wdata[23:16];
        if (wstrb[3]) mem[waddr[ram_aw-1:2]][31:24] <= wdata[31:24];
     end

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

   always @(posedge axi.aclk)
     if (!read_response_stall && valid_read_address)
       axi.rdata <= mem[raddr[ram_aw-1:2]];

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
