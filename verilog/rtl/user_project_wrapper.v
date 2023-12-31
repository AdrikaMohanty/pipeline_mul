// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

/*--------------------------------------*/
/* User project is instantiated  here   */
/*--------------------------------------*/

pipeline_mul pipeline_mul(
`ifdef USE_POWER_PINS
	.vccd1(vccd1),	// User area 1 1.8V power
	.vssd1(vssd1),	// User area 1 digital ground
`endif

    .clk(wb_clk_i),
    .rst(wb_rst_i),

    // MGMT SoC Wishbone Slave

    /*.wbs_cyc_i(wbs_cyc_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_ack_o(wbs_ack_o),
    .wbs_dat_o(wbs_dat_o),

    // Logic Analyzer

    .la_data_in(la_data_in),
    .la_data_out(la_data_out),
    .la_oenb (la_oenb),*/

    // IO Pads

    .A(io_in),
    .B(io_in),
    .F(io_out)
    //.io_oeb({io_oeb[37:30],io_oeb[7:0]}),

    // IRQ
    //.irq(user_irq)
);

endmodule	// user_project_wrapper

module pipeline_mul(
   `define BIAS 8'b01111111
   `ifdef USE_POWER_PINS
	inout vccd1,
	inout vssd1,	// User area 1 digital ground
   `endif
   input clk, rst,
   input [31:0]A,
   input [31:0]B,

   output [31:0]F);
   reg [31:0]F;
	

//   reg [1:0]sign;
//   reg [49:0]mantissa;


//////////////// PIPE-LINE REGISTERS /////////////////
reg [62:0] P1;
reg [66:0] P2;
reg [31:0] P3;
//////////////////////////////////////////////////////

initial
begin	
	P1 = 0;
	P2 = 0;
	P3 = 0;
end


wire [1:0]sign;
wire [49:0]mantissa;

assign sign = A[31]+B[31];

//always @ ( F or A or B )
always @ ( posedge clk )
begin
	//solve for the sign bit part
	/////////////////////////////////////////////////////////
	P1[0] <= (sign == 1'b1) ? 1'b1 : 1'b0;
	P1[31:1] <= A[30:0];
	P1[62:32] <= B[30:0];

	///////////////////////////////////////////////////////////
	P2[0] <= P1[0];
	P2[50:1] <= P1[23:1] * P1[54:32];

	P2[58:51] <= P1[31:24];
	P2[66:59] <= P1[62:55];

///////////////////////////////////////////////////////////
	P3[0] <= P2[0];

	if(P2[50:24] == 0) begin
	   P3[23:1] = P2[23:1];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h00;
	end
	else if(P2[50] == 1) begin
	   P3[23:1] = P2[49:27];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h1a;
	end
	else if(P2[49] == 1) begin
	   P3[23:1] = P2[48:26];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h19;
	end
	else if(P2[48] == 1) begin
	   P3[23:1] = P2[47:25];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h18;
	end
	else if(P2[47] == 1) begin
	   P3[23:1] = P2[46:24];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h17;
	end			
	else if(P2[46] == 1) begin
	   P3[23:1] = P2[45:23];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h16;
	end	
	else if(P2[45] == 1) begin
	   P3[23:1] = P2[44:22];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h15;
	end	
	else if(P2[44] == 1) begin
	   P3[23:1] = P2[43:21];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h14;
	end
	else if(P2[43] == 1) begin
	   P3[23:1] = P2[42:20];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h13;
	end
	else if(P2[42] == 1) begin
	   P3[23:1] = P2[41:19];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h12;
	end
	else if(P2[41] == 1) begin
	   P3[23:1] = P2[40:18];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h11;
	end
	else if(P2[40] == 1) begin
	   P3[23:1] = P2[39:17];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h10;
	end
	else if(P2[39] == 1) begin
	   P3[23:1] = P2[38:16];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h0f;
	end
	else if(P2[38] == 1) begin
	   P3[23:1] = P2[37:15];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h0e;
	end
	else if(P2[37] == 1) begin
	   P3[23:1] = P2[36:14];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h0d;
	end
	else if(P2[36] == 1) begin
	   P3[23:1] = P2[35:13];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h0c;
	end
	else if(P2[35] == 1) begin
	   P3[23:1] = P2[34:12];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h0b;
	end
	else if(P2[34] == 1) begin
	   P3[23:1] = P2[33:11];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h0a;
	end
	else if(P2[33] == 1) begin
	   P3[23:1] = P2[32:10];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h09;
	end
	else if(P2[32] == 1) begin
	   P3[23:1] = P2[31:09];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h08;
	end
	else if(P2[31] == 1) begin
	   P3[23:1] = P2[30:08];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h07;
	end
	else if(P2[30] == 1) begin
	   P3[23:1] = P2[29:07];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h06;
	end
	else if(P2[29] == 1) begin
	   P3[23:1] = P2[28:06];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h05;
	end
	else if(P2[28] == 1) begin
	   P3[23:1] = P2[27:05];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h04;
	end
	else if(P2[27] == 1) begin
	   P3[23:1] = P2[26:04];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h03;
	end
	else if(P2[26] == 1) begin
	   P3[23:1] = P2[25:03];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h02;
	end
	else begin
	   P3[23:1] = P2[24:02];
	   P3[31:24] = P2[58:51] + P2[66:59] - `BIAS + 8'h01;
	end

///////////////////////////////////////////////////////////
	F[31] <= P3[0];
	F[30:0] <= P3[31:1];

////////////////////////////////////////////////////////////
end

endmodule

`default_nettype wire
