module usbreset(
    input clk,
    input rst_n,

    output reg usb_rst_n = 0

);

reg [29:0]cnt;
always @(posedge clk) begin
    if(~rst_n) begin
        cnt <= 30'd0;
        usb_rst_n <= 1'b0;
    end else if(cnt < 30'd20_000_000)begin //20M * 50ns = 1s
        cnt <= cnt + 30'b1;
        usb_rst_n <= 1'b0;
    end else begin
        usb_rst_n <= 1'b1;
    end
    
end

endmodule