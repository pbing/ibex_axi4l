/* Converter between DM slave interface and AXI4-Lite interface */

module slave2axi4l
  (core_if.master slave,
   axi4l_if.slave axi);

   import axi4l_pkg::OKAY;

   assign
     slave.req   = 1'b0,
     //          = slave.gnt,
     //          = slave.rvalid,
     slave.we    = 1'b0,
     slave.be    = '0,
     slave.addr  = '0,
     slave.wdata = '0;
     //          = slave.rdata,
     //          = slave.err;

   assign
      //         = axi.awvalid
     axi.awready = 1'b1,
     //          = axi.awaddr,
     //          = axi.awprot,

     //          = axi.wvalid,
     axi.wready  = 1'b1,
     //          = axi.wdata,
     //          = axi.wstrb,

     axi.bvalid  = 1'b1,
     //          = axi.bready,
     axi.bresp   = OKAY,
     
     //          = axi.arvalid,
     axi.arready = 1'b1,
     //          = axi.araddr,
     //          = axi.arprot,

     axi.rvalid  = 1'b1;
     //          = axi.rdata,
     //          = axi.rresp;
endmodule
