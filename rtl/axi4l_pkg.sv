/* AXI4 definitions */

package axi4l_pkg;
   typedef logic [31:0] addr_t;
   typedef logic [31:0] data_t;
   typedef logic [3:0]  strb_t;

   typedef struct packed {
      enum logic {UNPRIVILEGED, PRIVILEGED} access_e;
      enum logic {SECURE, NONSECURE}        secure_e;
      enum logic {DATA, INSTRUCTION}        type_e;
   } prot_t;

   typedef enum logic [1:0] {OKAY, EXOKAY, SLVERR, DECERR} resp_t /*verilator public*/;
endpackage
