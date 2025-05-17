module tb;
   import axi4l_pkg::*;

   localparam RAM_SIZE = 'h10;

   logic aclk;
   logic aresetn;

   int unsigned f_axi_awr_outstanding, f_axi_wr_outstanding, f_axi_rd_outstanding;

   axi4l_if axi (.aclk, .aresetn);
   axi4l_dpramx32 #(.size(RAM_SIZE)) dut (.axi);

   //--------------------------------------------------------------------------------
   // Helper code
   //--------------------------------------------------------------------------------
   initial aresetn <= 1'b0;
   always @(posedge aclk) aresetn <= 1'b1;

   logic f_past_valid;
   initial f_past_valid <= 1'b0;
   always @(posedge aclk)
     f_past_valid <= 1'b1;

   always @(*)
     if (!f_past_valid)
       assume(!aresetn);

   logic axi_awr_req, axi_wr_req, axi_wr_ack, axi_ard_req, axi_rd_ack;
   assign axi_awr_req = axi.awvalid && axi.awready;
   assign axi_wr_req  = axi.wvalid  && axi.wready;
   assign axi_wr_ack  = axi.bvalid  && axi.bready;
   assign axi_ard_req = axi.arvalid && axi.arready;
   assign axi_rd_ack  = axi.rvalid  && axi.rready;

   // Count outstanding write address channel requests
   initial f_axi_awr_outstanding = 0;
   always @(posedge aclk)
     if (!aresetn)
       f_axi_awr_outstanding <= 0;
     else
       case({axi_awr_req, axi_wr_ack})
         2'b10: f_axi_awr_outstanding <= f_axi_awr_outstanding + 1'b1;
         2'b01: f_axi_awr_outstanding <= f_axi_awr_outstanding - 1'b1;
       endcase

   // Count outstanding write data channel requests
   initial f_axi_wr_outstanding = 0;
   always @(posedge aclk)
     if (!aresetn)
       f_axi_wr_outstanding <= 0;
     else
       case({axi_wr_req, axi_wr_ack})
         2'b10: f_axi_wr_outstanding <= f_axi_wr_outstanding + 1'b1;
         2'b01: f_axi_wr_outstanding <= f_axi_wr_outstanding - 1'b1;
       endcase

   // Count outstanding read requests
   initial f_axi_rd_outstanding = 0;
   always @(posedge aclk)
     if (!aresetn)
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
   always @(posedge aclk)
     if (!aresetn)
       cvr_writes <= 0;
     else
       if (axi.bvalid && axi.bready)
         cvr_writes <= cvr_writes + 1;

   int cvr_reads;
   initial cvr_reads = 0;
   always @(posedge aclk)
     if (!aresetn)
       cvr_reads <= 0;
     else
       if (axi.rvalid && axi.rready)
         cvr_reads <= cvr_reads + 1;

   // --------------------------------------------------------------------------
   // Memory
   // https://zipcpu.com/zipcpu/2018/07/13/memories.html
   // --------------------------------------------------------------------------
   localparam ram_aw = $clog2(RAM_SIZE) - 2;

   (* anyconst *) addr_t f_addr;
   data_t                f_data, f_data1;

   always @(posedge aclk)
     f_data1 <= f_data;

   initial
     assume (dut.mem[f_addr] == f_data);

   always @(*)
     assert (dut.mem[f_addr] == f_data);

   always @(posedge aclk)
     if ((dut.waddr[ram_aw+1:2] == f_addr[ram_aw-1:0]) && dut.write_enable) begin
        if (dut.wstrb[0]) f_data[7:0]   <= dut.wdata[7:0];
        if (dut.wstrb[1]) f_data[15:8]  <= dut.wdata[15:8];
        if (dut.wstrb[2]) f_data[23:16] <= dut.wdata[23:16];
        if (dut.wstrb[3]) f_data[31:24] <= dut.wdata[31:24];
     end

   always @(posedge aclk)
     if (f_past_valid && $past(dut.raddr[ram_aw+1:2] == f_addr[ram_aw-1:0]) && $past(dut.read_enable))
       assert (axi.rdata == f_data1);

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

   always @(posedge aclk)
     if (f_past_valid && $past(!aresetn)) begin
        ASM_axi_awvalid_reset: assume (!axi.awvalid);
        ASM_axi_wvalid_reset:  assume (!axi.wvalid);
        AST_axi_bvalid_reset:  assert (!axi.bvalid);
        ASM_axi_arvalid_reset: assume (!axi.arvalid);
        AST_axi_rvalid_reset:  assert (!axi.rvalid);
     end

   always @(posedge aclk)
     if (f_past_valid && $past(aresetn) && aresetn) begin
        // Write address channel
        if (f_past_valid && $past(axi.awvalid && !axi.awready)) begin
           ASM_axi_awvalid_stable: assume (axi.awvalid);
           ASM_axi_awaddr_stable:  assume ($stable(axi.awaddr));
           ASM_axi_awprot_stable:  assume ($stable(axi.awprot));
        end

        // Write data channel
        if (f_past_valid && $past(axi.wvalid && !axi.wready)) begin
           ASM_axi_wvalid_stable: assume (axi.wvalid);
           ASM_axi_wdata_stable:  assume ($stable(axi.wdata));
           ASM_axi_wstrb_stable:  assume ($stable(axi.wstrb));
        end

        // Write response channel
        if (f_past_valid && $past(axi.bvalid && !axi.bready)) begin
           AST_axi_bvalid_stable: assert (axi.bvalid);
           AST_axi_bresp_stable:  assert ($stable(axi.bresp));
        end

        // Read address channel
        if (f_past_valid && $past(axi.arvalid && !axi.arready)) begin
           ASM_axi_arvalid_stable: assume (axi.arvalid);
           ASM_axi_araddr_stable:  assume ($stable(axi.araddr));
           ASM_axi_arprot_stable:  assume ($stable(axi.arprot));
        end

        // Read response channel
        if (f_past_valid && $past(axi.rvalid && !axi.rready)) begin
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
   always @(posedge aclk)
     if (axi.bvalid)
       begin
          AST_axi_awr_handshake: assert (f_axi_awr_outstanding > 0);
          AST_axi_wr_handshake:  assert (f_axi_wr_outstanding  > 0);
       end

   // No RVALID w/o an outstanding request
   always @(posedge aclk)
     if (axi.rvalid)
       AST_axi_rd_handshake: assert (f_axi_rd_outstanding > 0);

   // --------------------------------------------------------------------------
   // Induction
   // --------------------------------------------------------------------------
`ifdef SMTBMC_PROVE_ENGINE
   always @(*)
     if (axi.bvalid) begin
        assert (f_axi_awr_outstanding == 1 + (axi.awready ? 0 : 1));
        assert (f_axi_wr_outstanding  == 1 + (axi.wready  ? 0 : 1));
     end else begin
        assert (f_axi_awr_outstanding == (axi.awready ? 0 : 1));
        assert (f_axi_wr_outstanding  == (axi.wready  ? 0 : 1));
     end

   always @(*)
     if (axi.rvalid) begin
        assert (f_axi_rd_outstanding == 1 + (axi.arready ? 0 : 1));
     end
     else begin
        assert (f_axi_rd_outstanding == (axi.arready ? 0 : 1));
     end
`endif

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
