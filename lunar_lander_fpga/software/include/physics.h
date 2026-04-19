#ifndef PHYSICS_H
#define PHYSICS_H

#include "game_logic.h"

void physics_update(
    LanderState *state,
    const LanderInput *input,
    const LanderConfig *config,
    float dt_seconds
);

#endif
