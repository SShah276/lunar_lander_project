module game_state_regs (
    input  logic [31:0] position_word,
    input  logic [31:0] status_word,
    input  logic [31:0] velocity_word,
    output logic [9:0]  lander_x,
    output logic [9:0]  lander_y,
    output logic [1:0]  game_state,
    output logic [1:0]  angle_idx,
    output logic        thrust_active,
    output logic [7:0]  fuel_scaled,
    output logic [7:0]  vel_y_scaled,
    output logic [7:0]  vel_x_scaled
);

    always_comb begin
        lander_x = position_word[9:0];
        lander_y = position_word[19:10];

        fuel_scaled = status_word[7:0];
        thrust_active = status_word[16];
        angle_idx = status_word[23:22];
        game_state = status_word[25:24];

        vel_x_scaled = velocity_word[7:0];
        vel_y_scaled = velocity_word[15:8];
    end

endmodule
