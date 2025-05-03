// mtime
// mtimecmp

module axi4l_timer
  (input  logic   clk,
   input  logic   rst_n,
   output logic   irq,
`ifndef FORMAL
   axi4l_if.slave axi
`else
   axi4l_if       axi
`endif
   );
   import axi4l_pkg::*;

   enum [11:2] {MTIME     = 10'h000,
                MTIMEH    = 10'h001,
                MTIMECMP  = 10'h002,
                MTIMECMPH = 10'h003
                } timer_addr_e;

   logic [63:0] mtime;
   logic [63:0] mtimecmp;

   logic  valid_write_address;
   logic  valid_write_data;
   logic  write_response_stall;
   addr_t pre_waddr, waddr;
   addr_t pre_wdata, wdata;
   strb_t pre_wstrb, wstrb;

   logic  valid_read_address;
   logic  read_response_stall;
   addr_t pre_raddr, raddr;

   always_ff @(posedge clk or negedge rst_n)
     if (!rst_n)
       mtime <= 64'h0000000000000000;
     else
       mtime <= mtime + 64'h0000000000000001;

   assign irq = (mtime >= mtimecmp);

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

   always_ff @(posedge axi.aclk or negedge axi.aresetn)
     if (!axi.aresetn)
       mtimecmp <= 64'hffffffffffffffff;
     else
       if (!write_response_stall && valid_write_address && valid_write_data)
         begin
            // Verilator lint_off CASEINCOMPLETE
            unique0 case (waddr[11:2])
              MTIMECMP: begin
                 if (wstrb[0]) mtimecmp[7:0]   <= wdata[7:0];
                 if (wstrb[1]) mtimecmp[15:8]  <= wdata[15:8];
                 if (wstrb[2]) mtimecmp[23:16] <= wdata[23:16];
                 if (wstrb[3]) mtimecmp[31:24] <= wdata[31:24];
              end
              MTIMECMPH: begin
                 if (wstrb[0]) mtimecmp[39:32] <= wdata[7:0];
                 if (wstrb[1]) mtimecmp[47:40] <= wdata[15:8];
                 if (wstrb[2]) mtimecmp[55:48] <= wdata[23:16];
                 if (wstrb[3]) mtimecmp[63:56] <= wdata[31:24];
              end
            endcase
            // Verilator lint_on CASEINCOMPLETE
         end

   always_ff @(posedge axi.aclk)
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
          MTIME:     axi.rdata <= mtime[31:0];
          MTIMEH:    axi.rdata <= mtime[63:32];
          MTIMECMP:  axi.rdata <= mtimecmp[31:0];
          MTIMECMPH: axi.rdata <= mtimecmp[63:32];
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
      return (addr[11:2] inside {MTIME, MTIMEH, MTIMECMP, MTIMECMPH}) ? OKAY : SLVERR;
   endfunction
endmodule
