module  dif_cmd(in1,in2,out1,out2,clk,in3);
input clk;

input in1;
input in3;
input [15:0] in2;
output wire  out1;
output wire [15:0] out2;

assign out2 = in2;
reg out1_reg;
//reg  out_b;
//assign out1 = out_b &in3;
assign out1 = out1_reg && in1;
always@(posedge clk)begin

	out1_reg <=in1;    //  从rdreq 拉高到 输出有效的fifo数据，要有1个周期延迟。

end 
endmodule