package input;

import rl "vendor:raylib"

up :: proc() -> bool {
    return rl.IsKeyDown(.UP) || rl.IsKeyDown(.W)
}

down :: proc() -> bool {
    return rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S)
}

right :: proc() -> bool {
    return rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D)
}

left :: proc() -> bool {
    return rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A)
}

shoot :: proc() -> bool {
    return rl.IsKeyPressed(.SPACE)
}