// SVA constraints

module fv_axi4l2core
  (core_if.monitor  core,
   axi4l_if.monitor axi);

   default clocking defclk @(posedge axi.aclk);
   endclocking

   default disable iff (!axi.aresetn);

   // --------------------------------------------------------------------------
   // CORE
   // --------------------------------------------------------------------------

   AST_core_addr_stable: assert property ((core.req && !core.gnt) |=> $stable(core.addr));

   AST_core_we_stable: assert property ((core.req && !core.gnt) |=> $stable(core.we));

   AST_core_be_stable: assert property ((core.req && !core.gnt && core.we) |=> $stable(core.be));

   AST_core_wdata_stable: assert property ((core.req && !core.gnt && core.we) |=> $stable(core.wdata));

   AST_core_req_stable: assert property ((core.req && !core.gnt) |=> core.req);

   // --------------------------------------------------------------------------
   // AXI4-Lite
   // --------------------------------------------------------------------------

   ASM_axi_awaddr_stable: assume property ((axi.awvalid && !axi.awready) |=> $stable(axi.awaddr));

   ASM_axi_awprot_stable: assume property ((axi.awvalid && !axi.awready) |=> $stable(axi.awprot));

   ASM_axi_awvalid_stable: assume property ((axi.awvalid && !axi.awready) |=> axi.awvalid);

   // --------------------------------------------------------------------------

   ASM_axi_wdata_stable: assume property ((axi.wvalid && !axi.wready) |=> $stable(axi.wdata));

   ASM_axi_wstrb_stable: assume property ((axi.wvalid && !axi.wready) |=> $stable(axi.wstrb));

   ASM_axi_wvalid_stable: assume property ((axi.wvalid && !axi.wready) |=> axi.wvalid);

   // --------------------------------------------------------------------------

   AST_axi_bresp_stable: assert property ((axi.bvalid && !axi.bready) |=> $stable(axi.bresp));

   AST_axi_bvalid_stable: assert property ((axi.bvalid && !axi.bready) |=> axi.bvalid);

   // --------------------------------------------------------------------------

   ASM_axi_araddr_stable: assume property ((axi.arvalid && !axi.arready) |=> $stable(axi.araddr));

   ASM_axi_arprot_stable: assume property ((axi.arvalid && !axi.arready) |=> $stable(axi.arprot));

   ASM_axi_arvalid_stable: assume property ((axi.arvalid && !axi.arready) |=> axi.arvalid);

   // --------------------------------------------------------------------------

   AST_axi_rdata_stable: assert property ((axi.rvalid && !axi.rready) |=> $stable(axi.rdata));

   AST_axi_rresp_stable: assert property ((axi.rvalid && !axi.rready) |=> $stable(axi.rresp));

   AST_axi_rvalid_stable: assert property ((axi.rvalid && !axi.rready) |=> axi.rvalid);

   // --------------------------------------------------------------------------
   // Covers
   // --------------------------------------------------------------------------

   COV_read: cover property (axi.rvalid && axi.rready);

   COV_write: cover property (axi.bvalid && axi.bready);

   COV_burst: cover property (((axi.bvalid && axi.bready) || (axi.rvalid && axi.rready))[->5]);
endmodule

bind axi4l2core fv_axi4l2core fv(.*);
