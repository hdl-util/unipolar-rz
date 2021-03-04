module sea_top
(
  input CLK_100MHZ,
  input RESET,
  output RGB
);

logic enable = 1'd0, ready;
localparam int DATA_WIDTH = 24;
logic [DATA_WIDTH-1:0] data = 24'h00ff00;

unipolar_rz #(
    .DATA_WIDTH(DATA_WIDTH),
    .CLOCK_RATE(100e6),
    .PERIOD_TIME(1.2e-6),
    .ZERO_LOW_TIME(1e-6),
    .ZERO_HIGH_TIME(0.3e-6),
    .ONE_LOW_TIME(0.5e-6),
    .ONE_HIGH_TIME(0.8e-6),
    .RESET_TIME(90e-6)
)
sk6805 (
    .clock(CLK_100MHZ),
    .data(data),
    .enable(enable),
    .line(RGB),
    .ready(ready)
);

logic [1:0] ready_number = 2'd0;
always_ff @(posedge CLK_100MHZ)
begin
    if (ready && ready_number == 2'd0)
    begin
        enable <= 1'd1;
        ready_number <= 2'd1;
    end
    else if (ready && ready_number == 2'd1)
    begin
        data <= {data[22:0], data[23]};
        enable <= 1'd1;
        ready_number <= 2'd2;
    end
    // settle LEDs
    else if (ready && ready_number == 2'd2)
    begin
        // data <= !data;
        enable <= 1'd0;
        ready_number <= 2'd0;
    end
    else
    begin
        enable <= 1'd0;
    end
end
endmodule
