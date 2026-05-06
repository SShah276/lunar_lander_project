#ifndef TERRAIN_H
#define TERRAIN_H

#define TERRAIN_SEGS   20
#define TERRAIN_WIDTH  32

typedef struct {
    int start_seg;
    int end_seg;
    int y;
    int multiplier;
} LandingPad;

typedef enum {
    TERRAIN_EASY = 0,
    TERRAIN_MEDIUM = 1,
    TERRAIN_HARD = 2
} TerrainDifficulty;

extern const int terrain_easy[TERRAIN_SEGS];
extern const int terrain_medium[TERRAIN_SEGS];
extern const int terrain_hard[TERRAIN_SEGS];

extern const LandingPad pads_easy[2];
extern const LandingPad pads_medium[2];
extern const LandingPad pads_hard[1];

void terrain_set_difficulty(TerrainDifficulty difficulty);
const int *terrain_current(void);
const LandingPad *terrain_current_pads(void);
int terrain_current_pad_count(void);
int terrain_y_at_x(int pixel_x);
const LandingPad *terrain_pad_at_x(int pixel_x);

#endif

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