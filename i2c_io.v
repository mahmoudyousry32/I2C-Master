module I2C_IO (clk,
			   rst,
			   addr,
			   read,
			   write,
			   read_data,
			   write_data,
			   cs,
			   sda,
			   scl); 


input clk;
input rst;
input [4:0] addr;
input read;
input write;
input [31:0] write_data;
input cs;

output [31:0] read_data;
output tri scl;
inout tri sda ;
			   
wire [7:0] dout;
wire ack;
wire rdy;
wire done_tick;
wire wr_i2c_freq;
wire wr_cmd_data;
reg [1:0] i2c_freq;

assign wr_i2c_freq = (cs & write & addr == 0 );
assign wr_cmd_data = (cs & write & addr == 1);
assign read_data 	   = {22'b0,ack,rdy,dout};
I2C_Controller	  I2C(.clk(clk),
					  .rst(rst),
					  .wr_i2c(wr_cmd_data),
					  .cmd(write_data[10:8]),
					  .din(write_data[7:0]),
					  .clk_dvsr(i2c_freq),
					  .dout(dout),
					  .ack(ack),
					  .rdy(rdy),
					 .done_tick(done_tick),
					  .sda(sda),
					  .scl(scl));
					  
always@(posedge clk ,posedge rst)begin
if(rst) i2c_freq <= 0;
else if(wr_i2c_freq) i2c_freq <= write_data[1:0];
end

endmodule

