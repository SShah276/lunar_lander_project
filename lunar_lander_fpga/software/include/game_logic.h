#ifndef GAME_LOGIC_H
#define GAME_LOGIC_H

#define STATE_PLAYING  0
#define STATE_LANDED   1
#define STATE_CRASHED  2

#define MAX_FUEL         1000
#define FUEL_BURN_RATE   1

#define GROUND_Y         450
#define SAFE_VEL_Y       80
#define SAFE_VEL_X       60

extern int game_state;
extern int fuel;

void game_logic_init(void);
void game_logic_update(void);

#endif
