/* Core memory interface to AXI4-Lite converter
 *
 * Based on https://github.com/pulp-platform/core2axi
 */

module core2axi4l
  (core_if.slave   core,
   axi4l_if.master axi);

   import axi4l_pkg::*;

   enum logic [2:0] {IDLE, READ_WAIT, WRITE_DATA, WRITE_ADDR, WRITE_WAIT} state, state_next;

   logic clk;
   logic rst_n;
   logic valid;
   logic granted;

   assign clk   = axi.aclk;
   assign rst_n = axi.aresetn;

   // main FSM
   always_comb begin
      state_next  = state;
      granted     = 1'b0;
      valid       = 1'b0;
      axi.awvalid = 1'b0;
      axi.arvalid = 1'b0;
      axi.rready  = 1'b0;
      axi.wvalid  = 1'b0;
      axi.bready  = 1'b0;

      case (state)
        // wait for a request to come in from the core
        IDLE:
          // the same logic is also inserted in READ_WAIT and WRITE_WAIT, if you
          // change it here, take care to change it there too!
          if (core.req)
            // send address over aw channel for writes,
            // over ar channels for reads
            if (core.we) begin
               axi.awvalid = 1'b1;
               axi.wvalid  = 1'b1;
               if (axi.awready)
                 if (axi.wready) begin
                    granted = 1'b1;
                    state_next = WRITE_WAIT;
                 end
                 else
                   state_next = WRITE_DATA;
               else
                 if (axi.wready)
                   state_next = WRITE_ADDR;
            end
            else begin
               axi.arvalid = 1'b1;
               if (axi.arready) begin
                  granted = 1'b1;
                  state_next = READ_WAIT;
               end
            end

        // if the bus has not accepted our write data right away, but has
        // accepted the address already
        WRITE_DATA:
          begin
             axi.wvalid = 1'b1;
             if (axi.wready) begin
                granted = 1'b1;
                state_next = WRITE_WAIT;
             end
          end

        // the bus has accepted the write data, but not yet the address
        // this happens very seldom, but we still have to deal with the
        // situation
        WRITE_ADDR:
          begin
             axi.awvalid = 1'b1;
             if (axi.awready) begin
                granted = 1'b1;
                state_next = WRITE_WAIT;
             end
          end

        // we have sent the address and data and just wait for the write data to
        // be done
        WRITE_WAIT:
          begin
             axi.bready = 1'b1;
             if (axi.bvalid) begin
                valid = 1'b1;
                state_next = IDLE;
             end
          end

        // we wait for the read response, address has been sent successfully
        READ_WAIT:
          if (axi.rvalid) begin
             valid = 1'b1;
             axi.rready = 1'b1;
             state_next = IDLE;
          end

        default state_next = IDLE;
      endcase
   end

   always_ff @(posedge clk or negedge rst_n)
     if (!rst_n)
       state <= IDLE;
     else
       state <= state_next;

   assign axi.wdata   = core.wdata;
   assign axi.wstrb   = core.be;

   assign axi.awaddr  = core.addr;
   assign axi.awprot  = '0;

   assign axi.araddr  = core.addr;
   assign axi.arprot  = '0;

   assign core.rdata  = axi.rdata;
   assign core.err    = (axi.rvalid && (axi.rresp != OKAY)) || (axi.bvalid && (axi.bresp != OKAY));
   assign core.rvalid = valid;
   assign core.gnt    = granted;
endmodule
