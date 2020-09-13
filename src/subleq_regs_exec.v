module subleq_regs_exec(
	input clk,
	input rst_n,
	input s00_idle,  // idle status
	input s01_rop0,  // read operand 0
	input s02_rop1,  // read operand 1
	input s03_rop2,  // read operand 2
	input s04_rmd0,  // read memory data 0
	input s05_rmd1,  // read memory data 1
	input s06_exec,  // execute substruction
	input s07_wbmd,  // write back memory data
	output run,
	output [7:0] ram_radr,
	input [7:0] ram_rdata,
	output [7:0] ram_wadr,
	output [7:0] ram_wdata,
	output ram_wen,
	// from controller
	input [7:0] write_adr_dat,
	input cpu_start,
	input write_address_set,
	input write_data_en,
	input read_start_set,
	input read_end_set,
	input read_stop,
	output rdata_snd_start,
	output [23:0] rdata_snd,
	input flushing_wq,
	output dump_running,
	input start_trush,
	output trush_running,
	input start_step,
	output wire cpu_running,
	input quit_cmd,
	input dump_cpu,
	output cpust_start,
	output [55:0] cpust_snd

	);

// PC

reg [7:0] pc;
wire inc_pc;
wire ld_pc;
wire [7:0] ld_value_pc;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		pc <= 8'd0;
	else if (start_trush)
		pc <= 8'd0;
	else if (cpu_start)
		pc <= write_adr_dat;
	else if (ld_pc)
		pc <= ld_value_pc;
	else if (inc_pc)
		pc <= pc + 8'd1;
end

// index registers

reg [7:0] idx0;
reg [7:0] idx1;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		idx0 <= 8'd0;
	else if (s02_rop1)
		idx0 <= ram_rdata;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		idx1 <= 8'd0;
	else if (s03_rop2)
		idx1 <= ram_rdata;
end

// jump address register

reg [7:0] jmpa;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		jmpa <= 8'd0;
	else if (s04_rmd0)
		jmpa <= ram_rdata;
end

// data register

reg [7:0] data0;
wire [7:0] data1; // using output of memory to reduce status. It could be critical path.

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		data0 <= 8'd0;
	else if (s05_rmd1)
		data0 <= ram_rdata;
end

assign data1 = ram_rdata;

// executor

wire [8:0] sub;
wire [8:0] pre_accm;
reg [8:0] accm;

assign sub = { data0[7], data0 } - { data1[7], data1 };
assign pre_accm = ((sub[8] == 0)&&(sub[7] == 1)) ? 9'h07f :
                  ((sub[8] == 1)&&(sub[7] == 0)) ? 9'd180 : sub;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		accm <= 9'd0;
	else if (s06_exec)
		accm <= pre_accm;
end

// read address selector
reg [8:0] cmd_read_adr;

assign ram_radr = dump_running ? cmd_read_adr :
				  s01_rop0 ? pc :
                  s02_rop1 ? pc :
				  s03_rop2 ? pc :
				  s04_rmd0 ? idx0 :
				  s05_rmd1 ? idx1 : 8'd0;

// write signals
reg [7:0] cmd_wadr_cntr;
wire [7:0] trush_adr;

assign ram_wadr = trush_running ? trush_adr :
                  write_data_en ? cmd_wadr_cntr : idx0;
assign ram_wdata = trush_running ? 8'd0 :
                   write_data_en ? write_adr_dat : accm[7:0];
assign ram_wen = trush_running | write_data_en | s07_wbmd;

// pc jump selector and control logics

assign ld_value_pc = jmpa;
assign ld_pc = ((accm[8] == 1)|(accm[7:0] == 8'd0)) & s07_wbmd;
assign inc_pc = s01_rop0 | s02_rop1 | s03_rop2;

//
// control logics
// CPU running state

reg cpu_run_state;
reg step_reserve;
reg cupst_snd_wait;
wire rdata_snd_wait;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		cpu_run_state <= 1'b0;
	else if (quit_cmd)
		cpu_run_state <= 1'b0;	
	else if (cpu_start)
		cpu_run_state <= 1'b1;
end

assign cpu_running = cpu_run_state & ~(rdata_snd_wait | cupst_snd_wait);

wire step_idle_nodump = s00_idle & ~dump_cpu;
wire step_start_cond = step_idle_nodump & ~(rdata_snd_wait | cupst_snd_wait);

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		step_reserve <= 1'b0;
	else if (step_start_cond)
		step_reserve <= 1'b0;	
	else if (~step_idle_nodump & start_step)
		step_reserve <= 1'b1;
end

wire step_run = step_start_cond & (step_reserve | start_step);

// sequencer start signal
assign run = cpu_running | step_run;

// write data address 
always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		cmd_wadr_cntr <= 8'd0;
	else if (write_address_set)
		cmd_wadr_cntr <= write_adr_dat;
	else if (write_data_en)
		cmd_wadr_cntr <= cmd_wadr_cntr + 8'd1;
end

// read data address
reg [7:0] cmd_read_end;
wire dump_end;
wire radr_cntup;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		cmd_read_adr <= 9'd0;
	else if (read_start_set)
		cmd_read_adr <= write_adr_dat;
	else if (radr_cntup)
		cmd_read_adr <= cmd_read_adr + 9'd1;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		cmd_read_end <= 8'd0;
	else if (read_end_set)
		cmd_read_end <= write_adr_dat;
end

assign dump_end = (cmd_read_adr >= { 1'b0, cmd_read_end });

`define D_IDLE 3'd0
`define D_1STR 3'd1
`define D_2NDR 3'd2
`define D_3RDR 3'd3
`define D_WAIT 3'd4

reg [2:0] status_dump;
wire [2:0] next_status_dump;

function [2:0] dump_status;
input [2:0] status_dump;
input read_end_set;
input read_stop;
input flushing_wq;
input dump_end;
begin
	case(status_dump)
		`D_IDLE :
			if (read_end_set)
				dump_status = `D_1STR;
			else
				dump_status = `D_IDLE;
		`D_1STR :
			if (read_stop)
				dump_status = `D_IDLE;
			else
				dump_status = `D_2NDR;
		`D_2NDR :
			if (read_stop)
				dump_status = `D_IDLE;
			else
				dump_status = `D_3RDR;
		`D_3RDR :
			if (read_stop)
				dump_status = `D_IDLE;
			else
				dump_status = `D_WAIT;
		`D_WAIT :
			if (read_stop)
				dump_status = `D_IDLE;
			else if (flushing_wq & dump_end)
				dump_status = `D_IDLE;
			else if (flushing_wq & ~dump_end)
				dump_status = `D_1STR;
			else
				dump_status = `D_WAIT;
		default : dump_status = `D_IDLE;
	endcase
end
endfunction

assign next_status_dump = dump_status(
							status_dump,
							read_end_set,
							read_stop,
							flushing_wq,
							dump_end);

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		status_dump <= 3'd0;
	else
		status_dump <= next_status_dump;
end

assign radr_cntup = (status_dump == `D_1STR)|(status_dump == `D_2NDR)|(status_dump == `D_3RDR);
assign dump_running = (status_dump != `D_IDLE);
assign rdata_snd_wait = (status_dump == `D_WAIT);
wire en_1st_data = (status_dump == `D_2NDR);
wire en_2nd_data = (status_dump == `D_3RDR);
reg en_3rd_data;
reg [7:0] data_1st;
reg [7:0] data_2nd;
reg [7:0] data_3rd;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		en_3rd_data <= 1'b0;
	else
		en_3rd_data <= en_2nd_data;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		data_1st <= 8'd0;
	else if (en_1st_data)
		data_1st <= ram_rdata;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		data_2nd <= 8'd0;
	else if (en_2nd_data)
		data_2nd <= ram_rdata;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		data_3rd <= 8'd0;
	else if (en_3rd_data)
		data_3rd <= ram_rdata;
end

assign rdata_snd = { data_1st, data_2nd, data_3rd };

// trashing memory data
reg [8:0] trash_cntr;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		trash_cntr <= 9'd0;
	else if (start_trush)
		trash_cntr <= 9'h100;
	else if (trash_cntr[8])
		trash_cntr <= trash_cntr + 9'd1;
end

assign trush_adr = trash_cntr[7:0];
assign trush_running = trash_cntr[8];

// send CPU status to UART i/f
reg [7:0] sample_pc;
reg [7:0] sample_data1;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		sample_pc <= 8'd0;
	else if (s01_rop0)
		sample_pc <= pc;
end

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		sample_data1 <= 8'd0;
	else if (s06_exec)
		sample_data1 <= data1;
end

assign cpust_snd = {  sample_pc, idx0, idx1, jmpa, data0, sample_data1, accm[7:0] } ;


always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		cupst_snd_wait <= 1'b0;
	else if (flushing_wq)
		cupst_snd_wait <= 1'b0;
	else if (s07_wbmd)
		cupst_snd_wait <= 1'b1;
end

reg cpust_snd_wait_dly;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		cpust_snd_wait_dly <= 1'b0;
	else
		cpust_snd_wait_dly <= cupst_snd_wait;
end

assign cpust_start = cupst_snd_wait & ~cpust_snd_wait_dly;

reg rdata_snd_wait_dly;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n)
		rdata_snd_wait_dly <= 1'b0;
	else
		rdata_snd_wait_dly <= rdata_snd_wait;
end

assign rdata_snd_start = rdata_snd_wait & ~rdata_snd_wait_dly;


endmodule
