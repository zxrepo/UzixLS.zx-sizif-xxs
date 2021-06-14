import common::*;
module magic(
    input rst_n,
    input clk28,

    cpu_bus bus,
    input n_int,
    input n_int_next,
    output n_nmi,

    input magic_button,

    output logic magic_mode,
    output logic magic_map,
    output magic_active_next,

    output logic extlock,
    output logic magic_beeper,
    output timings_t timings,
    output turbo_t turbo,
    output logic joy_sinclair,
    output logic rom_plus3,
    output logic rom_alt48,
    output logic ay_abc,
    output logic ay_mono
);

assign magic_active_next = magic_button;
logic magic_unmap_next;
logic magic_map_next;
assign n_nmi = magic_mode? 1'b0 : 1'b1;
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        magic_mode <= 0;
        magic_map <= 0;
        magic_unmap_next <= 0;
        magic_map_next <= 0;
    end
    else begin
        if (magic_button == 1'b1 && n_int == 1'b1 && n_int_next == 1'b0)
            magic_mode <= 1'b1;

        if (magic_map && bus.memreq && bus.rd && bus.a_reg == 16'hf000 && !magic_map_next) begin
            magic_unmap_next <= 1'b1;
            magic_mode <= 1'b0;
        end
        else if (magic_map && bus.memreq && bus.rd && bus.a_reg == 16'hf008) begin
            magic_unmap_next <= 1'b1;
            magic_map_next <= 1'b1;
        end
        else if (magic_unmap_next && !bus.memreq) begin
            magic_map <= 1'b0;
            magic_unmap_next <= 1'b0;
        end
        else if (magic_mode && bus.m1 && bus.memreq && (bus.a_reg == 16'h0066 || magic_map_next)) begin
            magic_map <= 1'b1;
            magic_map_next <= 1'b0;
        end
    end
end


/* MAGIC CONFIG */
wire config_cs = magic_map && bus.ioreq && bus.a_reg[7:0] == 8'hff;
always @(posedge clk28 or negedge rst_n) begin
    if (!rst_n) begin
        magic_beeper <= 0;
        extlock <= 0;
        timings <= TIMINGS_PENT;
        turbo <= TURBO_NONE;
        ay_abc <= 1'b1;
        ay_mono <= 0;
        rom_plus3 <= 0;
        rom_alt48 <= 0;
        joy_sinclair <= 0;
    end
    else if (config_cs && bus.wr) begin
        if (bus.a_reg[15:12] == 4'h0)
            magic_beeper <= bus.d_reg[0];
        if (bus.a_reg[15:12] == 4'h1)
            extlock <= bus.d_reg[0];
        if (bus.a_reg[15:12] == 4'h2)
            timings <= timings_t'(bus.d_reg[1:0]);
        if (bus.a_reg[15:12] == 4'h3)
            turbo <= turbo_t'(bus.d_reg[1:0]);
        if (bus.a_reg[15:12] == 4'h4)
            {ay_mono, ay_abc} <= bus.d_reg[1:0];
        if (bus.a_reg[15:12] == 4'h5)
            rom_plus3 <= bus.d_reg[0];
        if (bus.a_reg[15:12] == 4'h6)
            rom_alt48 <= bus.d_reg[0];
        if (bus.a_reg[15:12] == 4'h7)
            joy_sinclair <= bus.d_reg[0];
    end
end

endmodule