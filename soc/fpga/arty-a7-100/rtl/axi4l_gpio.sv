/* GPIO
 *
 * https://zipcpu.com/blog/2019/01/12/demoaxilite.html
 * https://github.com/ZipCPU/wb2axip/blob/master/rtl/demoaxi.v
 */

module axi4l_gpio
  (
`ifndef FORMAL
   axi4l_if.slave      axi,
`else
   axi4l_if            axi,
`endif
   input  logic [31:0] gpio_i,
   output logic [31:0] gpio_o,
   output logic [31:0] gpio_en,
   output logic        gpio_irq
   );

   import axi4l_pkg::*;

   enum logic [11:2] {GPIO_DATA = 10'h000,
                      GPIO_DIR  = 10'b001
                      } gpio_addr_e;

   logic [31:0] gpio_sync;

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
   // Synchronizer
   // --------------------------------------------------------------------------

   for (genvar i = 0; i < 32; i += 1) begin
      sync_data
        #(.N(2))
      u_sync
        (.clk    (axi.aclk),
         .rst_n  (axi.aresetn),
         .data_i (gpio_i[i]),
         .data_o (gpio_sync[i]));
   end

   // --------------------------------------------------------------------------
   // Interrupt
   // --------------------------------------------------------------------------
   assign gpio_irq = |gpio_sync;

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

   always_ff @(posedge axi.aclk )
     if (!write_response_stall && valid_write_address && valid_write_data)
       begin
          // Verilator lint_off CASEINCOMPLETE
          unique0 case (waddr[11:2])
            GPIO_DATA: begin
               if (wstrb[0]) gpio_o[7:0]   <= wdata[7:0];
               if (wstrb[1]) gpio_o[15:8]  <= wdata[15:8];
               if (wstrb[2]) gpio_o[23:16] <= wdata[23:16];
               if (wstrb[3]) gpio_o[31:24] <= wdata[31:24];
            end
            GPIO_DIR: begin
               if (wstrb[0]) gpio_en[7:0]   <= wdata[7:0];
               if (wstrb[1]) gpio_en[15:8]  <= wdata[15:8];
               if (wstrb[2]) gpio_en[23:16] <= wdata[23:16];
               if (wstrb[3]) gpio_en[31:24] <= wdata[31:24];
            end
          endcase
          // Verilator lint_on CASEINCOMPLETE
       end

   always_ff @(posedge axi.aclk )
     if (!axi.aresetn)
       axi.bvalid <= 1'b0;
     else
       if (valid_write_address && valid_write_data)
         axi.bvalid <= 1'b1;
       else if (axi.bready)
         axi.bvalid <= 1'b0;

   always_ff @(posedge axi.aclk)
     if (!write_response_stall && valid_write_address) begin
        axi.bresp <= check(waddr);
     end

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
     if (!read_response_stall && valid_read_address) begin
        // Verilator lint_off CASEINCOMPLETE
        unique0 case (raddr[11:2])
          GPIO_DATA: axi.rdata <= gpio_sync;
          GPIO_DIR:  axi.rdata <= gpio_en;
        endcase
        // Verilator lint_on CASEINCOMPLETE
        axi.rresp <= check(raddr);
     end

   always_ff @(posedge axi.aclk)
     if (!axi.aresetn)
       axi.arready <= 1'b1;
     else
       if (read_response_stall)
         axi.arready <= !valid_read_address;
       else
         axi.arready <= 1'b1;

   function resp_t check(input addr_t addr);
      return (addr[11:2] inside {GPIO_DATA, GPIO_DIR}) ? OKAY : SLVERR;
   endfunction
endmodule
