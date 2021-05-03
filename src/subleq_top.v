/*
 * SUBLEQ CPU Sample
 *   SUBLEQ Top Module
 *    Verilog code
 * @auther		Yoshiki Kurokawa <yoshiki.k963@gmail.com>
 * @copylight	2020 Yoshiki Kurokawa
 * @license		https://opensource.org/licenses/MIT     MIT license
 * @version		0.1
 */

module subleq_top(
	input rst_n,
	input fpga_rx,
	output fpga_tx,
	output [2:0] led
	);

wire clk;
wire [23:0] rdata_snd;
wire [55:0] cpust_snd;
wire [7:0] ram_radr;
wire [7:0] ram_rdata;
wire [7:0] ram_wadr;
wire [7:0] ram_wdata;
wire [7:0] rout;
wire [7:0] write_adr_dat;
wire cpu_running;
wire cpu_start;
wire cpust_start;
wire dump_cpu;
wire dump_running;
wire flushing_wq;
wire quit_cmd; 
wire ram_wen;
wire rdata_snd_start;
wire read_end_set;
wire read_start_set;
wire read_stop;
wire rout_en;
wire run;
wire s00_idle;
wire s01_rop0;
wire s02_rop1;
wire s03_rop2;
wire s04_rmd0;
wire s05_rmd1;
wire s06_exec;
wire s07_wbmd;
wire start_step;
wire start_trush;
wire trush_running;
wire write_address_set;
wire write_data_en;
wire crlf_in;

clkgen clkgen (
	.clk(clk)
	);

controller controller (
	.clk(clk),
	.rst_n(rst_n),
	.rout(rout),
	.rout_en(rout_en),
	.write_adr_dat(write_adr_dat),
	.cpu_start(cpu_start),
	.write_address_set(write_address_set),
	.write_data_en(write_data_en),
	.read_start_set(read_start_set),
	.read_end_set(read_end_set),
	.read_stop(read_stop),
	.dump_running(dump_running),
	.start_trush(start_trush),
	.trush_running(trush_running),
	.start_step(start_step),
	.cpu_running(cpu_running),
	.crlf_in(crlf_in),
	.quit_cmd(quit_cmd)
	);

led_io led_io (
	.clk(clk),
	.rst_n(rst_n),
	.ram_wadr(ram_wadr),
	.ram_wdata(ram_wdata),
	.ram_wen(ram_wen),
	.led(led)
	);

subleq_ram subleq_ram (
	.clk(clk),
	.ram_radr(ram_radr),
	.ram_rdata(ram_rdata),
	.ram_wadr(ram_wadr),
	.ram_wdata(ram_wdata),
	.ram_wen(ram_wen)
	);

subleq_regs_exec subleq_regs_exec (
	.clk(clk),
	.rst_n(rst_n),
	.s00_idle(s00_idle),
	.s01_rop0(s01_rop0),
	.s02_rop1(s02_rop1),
	.s03_rop2(s03_rop2),
	.s04_rmd0(s04_rmd0),
	.s05_rmd1(s05_rmd1),
	.s06_exec(s06_exec),
	.s07_wbmd(s07_wbmd),
	.run(run),
	.ram_radr(ram_radr),
	.ram_rdata(ram_rdata),
	.ram_wadr(ram_wadr),
	.ram_wdata(ram_wdata),
	.ram_wen(ram_wen),
	.write_adr_dat(write_adr_dat),
	.cpu_start(cpu_start),
	.write_address_set(write_address_set),
	.write_data_en(write_data_en),
	.read_start_set(read_start_set),
	.read_end_set(read_end_set),
	.read_stop(read_stop),
	.rdata_snd_start(rdata_snd_start),
	.rdata_snd(rdata_snd),
	.flushing_wq(flushing_wq),
	.dump_running(dump_running),
	.start_trush(start_trush),
	.trush_running(trush_running),
	.start_step(start_step),
	.cpu_running(cpu_running),
	.quit_cmd(quit_cmd),
	.dump_cpu(dump_cpu),
	.cpust_start(cpust_start),
	.cpust_snd(cpust_snd)
	);

subleq_status subleq_status (
	.clk(clk),
	.rst_n(rst_n),
	.run(run),
	.s00_idle(s00_idle),
	.s01_rop0(s01_rop0),
	.s02_rop1(s02_rop1),
	.s03_rop2(s03_rop2),
	.s04_rmd0(s04_rmd0),
	.s05_rmd1(s05_rmd1),
	.s06_exec(s06_exec),
	.s07_wbmd(s07_wbmd)
	);

uart_if uart_if (
	.clk(clk),
	.rst_n(rst_n),
	.fpga_rx(fpga_rx),
	.fpga_tx(fpga_tx),
	.rout(rout),
	.rout_en(rout_en),
	.rdata_snd_start(rdata_snd_start),
	.rdata_snd(rdata_snd),
	.flushing_wq(flushing_wq),
	.cpust_start(cpust_start),
	.cpust_snd(cpust_snd),
	.crlf_in(crlf_in),
	.dump_cpu(dump_cpu)
	);

endmodule
