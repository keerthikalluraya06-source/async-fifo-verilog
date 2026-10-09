
module async_fifo (
    input  wire       wr_clk,
    input  wire       rd_clk,
    input  wire       rst,
    input  wire       wr_en,
    input  wire       rd_en,
    input  wire [7:0] data_in,
    output reg  [7:0] data_out,
    output reg        full,
    output reg        empty
);

    // FIFO memory: 8 entries, 8 bits each
    reg [7:0] mem [0:7];

    // Binary pointers: 3 address bits + 1 wrap bit
    reg [3:0] wr_ptr, rd_ptr;

    // Registered Gray-code pointers
    reg [3:0] wr_gray, rd_gray;

    // Two-stage pointer synchronizers
    reg [3:0] rd_gray_sync1, rd_gray_sync2;
    reg [3:0] wr_gray_sync1, wr_gray_sync2;

    // Next-pointer wires
    wire [3:0] wr_bin_next, rd_bin_next;
    wire [3:0] wr_gray_next, rd_gray_next;

    // Calculate next binary pointers
    assign wr_bin_next =
        wr_ptr + ((wr_en && !full) ? 1'b1 : 1'b0);

    assign rd_bin_next =
        rd_ptr + ((rd_en && !empty) ? 1'b1 : 1'b0);

    // Convert next binary pointers to Gray code
    assign wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
    assign rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;

    // Synchronize read pointer into write clock domain
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            rd_gray_sync1 <= 4'b0000;
            rd_gray_sync2 <= 4'b0000;
        end
        else begin
            rd_gray_sync1 <= rd_gray;
            rd_gray_sync2 <= rd_gray_sync1;
        end
    end

    // Synchronize write pointer into read clock domain
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            wr_gray_sync1 <= 4'b0000;
            wr_gray_sync2 <= 4'b0000;
        end
        else begin
            wr_gray_sync1 <= wr_gray;
            wr_gray_sync2 <= wr_gray_sync1;
        end
    end

    // Write pointer and FULL flag
    always @(posedge wr_clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 4'b0000;
            wr_gray <= 4'b0000;
            full    <= 1'b0;
        end
        else begin
            wr_ptr  <= wr_bin_next;
            wr_gray <= wr_gray_next;

            full <= (wr_gray_next ==
                    {~rd_gray_sync2[3:2],
                      rd_gray_sync2[1:0]});
        end
    end

    // Read pointer and EMPTY flag
    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_ptr <= 4'b0000;
            rd_gray <= 4'b0000;
            empty   <= 1'b1;
        end
        else begin
            rd_ptr  <= rd_bin_next;
            rd_gray <= rd_gray_next;

            empty <= (rd_gray_next == wr_gray_sync2);
        end
    end

    // Write data into memory
    always @(posedge wr_clk) begin
        if (!rst && wr_en && !full)
            mem[wr_ptr[2:0]] <= data_in;
    end

    // Read data from memory
    always @(posedge rd_clk or posedge rst) begin
        if (rst)
            data_out <= 8'b00000000;
        else if (rd_en && !empty)
            data_out <= mem[rd_ptr[2:0]];
    end

endmodule
