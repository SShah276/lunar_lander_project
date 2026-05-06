#include "terrain.h"

// ============================================================
// TERRAIN DATA
// Monochrome vector-style terrain. Keep these points in sync with
// hardware/render/Color_Mapper.sv.
// ============================================================

int terrain_y[TERRAIN_SEGS] = {
    448, 448, 368, 338, 398,
    350, 350, 424, 406, 332,
    238, 252, 336, 426, 448,
    448, 366, 304, 340, 340
};

LandingPad pads[NUM_PADS] = {
    { 1,  1,  448, 2 },   // far-left low pad
    { 5,  6,  350, 4 },   // mid-left pad
    { 14, 15, 448, 2 },   // valley pad
    { 18, 19, 340, 4 }    // right pad
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
    int frac = pixel_x % TERRAIN_SEG_W;

    if (seg < 0)               seg = 0;
    if (seg >= TERRAIN_SEGS)   seg = TERRAIN_SEGS - 1;

    if (seg == TERRAIN_SEGS - 1) return terrain_y[seg];

    return terrain_y[seg] +
           ((terrain_y[seg + 1] - terrain_y[seg]) * frac) / TERRAIN_SEG_W;
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
