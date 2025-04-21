/* AXI4-Lite to core memory interface converter */

module axi4l2core
  (
`ifndef FORMAL
   core_if.master core,
   axi4l_if.slave axi
`else
   core_if        core,
   axi4l_if       axi
`endif
   );

   import axi4l_pkg::*;

   enum logic [2:0] {IDLE, READ_WAIT, WRITE_DATA, WRITE_ADDR, WRITE_WAIT} state, state_next;

   always_ff @(posedge axi.aclk or negedge axi.aresetn)
     if (!axi.aresetn)
       state <= IDLE;
     else
       state <= state_next;

   always_comb begin
      state_next  = state;

      core.req    = 1'b0;
      core.we     = 1'b0;
      core.be     = '0;
      core.addr   = '0;
      core.wdata  = axi.wdata;

      axi.awready = 1'b0;
      axi.wready  = 1'b0;
      axi.bvalid  = 1'b0;
      axi.bresp   = OKAY;
      axi.arready = 1'b0;
      axi.rvalid  = 1'b0;
      axi.rdata   = core.rdata;
      axi.rresp   = OKAY;

      case (state)
        IDLE:
          if (axi.arvalid) begin
             core.req = 1'b1;
             core.we = 1'b0;
             core.addr = axi.araddr;
             if (core.gnt) begin
                axi.arready = 1'b1;
                state_next = READ_WAIT;
             end
          end
          else if (axi.awvalid) begin
             core.req = 1'b1;
             core.we = 1'b1;
             core.addr = axi.awaddr;
             if (core.gnt) begin
                axi.awready = 1'b1;
                state_next = WRITE_DATA;
             end
          end

        READ_WAIT:
          if (core.rvalid || axi.rvalid) begin
             axi.rvalid = 1'b1;
             axi.rresp = core.err ? SLVERR : OKAY;
             if (axi.rready)
               state_next = IDLE;
          end

        WRITE_DATA:
          begin
             axi.wready = 1'b1;
             if (axi.wvalid)
               state_next = WRITE_WAIT;
          end

        WRITE_WAIT:
          if (core.rvalid) begin
             axi.bvalid = 1'b1;
             axi.bresp = core.err ? SLVERR : OKAY;
             if (axi.bready)
               state_next = IDLE;
          end
      endcase
   end
endmodule
