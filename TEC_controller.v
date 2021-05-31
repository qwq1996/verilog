`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: qianhao
// 
// Create Date: 2019/04/03 14:50:41
// Design Name: 
// Module Name: TEC_controller
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


module TEC_controller(
    input CLK,              //20MHz
    input rst_n,
    input signed [3:0] du_reg,
    input Cooling,
    output reg DAC_CS = 1'b1,
    output DAC_SCK,
    output reg DAC_SDI,
    output [11:0] v_monitor
    );
/***********************************************************************************************************/
/*************************************  Start Parameter Declaration  ***************************************/
/***********************************************************************************************************/
   //    parameter dac_out = 24'b0011_0000_1000_0000_0000_0000;
    

/***********************************************************************************************************/
/***************************************  End Parameter Declaration  ***************************************/
/***********************************************************************************************************/

/***********************************************************************************************************/
/******************************************  Start Wire Declaration  ***************************************/
/***********************************************************************************************************/
    wire [23:0] dac_out;

    wire [12:0] V_reg_judge;
/*************************************************************************************************************/
/*****************************************  End Wire Declaration  ********************************************/
/*************************************************************************************************************/

/***********************************************************************************************************/
/*************************************  Start Registers Declaration  ***************************************/
/***********************************************************************************************************/
    reg [2:0] SM = 3'd0;
    reg spi_en = 1'b0;
    reg [4:0] cnt = 5'd0;
    reg [24:0] delay_cnt = 25'd0;
    reg dac_set = 1'b0;

    reg signed [12:0] V_reg = 12'h0;
   // reg [11:0] V_reg = 12'h0;
    reg PID_en=1'b0;
    
    reg [2:0] state_cooling = 3'h0;
    reg w_flag = 1'b0;
    reg dac_set_reg = 1'b0;
    reg [23:0] w_cnt = 24'd0;
/***********************************************************************************************************/
/***************************************  End Registers Declaration  ***************************************/
/***********************************************************************************************************/

/***********************************************************************************************************/
/*****************************************  Start instants Declaration  ************************************/
/***********************************************************************************************************/

/***********************************************************************************************************/
/****************************************  End of instants Declaration  ************************************/
/***********************************************************************************************************/


    always@(posedge CLK or negedge rst_n)
    begin
        if(!rst_n) PID_en <= 1'b0;
        else if(start_PID_control) PID_en <= 1'b1;
        else if(end_PID_control) PID_en <= 1'b0;
    end
    
reg start_PID_control = 1'b0;
reg end_PID_control = 1'b0;
reg Cooling_reg=8'b0;

    always@(posedge CLK)
    begin
        Cooling_reg <= Cooling;
        if(!Cooling_reg && Cooling ) start_PID_control <= 1'b1;
        else start_PID_control <= 1'b0;
        if(Cooling_reg && !Cooling) end_PID_control <= 1'b1;
        else end_PID_control <= 1'b0;
    end

/*************************************************************************************************************/
/*********************************  Start Design RTL Description  ********************************************/
/*************************************************************************************************************/
    assign DAC_SCK = spi_en ? ~CLK : 1'b0;
    assign dac_out = {8'b0011_0000, V_reg[11:0], 4'b0000};
//    assign dac_out = 24'b0011_0000_1000_0000_0000_0000;
    assign v_monitor = V_reg;
    
    always@(posedge CLK or negedge rst_n)
    begin
        if(!rst_n) delay_cnt <= 25'd0;
        else if(PID_en && (delay_cnt < 25'd20000000)) delay_cnt <= delay_cnt + 1'b1;
        else delay_cnt <= 25'd0;
    end
    
    always@(posedge CLK or negedge rst_n)
    begin
        if(!rst_n) dac_set <= 1'b0;
        else if(start_PID_control) dac_set <= 1'b1;
//        else if(PID_en && (delay_cnt == 25'd20)) dac_set <= 1'b1;
        else if(PID_en && (delay_cnt == 25'd20000000)) dac_set <= 1'b1;
        else if(w_flag) dac_set <= dac_set_reg;
        else dac_set <= 1'b0;
    end
    
    assign V_reg_judge = V_reg + du_reg;
    always@(posedge CLK or negedge rst_n)
    begin
        if(!rst_n) V_reg <= 12'h0;
        else begin
            case(state_cooling)
            3'h0:begin
                if(end_PID_control) state_cooling <= 3'h1;
                else if(dac_set && PID_en && (V_reg_judge > 13'hfff) && (V_reg < 12'hf)) V_reg <= V_reg + 4'd3;
                else if(dac_set && PID_en && (V_reg_judge <= 13'hfff)) V_reg <= V_reg + du_reg;
                else if(dac_set && PID_en) V_reg <= 12'hfff;
                else if(!PID_en) V_reg <= 12'h0;
                
                w_flag <= 1'b0;
                dac_set_reg <= 1'b0;
                w_cnt <= 24'd0;
            end
            3'h1:begin
                w_flag <= 1'b1;
                if(V_reg[11:0] >12'd0) begin
                    V_reg <= V_reg - 1'b1;
                end
                state_cooling <= 3'h2;
                dac_set_reg <= 1'b0;
                w_cnt <= 24'd0;
            end
            3'h2:begin
                w_cnt <= w_cnt + 1'b1;
                if(start_PID_control) begin
                    state_cooling <= 3'h0;    
                end
                else begin
                    if(w_cnt == 24'd4_000_000)begin
                        dac_set_reg <= 1'b1;
                        if(V_reg[11:0] < 12'd10) begin
                            state_cooling <= 3'h0;
                            V_reg <= 12'h0;
                        end
                        else  state_cooling <= 3'h1;
                    end
                end
            end
            default state_cooling <= 3'h0;
            endcase
        end
    end
    
    always@(posedge CLK or negedge rst_n)
    begin
        if(!rst_n) SM <= 3'd0;
        else begin
            case(SM)
            3'd0:begin
                if(dac_set) begin
                    SM <= 3'd1;
                    DAC_CS <= 1'b0;
                end
                else begin
                    DAC_SDI <= 1'b0;
                    spi_en <= 1'b0;
                    DAC_CS <= 1'b1;
                    cnt <= 5'd0;
                end
            end
            3'd1:begin
                spi_en <= 1'b1;
                DAC_CS <= 1'b0;
                DAC_SDI <= dac_out[5'd23 - cnt];
                if(cnt < 5'd23) cnt <= cnt + 1'b1;
                else SM <= 3'd0;
            end
            default:begin
                SM <= 3'd0;
            end
            endcase
        end
    end
/*************************************************************************************************************/
/***********************************  End Design RTL Description  ********************************************/
/*************************************************************************************************************/

/*************************************************************************************************************/
/***********************************  Start test Description  ************************************************/
/*************************************************************************************************************/

   ila_14 ila_14_inst(
   .clk(CLK),
   .probe0(PID_en),
   .probe1(start_PID_control),
   .probe2(dac_set),
   .probe3(SM),
   .probe4(V_reg),
   .probe5(dac_set_reg),
   .probe6(state_cooling),
   .probe7(w_flag),
   .probe8(0),
   .probe9(du_reg),
   .probe10(du)
   //.probe11(p0),
   //.probe12(p1),
   //.probe13(p2)
   );

/*************************************************************************************************************/
/*************************************  end test Description  ************************************************/
/*************************************************************************************************************/

endmodule
