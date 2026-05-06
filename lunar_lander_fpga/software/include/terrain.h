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
