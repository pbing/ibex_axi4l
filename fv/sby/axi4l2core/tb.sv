module tb;
   import axi4l_pkg::*;

   logic clk;
   logic rst_n;
   logic aclk;
   logic aresetn;

   int unsigned f_core_outstanding;
   int unsigned f_axi_awr_outstanding, f_axi_wr_outstanding, f_axi_rd_outstanding;

   core_if core (.clk, .rst_n);
   axi4l_if axi (.aclk, .aresetn);
   axi4l2core u_axi4l2core (.core, .axi);

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
   always @(posedge axi.clk)
     if (!axi.aresetn)
       f_axi_rd_outstanding <= 0;
     else
       case({axi_ard_req, axi_rd_ack})
         2'b10: f_axi_rd_outstanding <= f_axi_rd_outstanding + 1'b1;
         2'b01: f_axi_rd_outstanding <= f_axi_rd_outstanding - 1'b1;
       endcase

   // prevent overflow
   always @(*) begin
      if (f_axi_awr_outstanding == '1)
        assume (!axi.awready);

      if (f_axi_wr_outstanding == '1)
        assume (!axi.wready);

      if (f_axi_rd_outstanding == '1)
        assume (!axi.arready);
   end

   int unsigned cvr_writes;
   initial cvr_writes = 0;
   always @(posedge axi.aclk)
     if (!axi.aresetn)
       cvr_writes <= 0;
     else
       if (axi.bvalid && axi.bready)
         cvr_writes <= cvr_writes + 1;

   int cvr_reads;
   initial cvr_reads = 0;
   always @(posedge axi.aclk)
     if (!axi.aresetn)
       cvr_reads <= 0;
     else
       if (axi.rvalid && axi.rready)
         cvr_reads <= cvr_reads + 1;

   // --------------------------------------------------------------------------
   // CORE
   // --------------------------------------------------------------------------
   initial
     AST_core_req_initial: assert (!core.req);

   always @(posedge clk)
     if (past_valid && $past(!rst_n))
       AST_core_req_reset:  assert (!core.req);

   always @(posedge clk)
     if (past_valid && $past(rst_n) && rst_n) begin
        if (past_valid && $past(core.req && !core.gnt)) begin
           AST_core_req_stable: assert (core.req);
           AST_core_addr_stable: assert ($stable(core.addr));
           AST_core_we_stable: assert ($stable(core.we));

           if (core.we) begin
              AST_core_be_stable: assert ($stable(core.be));
              AST_core_wdata_stable: assert ($stable(core.wdata));
           end
        end
     end

   always @(*) begin
      // Only send an rvalid if there is an outstanding request
      if (f_core_outstanding == 0)
        ASM_no_rvalid: assume (!core.rvalid);

      // Grants can only be sent when they are requested
      if (!core.req)
        ASM_no_gnt: assume (!core.gnt);
   end

   // --------------------------------------------------------------------------
   // AXI4-Lite
   // --------------------------------------------------------------------------
   initial begin
      ASM_axi_awvalid_initial: assume (!axi.awvalid);
      ASM_axi_wvalid_initial:  assume (!axi.wvalid);
      ASM_axi_bready_initial:  assert (!axi.bvalid);
      ASM_axi_arvalid_initial: assume (!axi.arvalid);
      ASM_axi_rready_initial:  assert (!axi.rvalid);
   end

   always @(posedge axi.aclk)
     if (past_valid && $past(!axi.aresetn)) begin
        ASM_axi_awvalid_reset: assume (!axi.awvalid);
        ASM_axi_wvalid_reset:  assume (!axi.wvalid);
        AST_axi_bvalid_reset:  assert (!axi.bvalid);
        ASM_axi_arvalid_reset: assume (!axi.arvalid);
        AST_axi_rvalid_reset:  assert (!axi.rvalid);
     end

   always @(posedge axi.aclk)
     if (past_valid && $past(axi.aresetn) && axi.aresetn) begin
        // Write address channel
        if (past_valid && $past(axi.awvalid && !axi.awready)) begin
           ASM_axi_awvalid_stable: assume (axi.awvalid);
           ASM_axi_awaddr_stable:  assume ($stable(axi.awaddr));
           ASM_axi_awprot_stable:  assume ($stable(axi.awprot));
        end

        // Write data channel
        if (past_valid && $past(axi.wvalid && !axi.wready)) begin
           ASM_axi_wvalid_stable: assume (axi.wvalid);
           ASM_axi_wdata_stable:  assume ($stable(axi.wdata));
           ASM_axi_wstrb_stable:  assume ($stable(axi.wstrb));
        end

        // Write response channel
        if (past_valid && $past(axi.bvalid && !axi.bready)) begin
           AST_axi_bvalid_stable: assert (axi.bvalid);
           AST_axi_bresp_stable:  assert ($stable(axi.bresp));
        end

        // Read address channel
        if (past_valid && $past(axi.arvalid && !axi.arready)) begin
           ASM_axi_arvalid_stable: assume (axi.arvalid);
           ASM_axi_araddr_stable:  assume ($stable(axi.araddr));
           ASM_axi_arprot_stable:  assume ($stable(axi.arprot));
        end

        // Read response channel
        if (past_valid && $past(axi.rvalid && !axi.rready)) begin
           AST_axi_rvalid_stable: assert (axi.rvalid);
           AST_axi_rresp_stable:  assert ($stable(axi.rresp));
        end
     end

   // xRESP checking
   always @(*) begin
      if (axi.bvalid)
        AST_axi_bresp_valid: assert ((axi.bresp == OKAY) || axi.bresp == SLVERR);

      if (axi.rvalid)
        AST_axi_rresp_valid: assert ((axi.rresp == OKAY) || axi.rresp == SLVERR);
   end

   // No BVALID w/o an outstanding request
   always @(posedge axi.aclk)
     if (axi.bvalid)
       begin
          AST_axi_awr_handshake: assert (f_axi_awr_outstanding > 0);
          AST_axi_wr_handshake:  assert (f_axi_wr_outstanding  > 0);
       end

   // No RVALID w/o an outstanding request
   always @(posedge axi.aclk)
     if (axi.rvalid)
       AST_axi_rd_handshake: assert (f_axi_rd_outstanding > 0);

   // --------------------------------------------------------------------------
   // Induction
   // --------------------------------------------------------------------------
   always @(*)
     if (axi.aresetn && (u_axi4l2core.state == 4)) // WRITE
       assert (axi.awvalid && axi.wvalid);

   always @(*)
     if (axi.aresetn && (u_axi4l2core.state == 5)) // WRITE_WAIT0
       assert ((f_axi_awr_outstanding > 0) && (f_axi_wr_outstanding > 0));

   always @(*)
     if (axi.aresetn && (u_axi4l2core.state == 1)) // READ
       assert (axi.arvalid);

   always @(*)
     if (axi.aresetn && (u_axi4l2core.state == 2)) // READ_WAIT0
       assert (f_axi_rd_outstanding > 0);

   //--------------------------------------------------------------------------------
   // COVER section
   //--------------------------------------------------------------------------------
   always @(*)
     COV_axi_write_5: cover(cvr_writes == 5);

   always @(*)
     COV_axi_read_5: cover(cvr_reads == 5);

   always @(*)
     COV_axi_rd_wr_8: cover(cvr_reads + cvr_writes == 8);
endmodule
