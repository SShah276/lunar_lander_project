#ifndef TERRAIN_H
#define TERRAIN_H

#define SCREEN_W       640
#define TERRAIN_SEGS   20
#define TERRAIN_SEG_W  32
#define NUM_PADS       4

typedef struct {
    int seg_start;
    int seg_end;
    int y;
    int score_mult;
} LandingPad;

extern int terrain_y[TERRAIN_SEGS];
extern LandingPad pads[NUM_PADS];

void terrain_init(void);
int terrain_get_y(int pixel_x);
int terrain_get_pad(int pixel_x);

#endif


/* #ifndef TERRAIN_H
#define TERRAIN_H

#define TERRAIN_SEGS   20
#define TERRAIN_SEG_W  32
#define NUM_PADS       2

// ============================================================
// LANDING PAD STRUCT
// ============================================================
typedef struct {
    int seg_start;
    int seg_end;
    int y;
    int score_mult;
} LandingPad;

// ============================================================
// GLOBAL DATA
// ============================================================
extern int terrain_y[TERRAIN_SEGS];
extern LandingPad pads[NUM_PADS];

// ============================================================
// API
// ============================================================
void terrain_init(void);
int terrain_get_y(int pixel_x);
int terrain_get_pad(int pixel_x);

#endif
*/
