module tb;
   import axi4l_pkg::*;

   logic clk;
   logic rst_n;
   logic irq;
   logic aclk;
   logic aresetn;

   axi4l_if axi (.aclk, .aresetn);
   axi4l_timer u_axi4l_timer (.clk, .rst_n, .irq, .axi);

   //--------------------------------------------------------------------------------
   // FORMAL section
   //--------------------------------------------------------------------------------

   initial axi.aresetn <= 1'b0;
   always @(posedge axi.aclk) axi.aresetn <= 1'b1;

   logic past_valid;
   initial past_valid <= 1'b0;
   always @(posedge axi.aclk)
     past_valid <= 1'b1;

   always @(*)
     if (!past_valid)
       assume(!axi.aresetn);

   always @(*)
     assume (rst_n == axi.aresetn);

   initial begin
      ASM_axi_awvalid_initial: assume (!axi.awvalid);
      ASM_axi_wvalid_initial: assume (!axi.wvalid);
      ASM_axi_bready_initial: assume (!axi.bready);
      ASM_axi_arvalid_initial: assume (!axi.arvalid);
      ASM_axi_rready_initial: assume (!axi.rready);
   end

   always @(posedge axi.aclk)
     if (past_valid && $past(!axi.aresetn)) begin
        ASM_axi_awvalid_reset: assume (!axi.awvalid);
        ASM_axi_wvalid_reset: assume (!axi.wvalid);
        AST_axi_bvalid_reset: assert (!axi.bvalid);
        ASM_axi_arvalid_reset: assume (!axi.arvalid);
        AST_axi_rvalid_reset: assert (!axi.rvalid);
     end

   always @(posedge axi.aclk)
     if (past_valid && $past(axi.aresetn) && axi.aresetn) begin
        // Write address channel
        if (past_valid && $past(axi.awvalid && !axi.awready)) begin
           ASM_axi_awvalid_stable: assume (axi.awvalid);
           ASM_axi_awaddr_stable: assume ($stable(axi.awaddr));
           ASM_axi_awprot_stable: assume ($stable(axi.awprot));
        end

        // Write data channel
        if (past_valid && $past(axi.wvalid && !axi.wready)) begin
           ASM_axi_wvalid_stable: assume (axi.wvalid);
           ASM_axi_wdata_stable: assume ($stable(axi.wdata));
           ASM_axi_wstrb_stable: assume ($stable(axi.wstrb));
        end

        // Write response channel
        if (past_valid && $past(axi.bvalid && !axi.bready)) begin
           AST_axi_bvalid_stable: assert (axi.bvalid);
           AST_axi_bresp_stable: assert ($stable(axi.bresp));
        end

        // Read address channel
        if (past_valid && $past(axi.arvalid && !axi.arready)) begin
           ASM_axi_arvalid_stable: assume (axi.arvalid);
           ASM_axi_araddr_stable: assume ($stable(axi.araddr));
           ASM_axi_arprot_stable: assume ($stable(axi.arprot));
        end

        // Read response channel
        if (past_valid && $past(axi.rvalid && !axi.rready)) begin
           AST_axi_rvalid_stable: assert (axi.rvalid);
           AST_axi_rresp_stable: assert ($stable(axi.rresp));
        end
     end

   // xRESP checking
   always @(*) begin
      if (axi.bvalid && axi.aresetn)
        AST_axi_bresp_valid: assert ((axi.bresp == OKAY) || axi.bresp == SLVERR);

      if (axi.rvalid && axi.aresetn)
        AST_axi_rresp_valid: assert ((axi.rresp == OKAY) || axi.rresp == SLVERR);
   end

   // COVER section
   always @(posedge axi.aclk)
     COV_axi_write_1: cover (axi.bvalid && axi.bready);

   always @(posedge axi.aclk)
     COV_axi_read_1: cover (axi.rvalid && axi.rready);

   always @(posedge axi.aclk)
     COV_axi_read_2: cover (past_valid &&
                            $past(axi.rvalid && axi.rready && axi.rdata != 32'h12345678, 1) &&
                                  axi.rvalid && axi.rready && axi.rdata == 32'h12345678);

   always @(posedge axi.aclk)
     COV_axi_read_4: cover (past_valid &&
                            $past(axi.araddr == 0 && axi.rvalid && axi.rready && axi.rdata == 32'h00000005, 3) &&
                            $past(axi.araddr == 0 && axi.rvalid && axi.rready && axi.rdata == 32'h00000006, 2) &&
                            $past(axi.araddr == 0 && axi.rvalid && axi.rready && axi.rdata == 32'h00000007, 1) &&
                                  axi.araddr == 0 && axi.rvalid && axi.rready && axi.rdata == 32'h00000008);

   always @(posedge axi.aclk)
     COV_axi_write_5: cover (past_valid &&
                             $past(axi.bvalid && axi.bready, 4) &&
                             $past(axi.bvalid && axi.bready, 3) &&
                             $past(axi.bvalid && axi.bready, 2) &&
                             $past(axi.bvalid && axi.bready, 1) &&
                                   axi.bvalid && axi.bready);
   always @(posedge axi.aclk)
     COV_axi_read_5: cover (past_valid &&
                            $past(axi.rvalid && axi.rready, 4) &&
                            $past(axi.rvalid && axi.rready, 3) &&
                            $past(axi.rvalid && axi.rready, 2) &&
                            $past(axi.rvalid && axi.rready, 1) &&
                                  axi.rvalid && axi.rready);
   always @(posedge axi.aclk)
     COV_axi_rd_wr_5: cover (past_valid &&
                             $past((axi.bvalid && axi.bready) || (axi.rvalid && axi.rready), 4) &&
                             $past((axi.bvalid && axi.bready) || (axi.rvalid && axi.rready), 3) &&
                             $past((axi.bvalid && axi.bready) || (axi.rvalid && axi.rready), 2) &&
                             $past((axi.bvalid && axi.bready) || (axi.rvalid && axi.rready), 1) &&
                                   (axi.bvalid && axi.bready) || (axi.rvalid && axi.rready));
endmodule
