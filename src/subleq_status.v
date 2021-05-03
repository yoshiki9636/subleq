/*
 * SUBLEQ CPU Sample
 *  SUBLEQ Status Module
 *    Verilog code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2020 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

module subleq_status(
	input clk,
	input rst_n,
	input run,
	output s00_idle,  // idle status
	output s01_rop0,  // read operand 0
	output s02_rop1,  // read operand 1
	output s03_rop2,  // read operand 2
	output s04_rmd0,  // read memory data 0
	output s05_rmd1,  // read memory data 1
	output s06_exec,  // execute substruction
	output s07_wbmd   // write back memory data
	);


// status counter
reg [2:0] status_cntr;

always @ ( posedge clk or negedge rst_n ) begin
	if (~rst_n)
		status_cntr <= 3'd0;
	else if ((status_cntr == 3'd0)&&run)
		status_cntr <= 3'd1;
	else if (status_cntr == 3'd7)
		status_cntr <= 3'd0;
	else if (status_cntr >= 3'd1)
		status_cntr <= status_cntr + 3'd1;
end

// status decoder

function [7:0] status_decoder;
input [2:0] status_cntr;
begin
	case(status_cntr)
		3'd0 : status_decoder = 8'b0000_0001;
		3'd1 : status_decoder = 8'b0000_0010;
		3'd2 : status_decoder = 8'b0000_0100;
		3'd3 : status_decoder = 8'b0000_1000;
		3'd4 : status_decoder = 8'b0001_0000;
		3'd5 : status_decoder = 8'b0010_0000;
		3'd6 : status_decoder = 8'b0100_0000;
		3'd7 : status_decoder = 8'b1000_0000;
		default : status_decoder = 8'd0;
	endcase
end
endfunction

wire [7:0] decode_bits;

assign decode_bits = status_decoder( status_cntr );

assign s00_idle = decode_bits[0];  // idle status
assign s01_rop0 = decode_bits[1];  // read operand 0
assign s02_rop1 = decode_bits[2];  // read operand 1
assign s03_rop2 = decode_bits[3];  // read operand 2
assign s04_rmd0 = decode_bits[4];  // read memory data 0
assign s05_rmd1 = decode_bits[5];  // read memory data 1
assign s06_exec = decode_bits[6];  // execute substruction
assign s07_wbmd = decode_bits[7];   // write back memory data

endmodule
