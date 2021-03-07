module unipolar_rz #(
    parameter int DATA_WIDTH,
    // in Hz
    parameter real CLOCK_RATE,
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
    parameter real RESET_TIME
) (
    input logic clock,
    input logic [DATA_WIDTH-1:0] data,
    input logic enable,
    output logic line = 1'd0,
    output logic ready
);

localparam int TIME_COUNTER_WIDTH = $clog2($unsigned(int'(1.0 + CLOCK_RATE * (RESET_TIME + (ONE_LOW_TIME > ZERO_LOW_TIME ? ONE_LOW_TIME : ZERO_LOW_TIME)))));
localparam int STATE_WIDTH = $clog2(2 * DATA_WIDTH + 1);

localparam bit [TIME_COUNTER_WIDTH-1:0] PERIOD = TIME_COUNTER_WIDTH'($unsigned(int'(CLOCK_RATE * PERIOD_TIME)));
localparam bit [TIME_COUNTER_WIDTH-1:0] ZERO_LOW = TIME_COUNTER_WIDTH'($unsigned(int'(CLOCK_RATE * ZERO_LOW_TIME)));
localparam bit [TIME_COUNTER_WIDTH-1:0] ZERO_HIGH = TIME_COUNTER_WIDTH'($unsigned(int'(CLOCK_RATE * ZERO_HIGH_TIME)));
localparam bit [TIME_COUNTER_WIDTH-1:0] ONE_LOW = TIME_COUNTER_WIDTH'($unsigned(int'(CLOCK_RATE * ONE_LOW_TIME)));
localparam bit [TIME_COUNTER_WIDTH-1:0] ONE_HIGH = TIME_COUNTER_WIDTH'($unsigned(int'(CLOCK_RATE * ONE_HIGH_TIME)));
localparam bit [TIME_COUNTER_WIDTH-1:0] RESET = TIME_COUNTER_WIDTH'($unsigned(int'(CLOCK_RATE * RESET_TIME)));

localparam bit [TIME_COUNTER_WIDTH-1:0] ZERO = TIME_COUNTER_WIDTH'(0);
localparam bit [TIME_COUNTER_WIDTH-1:0] ONE = TIME_COUNTER_WIDTH'(1);

logic [TIME_COUNTER_WIDTH-1:0] time_counter = RESET;

logic [DATA_WIDTH-1:0] internal_data;

// 0 = ready, 1+ = transmitting nth bit
localparam bit [STATE_WIDTH-1:0] NOT_SENDING = STATE_WIDTH'(0);
localparam bit [STATE_WIDTH-1:0] SENDING_LAST = STATE_WIDTH'(2 * DATA_WIDTH);
localparam bit [STATE_WIDTH-1:0] NEXT_STATE = STATE_WIDTH'(1);
logic [STATE_WIDTH-1:0] state = NOT_SENDING;

assign ready = !enable && (state == NOT_SENDING && time_counter == ZERO) || (state == SENDING_LAST && time_counter == ONE);

always_ff @(posedge clock)
begin
    if (time_counter != ZERO)
    begin
        time_counter <= time_counter - ONE;
    end
    else if (state == NOT_SENDING)
    begin
        if (enable)
        begin
            // load shift register
            internal_data <= data;
            state <= state + NEXT_STATE;
        end
    end
    // odd state, driving high part of bit
    else if (state[0])
    begin
        line <= 1'd1;
        state <= state + NEXT_STATE;
        time_counter <= internal_data[DATA_WIDTH-1] ? ONE_HIGH : ZERO_HIGH;
    end
    // even state, driving low part of bit
    else if (!state[0])
    begin
        line <= 1'd0;
        if (state == SENDING_LAST)
        begin
            // pipelining to go direct to transmitting next data
            if (enable)
            begin
                internal_data <= data;
                state <= STATE_WIDTH'(1);
                time_counter <= internal_data[DATA_WIDTH-1] ? ONE_LOW : ZERO_LOW;
            end
            // otherwise need to settle state with a reset
            else
            begin
                internal_data <= 1'bx;
                state <= NOT_SENDING;
                time_counter <= RESET + (internal_data[DATA_WIDTH-1] ? ONE_LOW : ZERO_LOW) + ONE;
            end
        end
        else
        begin
            internal_data <= internal_data << 1;
            state <= state + NEXT_STATE;
            time_counter <= internal_data[DATA_WIDTH-1] ? ONE_LOW : ZERO_LOW;
        end
    end
end
    
endmodule