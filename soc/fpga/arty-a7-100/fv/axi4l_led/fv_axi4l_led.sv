module fv_axi4l_led
  #(parameter N = 4)
   (input logic [N-1:0] led,
    axi4l_if.monitor    axi);

   import axi4l_pkg::*;

   default clocking defclk @(posedge axi.aclk);
   endclocking

   default disable iff (!axi.aresetn);

   // --------------------------------------------------------------------------
   // LED
   // --------------------------------------------------------------------------

   AST_read_led: assume property ((axi.arvalid && !axi.arready && axi.rready) |=> (axi.rvalid && (axi.rdata == led)));

   AST_write_led_data: assume property
   ((((axi.awaddr[11:2] == 10'h000) && axi.awvalid && !axi.awready) && (axi.awvalid && !axi.awready))
    |=> (led == axi.wdata));

   AST_write_led_resp_ok: assume property
   (((axi.awaddr[11:2] == 10'h000) && axi.awvalid && !axi.awready && axi.bready) |=> (axi.bvalid && (axi.bresp == OKAY)));

   AST_write_led_resp_err: assume property
   (((axi.awaddr[11:2] != 10'h000) && axi.awvalid && !axi.awready) && axi.bready |=> (axi.bvalid && (axi.bresp == SLVERR)));


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

bind axi4l_led fv_axi4l_led #(.N(N)) fv(.*);
