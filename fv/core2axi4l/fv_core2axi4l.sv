// SVA constraints

module fv_core2axi4l
  (core_if.monitor  core,
   axi4l_if.monitor axi);

   default clocking defclk @(posedge core.clk);
   endclocking

   default disable iff (!core.rst_n);

   // --------------------------------------------------------------------------
   // CORE
   // --------------------------------------------------------------------------

   ASM_core_addr_stable: assume property ((core.req && !core.gnt) |=> $stable(core.addr));

   ASM_core_we_stable: assume property ((core.req && !core.gnt) |=> $stable(core.we));

   ASM_core_be_stable: assume property ((core.req && !core.gnt && core.we) |=> $stable(core.be));

   ASM_core_wdata_stable: assume property ((core.req && !core.gnt && core.we) |=> $stable(core.wdata));

   ASM_core_req_stable: assume property ((core.req && !core.gnt) |=> core.req);

   // --------------------------------------------------------------------------
   // AXI4-Lite
   // --------------------------------------------------------------------------

   AST_axi_awaddr_stable: assert property ((axi.awvalid && !axi.awready) |=> $stable(axi.awaddr));

   AST_axi_awprot_stable: assert property ((axi.awvalid && !axi.awready) |=> $stable(axi.awprot));

   AST_axi_awvalid_stable: assert property ((axi.awvalid && !axi.awready) |=> axi.awvalid);

   // --------------------------------------------------------------------------

   AST_axi_wdata_stable: assert property ((axi.wvalid && !axi.wready) |=> $stable(axi.wdata));

   AST_axi_wstrb_stable: assert property ((axi.wvalid && !axi.wready) |=> $stable(axi.wstrb));

   AST_axi_wvalid_stable: assert property ((axi.wvalid && !axi.wready) |=> axi.wvalid);

   // --------------------------------------------------------------------------

   ASM_axi_bresp_stable: assume property ((axi.bvalid && !axi.bready) |=> $stable(axi.bresp));

   ASM_axi_bvalid_stable: assume property ((axi.bvalid && !axi.bready) |=> axi.bvalid);

   // --------------------------------------------------------------------------

   AST_axi_araddr_stable: assert property ((axi.arvalid && !axi.arready) |=> $stable(axi.araddr));

   AST_axi_arprot_stable: assert property ((axi.arvalid && !axi.arready) |=> $stable(axi.arprot));

   AST_axi_arvalid_stable: assert property ((axi.arvalid && !axi.arready) |=> axi.arvalid);

   // --------------------------------------------------------------------------

   ASM_axi_rdata_stable: assume property ((axi.rvalid && !axi.rready) |=> $stable(axi.rdata));

   ASM_axi_rresp_stable: assume property ((axi.rvalid && !axi.rready) |=> $stable(axi.rresp));

   ASM_axi_rvalid_stable: assume property ((axi.rvalid && !axi.rready) |=> axi.rvalid);

   // --------------------------------------------------------------------------
   // Covers
   // --------------------------------------------------------------------------

   COV_read: cover property (core.rvalid);

   COV_write: cover property (core.rvalid);

   COV_burst: cover property (core.rvalid[->5]);
endmodule

bind core2axi4l fv_core2axi4l fv(.*);
