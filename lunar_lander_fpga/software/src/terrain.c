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

/* #include "terrain.h"

// ============================================================
// TERRAIN DATA
// Hand-crafted terrain for consistent gameplay
// ============================================================

int terrain_y[TERRAIN_SEGS] = {
    370, 360, 340,   // 0-2: left cliff
    320, 300,        // 3-4: slope down
    350, 350,        // 5-6: PAD 1
    330, 310, 320,   // 7-9: rough middle
    290, 280,        // 10-11: peak
    280, 280,        // 12-13: PAD 2
    300, 330, 350,   // 14-16: slope down
    360, 370, 370    // 17-19: right terrain
};

// ============================================================
// LANDING PADS
// ============================================================

LandingPad pads[NUM_PADS] = {
    { 5,  6,  350, 1 },   // easy pad
    { 12, 13, 280, 2 }    // hard pad
};

// ============================================================
// INIT
// ============================================================

void terrain_init(void) {
    // Static terrain — nothing needed
}

// ============================================================
// GET TERRAIN HEIGHT (block-style, no interpolation)
// ============================================================

int terrain_get_y(int pixel_x) {
    if (pixel_x < 0) pixel_x = 0;
    if (pixel_x >= TERRAIN_SEGS * TERRAIN_SEG_W)
        pixel_x = TERRAIN_SEGS * TERRAIN_SEG_W - 1;

    int seg = pixel_x / TERRAIN_SEG_W;

    if (seg < 0) seg = 0;
    if (seg >= TERRAIN_SEGS) seg = TERRAIN_SEGS - 1;

    return terrain_y[seg];
}

// ============================================================
// GET PAD INDEX
// Returns: pad index OR -1 if not on pad
// ============================================================

int terrain_get_pad(int pixel_x) {
    int seg = pixel_x / TERRAIN_SEG_W;

    for (int i = 0; i < NUM_PADS; i++) {
        if (seg >= pads[i].seg_start &&
            seg <= pads[i].seg_end) {
            return i;
        }
    }

    return -1;
}
*/
