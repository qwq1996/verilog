`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: qianhao
// 
// Create Date: 2019/04/02 21:36:32
// Design Name: 
// Module Name: PID_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module PID_controller(
    input CLK,              //20MHz
    input rst_n,
//    input [7:0] Cooling,
    input CLK_RST_N,
    input [15:0] Targer_Temp,
    input CMOS_Temp_en,
    input [15:0] CMOS_Temp,
    output reg read_cmos_temp,
    output signed [3:0] du_reg,
    input [23:0] PID_Parameter
    );
/***********************************************************************************************************/
/*************************************  Start Parameter Declaration  ***************************************/
/***********************************************************************************************************/

//    parameter Kp = 8'h1;
//    parameter Ti = 4'd3;
//    parameter Td = 4'd3;
//    parameter T  = 4'd10;

/***********************************************************************************************************/
/***************************************  End Parameter Declaration  ***************************************/
/***********************************************************************************************************/

/***********************************************************************************************************/
/******************************************  Start Wire Declaration  ***************************************/
/***********************************************************************************************************/
    wire [7:0] Kp;
    wire [3:0] Ti, Td, T;

    wire [20:0] p0;
    wire [20:0] p1;
    wire [20:0] p2;
    wire signed [16:0] a0;
    wire signed [16:0] a1;
    wire signed [16:0] a2;
    wire signed [20:0] p;

//    wire signed [20:0] p0, p1, p2;
    
//    wire signed [30:0] du;
/*************************************************************************************************************/
/*****************************************  End Wire Declaration  ********************************************/
/*************************************************************************************************************/

/***********************************************************************************************************/
/*************************************  Start Registers Declaration  ***************************************/
/***********************************************************************************************************/
    reg [15:0] y2 = 16'h7183;        //default initial temp is 25��
    reg [15:0] y1 = 16'h7183;
    reg [15:0] y0 = 16'h7183;        //y0 is current Temp, y1 is previous Temp
    reg [24:0] cnt = 25'd0;
    reg signed [3:0] du_reg;
    reg signed [30:0]du;
/***********************************************************************************************************/
/***************************************  End Registers Declaration  ***************************************/
/***********************************************************************************************************/

/***********************************************************************************************************/
/*****************************************  Start instants Declaration  ************************************/
/***********************************************************************************************************/

    assign Kp = PID_Parameter[19:12];
    assign Ti = PID_Parameter[11:8];
    assign Td = PID_Parameter[7:4];
    assign T  = PID_Parameter[3:0];

    mult_gen_0 mult0_inst(
    .CLK(CLK),
    .A(T),
    .B(a0),
    .P(p0)
    );
    
    mult_gen_0 mult1_inst(
    .CLK(CLK),
    .A(Ti),
    .B(a1),
    .P(p1)
    );
    
    mult_gen_0 mult2_inst(
    .CLK(CLK),
    .A(Td),
    .B(a2),
    .P(p2)
    );
    
/***********************************************************************************************************/
/****************************************  End of instants Declaration  ************************************/
/***********************************************************************************************************/

/*************************************************************************************************************/
/*********************************  Start Design RTL Description  ********************************************/
/*************************************************************************************************************/
    assign a0 = y0 - y1;
    assign a1 = y0 - Targer_Temp;
    assign a2 = y0 + y2 - y1 - y1;
    
    assign p = p0 + p1 + p2;
    
    always@(posedge CLK or negedge rst_n)
    begin
        if(!rst_n) cnt <= 25'd0;
        else if(CLK_RST_N && (cnt < 25'd20_000_000)) cnt <= cnt + 1'b1;
        else cnt <= 25'd0;
    end
    
    always@(posedge CLK or negedge rst_n)
    begin
        if(!rst_n) read_cmos_temp <= 1'b0;
        else if(cnt == 25'd20_000_000) read_cmos_temp <= 1'b1;
        else read_cmos_temp <= 1'b0;
    end
    
    always@(posedge CLK or negedge rst_n)
    begin
        if(!rst_n) begin
            y0 <= 16'h7183;
            y1 <= 16'h7183;
            y2 <= 16'h7183;
        end
        else if(CMOS_Temp_en) begin
            y0 <= CMOS_Temp;
            y1 <= y0;
            y2 <= y1;
        end
    end

        
    always@(posedge CLK or negedge rst_n)
    begin
        du=p*$signed({1'b0,Kp});
        if(!rst_n) du_reg <= 4'h0;
        else if((p > 22'h200)&&(p<22'h100000)) du_reg <= 4'd0 + 4'd3;
        else if((p > 22'h100)&&(p<22'h100000)) du_reg <= 4'd0 + 4'd2;
        else if((p > 22'h0)&&(p<22'h100000)) du_reg <= 4'd0 + 4'd1;
        else if(p== 22'd0) du_reg <= 4'd0 + 4'd0;
        else if(p > 22'h1FFF00) du_reg <= 4'd0 - 4'd1;
        else if(p > 22'h1FFE00) du_reg <= 4'd0 - 4'd2;
        else du_reg <= 4'd0 - 4'd3;
    end
/*************************************************************************************************************/
/***********************************  End Design RTL Description  ********************************************/
/*************************************************************************************************************/

/*************************************************************************************************************/
/***********************************  Start test Description  ************************************************/
/*************************************************************************************************************/

/*************************************************************************************************************/
/*************************************  end test Description  ************************************************/
/*************************************************************************************************************/


    
endmodule
