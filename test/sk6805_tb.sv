`timescale 1ns/1ps
module sk6805_tb (
);
    logic clock = 0;
    always
    begin
        #5000ps clock = 1;
        #5000ps clock = 0;
    end
    logic enable = 1'd0, line, ready;
    localparam int DATA_WIDTH = 24;
    localparam [DATA_WIDTH-1:0] INITIAL_DATA = 24'habcdef;
    logic [DATA_WIDTH-1:0] data = INITIAL_DATA;
    unipolar_rz #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLOCK_RATE(100e6),
        .PERIOD_TIME(1.2e-6),
        .ZERO_LOW_TIME(0.8e-6),
        .ZERO_HIGH_TIME(0.3e-6),
        .ONE_LOW_TIME(0.2e-6),
        .ONE_HIGH_TIME(0.6e-6),
        .RESET_TIME(80e-6)
    )
    sk6805 (
        .clock(clock),
        .data(data),
        .enable(enable),
        .line(line),
        .ready(ready)
    );

    localparam int SHIFT_OUT_COUNT = 4;
    int shift_out_counter = SHIFT_OUT_COUNT;

    always_ff @(posedge clock)
    begin
        if (ready && shift_out_counter > 0)
        begin
            if (shift_out_counter != SHIFT_OUT_COUNT)
                data <= data + 1;
            enable <= 1'd1;
            shift_out_counter <= shift_out_counter - 1;
            assert (shift_out_counter == 4 ? sk6805.state == 0 : sk6805.state == 48) else $fatal("not in expected state: %d, %d", shift_out_counter, sk6805.state);
            assert (shift_out_counter == 4 ? sk6805.time_counter == 0 : sk6805.time_counter == 1) else $fatal("not about to drive final");
        end
        else if (ready && shift_out_counter == 0)
        begin
            enable <= 1'd0;
            shift_out_counter <= -1;
            assert (sk6805.state == 48) else $fatal("not in expected state: %d", sk6805.state);
            assert (sk6805.time_counter == 1) else $fatal("not about to drive final");
        end
        else if (ready && shift_out_counter == -1)
        begin
            enable <= 1'd0;
            assert (sk6805.state == 0) else $fatal("not in expected state: %d", sk6805.state);
            assert (sk6805.time_counter == 0) else $fatal("did not reset");
        end
        else
        begin
            enable <= 1'd0;
        end
    end

    int i, j;
    realtime now, high_time, low_time;
    logic [DATA_WIDTH-1:0] current_data = INITIAL_DATA;
    initial
    begin
        $timeformat(-9, 2, "ns");
        wait (!line);
        for (i = 0; i < SHIFT_OUT_COUNT; i++)
        begin
            for (j = 0; j < DATA_WIDTH; j++)
            begin
                wait (line);
                now = $realtime;
                wait (!line);
                high_time = $realtime - now;
                if (high_time == 600)
                begin
                    // one
                    assert (current_data[j]) else $fatal("Unexpected 1 for %h @ %d, %d", current_data, i, j);
                end
                else if (high_time == 300)
                begin
                    // zero
                    assert (!current_data[j]) else $fatal("Unexpected 0 for %h @ %d, %d", current_data, i, j);
                end
                else
                begin
                    $fatal("unexpected tHIGH = %t", high_time);
                end
            end
            current_data  = current_data + 1;
        end
        wait(!line);
        $finish;
    end
endmodule
