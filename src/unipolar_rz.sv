module unipolar_rz #(
    parameter int DATA_WIDTH,
    // in Hz
    parameter int CLOCK_RATE,
    // in seconds
    parameter real PERIOD_TIME,
    // in seconds
    parameter real ZERO_LOW_TIME,
    // in seconds
    parameter real ZERO_HIGH_TIME,
    // in seconds
    parameter real ONE_LOW_TIME,
    // in seconds
    parameter real ONE_HIGH_TIME,
    // in seconds
    parameter real RESET_TIME,
    // Conventionally 0 = GND and 1 = VCC.
    // Maybe your application is different!
    parameter bit INVERT = 0
) (
    input logic clock,
    input logic [DATA_WIDTH-1:0] data,
    input logic enable,
    output logic line = INVERT,
    output logic ready
);

localparam int TIME_COUNTER_WIDTH = $clog2($unsigned(int'($unsigned(CLOCK_RATE) * (RESET_TIME + (ONE_LOW_TIME > ZERO_LOW_TIME ? ONE_LOW_TIME : ZERO_LOW_TIME)))));

localparam bit [TIME_COUNTER_WIDTH-1:0] PERIOD = TIME_COUNTER_WIDTH'($unsigned(CLOCK_RATE) * PERIOD_TIME - 1);
localparam bit [TIME_COUNTER_WIDTH-1:0] ZERO_LOW = TIME_COUNTER_WIDTH'($unsigned(CLOCK_RATE) * ZERO_LOW_TIME - 1);
localparam bit [TIME_COUNTER_WIDTH-1:0] ZERO_HIGH = TIME_COUNTER_WIDTH'($unsigned(CLOCK_RATE) * ZERO_HIGH_TIME - 1);
localparam bit [TIME_COUNTER_WIDTH-1:0] ONE_LOW = TIME_COUNTER_WIDTH'($unsigned(CLOCK_RATE) * ONE_LOW_TIME - 1);
localparam bit [TIME_COUNTER_WIDTH-1:0] ONE_HIGH = TIME_COUNTER_WIDTH'($unsigned(CLOCK_RATE) * ONE_HIGH_TIME - 1);
localparam bit [TIME_COUNTER_WIDTH-1:0] RESET = TIME_COUNTER_WIDTH'($unsigned(CLOCK_RATE) * RESET_TIME - 1);

logic [TIME_COUNTER_WIDTH-1:0] time_counter = TIME_COUNTER_WIDTH'(RESET);

logic [$clog2(DATA_WIDTH)-1:0] data_counter = 0;
logic [DATA_WIDTH-1:0] internal_data;

localparam int STATE_WIDTH = $clog2(2 * DATA_WIDTH + 1);
// 0 = ready, 1+ = transmitting nth bit
logic [STATE_WIDTH-1:0] state = 0;

assign ready = !enable && (state == STATE_WIDTH'(0) && time_counter == TIME_COUNTER_WIDTH'(0)) || (state == STATE_WIDTH'(2 * DATA_WIDTH) && time_counter == TIME_COUNTER_WIDTH'(1));

always_ff @(posedge clock)
begin
    if (time_counter != TIME_COUNTER_WIDTH'(0))
    begin
        time_counter <= time_counter - 1;
    end
    else if (state == STATE_WIDTH'(0))
    begin
        if (enable)
        begin
            internal_data <= data;
            state <= STATE_WIDTH'(1);
        end
    end
    // odd state, driving high part of bit
    else if (state[0])
    begin
        line <= !INVERT;
        state <= state + 1'd1;
        time_counter <= (INVERT ? !internal_data[0] : internal_data[0]) ? ONE_HIGH : ZERO_HIGH;
    end
    // even state, driving low part of bit
    else if (!state[0])
    begin
        line <= INVERT;
        if (state == STATE_WIDTH'(2 * DATA_WIDTH))
        begin
            // pipelining to go direct to transmitting next data
            if (enable)
            begin
                internal_data <= data;
                state <= STATE_WIDTH'(1);
                time_counter <= (INVERT ? !internal_data[0] : internal_data[0]) ? ONE_LOW : ZERO_LOW;
            end
            // otherwise need to settle state with a reset
            else
            begin
                internal_data <= 1'bx;
                state <= STATE_WIDTH'(0);
                time_counter <= RESET + ((INVERT ? !internal_data[0] : internal_data[0]) ? ONE_LOW : ZERO_LOW);
            end
        end
        else
        begin
            internal_data <= internal_data >> 1;
            state <= state + 1'd1;
            time_counter <= (INVERT ? !internal_data[0] : internal_data[0]) ? ONE_LOW : ZERO_LOW;
        end
    end
end
    
endmodule