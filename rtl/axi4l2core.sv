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

   resp_t bresp_buf;
   resp_t rresp_buf;
   data_t rdata_buf;

   enum logic [2:0] {IDLE, READ, READ_WAIT[2], WRITE, WRITE_WAIT[2]} state, state_next;

   always_ff @(posedge axi.aclk or negedge axi.aresetn)
     if (!axi.aresetn)
       state <= IDLE;
     else
       state <= state_next;

   always_comb begin
      state_next  = state;
      core.req    = 1'b0;
      core.we     = 1'b0;
      core.be     = axi.wstrb;
      core.addr   = axi.araddr;
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
             core.addr = axi.araddr;
             core.we = 1'b0;
             if (core.gnt) begin
                axi.arready = 1'b1;
                state_next = READ_WAIT0;
             end
             else
               state_next = READ;
          end
          else
            if (axi.awvalid && axi.wvalid) begin
               core.req = 1'b1;
               core.addr = axi.awaddr;
               core.we = 1'b1;
               if (core.gnt) begin
                  axi.awready = 1'b1;
                  axi.wready = 1'b1;
                  state_next = WRITE_WAIT0;
               end
               else
                 state_next = WRITE;
            end

        READ:
          begin
             core.req = 1'b1;
             core.addr = axi.araddr;
             core.we = 1'b0;
             if (core.gnt) begin
                axi.arready = 1'b1;
                state_next = READ_WAIT0;
             end
          end

        READ_WAIT0:
          if (core.rvalid) begin
             axi.rvalid = 1'b1;
             axi.rresp = resp(core.err);
             axi.rdata = core.rdata;
             if (axi.rready)
               state_next = IDLE;
             else
               state_next = READ_WAIT1;
          end

        READ_WAIT1:
          begin
             axi.rvalid = 1'b1;
             axi.rresp = rresp_buf;
             axi.rdata = rdata_buf;
             if (axi.rready)
               state_next = IDLE;
          end

        WRITE:
          begin
             core.req = 1'b1;
             core.addr = axi.awaddr;
             core.we = 1'b1;
             if (core.gnt) begin
                axi.awready = 1'b1;
                axi.wready = 1'b1;
                state_next = WRITE_WAIT0;
             end
          end

        WRITE_WAIT0:
          if (core.rvalid) begin
             axi.bvalid = 1'b1;
             axi.bresp = resp(core.err);
             if (axi.bready)
               state_next = IDLE;
             else
               state_next = WRITE_WAIT1;
          end

        WRITE_WAIT1:
          begin
             axi.bvalid = 1'b1;
             axi.bresp = bresp_buf;
             if (axi.bready)
               state_next = IDLE;
          end

        default state_next = IDLE;
      endcase
   end

   /* Buffer all responses because core.rvalid is only active for one clock cycle. */
   always_ff @(posedge axi.aclk)
     if ((state == WRITE_WAIT0) && core.rvalid)
       bresp_buf <= resp(core.err);

   always_ff @(posedge axi.aclk)
     if ((state == READ_WAIT0) && core.rvalid) begin
        rresp_buf <= resp(core.err);
        rdata_buf <= core.rdata;
     end

   function resp_t resp(input logic err);
      return err ? SLVERR : OKAY;
   endfunction
endmodule
