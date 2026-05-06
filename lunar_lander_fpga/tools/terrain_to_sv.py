#!/usr/bin/env python3
"""Generate a SystemVerilog terrain case statement from a C-style array."""

TERRAINS = {
    "easy": [
        420, 410, 400, 380, 360, 350, 350, 350, 370, 390,
        400, 410, 380, 360, 340, 340, 360, 380, 400, 420,
    ],
    "medium": [
        380, 390, 410, 430, 430, 405, 380, 360, 360, 360,
        380, 405, 430, 420, 390, 370, 370, 400, 430, 450,
    ],
    "hard": [
        300, 320, 350, 380, 410, 430, 440, 450, 440, 430,
        400, 370, 340, 340, 370, 400, 430, 450, 440, 420,
    ],
}


def emit_case(name):
    terrain = TERRAINS[name]
    print("case (seg)")
    for i, y in enumerate(terrain):
        print(f"    5'd{i}: terrain_point = 10'd{y};")
    print("    default: terrain_point = 10'd450;")
    print("endcase")


if __name__ == "__main__":
    emit_case("medium")
