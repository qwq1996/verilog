
// -----------------------------------------------------------------------------
// Author : 陈诚 ccdyx@mail.ustc.edu.cn
// File   : USB3_interface.v
// Create : 2018-11-20 19:05:56
// Editor : sublime text3, tab size (4)
//11-27 ep2各种速度上传都没有问题，把原来的两段式状态机改成�?段式，方便进行时序判�?

//11-28 命令下发出了点问题，弄好了�?�目前状态机过于丑陋，有时间再优化一�?


// -----------------------------------------------------------------------------

module USB3_interface(
			input clk_100,					// module main clk 100M
			input reset_,				// PLL lock,
			input FLAGA,					//
			input FLAGB,					//
			input FLAGC,					// 0 means EP6 full
			input FLAGD,					// 
			input updata_rden,			// UP FIFO read enable
			input [31:0]EP2FifoData,			//  From FPGA to FX3
			input downdata_wren,			// down data FIFO write enable, IN fact,so far, NO USE of down data FIFO in FPGA,
			input FIFO_AF,					//  FIFO almost full
			input FIFO_AE,					//  FIFO almost empty
			input      [31:0] EP6In,  
			input             EP6En, 

			inout	[31:0]fdata,          //data bus INOUT type
			output wire InorOut,
			output reg [1:0] faddr,		//output fifo address  
			output wire SLRD,				//output read select
			output wire SLOE,				//output output enable select
			output wire SLWR,				//output write select
			output wire PKTEND,			//output pkt end
			output wire SLCS,				//output chip select
			output reg[31:0] downdata, // flopping fdata when FPGA receive CMD
			output reg downdata_acq,		// 读出到fdata数据，做�?个指示，以便输出�?
			output wire EP2_FIFO_rdreq,
			input ep2_pktend		
);
/***********************************************************************************************************/
/*************************************  Start Parameter Declaration  ***************************************/
/***********************************************************************************************************/

//parameters for interface state machine
parameter  idle                   = 4'd0;
parameter  flagd_rcvd             = 4'd1;
parameter  wait_flagd             = 4'd2;
parameter  read                   = 4'd3;
parameter  read_rd_and_oe_delay   = 4'd4;
parameter  read_oe_delay          = 4'd5;
parameter  wait_flagb             = 4'd6;
parameter  write                  = 4'd7;
parameter  write_wr_delay         = 4'd8;
parameter  ep6_write			  = 4'd9;
parameter  ep6_write_end		  = 4'd10;
parameter  wait_ep2_flag          = 4'd11;
parameter  wait_ep2_flag_2   	  = 4'd12;

/***********************************************************************************************************/
/***************************************  End Parameter Declaration  ***************************************/
/***********************************************************************************************************/

/***********************************************************************************************************/
/******************************************  Start Wire Declaration  ***************************************/
/***********************************************************************************************************/

wire [15:0] updata1;

wire slwr_streamIN_;
wire slwr_streamIN2;

wire EP6_UP_flag;
/*************************************************************************************************************/
/*****************************************  End Wire Declaration  ********************************************/
/*************************************************************************************************************/

/***********************************************************************************************************/
/*************************************  Start Registers Declaration  ***************************************/
/***********************************************************************************************************/

///flopping the INPUTs flags
reg  flaga_d;
reg  flagb_d;
reg  flagc_d;
reg  flagd_d;
reg [1:0] oe_delay_cnt;	
reg [1:0] rd_oe_delay_cnt; 
reg [3:0] current_state;
reg  [3:0] next_state;
reg [31:0]fdata_wr;
reg slwr_streamIN_d1_;
reg slwr_streamIN_d2_;
reg EP6_UP_flag_d;
reg [15:0]  ep2_bulk_cnt=0;
reg ep2_req_flag;
reg EP6En_reg;

/***********************************************************************************************************/
/***************************************  End Registers Declaration  ***************************************/
/***********************************************************************************************************/

/***********************************************************************************************************/
/*****************************************  Start instants Declaration  ************************************/
/***********************************************************************************************************/

/***********************************************************************************************************/
/****************************************  End of instants Declaration  ************************************/
/***********************************************************************************************************/

/*************************************************************************************************************/
/*********************************  Start Design RTL Description  ********************************************/
/*************************************************************************************************************/

assign SLRD   = (current_state == read) ? 1'b0 : 1'b1;
assign SLOE   = (current_state==flagd_rcvd || current_state==read)? 1'b0:1'b1; // OE 是读的时候有效（=0�?
assign SLCS   = 1'b0; 			// always  SLCS=0
assign PKTEND = ((current_state == ep6_write && !EP6En_reg) || ep2_pktend) ? 1'b0: 1'b1;  
assign SLWR   = slwr_streamIN_d2_; 
assign InorOut=(current_state==wait_flagb||current_state==write||current_state==write_wr_delay ||current_state==ep6_write ||current_state==ep6_write_end ||current_state == wait_ep2_flag || current_state == wait_ep2_flag_2)? 1'b1 : 1'b0;
assign fdata = InorOut ? ((faddr == 2'd2) ? fdata_wr : EP2FifoData ):32'dz; 
assign slwr_streamIN_ =  (current_state == write)?  1'b0: 1'b1;	  // 
assign slwr_streamIN2 =  (current_state == write || current_state == ep6_write )?  1'b0: 1'b1;	  // 
assign EP6_UP_flag = (current_state == ep6_write) ? 1'b1 : 1'b0;	//
assign EP2_FIFO_rdreq =  ep2_req_flag; //&& !slwr_streamIN_d1_1;

//flop the input flag
always @(posedge clk_100)begin
	flaga_d <= FLAGA;
	flagb_d <= FLAGB;
	flagc_d <= FLAGC;
	flagd_d <= FLAGD;	
end

//USB地址
always@(*)
begin
	if(current_state==flagd_rcvd ||current_state==read)
		faddr =2'b11;  //EP8
	else if(current_state==ep6_write ||current_state==ep6_write_end)
		faddr =2'b10;  //EP6
	else  
		faddr =2'b00;	//EP2
end 

always @(posedge clk_100)begin
	if(!reset_)begin 
		slwr_streamIN_d1_ <= 1'b1;
		slwr_streamIN_d2_	<= 1'b1;
	end else begin
		slwr_streamIN_d1_ <= slwr_streamIN_;
		slwr_streamIN_d2_	<= slwr_streamIN2;
	end	
end

always @(posedge clk_100, negedge reset_)begin
	if(!reset_)begin 
		EP6_UP_flag_d <= 1'b1;
	end else begin
		EP6_UP_flag_d <= EP6_UP_flag;
	end	
end

always @(posedge clk_100)begin	// flopping fdata when FPGA receive CMD
	if(!reset_)begin 
		downdata <= 32'd0;
 	end else begin
		downdata <= fdata; //changed by tyj on 20210111
	end	
end

always @(posedge clk_100)
begin
	if(!reset_)
		begin 
			oe_delay_cnt <= 2'd0;
		end
	else
	begin
		if( current_state == flagd_rcvd)  
			oe_delay_cnt <=oe_delay_cnt +2'd1;   
		else
			oe_delay_cnt <= 2'd0;
	
		if( current_state == read)  
			if(rd_oe_delay_cnt <=2'd1)begin
				rd_oe_delay_cnt <=rd_oe_delay_cnt +2'd1;  
			end
			else begin
				rd_oe_delay_cnt <=rd_oe_delay_cnt;  				
			end 
		else
			rd_oe_delay_cnt <= 2'd0;
	end	
end 

always @(posedge clk_100)
begin
	if(!reset_)
		begin
			ep2_bulk_cnt <=0;
		end
	else
		begin
			if(!slwr_streamIN_) begin // fifo read 4096 points OUT�?
				ep2_bulk_cnt <=ep2_bulk_cnt+1;
			end 
			else begin
				ep2_bulk_cnt <=0;	
			end 
		end 
end 

always @(posedge clk_100) begin
	EP6En_reg<= EP6En;
end

always @(posedge clk_100, negedge reset_)
begin
	if(!reset_)begin 
		current_state <= idle;
		ep2_req_flag <=1'b0;
	end
	else begin
	case(current_state)
	idle:
	begin
		downdata_acq<=1'b0;  //将downdata_acq 初始值设�?0
		if(flagd_d == 1'b1)	begin		// FX3 Down BUFFER NO EMPty.
			current_state <= flagd_rcvd;
		end
		else if(EP6En && flagc_d)begin
			current_state <= ep6_write;	

		end 
		else begin
				if(flaga_d == 1'b1)	begin	//  FX3 UP BUFFER not full 
					current_state <= wait_flagb; 
				end 
				else begin
					current_state <= idle;
				end
		end
	end
	
	wait_flagb :
	begin
		if(flagd_d == 1'b1)	begin		// FX3 Down BUFFER NO EMPty.
			current_state <= flagd_rcvd;
		end
		else begin
				if (flagb_d == 1'b1 && FIFO_AF)begin// there is enough data for fx3 to read.
					current_state <= wait_ep2_flag_2;
					fdata_wr <= EP2FifoData;
				end
				else if(EP6En && flagc_d)begin
					current_state <= ep6_write;	

				end 
				else begin
					current_state <= wait_flagb; 
					ep2_req_flag <=1'b0;
				end
		end
	end
	wait_ep2_flag_2:
	begin
		current_state <= write;
		fdata_wr <= EP2FifoData;
		ep2_req_flag <=1'b1;
	end

	write:
	begin
		if(flagd_d == 1'b1)begin		// FX3 Down BUFFER NO EMPty.
			current_state<= flagd_rcvd;
		end
		else
			begin
				if(flagb_d == 1'b0)begin
					current_state <= wait_ep2_flag;
				end
				else begin //FX3 DMAbuffer is not full ADN FPGA fifo is not empty
					if(ep2_bulk_cnt <16'd4095) begin// bulk 16kb data to PE2�?
						current_state <= write;
						fdata_wr <= EP2FifoData;
						ep2_req_flag = 1'b1;
					end 
					else begin
						current_state <= wait_ep2_flag;
						fdata_wr <= EP2FifoData;
						ep2_req_flag = 1'b0;
					end	
				end
			end
	end
	wait_ep2_flag:begin
			current_state <= write_wr_delay;
			fdata_wr <= EP2FifoData;
			ep2_req_flag <=1'b0;
	end

   write_wr_delay:
	begin
		if(flagd_d == 1'b1)	begin // FX3 Down BUFFER NO EMPty.
			current_state <= flagd_rcvd;
		end
		else begin
			current_state <= idle;	
		end
	end
	
	flagd_rcvd:
		begin
			if(oe_delay_cnt <=2'd1)  begin /// OE 之后，延�?2个周期读�?
				current_state <= flagd_rcvd;	
			end 
			else begin	
				current_state <= read;
			end 
		end	
   read :
		begin
	      if(flagd_d == 1'b0)begin
					current_state <= idle;
					downdata_acq<=1'b0;
			end 
			else begin
				current_state <= read;
				if(rd_oe_delay_cnt <=2'd1)   downdata_acq<=1'b0;//RD 后延�?2个周期是有效数据�?
				else downdata_acq<=1'b1;
				end
		end
	
	ep6_write:
		begin
			if(flagd_d == 1)begin
				current_state <= flagd_rcvd;
			end 
			else if (EP6En_reg && flagc_d)begin
				current_state <= ep6_write;
				fdata_wr <= EP6In;
			end 
			else if(!EP6En_reg) current_state <= ep6_write_end;
		end 
		
	ep6_write_end:  // pktend =0
		begin
			current_state <= idle;
		end
	
	default:
		begin
			current_state <= idle;
		end
	endcase
	
end
end
/*************************************************************************************************************/
/***********************************  End Design RTL Description  ********************************************/
/*************************************************************************************************************/

// ila_10 u_ila_10 (
// 	.clk(clk_100), // input wire clk

// 	.probe0(FLAGA), // input wire [0:0]  probe0  
// 	.probe1(FLAGB), // input wire [0:0]  probe1 
// 	.probe2(FLAGC), // input wire [0:0]  probe2 
// 	.probe3(FLAGD), // input wire [0:0]  probe3 
// 	.probe4(ep2_bulk_cnt), // input wire [15:0]  probe4 
// 	.probe5(EP2FifoData), // input wire [31:0]  probe5 
// 	.probe6(fdata_wr), // input wire [15:0]  probe6 
// 	.probe7(FIFO_AF), // input wire [0:0]  probe7 
// 	.probe8(FIFO_AE), // input wire [0:0]  probe8 
// 	.probe9(EP6In), // input wire [31:0]  probe9 
// 	.probe10(EP6En), // input wire [0:0]  probe10 
// 	.probe11(faddr), // input wire [1:0]  probe11 
// 	.probe12(SLRD), // input wire [0:0]  probe12 
// 	.probe13(SLOE), // input wire [0:0]  probe13 
// 	.probe14(SLWR), // input wire [0:0]  probe14 
// 	.probe15(PKTEND), // input wire [0:0]  probe15 
// 	.probe16(SLCS), // input wire [0:0]  probe16 
// 	.probe17(current_state), // input wire [3:0]  probe17 //
// 	.probe18(downdata), // input wire [31:0]  probe18 
// 	.probe19(downdata_acq), // input wire [0:0]  probe19 
// 	.probe20(EP2_FIFO_rdreq), // input wire [0:0]  probe20 
// 	.probe21(EP6_UP_flag) // input wire [3:0]  probe21
// );


endmodule
