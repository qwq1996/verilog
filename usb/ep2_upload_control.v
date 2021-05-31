module  ep2_upload_control(
input reset,
input [255:0] data_gen_stream_in,				// input data
input wrclk,					// if it is from counter ,should be 180 phase shift			
input wrreq,							
input rdreq,					// input from SLWR , should be 180 phase shift			
input rdclk,					// clk_100 100M
output wire upcounterfifo_AlmostFull,				//upcounterfifo_AlmostFull
output wire upcounterfifo_AlmostEmpty,				//upcounterfifo_AlmostEmpty
output wire [31:0] upcounterfifo_dataout,									// FIFO read out data
output wire upcounterfifo_AlmostFull_add,
output wire [15:0] upcounterfifo_wrusedw,
output [13:0] upcounterfifo_rdusedw,
output upcounterfifo_DDR_wr_reg
);

/***********************************************************************************************************/
/*************************************  Start Parameter Declaration  ***************************************/
/***********************************************************************************************************/

/***********************************************************************************************************/
/***************************************  End Parameter Declaration  ***************************************/
/***********************************************************************************************************/

/***********************************************************************************************************/
/******************************************  Start Wire Declaration  ***************************************/
/***********************************************************************************************************/

// wire upcounterfifo_wrfull;
// wire upcounterfifo_rdempty;

/*************************************************************************************************************/
/*****************************************  End Wire Declaration  ********************************************/
/*************************************************************************************************************/

/***********************************************************************************************************/
/*************************************  Start Registers Declaration  ***************************************/
/***********************************************************************************************************/

/***********************************************************************************************************/
/***************************************  End Registers Declaration  ***************************************/
/***********************************************************************************************************/

/***********************************************************************************************************/
/*****************************************  Start instants Declaration  ************************************/
/***********************************************************************************************************/

//------------------------------------------------------------------------------
// NAME : 
// TYPE : instance
// -----------------------------------------------------------------------------
// PURPOSE : 
// -----------------------------------------------------------------------------
// Other : 
//------------------------------------------------------------------------------
wire ep2_full;
ep2_upload u_ep2_upload(
  .rst(reset),                      // input wire rst
  .wr_clk(wrclk),                // input wire wr_clk
  .rd_clk(rdclk),                // input wire rd_clk
  .din(data_gen_stream_in),                      // input wire [255 : 0] din
  .wr_en(wrreq),                  // input wire wr_en
  .rd_en(rdreq),                  // input wire rd_en
  .dout(upcounterfifo_dataout),                    // output wire [31 : 0] dout
  .full(ep2_full),                    // output wire full
  .empty(ep2_empty),                  // output wire empty
  .rd_data_count(upcounterfifo_rdusedw),  // output wire [15 : 0] rd_data_count
  .wr_data_count(upcounterfifo_wrusedw),  // output wire [13 : 0] wr_data_count
  .wr_rst_busy(),      // output wire wr_rst_busy
  .rd_rst_busy()      // output wire rd_rst_busy
);

/***********************************************************************************************************/
/****************************************  End of instants Declaration  ************************************/
/***********************************************************************************************************/

/*************************************************************************************************************/
/*********************************  Start Design RTL Description  ********************************************/
/*************************************************************************************************************/

///bulk 16kB
assign upcounterfifo_AlmostFull=(upcounterfifo_rdusedw>16'd4096)? 1'b1:1'b0;
assign upcounterfifo_AlmostEmpty=(upcounterfifo_rdusedw<14'd300)? 1'b1:1'b0;
assign upcounterfifo_AlmostFull_add=(upcounterfifo_wrusedw>16'd8190)? 1'b1:1'b0;
assign upcounterfifo_DDR_wr_reg = (upcounterfifo_wrusedw<14'd1020)? 1'b1:1'b0;

/*************************************************************************************************************/
/***********************************  End Design RTL Description  ********************************************/
/*************************************************************************************************************/

// reg [31:0] ep2_upload_cnt = 32'd0;
// always@(posedge rdclk)
// begin
//     if(reset)
//       begin
//         ep2_upload_cnt <= 32'd0;
//       end
//     else begin
//       if(rdreq)begin
//         ep2_upload_cnt <= ep2_upload_cnt + 32'd1;
//       end
//       else begin
//         ep2_upload_cnt <= ep2_upload_cnt;
//       end
//     end
// end

// ila_13 ep2(
//   .clk(wrclk),

//   .probe0(wrreq),
//   .probe1(ep2_full),
//   .probe2(rdreq),
//   .probe3(ep2_empty),
//   .probe4(upcounterfifo_rdusedw),
//   .probe5(upcounterfifo_wrusedw)
// );

endmodule