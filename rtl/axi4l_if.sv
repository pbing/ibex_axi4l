/* AXI4-Lite interface */

`default_nettype none

interface axi4l_if
  (input logic aclk,
   input logic aresetn);

   import axi4l_pkg::*;

   logic  awvalid;
   logic  awready;
   addr_t awaddr;
   prot_t awprot;

   logic  wvalid;
   logic  wready;
   data_t wdata;
   strb_t wstrb;

   logic  bvalid;
   logic  bready;
   resp_t bresp;

   logic  arvalid;
   logic  arready;
   addr_t araddr;
   prot_t arprot;

   logic  rvalid;
   logic  rready;
   data_t rdata;
   resp_t rresp;

   modport master
     (input  aclk,
      input  aresetn,
      output awvalid,
      input  awready,
      output awaddr,
      output awprot,
      output wvalid,
      input  wready,
      output wdata,
      output wstrb,
      input  bvalid,
      output bready,
      input  bresp,
      output arvalid,
      input  arready,
      output araddr,
      output arprot,
      input  rvalid,
      output rready,
      input  rdata,
      input  rresp);

   modport slave
     (input  aclk,
      input  aresetn,
      input  awvalid,
      output awready,
      input  awaddr,
      input  awprot,
      input  wvalid,
      output wready,
      input  wdata,
      input  wstrb,
      output bvalid,
      input  bready,
      output bresp,
      input  arvalid,
      output arready,
      input  araddr,
      input  arprot,
      output rvalid,
      input  rready,
      output rdata,
      output rresp);

   modport monitor
     (input  aclk,
      input  aresetn,
      input  awvalid,
      input  awready,
      input  awaddr,
      input  awprot,
      input  wvalid,
      input  wready,
      input  wdata,
      input  wstrb,
      input  bvalid,
      input  bready,
      input  bresp,
      input  arvalid,
      input  arready,
      input  araddr,
      input  arprot,
      input  rvalid,
      input  rready,
      input  rdata,
      input  rresp);
endinterface

`resetall
