module counter_data_gen(clk,reset_ ,data_gen_stream_in,counter_en,upcounterfifo_AlmostFull);
input clk;
input reset_;
input counter_en;
output reg [31:0] data_gen_stream_in;
input upcounterfifo_AlmostFull;


//data generator counter for StreamIN modes
always @(posedge clk, negedge reset_)
	begin
	if(!reset_)
		begin 
			data_gen_stream_in <= 32'd0;
		end 
// 	else begin
// //	if(upcounterfifo_AlmostFull == 1'b0) // counter  的FIFO 没写满。
// 		data_gen_stream_in <= data_gen_stream_in + 1;
// 	end

/////////////////////for test continuity/////////////

    else if(counter_en )begin
    	data_gen_stream_in <= data_gen_stream_in + 1;
    end

	
end


endmodule