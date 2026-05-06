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

/* #include "terrain.h"

// ============================================================
// TERRAIN DATA
// Hand-crafted terrain for a consistent, playable layout.
// Y values: higher = lower on screen.
// Landing pads are flat segments between the rough terrain.
//
// Layout overview (segment 0-19, left to right):
//  0-2:   high cliff on left
//  3-4:   slope down
//  5-6:   PAD 1 (easy, wide, low altitude = segment Y ~350)
//  7-9:   rough mid terrain
//  10-11: peak
//  12-13: PAD 2 (hard, narrow, higher altitude = segment Y ~280)
//  14-16: slope down
//  17-19: low right terrain
// ============================================================

int terrain_y[TERRAIN_SEGS] = {
    370, 360, 340,   // 0-2:  left cliff
    320, 300,        // 3-4:  slope down to pad 1
    350, 350,        // 5-6:  PAD 1 (easy, flat)
    330, 310, 320,   // 7-9:  rough middle
    290, 280,        // 10-11: peak
    280, 280,        // 12-13: PAD 2 (hard, flat, higher up)
    300, 330, 350,   // 14-16: slope bac1k down
    360, 370, 370    // 17-19: right terrain
};

LandingPad pads[NUM_PADS] = {
    { 5,  6,  350, 1 },   // Pad 0: easy,  wide,   low altitude
    { 12, 13, 280, 2 }    // Pad 1: hard,  narrow, high altitude
};

void terrain_init(void) {
    // Nothing to initialize for static terrain.
    // If you add procedural generation later, put it here.
}

int terrain_get_y(int pixel_x) {
    // Clamp to screen
    if (pixel_x < 0)           pixel_x = 0;
    if (pixel_x >= SCREEN_W)   pixel_x = SCREEN_W - 1;

    int seg = pixel_x / TERRAIN_SEG_W;

    if (seg < 0)               seg = 0;
    if (seg >= TERRAIN_SEGS)   seg = TERRAIN_SEGS - 1;

    return terrain_y[seg];
}

int terrain_get_pad(int pixel_x) {
    int seg = pixel_x / TERRAIN_SEG_W;
    int i;
    for (i = 0; i < NUM_PADS; i++) {
        if (seg >= pads[i].seg_start && seg <= pads[i].seg_end) {
            return i;   // return which pad we're over
        }
    }
    return -1;   // not over any pad
}
*/