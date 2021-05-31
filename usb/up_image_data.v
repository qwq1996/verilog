// -----------------------------------------------------------------------------
// Author : 陈诚 ccdyx@mail.ustc.edu.cn
// File   : up_image_data.v
// Create : 2018-12-6 10:04:06
// Editor : sublime text3, tab size (4)
// -----------------------------------------------------------------------------

/////////////////////////////////////////////////////////////////////////////
//模拟图像上传
module up_image_data(
				//时钟和复位接口
			input clk,		//
			input start,	//
			input rst_n,
				
			output reg[15:0] image_data,		//
			output reg image_data_en,
			output reg data_up_end
		);
		
////////////////////////////////////////////////////		
reg [3:0] cstate;
reg [19:0] cnt_ff;
reg [11:0] cnt_row;
reg [12:0] cnt_col;
reg [29:0] cnt_delay;

parameter idle = 4'd0;
parameter upload_ff = 4'd1;
parameter upload_image = 4'd2;
parameter upload_delay = 4'd3;


//assign image_data_en = (cstate == upload_ff || cstate == upload_image) ? 1 : 0;

always @(posedge clk) begin
	if(~rst_n) begin
		cstate <= idle;
	end else begin
		case(cstate)
			idle:begin
				data_up_end <= 1'b0;
				if(start)begin
					cstate <= upload_delay;
				end // if(start)
				else begin
					cstate <= idle;
				end // else
			end

			upload_delay:begin
				if(cnt_delay == 30'd40_0000)begin
					cstate <= upload_image;
				end // if(cnt_delay == )
				else begin
					cstate <= upload_delay;
				end // else
			end // upload_delay:

			upload_ff:begin
				if(cnt_ff == 20'd100_000)begin
					cstate <= idle;
				end // if(cnt == 16'd50_000)
				else begin
					cstate <= upload_ff;
				end // else
			end // upload_ff:

			upload_image:begin
				if(cnt_col == 13'd4096)begin
					cstate <= idle;
					data_up_end <= 1'b1;
				end // if(cnt_col == 12'd4095) 
				else begin
					cstate <= upload_image;
				end // else
			end // upload_image:
		endcase // cstate
	end
end

always @(posedge clk) begin
	if(~rst_n) begin
		cnt_row <= 12'd0;
		cnt_col <= 13'd0;
		cnt_ff  <= 16'd0;
	end else begin
		if(cstate == upload_delay)begin
			cnt_delay <= cnt_delay +1'b1;
			image_data_en <= 1'b0;
		end // if(cstate == upload_delay)
		else if(cstate == upload_ff)begin
			image_data <= 16'hffff;
			cnt_ff     <= cnt_ff + 1'b1;
			image_data_en <= 1'b1;
		end // if(cstate == upload_ff)
		else if(cstate == upload_image)begin
			image_data_en <= 1'b1;
			if(cnt_row == 12'd4095)begin
				cnt_row <= 12'd0;
				cnt_col <= cnt_col + 1'd1;
				image_data <= cnt_row;
			end // if(cnt_row == 12'd4095)
			else begin
				cnt_row <= cnt_row + 1'd1;
			//	cnt_col <= cnt_col;
				image_data <= cnt_row;
			end // else

		end // else if(cstate == upload_image)
		else if(cstate == idle)begin
				cnt_row <= 12'd0;
				cnt_col <= 13'd0;
				cnt_ff  <= 20'd0;
				cnt_delay <= 30'd0;
				image_data_en <= 1'b0;
		end // else if(cstate == idle)

	end
end

// ila_17 u_la_17 (
// 	.clk(clk), // input wire clk


// 	.probe0(image_data_en), // input wire [0:0]  probe0  
// 	.probe1(image_data), // input wire [15:0]  probe1 
// 	.probe2(cstate), // input wire [3:0]  probe2 
// 	.probe3(cnt_col), // input wire [12:0]  probe3 
// 	.probe4(cnt_row) // input wire [11:0]  probe4
// );



endmodule

