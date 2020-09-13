module simtop;

reg rst_n;
wire fpga_rx = 1'b0;
wire fpga_tx;
wire [2:0] led;

subleq_top subleq_top(
	.rst_n(rst_n),
	.fpga_rx(fpga_rx),
	.fpga_tx(fpga_tx),
	.led(led)
	);

initial begin
	rst_n = 1'b1;
#10
	rst_n = 1'b0;
#20
	rst_n = 1'b1;
#500000
	$stop;
end

endmodule
