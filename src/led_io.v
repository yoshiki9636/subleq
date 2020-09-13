module led_io(
	input clk,
	input rst_n,
	input [7:0] ram_wadr,
	input [7:0] ram_wdata,
	input ram_wen,
    output [2:0] led // r,b,g
	);

// LED I/O
// address 0xFD:RED 0xFE:GREEN 0xFF:BLUE

reg red;
reg green;
reg blue;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		red <= 1'b0;
	else if ((ram_wadr == 8'hfd)&&(ram_wen))
		red <= (ram_wdata == 8'hff);
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		green <= 1'b0;
	else if ((ram_wadr == 8'hfe)&&(ram_wen))
		green <= (ram_wdata == 8'hff);
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		blue <= 1'b0;
	else if ((ram_wadr == 8'hff)&&(ram_wen))
		blue <= (ram_wdata == 8'hff);
end

assign led = { ~red, ~blue, ~green };

endmodule
