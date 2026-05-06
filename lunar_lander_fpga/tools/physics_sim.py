#!/usr/bin/env python3
"""Small off-board simulator for the fixed-point lander physics constants."""

GRAVITY = 2
THRUST_POWER = 6
H_THRUST_POWER = 2
H_DRAG = 1
MAX_VEL_Y = 400
MIN_VEL_Y = -400
MAX_VEL_X = 256
MIN_VEL_X = -256
FIXED_SHIFT = 8
LANDER_SIZE = 15
X_MIN_FP = LANDER_SIZE << FIXED_SHIFT
X_MAX_FP = (639 - LANDER_SIZE) << FIXED_SHIFT
Y_MIN_FP = LANDER_SIZE << FIXED_SHIFT
Y_MAX_FP = (479 - LANDER_SIZE) << FIXED_SHIFT


def clamp(value, low, high):
    return max(low, min(high, value))


def simulate(frames=300, thrust_frames=60, right_frames=0):
    pos_x = 320 << FIXED_SHIFT
    pos_y = 60 << FIXED_SHIFT
    vel_x = 0
    vel_y = 0

    for frame in range(frames):
        thrusting = frame < thrust_frames
        going_right = frame < right_frames

        vel_y += GRAVITY
        if thrusting:
            vel_y -= THRUST_POWER
        vel_y = clamp(vel_y, MIN_VEL_Y, MAX_VEL_Y)

        if going_right:
            vel_x += H_THRUST_POWER
        elif vel_x > H_DRAG:
            vel_x -= H_DRAG
        elif vel_x < -H_DRAG:
            vel_x += H_DRAG
        else:
            vel_x = 0
        vel_x = clamp(vel_x, MIN_VEL_X, MAX_VEL_X)

        pos_x += vel_x
        pos_y += vel_y

        if pos_y < Y_MIN_FP:
            pos_y = Y_MIN_FP
            vel_y = 0
        if pos_y > Y_MAX_FP:
            pos_y = Y_MAX_FP
            vel_y = 0
            vel_x = 0
        if pos_x < X_MIN_FP:
            pos_x = X_MIN_FP
            vel_x = 0
        if pos_x > X_MAX_FP:
            pos_x = X_MAX_FP
            vel_x = 0

        pixel_x = pos_x >> FIXED_SHIFT
        pixel_y = pos_y >> FIXED_SHIFT
        print(f"Frame {frame:03d}: x={pixel_x:3d} y={pixel_y:3d} vx={vel_x:4d} vy={vel_y:4d}")

        if pixel_y >= 450:
            print(f"HIT GROUND at frame {frame}, vel_y={vel_y}, vel_x={vel_x}")
            break


if __name__ == "__main__":
    simulate()
