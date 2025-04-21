/* AXI4-Lite to core memory interface converter */

module axi4l2core
  (core_if.master core,
   axi4l_if.slave axi);

   import axi4l_pkg::*;

   enum logic[1:0] {IDLE, READ_WAIT, WRITE_WAIT, BRESP_WAIT} state, state_next;

   always_ff @(posedge axi.aclk or negedge axi.aresetn)
     if (!axi.aresetn)
       state <= IDLE;
     else
       state <= state_next;

   always_comb begin
      core.req    = 1'b0;
      core.we     = 1'b0;
      core.be     = '0;
      core.addr   = '0;
      core.wdata  = axi.wdata;

      axi.awready = core.gnt;
      axi.wready  = core.gnt;
      axi.bvalid  = 1'b0;
      axi.bresp   = OKAY;
      axi.arready = core.gnt;
      axi.rvalid  = core.rvalid;
      axi.rdata   = core.rdata;
      axi.rresp   = OKAY;

      case (state)
        IDLE:
          if (axi.arvalid && axi.arready) begin
             core.req = 1'b1;
             core.addr = axi.araddr;
             state_next = READ_WAIT;
          end
          else if (axi.awvalid && axi.awready) begin
             core.req = 1'b1;
             core.we = 1'b1;
             core.addr = axi.awaddr;
             if (axi.wvalid && axi.wready)
               state_next = BRESP_WAIT;
             else
               state_next = WRITE_WAIT;
          end

        READ_WAIT:
          begin
             core.req = 1'b1;
             core.addr = axi.araddr;
             axi.rresp = core.err ? SLVERR : OKAY;
             if (axi.rvalid && axi.rready)
               state_next = IDLE;
          end

        WRITE_WAIT:
          begin
             core.req = 1'b1;
             core.we = 1'b1;
             core.addr = axi.awaddr;
             if (axi.wvalid && axi.wready)
               state_next = BRESP_WAIT;
          end

        BRESP_WAIT:
          begin
             axi.bvalid = 1'b1;
             axi.bresp = core.err ? SLVERR : OKAY;
             if (axi.bvalid && axi.bready)
               state_next = IDLE;
          end
      endcase
   end
endmodule
