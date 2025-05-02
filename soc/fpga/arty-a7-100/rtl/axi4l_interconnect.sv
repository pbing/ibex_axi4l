/* Wrapper around ZipCPU/axilxbar */

module  axi4l_interconnect
  #(parameter numm = 3,                      // number of masters
    parameter nums = 7,                      // number of slaves
    parameter [31:0] base_addr[nums] = '{0}, // base addresses of slaves
    parameter [31:0] size[nums]      = '{0}) // address size of slaves
   (axi4l_if.slave  axim[numm],              // AXI4-Lite master interfaces
    axi4l_if.master axis[nums]);             // AXI4-Lite slave interfaces

   import axi4l_pkg::*;

   localparam aw = $bits(addr_t);
   localparam dw = $bits(data_t);
   localparam sw = $bits(strb_t);
   localparam pw = $bits(prot_t);
   localparam rw = $bits(resp_t);

   localparam [nums-1:0][aw-1:0] slave_addr = {base_addr[6],
                                               base_addr[5],
                                               base_addr[4],
                                               base_addr[3],
                                               base_addr[2],
                                               base_addr[1],
                                               base_addr[0]};

   localparam [nums-1:0][aw-1:0] slave_mask = {~(size[6] - 1),
                                               ~(size[5] - 1),
                                               ~(size[4] - 1),
                                               ~(size[3] - 1),
                                               ~(size[2] - 1),
                                               ~(size[1] - 1),
                                               ~(size[0] - 1)};

   logic [numm-1:0]         axim_awvalid;
   logic [numm-1:0]         axim_awready;
   logic [numm-1:0][aw-1:0] axim_awaddr;
   logic [numm-1:0][pw-1:0] axim_awprot;

   logic [numm-1:0]         axim_wvalid;
   logic [numm-1:0]         axim_wready;
   logic [numm-1:0][dw-1:0] axim_wdata;
   logic [numm-1:0][sw-1:0] axim_wstrb;

   logic [numm-1:0]         axim_bvalid;
   logic [numm-1:0]         axim_bready;
   logic [numm-1:0][rw-1:0] axim_bresp;

   logic [numm-1:0]         axim_arvalid;
   logic [numm-1:0]         axim_arready;
   logic [numm-1:0][aw-1:0] axim_araddr;
   logic [numm-1:0][pw-1:0] axim_arprot;

   logic [numm-1:0]         axim_rvalid;
   logic [numm-1:0]         axim_rready;
   logic [numm-1:0][dw-1:0] axim_rdata;
   logic [numm-1:0][rw-1:0] axim_rresp;

   logic [nums-1:0]         axis_awvalid;
   logic [nums-1:0]         axis_awready;
   logic [nums-1:0][aw-1:0] axis_awaddr;
   logic [nums-1:0][pw-1:0] axis_awprot;

   logic [nums-1:0]         axis_wvalid;
   logic [nums-1:0]         axis_wready;
   logic [nums-1:0][dw-1:0] axis_wdata;
   logic [nums-1:0][sw-1:0] axis_wstrb;

   logic [nums-1:0]         axis_bvalid;
   logic [nums-1:0]         axis_bready;
   logic [nums-1:0][rw-1:0] axis_bresp;

   logic [nums-1:0]         axis_arvalid;
   logic [nums-1:0]         axis_arready;
   logic [nums-1:0][aw-1:0] axis_araddr;
   logic [nums-1:0][pw-1:0] axis_arprot;

   logic [nums-1:0]         axis_rvalid;
   logic [nums-1:0]         axis_rready;
   logic [nums-1:0][dw-1:0] axis_rdata;
   logic [nums-1:0][rw-1:0] axis_rresp;

   axilxbar
     #(.NM (numm),
       .NS (nums),
       .SLAVE_ADDR (slave_addr),
       .SLAVE_MASK (slave_mask))
   u_axilxbar
     (.S_AXI_ACLK    (axim[0].aclk),
      .S_AXI_ARESETN (axim[0].aresetn),

      .S_AXI_AWVALID (axim_awvalid),
      .S_AXI_AWREADY (axim_awready),
      .S_AXI_AWADDR  (axim_awaddr),
      .S_AXI_AWPROT  (axim_awprot),

      .S_AXI_WVALID  (axim_wvalid),
      .S_AXI_WREADY  (axim_wready),
      .S_AXI_WDATA   (axim_wdata),
      .S_AXI_WSTRB   (axim_wstrb),

      .S_AXI_BVALID  (axim_bvalid),
      .S_AXI_BREADY  (axim_bready),
      .S_AXI_BRESP   (axim_bresp),

      .S_AXI_ARVALID (axim_arvalid),
      .S_AXI_ARREADY (axim_arready),
      .S_AXI_ARADDR  (axim_araddr),
      .S_AXI_ARPROT  (axim_arprot),

      .S_AXI_RVALID  (axim_rvalid),
      .S_AXI_RREADY  (axim_rready),
      .S_AXI_RDATA   (axim_rdata),
      .S_AXI_RRESP   (axim_rresp),

      .M_AXI_AWADDR  (axis_awaddr),
      .M_AXI_AWPROT  (axis_awprot),
      .M_AXI_AWVALID (axis_awvalid),
      .M_AXI_AWREADY (axis_awready),

      .M_AXI_WDATA   (axis_wdata),
      .M_AXI_WSTRB   (axis_wstrb),
      .M_AXI_WVALID  (axis_wvalid),
      .M_AXI_WREADY  (axis_wready),

      .M_AXI_BRESP   (axis_bresp),
      .M_AXI_BVALID  (axis_bvalid),
      .M_AXI_BREADY  (axis_bready),

      .M_AXI_ARADDR  (axis_araddr),
      .M_AXI_ARPROT  (axis_arprot),
      .M_AXI_ARVALID (axis_arvalid),
      .M_AXI_ARREADY (axis_arready),

      .M_AXI_RDATA   (axis_rdata),
      .M_AXI_RRESP   (axis_rresp),
      .M_AXI_RVALID  (axis_rvalid),
      .M_AXI_RREADY  (axis_rready));


   for (genvar i = 0; i < numm; i++)
     assign
       axim_awvalid[i] = axim[i].awvalid, 
       axim[i].awready = axim_awready[i],
       axim_awaddr[i] = axim[i].awaddr,
       axim_awprot[i] = axim[i].awprot,
   
       axim_wvalid[i] = axim[i].wvalid,
       axim[i].wready = axim_wready[i],
       axim_wdata[i] = axim[i].wdata,
       axim_wstrb[i] = axim[i].wstrb,
   
       axim[i].bvalid = axim_bvalid[i],
       axim_bready[i] = axim[i].bready,
       axim[i].bresp = resp_t'(axim_bresp[i]),
   
       axim_arvalid[i] = axim[i].arvalid,
       axim[i].arready = axim_arready[i],
       axim_araddr[i] = axim[i].araddr,
       axim_arprot[i] = axim[i].arprot,
   
       axim[i].rvalid = axim_rvalid[i],
       axim_rready[i] = axim[i].rready,
       axim[i].rdata = axim_rdata[i],
       axim[i].rresp = resp_t'(axim_rresp[i]);

   for (genvar i = 0; i < nums; i++)
     assign
       axis[i].awvalid = axis_awvalid[i],
       axis_awready[i] = axis[i].awready,
       axis[i].awaddr = axis_awaddr[i],
       axis[i].awprot = axis_awprot[i],
   
       axis[i].wvalid = axis_wvalid[i],
       axis_wready[i] = axis[i].wready,
       axis[i].wdata = axis_wdata[i],
       axis[i].wstrb = axis_wstrb[i],
   
       axis_bvalid[i] = axis[i].bvalid,
       axis[i].bready = axis_bready[i],
       axis_bresp[i] = axis[i].bresp,
   
       axis[i].arvalid = axis_arvalid[i],
       axis_arready[i] = axis[i].arready,
       axis[i].araddr = axis_araddr[i],
       axis[i].arprot = axis_arprot[i],
   
       axis_rvalid[i] = axis[i].rvalid,
       axis[i].rready = axis_rready[i],
       axis_rdata[i] = axis[i].rdata,
       axis_rresp[i] = axis[i].rresp;
endmodule
