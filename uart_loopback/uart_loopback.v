// Tang Nano UART master Loopback sample by yoshiki9636

module uart_loopback (
    //input clk ,
    input rst_n ,
    output [2:0] led , // r,b,g
    input wire fpga_rx ,
    output wire fpga_tx
);

wire clk;
wire oscclk;
// clock & PLL
Gowin_OSC osc1(
        .oscout(oscclk) //output oscout
);
Gowin_PLL pll1(
    .clkout(clk), //output clkout
    .clkin(oscclk) //input clkin
);
// uart connection
reg tx_en ;
wire [2:0] wadr;
reg [7:0] wdata;
reg rx_en; 
wire [2:0] radr;
wire [7:0] rdata;
wire rx_rdy_n = 1'b1;
wire tx_rdy_n = 1'b1;
wire ddis;
wire intr;
wire dcd_n = 1'b1;
wire cts_n = 1'b1;
wire dsr_n = 1'b1;
wire ri_n = 1'b1;
wire dtr_n;
wire rts_n;
// control signals
reg rx_dv ;
wire rdd ;
reg rx_rdy ;
reg rdy_dv ;

// rx read enable maker
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        rx_en <= 1'b0 ;
    else
        rx_en <= ~rx_en ;
end
// data read enable :  1:read rx-data  0:read rxrdy
assign rdd = rx_rdy & rx_en ;
// register address : 3'd0:rx-data 3'd5:rxrdy
assign radr = rdd ? 3'd0 :3'd5 ;
// read data valid
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        rx_dv <= 1'b0 ;
     else
        rx_dv <= rdd ;
end
// rxRDY valid
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        rdy_dv <= 1'b0 ;
    else
        rdy_dv <= rx_en ;
end
// rx-data ready
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        rx_rdy <= 1'b0;
    else if (rdy_dv)
        rx_rdy <= rdata[0] & ~rx_dv ;
end
// read data latch -> wdata
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        wdata <= 8'd0 ;
    else if (rx_dv)
        wdata <= rdata ;
end
// tx data enable
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        tx_en <= 1'b0 ;
    else
        tx_en <= rx_dv ;
end
// tx write address : 3'd0 fixed
assign wadr = 3'd0 ;
// uart master IP
UART_MASTER_Top uart1 (
  .I_CLK(clk),
  .I_RESETN(rst_n),
  .I_TX_EN(tx_en),
  .I_WADDR(wadr),
  .I_WDATA(wdata),
  .I_RX_EN(rx_en),
  .I_RADDR(radr),
  .O_RDATA(rdata),
  .SIN(fpga_rx),
  .RxRDYn(rx_rdy_n),
  .SOUT(fpga_tx),
  .TxRDYn(tx_rdy_n),
  .DDIS(ddis),
  .INTR(intr),
  .DCDn(dcd_n),
  .CTSn(cts_n),
  .DSRn(dsr_n),
  .RIn(ri_n),
  .DTRn(dtr_n),
  .RTSn(rts_n)
);
// rgb counter for debugging
wire rr, gg, bb;
reg [2:0] rgb;
always @ (posedge clk or negedge rst_n) begin
    if (~rst_n)
        rgb <= 3'd0 ;
    else if (rdd)
        rgb <= rgb + 3'd1 ;
end
// LED connection
assign rr = rgb[2] ;
assign gg = rgb[1] ;
assign bb = rgb[0] ;
assign led = { ~rr, ~bb, ~gg} ;

endmodule