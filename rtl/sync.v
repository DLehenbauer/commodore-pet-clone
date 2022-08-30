module sync (
    input clk,
    input enabled,
    input pending,          // read/write is pending
    output strobe,
    output done             // read/write has completed
);
    localparam PENDING_BIT = 0,
               DONE_BIT    = 1;

    localparam [1:0] IDLE    = 2'b00,
                     PENDING = 2'b1 << PENDING_BIT,
                     DONE    = 2'b1 << DONE_BIT;

    reg [1:0] state = IDLE;
    reg [1:0] next  = IDLE;

    always @(posedge clk or negedge pending) begin
        if (!pending) state = IDLE;
        else state <= next;
    end
    
    always @(*) begin
        next = 2'bxx;
    
        if (!pending) next = IDLE;
        else case (state)
            IDLE:   if (pending && !enabled) next = PENDING;
                    else next = IDLE;
            
            PENDING: if (enabled) next = DONE;
                     else next = PENDING;
            
            DONE:    next = DONE;

            default: next = 2'bxx;
        endcase
    end

    assign strobe = enabled && state[PENDING_BIT];
    assign done   = state[DONE_BIT];
endmodule