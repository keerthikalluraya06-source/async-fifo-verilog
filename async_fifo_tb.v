`timescale 1ns/1ps

module async_fifo_tb;

    reg wr_clk;
    reg rd_clk;
    reg rst;
    reg wr_en;
    reg rd_en;
    reg [7:0] data_in;

    wire [7:0] data_out;
    wire full;
    wire empty;

    async_fifo uut (
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .data_in(data_in),
        .data_out(data_out),
        .full(full),
        .empty(empty)
    );

    always #5 wr_clk = ~wr_clk;
    always #7 rd_clk = ~rd_clk;

    integer i;
    integer errors; // Counter for our self-checker

    initial begin
        wr_clk = 0;
        rd_clk = 0;
        rst = 1;
        wr_en = 0;
        rd_en = 0;
        data_in = 0;
        errors = 0; // Initialize errors to 0

        #20;
        rst = 0;

        // Write 10 values (Testing 8 valid writes + 2 overflow attempts)
        @(negedge wr_clk);
        wr_en = 1;
        for (i = 1; i <= 10; i = i + 1) begin
            data_in = i * 8'h11;
            @(negedge wr_clk);
        end
        wr_en = 0;

        #40;

        // Read and Auto-Check
        @(negedge rd_clk);
        rd_en = 1;
        
        $display("--- STARTING AUTOMATED FIFO CHECK ---");
        
        // Check the 8 valid reads
        for (i = 1; i <= 8; i = i + 1) begin
            @(negedge rd_clk);
            if (data_out == (i * 8'h11)) begin
                $display("PASS: Data out = %h", data_out);
            end else begin
                $display("FAIL: Expected %h, but got %h", (i * 8'h11), data_out);
                errors = errors + 1;
            end
        end

        // Check the 2 underflow reads (FIFO is empty, should hold last value '88')
        for (i = 9; i <= 10; i = i + 1) begin
            @(negedge rd_clk);
            if (data_out == 8'h88) begin
                $display("PASS: Underflow protection worked. Data held at %h", data_out);
            end else begin
                $display("FAIL: Underflow leaked data. Got %h", data_out);
                errors = errors + 1;
            end
        end
        
        rd_en = 0;
        
        $display("--- CHECK COMPLETE ---");
        if (errors == 0)
            $display("RESULT: SUCCESS! Your Asynchronous FIFO is Verified!");
        else
            $display("RESULT: FAILED with %0d errors.", errors);

        #100;
        $finish;
    end
endmodule
