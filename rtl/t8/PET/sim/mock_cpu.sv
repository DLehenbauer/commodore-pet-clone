/**
 * PET Clone - Open hardware implementation of the Commodore PET
 * by Daniel Lehenbauer and contributors.
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

module mock_cpu(
    output logic         cpu_rw_no,
    output logic         cpu_rw_noe,
    output logic [15:0]  cpu_addr_o,
    output logic         cpu_addr_oe,
    output logic  [7:0]  cpu_data_o,
    output logic         cpu_data_oe,
    input  logic         cpu_be_i
);
    logic [15:0] bus_addr;
    logic  [7:0] bus_data;
    logic        bus_rw_n;

    // CPU drives 'RWB' when 'BE' is asserted.
    assign bus_rw_no   = bus_rw_n;
    assign bus_rw_noe  = cpu_be_i;

    // CPU drives 'A[15:0]' when 'BE' is asserted.  The 17th bit A[16] is never driven by the CPU.
    assign bus_addr_o  = bus_addr;
    assign bus_addr_oe = cpu_be_i;

    // CPU drives 'D[7:0]' when writing and 'BE' is asserted.
    assign bus_data_o  = bus_data;
    assign bus_data_oe = !bus_rw_n && cpu_be_i;

    // Set CPU 'A[15:0]', 'D[7:0]', and 'RWB'.
    task set_cpu(
        input logic [15:0] bus_addr_i,
        input logic  [7:0] bus_data_i,
        input logic        bus_rw_ni
    );
        bus_addr = bus_addr_i;
        bus_data = bus_data_i;
        bus_rw_n = bus_rw_ni;
    endtask
endmodule
