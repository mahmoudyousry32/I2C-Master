module I2C_Controller(clk,
					  rst,
					  wr_i2c,
					  cmd,
					  din,
					  clk_dvsr,
					  dout,
					  ack,
					  rdy,
					  done_tick,
					  sda,
					  scl);
					  
input clk;
input rst;
input wr_i2c;
input [7:0] din;
input [1:0] clk_dvsr;
input [2:0] cmd ;

inout tri sda;
output tri scl;

output scl;
output done_tick;
output rdy;
output ack;
output [7:0] dout;

parameter SYS_CLK = 100000000;

localparam F_I2C_100k_Q	 = (SYS_CLK / 100000)/4;
localparam F_I2C_100k_H	 = (SYS_CLK / 100000)/2;
localparam F_I2C_400k_Q	 = (SYS_CLK / 400000)/4;
localparam F_I2C_400k_H	 = (SYS_CLK / 400000)/2;
localparam F_I2C_3400KHZ_Q	 = (SYS_CLK / 3400000)/4;
localparam F_I2C_3400KHZ_H	 = (SYS_CLK / 3400000)/2;
localparam COUNTER_W = $clog2(F_I2C_100k_H);
localparam F_100K = 2'b00;
localparam F_400K = 2'b01;
localparam F_3400K = 2'b10;

reg [3:0] state_reg;
reg [COUNTER_W : 0 ] tick_counter;
reg [3:0] bit_count;
reg [8:0] i2c_tx_reg;
reg [8:0] i2c_rx_reg;
reg [COUNTER_W : 0] quarter_period;
reg [COUNTER_W : 0] half_period ;
reg sda_out_reg;
reg scl_out_reg;
wire input_en ;
reg rdy;
reg done_tick;
reg [2:0] CMD_reg;
wire sda_out;




localparam 	IDLE	=	4'h0;
localparam	START_1	=	4'h1;
localparam	START_2	=	4'h2;
localparam	HOLD	=	4'h3;
localparam	DATA1	=	4'h4;
localparam	DATA2	=	4'h5;
localparam	DATA3	=	4'h6;
localparam	DATA4	=	4'h7;
localparam	DATA_E	=	4'h8;
localparam	STOP_1	=	4'h9;
localparam	STOP_2	=	4'ha;
localparam	RESTART	=	4'hb;

localparam CMD_IDLE	=	3'b000;
localparam CMD_STOP		=	3'b001;
localparam CMD_READ		=	3'b010;
localparam CMD_WRITE	=	3'b011;
localparam CMD_RESTART	=	3'b100;
localparam CMD_START		=   3'b101;

always@(posedge clk,posedge rst) 
	if(rst) CMD_reg <= CMD_IDLE;
	else if(wr_i2c) CMD_reg <= cmd;



always@(posedge clk,posedge rst)begin 
if(rst)begin
	state_reg <= IDLE;
	tick_counter <= 0 ;
	sda_out_reg <= 1;
	scl_out_reg <= 1;
	i2c_tx_reg <= 0 ;
	i2c_rx_reg <= 0;
	rdy = 1 ;
	bit_count <= 0;
	end
else
	case(state_reg)
	
	IDLE			:		if(wr_i2c && cmd == CMD_START)begin
							state_reg <= START_1;
							rdy = 0 ;
							sda_out_reg <= 0;
							end

	START_1			:		if(tick_counter == half_period - 1) begin
							tick_counter <= 0;
							state_reg <= START_2;
							scl_out_reg <= 0;
							end
							else tick_counter <= tick_counter + 1;
	
	START_2			:		if(tick_counter == half_period - 1) begin
							tick_counter <= 0;
							state_reg <= HOLD;
							rdy <= 1;
						    end
							else tick_counter <= tick_counter + 1 ;
							
	HOLD			:		begin
							if(wr_i2c && cmd == CMD_READ) begin
								state_reg <= DATA1;
								i2c_tx_reg <= {din,din[0]};
								rdy = 0 ;
								end
							else if (wr_i2c && cmd == CMD_WRITE) begin
								i2c_tx_reg <= {din,1'b1};
								state_reg <= DATA1;
								rdy = 0 ;
								end
							else if (wr_i2c && cmd == CMD_STOP)begin
								state_reg <= STOP_1;
								scl_out_reg <= 1;
								rdy = 0 ;
								end
							else if (wr_i2c && cmd == CMD_RESTART) begin
								state_reg <= RESTART;
								scl_out_reg <= 1;
								sda_out_reg <= 1;
								rdy = 0 ;
								end
							end
							
	DATA1			:		begin
							if(tick_counter == quarter_period - 1)begin
								state_reg <= DATA2;
								tick_counter <= 0;
								scl_out_reg <= 1;
								end
							else tick_counter <= tick_counter + 1 ;
							end
	
	DATA2			:		begin
							if(tick_counter == quarter_period - 1)begin
								state_reg <= DATA3;
								i2c_rx_reg <= {i2c_rx_reg[7:0],sda};
								tick_counter <= 0;
								end
							else tick_counter <= tick_counter + 1 ;
							end
							
	DATA3			:		begin
							if(tick_counter == quarter_period - 1)begin
								state_reg <= DATA4;
								tick_counter <= 0;
								scl_out_reg <= 0;
								end
							else tick_counter <= tick_counter + 1 ;
	
							end
	
	DATA4			:		begin
							if(tick_counter == quarter_period - 1)begin
							tick_counter <= 0;
							i2c_tx_reg <= {i2c_tx_reg[7:0],1'b0};
								if(bit_count < 8 ) begin
								state_reg <= DATA1;
								bit_count <= bit_count + 1;
								end
								else begin

								state_reg <= DATA_E;
								sda_out_reg <= 0;
								end
							end
							else tick_counter <= tick_counter + 1 ;
							end
	
	DATA_E			:		begin
							if(tick_counter == quarter_period - 1)begin
							tick_counter <= 0;
							state_reg <= HOLD;
							rdy <= 1;
							bit_count <= 0;
							end
							else tick_counter <= tick_counter + 1;
							end
							
	STOP_1			:		if(tick_counter == half_period - 1) begin
							tick_counter <= 0;
							state_reg <= STOP_2;
							sda_out_reg <= 1;
							end
							else tick_counter <= tick_counter + 1;
	
	STOP_2			:		if(tick_counter == half_period - 1) begin
							tick_counter <= 0;
							state_reg <= IDLE;
							scl_out_reg <= 1;
							rdy <= 1;
							
						    end
							else tick_counter <= tick_counter + 1 ;
							
	RESTART			:		if(tick_counter == half_period - 1) begin
							tick_counter <= 0;
							state_reg <= START_1;
							sda_out_reg <= 0;
						    end
							else tick_counter <= tick_counter + 1 ;
	endcase
end



assign sda_out = (state_reg == DATA1 || state_reg == DATA2 || state_reg == DATA3 || state_reg == DATA4) ? i2c_tx_reg[8] : sda_out_reg;

assign input_en = ((state_reg == DATA1 || state_reg == DATA2 || state_reg == DATA3 || state_reg == DATA4) && (CMD_reg == CMD_READ) && (bit_count < 8)) 
				   || ((state_reg == DATA1 || state_reg == DATA2 || state_reg == DATA3 || state_reg == DATA4) && (CMD_reg == CMD_WRITE) && (bit_count == 8));

assign sda = (input_en || sda_out) ? 1'bz : 1'b0;   //the FPGA device turns off the tristate buffer 
											//(i.e., changes the output to a high-impedance state) when a desired bus line level is 1 or when we the I2C is reading from the slave. 
											//Since the bus line is connected to VDD via a pull-up resistor, it is driven to 1 implicitly when all devices output 1 (i.e., all are in high-impedance state). 
											//Note that the scl port uses the tri data type because of the tristate buffer.
assign scl = (scl_out_reg) ? 1'bz : 1'b0;

	
assign dout = i2c_rx_reg[8:1];
assign ack = i2c_rx_reg[0];

always@* begin
quarter_period = F_I2C_100k_Q;
half_period		= F_I2C_100k_H;
case(clk_dvsr)
F_100K			:			begin
							quarter_period = F_I2C_100k_Q;
							half_period	 	= F_I2C_100k_H;
							end


F_400K			:			begin	
							quarter_period	=	F_I2C_400k_Q;
							half_period		=	F_I2C_400k_H;
							end


F_3400K			:			begin
							quarter_period	=	F_I2C_3400KHZ_Q;
							half_period		=	F_I2C_3400KHZ_H;
							end
							
default			:			begin
							quarter_period = F_I2C_100k_Q;
							half_period		= F_I2C_100k_H;
							end
endcase
end

endmodule
