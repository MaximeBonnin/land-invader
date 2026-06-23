package constant;

import rl "vendor:raylib"

FPS :: 60
TICK_RATE :: 60
TICK_TD :: f32(1.0) / TICK_RATE

SCREEN_SIZE :: [2]i32{420, 720}

PLAYER_SPEED :: 150
PLAYER_SIZE :: rl.Vector2{32, 32}
PLAYER_HP :: 10

BULLET_SIZE :: rl.Vector2{10, 10}
BULLET_SPEED :: 222

ENEMY_SIZE :: rl.Vector2{32, 32}
ENEMY_SPEED :: 33
ENEMY_BASE_HP :: 5
ENEMY_SPAWN_DELAY :: 5 * 60 // in ticks
ENEMY_SHOOT_DELAY :: 90 // in ticks

owner :: enum {
    PLAYER,
    ENEMY
}

TUTORIAL_MESSAGE : cstring : "Use WASD or Arrow Keys to move.\nUse Space to shoot."