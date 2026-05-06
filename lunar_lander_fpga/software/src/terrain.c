#include "terrain.h"

const int terrain_easy[TERRAIN_SEGS] = {
    420, 410, 400, 380, 360,
    350, 350, 350,
    370, 390, 400, 410,
    380, 360,
    340, 340,
    360, 380, 400, 420
};

const int terrain_medium[TERRAIN_SEGS] = {
    380, 390, 410, 430, 430,
    405, 380, 360,
    360, 360,
    380, 405, 430, 420,
    390, 370,
    370, 400, 430, 450
};

const int terrain_hard[TERRAIN_SEGS] = {
    300, 320, 350, 380, 410,
    430, 440, 450, 440, 430,
    400, 370,
    340, 340,
    370, 400, 430, 450, 440, 420
};

const LandingPad pads_easy[2] = {
    {5, 7, 350, 1},
    {14, 15, 340, 2}
};

const LandingPad pads_medium[2] = {
    {7, 9, 360, 2},
    {15, 16, 370, 3}
};

const LandingPad pads_hard[1] = {
    {12, 13, 340, 3}
};

static TerrainDifficulty current_difficulty = TERRAIN_MEDIUM;

void terrain_set_difficulty(TerrainDifficulty difficulty) {
    current_difficulty = difficulty;
}

const int *terrain_current(void) {
    if (current_difficulty == TERRAIN_EASY) return terrain_easy;
    if (current_difficulty == TERRAIN_HARD) return terrain_hard;
    return terrain_medium;
}

const LandingPad *terrain_current_pads(void) {
    if (current_difficulty == TERRAIN_EASY) return pads_easy;
    if (current_difficulty == TERRAIN_HARD) return pads_hard;
    return pads_medium;
}

int terrain_current_pad_count(void) {
    if (current_difficulty == TERRAIN_HARD) return 1;
    return 2;
}

int terrain_y_at_x(int pixel_x) {
    if (pixel_x < 0) pixel_x = 0;
    if (pixel_x > 639) pixel_x = 639;

    int seg = pixel_x / TERRAIN_WIDTH;
    if (seg >= TERRAIN_SEGS - 1) return terrain_current()[TERRAIN_SEGS - 1];

    int x0 = seg * TERRAIN_WIDTH;
    int y0 = terrain_current()[seg];
    int y1 = terrain_current()[seg + 1];
    return y0 + ((y1 - y0) * (pixel_x - x0)) / TERRAIN_WIDTH;
}

const LandingPad *terrain_pad_at_x(int pixel_x) {
    int seg = pixel_x / TERRAIN_WIDTH;
    const LandingPad *pads = terrain_current_pads();
    int pad_count = terrain_current_pad_count();

    for (int i = 0; i < pad_count; i++) {
        if (seg >= pads[i].start_seg && seg <= pads[i].end_seg) {
            return &pads[i];
        }
    }

    return 0;
}
