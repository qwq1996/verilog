/*
 * @Description: 
 * @Author: ChenCheng
 * @Email: ccdyx@mail.ustc.edu.cn
 * @Date: 2019-12-03 09:19:55
 * @LastEditors: ChenCheng
 * @LastEditTime: 2020-11-23 20:47:41
 */
module usb_top(
    input clk_100,
    input clk_200,
    //input clk_test,
    input clk_20,
    input rst_n,

    //usb3.0接口
	input flaga,
	input flagb,
	input flagc,
	input flagd,
	inout [31:0]fdata,
   // output clk_out,
    output [1:0]faddr,
    output slrd,
    output sloe,
    output slwr,
    output pktend,
    output slcs,
    //ep2
    input ep2_rst,
    input upfifo_clk,
    input updata_en,
    input [255:0]updata,
    output upcounterfifo_DDR_wr_reg,

    input  [31:0]CmdFB_Data,
    input  CmdFB_Data_Ready,
    input ep2_pktend,

    output CmdData_en,
    output [31:0]CmdData,
    output wire USB30_RESET,
    output reg[31:0] CmdData_to_Bram,// changed by tyj USB data to Bram
    output reg CmdData_to_Bram_en// changed by tyj USB data to Bram
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

//wire USB30_RESET_init;
wire [31:0] FIFO_Dataout;
wire FIFO_AF,FIFO_AE;
wire [31:0]EP6In;
wire EP6En;
wire [31:0]downdata;
wire downdata_acq;
wire EP2_FIFO_rdreq;
wire [31:0] data_gen_stream_in;
wire image_data_en;
wire [15:0]image_data;
wire downfifo_rdreq;
wire [31:0] downfifo_q;
wire downfifo_empty;

wire ep6_fifo_en;
wire ep6_rdempty;
wire ep6_fifo_wr;
wire [31:0]ep6_fifo_data;
wire data_up_end_simu;

//ep2
wire [15:0] wr_data_count;
wire [13:0] upcounterfifo_rdusedw;
wire FIFO_AF_add;

/*************************************************************************************************************/
/*****************************************  End Wire Declaration  ********************************************/
/*************************************************************************************************************/

/***********************************************************************************************************/
/*************************************  Start Registers Declaration  ***************************************/
/***********************************************************************************************************/

reg downfifo_empty_reg;
reg downfifo_empty_reg_1;
reg [5:0]cnt;
reg image_gen;
reg [27:0] i;


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
USB3_interface  u_USB3_interface (
    .clk_100                 ( clk_100              ),
    .reset_               ( rst_n                ),
    .FLAGA                   ( flaga                ),
    .FLAGB                   ( flagb                ),
    .FLAGC                   ( flagc                ),
    .FLAGD                   ( flagd                ),  
    .updata_rden             (                      ), //DNC
    .EP2FifoData             ( FIFO_Dataout         ),
    .downdata_wren           (                      ), //DNC
    .FIFO_AF                 ( FIFO_AF              ),
    .FIFO_AE                 ( FIFO_AE              ),
    .EP6In                   ( EP6In                ),
    .EP6En                   ( EP6En                ),
    .ep2_pktend              ( ep2_pktend           ),

    .InorOut                 (                      ),  //DNC
   // .clk_out                 ( clk_out              ),
    .faddr                   ( faddr                ),
    .SLRD                    ( slrd                 ),
    .SLOE                    ( sloe                 ),
    .SLWR                    ( slwr                 ),
    .PKTEND                  ( pktend               ),
    .SLCS                    ( slcs                 ),
    .downdata                ( downdata             ),
    .downdata_acq            ( downdata_acq         ),
    .EP2_FIFO_rdreq          ( EP2_FIFO_rdreq       ),

    .fdata                   ( fdata                )
);
//------------------------------------------------------------------------------
// NAME : 
// TYPE : instance
// -----------------------------------------------------------------------------
// PURPOSE : 
// -----------------------------------------------------------------------------
// Other : 
//------------------------------------------------------------------------------
usbreset  u_usbreset (
    .clk                     ( clk_20         ),
    .rst_n                   ( rst_n       ),

    .usb_rst_n               ( USB30_RESET   )
);
//------------------------------------------------------------------------------
// NAME : 
// TYPE : instance
// -----------------------------------------------------------------------------
// PURPOSE : 
// -----------------------------------------------------------------------------
// Other : 
//------------------------------------------------------------------------------
ep2_upload_control u_ep2_upload_control (
    .reset                         ( ep2_rst       ),
    .data_gen_stream_in            ( updata           ),
    .wrclk                         ( upfifo_clk       ),
    .wrreq                         ( updata_en        ),
    .rdreq                         ( EP2_FIFO_rdreq                 ),
    .rdclk                         ( clk_100                        ),

    .upcounterfifo_AlmostFull      ( FIFO_AF                        ),
    .upcounterfifo_AlmostEmpty     ( FIFO_AE                        ),
    .upcounterfifo_dataout         ( FIFO_Dataout                   ),
    .upcounterfifo_AlmostFull_add  ( FIFO_AF_add                    ),
    .upcounterfifo_wrusedw         ( wr_data_count          ),
    .upcounterfifo_rdusedw          (upcounterfifo_rdusedw),
    .upcounterfifo_DDR_wr_reg       (upcounterfifo_DDR_wr_reg)
);

//------------------------------------------------------------------------------
// NAME : 
// TYPE : instance
// -----------------------------------------------------------------------------
// PURPOSE : 
// -----------------------------------------------------------------------------
// Other : 
//------------------------------------------------------------------------------
// save the cmd data 
ep8_download  u_ep8_download(
  .rst(1'b0),                  // input wire rst
  .wr_clk(clk_100),            // input wire wr_clk
  .rd_clk(clk_100),            // input wire rd_clk
  .din(downdata),                  // input wire [31 : 0] din
  .wr_en(downdata_acq),              // input wire wr_en
  .rd_en(downfifo_rdreq),              // input wire rd_en
  .dout(downfifo_q),                // output wire [31 : 0] dout
  .full(),                // output wire full
  .empty(downfifo_empty),              // output wire empty
  .wr_rst_busy(),  // output wire wr_rst_busy
  .rd_rst_busy()  // output wire rd_rst_busy
);

//------------------------------------------------------------------------------
// NAME : 
// TYPE : instance
// -----------------------------------------------------------------------------
// PURPOSE : 
// -----------------------------------------------------------------------------
// Other : 
//------------------------------------------------------------------------------
EP6data_combo  u_EP6data_combo (
    .data1_en                ( CmdFB_Data_Ready                ),
    .data1                   ( CmdFB_Data         ),
    .data2_en                (                           ),
    .data2                   (                           ),
    .data3_en                (                           ),
    .data3                   (                           ),
    .clk_100                 ( clk_100                   ),
    .clk_20                  ( clk_20                    ),
    .clk_200                 ( clk_200),

    .dataout_en              ( ep6_fifo_wr               ),
    .dataout                 ( ep6_fifo_data             )
);

//------------------------------------------------------------------------------
// NAME : 
// TYPE : instance
// -----------------------------------------------------------------------------
// PURPOSE : 
// -----------------------------------------------------------------------------
// Other : 
//------------------------------------------------------------------------------
ep6_upload u_ep6_upload (
  .rst( 1'b0),                  // input wire rst
  .wr_clk(clk_100),            // input wire wr_clk
  .rd_clk(clk_100),            // input wire rd_clk
  .din(ep6_fifo_data),                  // input wire [31 : 0] din
  .wr_en(ep6_fifo_wr),              // input wire wr_en
  .rd_en(EP6En),              // input wire rd_en
  .dout(EP6In),                // output wire [31 : 0] dout
  .full(),                // output wire full
  .empty(ep6_rdempty),              // output wire empty
  .wr_rst_busy(),  // output wire wr_rst_busy
  .rd_rst_busy()  // output wire rd_rst_busy
);

/***********************************************************************************************************/
/****************************************  End of instants Declaration  ************************************/
/***********************************************************************************************************/

/*************************************************************************************************************/
/*********************************  Start Design RTL Description  ********************************************/
/*************************************************************************************************************/

assign downfifo_rdreq = !downfifo_empty;
assign CmdData_en = downfifo_empty_reg_1 && !downfifo_empty;
assign CmdData  = downfifo_q;
assign EP6En =  !ep6_fifo_wr && !ep6_rdempty;

always @(posedge clk_100) begin//changed by tyj clk_20��Ϊclk_100
    downfifo_empty_reg <= !downfifo_empty;
    downfifo_empty_reg_1 <= downfifo_empty_reg;
end

//------------------------------------------------------------------------------
// NAME : 
// TYPE : instance
// -----------------------------------------------------------------------------
// PURPOSE : test, image_gen
// -----------------------------------------------------------------------------
// Other : 
//------------------------------------------------------------------------------

// always @(posedge clk_20) begin
//     if(StartPhoto) cnt <= 6'd0;
//     else if(cnt <= 6'd30) begin
//         cnt <= cnt + 1'b1;
//         image_gen <= 1'b1;
//     end else image_gen <= 1'b0;

// end

// changed by tyj   USB data to Bram 

always @(posedge clk_100) begin
if (USB30_RESET) begin 
    if (i<28'd200000000) begin//10n*200000000=2s
    i <= i+1'b1;
    CmdData_to_Bram_en <= 1'b0;
    CmdData_to_Bram[31:16] <= 16'b0;
    CmdData_to_Bram[15:0] <= 16'b0;
    end
    else  begin
    CmdData_to_Bram_en <= CmdData_en;
    CmdData_to_Bram[31:16] <= CmdData[15:0];
    CmdData_to_Bram[15:0] <= CmdData[31:16];
    end
end 
else  begin
    i <= 28'd0;
    CmdData_to_Bram_en <= 1'b0;
    CmdData_to_Bram[31:16] <= 16'b0;
    CmdData_to_Bram[15:0] <= 16'b0;
end
end

/*************************************************************************************************************/
/***********************************  End Design RTL Description  ********************************************/
/*************************************************************************************************************/

/*************************************************************************************************************/
/***********************************  start test Description  ********************************************/
/*************************************************************************************************************/

//------------------------------------------------------------------------------
// NAME : 
// TYPE : instance
// -----------------------------------------------------------------------------
// PURPOSE : 
// -----------------------------------------------------------------------------
// Other : 
//------------------------------------------------------------------------------

//generate data for testing ep2 
// counter_data_gen  u_counter_data_gen (
//     .clk                       ( clk_test                   ),
//     .reset_                    ( !EndPhoto                  ),
//     .counter_en                ( !FIFO_AF_add               ),
//     .upcounterfifo_AlmostFull  ( upcounterfifo_AlmostFull   ),

//     .data_gen_stream_in        ( data_gen_stream_in         )
// );
//------------------------------------------------------------------------------
// NAME : 
// TYPE : instance
// -----------------------------------------------------------------------------
// PURPOSE : 
// -----------------------------------------------------------------------------
// Other : 
//------------------------------------------------------------------------------
//generate a picture with 4096*4096* 16b 
// up_image_data u_up_image_data (
//     .clk                     ( clk_test               ),
//     .start                   ( image_gen             ),
//     .rst_n                   ( !EndPhoto              ),

//     .image_data              ( image_data             ),
//     .image_data_en           ( image_data_en          ),
//     .data_up_end             ( data_up_end_simu            )
// );

/*************************************************************************************************************/
/***********************************  end test Description  ********************************************/
/*************************************************************************************************************/


//assign USB30_RESET = USB30_RESET_init || StartPhoto;

// ila_1 u_ila_1 (
// 	.clk(clk_200), // input wire clk

// 	.probe0(ep6_fifo_wr), // input wire [0:0]  probe0  
// 	.probe1(EP6En), // input wire [0:0]  probe1 
// 	.probe2(downdata_acq), // input wire [0:0]  probe2 
// 	.probe3(CmdData_en), // input wire [0:0]  probe3 
// 	.probe4(CmdData), // input wire [31:0]  probe4 
// 	.probe5(downdata),// input wire [31:0]  probe5
// 	.probe6(CmdData_to_Bram), //changd by tyj on 20200112  CmdData_to_Bram
//     .probe7(CmdData_to_Bram_en),//changd by tyj on 20200112   CmdData_to_Bram_en
//     .probe8(downfifo_empty_reg_1),//changd by tyj on 20200112
//     .probe9(downfifo_empty)//changd by tyj on 20200112
//      );//changd by tyj on 20200112

// dif_cmd  u_dif_cmd (
//     .clk                     ( clk_20            ),
//     .in1                     ( downfifo_rdreq    ),
//     .in3                     ( downfifo_rdreq    ),
//     .in2                     ( downfifo_q        ),

//     .out1                    ( CmdData_en        ),
//     .out2                    ( CmdData           )
// );

// ila_6 u_ila_6 (
// 	.clk(clk_200), // input wire clk

// 	.probe0(ep6_fifo_wr), // input wire [0:0]  probe0  
// 	.probe1(EP6En), // input wire [0:0]  probe1 
// 	.probe2(CmdFB_Data_Ready), // input wire [0:0]  probe2 
// 	.probe3(ep6_rdempty), // input wire [0:0]  probe3 
// 	.probe4(ep6_fifo_data), // input wire [31:0]  probe4 
// 	.probe5(EP6In), // input wire [31:0]  probe5 
// 	.probe6(CmdFB_Data) // input wire [31:0]  probe6
// );

// ila_2 rp2_ila(
//     .clk(clk_100),

//     .probe0(ep2_rst),
//     .probe1(wr_data_count),
//     .probe2(upcounterfifo_rdusedw),
//     .probe3(updata),
//     .probe4(updata_en),
//     .probe5(EP2_FIFO_rdreq),
//     .probe6(FIFO_Dataout),
//     .probe7(FIFO_AF),
//     .probe8(FIFO_AE),
//     .probe9(1'b0),
//     .probe10(ep2_pktend)
// );


endmodule


