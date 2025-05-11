module tb;
   import axi4l_pkg::*;

   logic clk;
   logic rst_n;
   logic aclk;
   logic aresetn;

   logic        f_core_wr;
   int unsigned f_core_outstanding;
   int unsigned f_axi_awr_outstanding, f_axi_wr_outstanding, f_axi_rd_outstanding;

   core_if core (.clk, .rst_n);
   axi4l_if axi (.aclk, .aresetn);
   core2axi4l u_core2axi4l (.core, .axi);

   //--------------------------------------------------------------------------------
   // Helper code
   //--------------------------------------------------------------------------------
   initial rst_n <= 1'b0;
   always @(posedge axi.aclk) rst_n <= 1'b1;

   initial axi.aresetn <= 1'b0;
   always @(posedge axi.aclk) axi.aresetn <= 1'b1;

   logic past_valid;
   initial past_valid <= 1'b0;
   always @(posedge axi.aclk)
     past_valid <= 1'b1;

   always @(*)
     if (!past_valid) begin
        assume(!rst_n);
        assume(!axi.aresetn);
     end

   initial f_core_outstanding <= 0;
   always @(posedge clk)
     if (!rst_n)
       f_core_outstanding <= 0;
     else
       if ((core.req && core.gnt) && !core.rvalid)
         f_core_outstanding = f_core_outstanding + 1;
       else if (!(core.req && core.gnt) && core.rvalid)
         f_core_outstanding = f_core_outstanding - 1;

   // prevent overflow
   always @(*)
     if ((f_core_outstanding == '1))
       assume (!core.req);

   // read or write transaction in flight
   always @(posedge clk)
     if (core.req && core.gnt)
       f_core_wr <= core.we;

   logic axi_awr_req, axi_wr_req, axi_wr_ack, axi_ard_req, axi_rd_ack;
   assign axi_awr_req = axi.awvalid && axi.awready;
   assign axi_wr_req  = axi.wvalid  && axi.wready;
   assign axi_wr_ack  = axi.bvalid  && axi.bready;
   assign axi_ard_req = axi.arvalid && axi.arready;
   assign axi_rd_ack  = axi.rvalid  && axi.rready;

   // Count outstanding write address channel requests
   initial f_axi_awr_outstanding = 0;
   always @(posedge axi.aclk)
     if (!axi.aresetn)
       f_axi_awr_outstanding <= 0;
     else
       case({axi_awr_req, axi_wr_ack})
         2'b10: f_axi_awr_outstanding <= f_axi_awr_outstanding + 1'b1;
         2'b01: f_axi_awr_outstanding <= f_axi_awr_outstanding - 1'b1;
       endcase

   // Count outstanding write data channel requests
   initial f_axi_wr_outstanding = 0;
   always @(posedge axi.aclk)
     if (!axi.aresetn)
       f_axi_wr_outstanding <= 0;
     else
       case({axi_wr_req, axi_wr_ack})
         2'b10: f_axi_wr_outstanding <= f_axi_wr_outstanding + 1'b1;
         2'b01: f_axi_wr_outstanding <= f_axi_wr_outstanding - 1'b1;
       endcase

   // Count outstanding read requests
   initial f_axi_rd_outstanding = 0;
   always @(posedge axi.aclk)
     if (!axi.aresetn)
       f_axi_rd_outstanding <= 0;
     else
       case({axi_ard_req, axi_rd_ack})
         2'b10: f_axi_rd_outstanding <= f_axi_rd_outstanding + 1'b1;
         2'b01: f_axi_rd_outstanding <= f_axi_rd_outstanding - 1'b1;
       endcase

   int unsigned cvr_writes;
   initial cvr_writes = 0;
   always @(posedge clk)
     if (!rst_n)
       cvr_writes <= 0;
     else
       if ((f_core_outstanding > 0) && f_core_wr && core.rvalid)
         cvr_writes <= cvr_writes + 1;

   int unsigned cvr_reads;
   initial cvr_reads = 0;
   always @(posedge clk)
     if (!rst_n)
       cvr_reads <= 0;
     else
       if ((f_core_outstanding > 0) && !f_core_wr && core.rvalid)
         cvr_reads <= cvr_reads + 1;

   // --------------------------------------------------------------------------
   // CORE
   // --------------------------------------------------------------------------
   initial
     ASM_core_req_initial: assume (!core.req);

   always @(posedge clk)
     if (past_valid && $past(!rst_n))
       ASM_core_req_reset:  assume (!core.req);

   always @(posedge clk)
     if (past_valid && $past(rst_n) && rst_n) begin
        if (past_valid && $past(core.req && !core.gnt)) begin
           ASM_core_req_stable:  assume (core.req);
           ASM_core_addr_stable: assume ($stable(core.addr));
           ASM_core_we_stable:   assume ($stable(core.we));

           if (core.we) begin
              ASM_core_be_stable:    assume ($stable(core.be));
              ASM_core_wdata_stable: assume ($stable(core.wdata));
           end
        end
     end

   always @(*) begin
      // Only send an rvalid if there is an outstanding request
      if (f_core_outstanding == 0)
        AST_no_rvalid: assert (!core.rvalid);

      // Grants can only be sent when they are requested
      if (!core.req)
        AST_no_gnt: assert (!core.gnt);
   end

   // --------------------------------------------------------------------------
   // AXI4-Lite
   // --------------------------------------------------------------------------
   initial begin
      AST_axi_awvalid_initial: assert (!axi.awvalid);
      AST_axi_wvalid_initial:  assert (!axi.wvalid);
      ASM_axi_bready_initial:  assume (!axi.bvalid);
      AST_axi_arvalid_initial: assert (!axi.arvalid);
      ASM_axi_rready_initial:  assume (!axi.rvalid);
   end

   always @(posedge axi.aclk)
     if (past_valid && $past(!axi.aresetn)) begin
        AST_axi_awvalid_reset: assert (!axi.awvalid);
        AST_axi_wvalid_reset:  assert (!axi.wvalid);
        ASM_axi_bvalid_reset:  assume (!axi.bvalid);
        AST_axi_arvalid_reset: assert (!axi.arvalid);
        ASM_axi_rvalid_reset:  assume (!axi.rvalid);
     end

   always @(posedge axi.aclk)
     if (past_valid && $past(axi.aresetn) && axi.aresetn) begin
        // Write address channel
        if (past_valid && $past(axi.awvalid && !axi.awready)) begin
           AST__axi_awvalid_stable: assert (axi.awvalid);
           AST__axi_awaddr_stable:  assert ($stable(axi.awaddr));
           AST__axi_awprot_stable:  assert ($stable(axi.awprot));
        end

        // Write data channel
        if (past_valid && $past(axi.wvalid && !axi.wready)) begin
           AST__axi_wvalid_stable: assert (axi.wvalid);
           AST__axi_wdata_stable:  assert ($stable(axi.wdata));
           AST__axi_wstrb_stable:  assert ($stable(axi.wstrb));
        end

        // Write response channel
        if (past_valid && $past(axi.bvalid && !axi.bready)) begin
           ASM_axi_bvalid_stable: assume (axi.bvalid);
           ASM_axi_bresp_stable:  assume ($stable(axi.bresp));
        end

        // Read address channel
        if (past_valid && $past(axi.arvalid && !axi.arready)) begin
           AST__axi_arvalid_stable: assert (axi.arvalid);
           AST__axi_araddr_stable:  assert ($stable(axi.araddr));
           AST__axi_arprot_stable:  assert ($stable(axi.arprot));
        end

        // Read response channel
        if (past_valid && $past(axi.rvalid && !axi.rready)) begin
           ASM_axi_rvalid_stable: assume (axi.rvalid);
           ASM_axi_rresp_stable:  assume ($stable(axi.rresp));
        end
     end

   // xRESP checking
   always @(*) begin
      if (axi.bvalid)
        ASM_axi_bresp_valid: assume ((axi.bresp == OKAY) || axi.bresp == SLVERR);

      if (axi.rvalid)
        ASM_axi_rresp_valid: assume ((axi.rresp == OKAY) || axi.rresp == SLVERR);
   end

   // No BVALID w/o an outstanding request
   always @(posedge axi.aclk)
     if (axi.bvalid)
       begin
          ASM_axi_awr_handshake: assume (f_axi_awr_outstanding > 0);
          ASM_axi_wr_handshake:  assume (f_axi_wr_outstanding  > 0);
       end

   // No RVALID w/o an outstanding request
   always @(posedge axi.aclk)
     if (axi.rvalid)
       ASM_axi_rd_handshake: assume (f_axi_rd_outstanding > 0);

   // --------------------------------------------------------------------------
   // Induction
   // --------------------------------------------------------------------------
   always @(*) begin
      if (axi.awvalid && axi.awready && axi.wvalid && axi.wready)
        assert (core.gnt);

      if (axi.arvalid && axi.arready)
        assert (core.gnt);
   end

   always @(*) begin
      if (axi.bvalid && axi.bready)
        assert (core.rvalid);

      if (axi.rvalid && axi.rready)
        assert (core.rvalid);
   end

   always @(*) begin
      if (rst_n && (u_core2axi4l.state == 1)) // READ_WAIT
         assert (f_core_outstanding > 0);

      if (rst_n && (u_core2axi4l.state == 2)) // WRITE_DATA
        assert (core.req && core.we);

      if (rst_n && (u_core2axi4l.state == 3)) // WRITE_ADDR
        assert (core.req && core.we);

      if (rst_n && (u_core2axi4l.state == 4)) // WRITE_WAIT
         assert (f_core_outstanding > 0);
   end

   //--------------------------------------------------------------------------------
   // COVER section
   //--------------------------------------------------------------------------------
   always @(*) begin
      COV_axi_write_5: cover (cvr_writes == 5);
      COV_axi_read_5:  cover (cvr_reads == 5);
      COV_axi_rd_wr_8: cover (cvr_reads + cvr_writes == 8);
   end
endmodule
