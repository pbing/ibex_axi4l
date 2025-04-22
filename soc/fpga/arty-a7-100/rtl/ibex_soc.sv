/* SoC Toplevel */

module ibex_soc
  #(parameter bit ICache = 1'b1) // 0:prefetch buffer, 1:instruction cache
   (input  logic       clk100mhz,
    input  logic       ck_rst_n,

    input  logic [3:0] sw,
    output logic [3:0] led,
    input  logic [3:0] btn
`ifndef SYNTHESIS
    input  logic       tck,
    input  logic       trst_n,
    input  logic       tms,
    input  logic       tdi,
    output wire        tdo
`endif
    );

   import ibex_pkg::*;

   localparam [31:0] ram_base_addr = 'h00000000;
   localparam [31:0] ram_size      = 'h10000;

   localparam [31:0] led_base_addr = 'h10000000;
   localparam [31:0] led_size      = 'h1000;

   localparam [31:0] dm_base_addr  = 'h1A110000;
   localparam [31:0] dm_size       = 'h1000;

   logic          clk;
   logic          rst_n;

   logic          debug_req;
   dm::hartinfo_t hartinfo = '{zero1: 0,
                               nscratch: 2,   // Debug module needs at least two scratch regs
                               zero0: 0,
                               dataaccess: 1, // data registers are memory mapped in the debugger
                               datasize: dm::DataCount,
                               dataaddr: dm::DataAddr};
   logic          dmi_rst_n;
   logic          dmi_req_valid;
   logic          dmi_req_ready;
   dm::dmi_req_t  dmi_req;
   logic          dmi_resp_valid;
   logic          dmi_resp_ready;
   dm::dmi_resp_t dmi_resp;

`ifndef SYNTHESIS
   logic          tdo_o;
   logic          tdo_oe;

   assign tdo = tdo_oe ? tdo_o : 1'bz;
`endif

   axi4l_if axim[3] (.aclk (clk), .aresetn (rst_n));
   axi4l_if axis[3] (.aclk (clk), .aresetn (rst_n));

   crg u_crg
     (.clk100m   (clk100mhz),
      .ext_rst_n (ck_rst_n),
      .rst_n,
      .clk);

   axi4l_ibex_top
     #(.RegFile (RegFileFPGA),
       .ICache  (ICache))
   u_axi_ibex_top
     (.clk,
      .rst_n,
      .instr_axi            (axim[2]),
      .data_axi             (axim[1]),

      .test_en              (1'b0),
      .ram_cfg              ('0),

      .hart_id              (32'h00000000),
      .boot_addr            (32'h00000000),

      .irq_software         (1'b0),
      .irq_timer            (1'b0),
      .irq_external         (1'b0),
      .irq_fast             (15'h0000),
      .irq_nm               (1'b0),

      .scramble_key_valid   (1'b0),
      .scramble_key         ('0),
      .scramble_nonce       ('0),
      .scramble_req         (),

      .debug_req,
      .crash_dump           (),
      .double_fault_seen    (),

      .fetch_enable         ('1),
      .alert_minor          (),
      .alert_major_internal (),
      .alert_major_bus      (),
      .core_sleep           (),

      .scan_rst_n           (1'b0));

   axi4l_dm_top u_dm_top
     (.clk,
      .rst_n,

      .next_dm_addr (32'h00000000),
      .testmode     (1'b0),
      .ndmreset     (),
      .ndmreset_ack (1'b0),
      .dmactive     (),
      .debug_req,
      .unavailable  ('0),
      .hartinfo,

      .axis         (axis[0]),
      .axim         (axim[0]),

      .dmi_rst_n,
      .dmi_req_valid,
      .dmi_req_ready,
      .dmi_req,

      .dmi_resp_valid,
      .dmi_resp_ready,
      .dmi_resp);

   dmi_jtag u_dmi_jtag
     (.clk_i            (clk),
      .rst_ni           (rst_n),
      .testmode_i       (1'b0),

      .dmi_rst_no       (dmi_rst_n),
      .dmi_req_o        (dmi_req),
      .dmi_req_valid_o  (dmi_req_valid),
      .dmi_req_ready_i  (dmi_req_ready),

      .dmi_resp_i       (dmi_resp),
      .dmi_resp_ready_o (dmi_resp_ready),
      .dmi_resp_valid_i (dmi_resp_valid),

      .tck_i            (tck),
      .tms_i            (tms),
      .trst_ni          (trst_n),
      .td_i             (tdi),
      .td_o             (tdo_o),
      .tdo_oe_o         (tdo_oe));

   axi4l_interconnect
     #(.numm      (3),
       .nums      (3),
       .base_addr ('{dm_base_addr, ram_base_addr, led_base_addr}),
       .size      ('{dm_size, ram_size, led_size}))
   u_interconnect
     (.axim, .axis);

   axi4l_dpramx32 #(ram_size) u_dpram(.axi (axis[1]));

   axi4l_led
     #(.N (4))
   u_ledg
     (.axi (axis[2]), .led);
endmodule
