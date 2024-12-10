\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
   

   // #################################################################
   // #                                                               #
   // #  Starting-Point Code for MEST Course Tiny Tapeout Calculator  #
   // #                                                               #
   // #################################################################
   
   // ========
   // Settings
   // ========
   //m4_define(DEBUG_MAX_CNT, 14'h)
   //-------------------------------------------------------
   // Build Target Configuration
   //
   var(my_design, tt_um_example)   /// The name of your top-level TT module, to match your info.yml.
   var(target, ASIC)   /// Note, the FPGA CI flow will set this to FPGA.
   //-------------------------------------------------------
   
   var(in_fpga, 1)   //0 1 to include the demo board. (Note: Logic will be under /fpga_pins/fpga.)
   var(debounce_inputs, 0)
                     /// Legal values:
                     ///   1: Provide synchronization and debouncing on all input signals.
                     ///   0: Don't provide synchronization and debouncing.
                     ///   m5_if_defined_as(MAKERCHIP, 1, 0, 1): Debounce unless in Makerchip.
   
   // ======================
   // Computed From Settings
   // ======================
   
   // If debouncing, a user's module is within a wrapper, so it has a different name.
   var(user_module_name, my_design)
   var(debounce_cnt, m5_if_defined_as(MAKERCHIP, 1, 8'h03, 8'hff))

\SV
   // Include Tiny Tapeout Lab.
   m4_include_lib(https:/['']/raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/35e36bd144fddd75495d4cbc01c4fc50ac5bde6f/tlv_lib/tiny_tapeout_lib.tlv)
   // Calculator VIZ.
   m4_include_lib(https:/['']/raw.githubusercontent.com/efabless/chipcraft---mest-course/main/tlv_lib/calculator_shell_lib.tlv)
   
   module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
       // The FPGA is based on TinyTapeout 3 which has no bidirectional I/Os (vs. TT6 for the ASIC).
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
        // Synchronize.
    logic [17:0] inputs_ff, inputs_sync;
    always @(posedge clk) begin
        inputs_ff <= {ui_in, uio_in, ena, rst_n};
        inputs_sync <= inputs_ff;
    end

    // Debounce.
    `define DEBOUNCE_MAX_CNT 14'h3fd;
    logic [17:0] inputs_candidate, inputs_captured;
    logic sync_rst_n = inputs_sync[0];
    logic [13:0] cnt;
    always @(posedge clk) begin
        if (!sync_rst_n)
           cnt <= `DEBOUNCE_MAX_CNT;
        else if (inputs_sync != inputs_candidate) begin
           // Inputs changed before stablizing.
           cnt <= `DEBOUNCE_MAX_CNT;
           inputs_candidate <= inputs_sync;
        end
        else if (cnt > 0)
           cnt <= cnt - 14'b1;
        else begin
           // Cnt == 0. Capture candidate inputs.
           inputs_captured <= inputs_candidate;
        end
    end
    logic [7:0] clean_ui_in, clean_uio_in;
    logic clean_ena, clean_rst_n;
    assign {clean_ui_in, clean_uio_in, clean_ena, clean_rst_n} = inputs_captured;

    my_design my_design (
        .ui_in(clean_ui_in),
        .uio_in(clean_uio_in),
        .ena(clean_ena),
        .rst_n(clean_rst_n),
        .*);
endmodule
\TLV calc()
   
   
   |calc
      @1
         $equals_in = *ui_in[7];
         $reset = *reset;
         $valid = (>>1$equals_in==0 & $equals_in ==1); 
         $val1[7:0] = >>1$out;
         $val2[7:0] = {4'b0000,*ui_in[3:0]};
         $sum[7:0] = $val1 + $val2;
         $diff[7:0] = $val1 - $val2;
         $prod[7:0] = $val1 * $val2;
         $quot[7:0] = $val1 / $val2;
         $op[1:0] = *ui_in[5:4];
         $out[7:0] = $reset ? 8'b0: $valid ? ($op[1:0] == 2'd0) ? $sum[7:0] : (($op[1:0] == 2'd1) ? $diff[7:0] : (($op[1:0] == 2'd2) ? $prod[7:0] : $quot[7:0])) : >>1$out ;
   
   $digit[3:0] = |calc>>1$out[3:0];
   *uo_out =
         $digit == 4'b0000 ? 8'b00111111 : //0
         $digit == 4'b0001 ? 8'b00000110 : //1
         $digit == 4'b0010 ? 8'b01011011 : //2
         $digit == 4'b0011 ? 8'b01001111 : //3
         $digit == 4'b0100 ? 8'b01100110 : //4
         $digit == 4'b0101 ? 8'b01111101 : //5
         $digit == 4'b0110 ? 8'b01111101 : //6
         $digit == 4'b0111 ? 8'b00000111 : //7
         $digit == 4'b1000 ? 8'b01111111 : //8
         $digit == 4'b1001 ? 8'b01101111 : //9
         $digit == 4'b1010 ? 8'b01110111 : //A
         $digit == 4'b1011 ? 8'b01111100 : //b
         $digit == 4'b1100 ? 8'b00111001 : //C
         $digit == 4'b1101 ? 8'b01011110 : //d
         $digit == 4'b1110 ? 8'b01111001 : //E
         $digit == 4'b1111 ? 8'b01110001 : 8'b11111111 ;
   
            
            
   
   // Note that pipesignals assigned here can be found under /fpga_pins/fpga.
   
   

   m5+cal_viz(@1, m5_if(m5_in_fpga, /fpga, /top))
   
   // Connect Tiny Tapeout outputs. Note that uio_ outputs are not available in the Tiny-Tapeout-3-based FPGA boards.
   //*uo_out = 8'b0;
   m5_if_neq(m5_target, FPGA, ['*uio_out = 8'b0;'])
   m5_if_neq(m5_target, FPGA, ['*uio_oe = 8'b0;'])

\SV

// ================================================
// A simple Makerchip Verilog test bench driving random stimulus.
// Modify the module contents to your needs.
// ================================================

module top(input logic clk, input logic reset, input logic [31:0] cyc_cnt, output logic passed, output logic failed);
   // Tiny tapeout I/O signals.
   logic [7:0] ui_in, uo_out;
   m5_if_neq(m5_target, FPGA, ['logic [7:0] uio_in, uio_out, uio_oe;'])
   logic [31:0] r;
   always @(posedge clk) r <= m5_if_defined_as(MAKERCHIP, 1, ['$urandom()'], ['0']);
   assign ui_in = r[7:0];
   m5_if_neq(m5_target, FPGA, ['assign uio_in = 8'b0;'])
   logic ena = 1'b0;
   logic rst_n = ! reset;
   
   // Instantiate the Tiny Tapeout module.
   tt_um_example tt(.*);
   
   assign passed = top.cyc_cnt > 80;
   assign failed = 1'b0;
endmodule


// Provide a wrapper module to debounce input signals if requested.
m5_if(m5_debounce_inputs, ['m5_tt_top(m5_my_design)'])
\SV



// =======================
// The Tiny Tapeout module
// =======================

module m5_user_module_name (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    m5_if_eq(m5_target, FPGA, ['/']['*'])   // The FPGA is based on TinyTapeout 3 which has no bidirectional I/Os (vs. TT6 for the ASIC).
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    m5_if_eq(m5_target, FPGA, ['*']['/'])
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
   wire reset = ! rst_n;

\TLV tt_lab()
   // Connect Tiny Tapeout I/Os to Virtual FPGA Lab.
   m5+tt_connections()
   // Instantiate the Virtual FPGA Lab.
   m5+board(/top, /fpga, 7, $, , calc)
   // Label the switch inputs [0..7] (1..8 on the physical switch panel) (top-to-bottom).
   m5_if(m5_in_fpga, ['m5+tt_input_labels_viz(['"Value[0]", "Value[1]", "Value[2]", "Value[3]", "Op[0]", "Op[1]", "Op[2]", "="'])'])

\TLV
   /* verilator lint_off UNOPTFLAT */
   m5_if(m5_in_fpga, ['m5+tt_lab()'], ['m5+calc()'])

\SV
endmodule
