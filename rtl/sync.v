/**
 * PET Clone - Open hardware implementation of the Commodore PET
 * by Daniel Lehenbauer (and contributors).
 * 
 * https://github.com/DLehenbauer/commodore-pet-clone
 *
 * To the extent possible under law, I, Daniel Lehenbauer, have waived all
 * copyright and related or neighboring rights to this project. This work is
 * published from the United States.
 *
 * @copyright CC0 http://creativecommons.org/publicdomain/zero/1.0/
 * @author Daniel Lehenbauer <DLehenbauer@users.noreply.github.com> and contributors
 */

module sync (
    input clk,
    input select,
    input pending,          // read/write is pending
    output strobe,
    output done             // read/write has completed
);
    parameter [1:0] IDLE    = 2'b00,
                    PENDING = 2'b01,
                    DONE    = 2'b11;

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
            IDLE:   if (pending && !select) next = PENDING;
                    else next = IDLE;
            
            PENDING: if (select) next = DONE;
                     else next = PENDING;
            
            DONE:    next = DONE;
        endcase
    end

    assign strobe = select && (state === PENDING);
    assign done   = (state === DONE);
endmodule