package main;

import rl "vendor:raylib"
import "core:fmt"
import "core:time"
import "core:math/rand"
import "input"
import "constant"

frame_collector: f32

State :: struct {
    tick: i32,
    player_pos: rl.Vector2,
    enemy_pos: [dynamic]rl.Vector2,
    enemy_hp: [dynamic]i32,
    bullet_pos: [dynamic]rl.Vector2, 
    bullet_dir: [dynamic]constant.owner
}

state := State{
    player_pos = rl.Vector2{f32(constant.SCREEN_SIZE.x) / 2, f32(constant.SCREEN_SIZE.y) - constant.PLAYER_SIZE.y}
}

main :: proc() {
    rl.InitWindow(constant.SCREEN_SIZE.x, constant.SCREEN_SIZE.y, "Land Invaders")
    init()


    for !rl.WindowShouldClose() {
        frame_collector += rl.GetFrameTime()

        for frame_collector >= constant.TICK_TD {
            fmt.println(rl.GetFPS())
            update(constant.TICK_TD)
            frame_collector -= constant.TICK_TD
        }

        render()
    }


    rl.CloseWindow()
}

// SETUP 

init :: proc() {
    rl.SetTargetFPS(constant.FPS)
}


// LOGIC

update :: proc(delta: f32) {
    state.tick += 1

    if state.tick % constant.ENEMY_SPAWN_DELAY == 0 {
        new_wave()
    }
    // fmt.println(state.tick)
    move_player(delta)
    if input.shoot() {
        spawn_bullet(player_bullet_spawn_point(state.player_pos, constant.PLAYER_SIZE), constant.owner.PLAYER)
    }
    
    move_enemies(delta)
    move_bullets(delta)
}

spawn_bullet :: proc(pos: rl.Vector2, owner: constant.owner) {
    fmt.println("pew")
    append(&state.bullet_pos, pos)
    append(&state.bullet_dir, owner)
}

move_player :: proc(delta: f32) {
    if input.up() do state.player_pos.y -= constant.PLAYER_SPEED * delta
    if input.down() do state.player_pos.y += constant.PLAYER_SPEED * delta
    if input.left() do state.player_pos.x -= constant.PLAYER_SPEED * delta
    if input.right() do state.player_pos.x += constant.PLAYER_SPEED * delta
}

move_enemies :: proc(delta: f32) {
    #reverse for &enemy, i in state.enemy_pos {
        enemy.y += constant.ENEMY_SPEED * delta

        if state.tick % constant.ENEMY_SHOOT_DELAY == 0 {
            spawn_bullet({enemy.x, enemy.y + constant.ENEMY_SIZE.y}, constant.owner.ENEMY)
        }
    }
}

move_bullets :: proc(delta: f32) {
    #reverse for &bullet, i_bullet in state.bullet_pos {

        if state.bullet_dir[i_bullet] == constant.owner.PLAYER {
            bullet.y -= constant.BULLET_SPEED * delta

            // check collision, trailing box
            #reverse for &enemy, i_enemy in state.enemy_pos {
                if rl.CheckCollisionRecs(bullet_hitbox(bullet), enemy_hitbox(enemy)) {
                    fmt.println("hit")
                    handle_hit(i_enemy, 1)

                    remove_bullet(i_bullet)
                    return

                }
            }

        } else {
            bullet.y += constant.BULLET_SPEED * delta

            // check player collision
            if rl.CheckCollisionRecs(bullet_hitbox(bullet), player_hitbox()) {
                fmt.println("player hit")
                remove_bullet(i_bullet)
                return
            }


            // check bullet collision
            #reverse for &other_bullet, i in state.bullet_pos {
                if state.bullet_dir[i] == constant.owner.ENEMY do continue

                if rl.CheckCollisionRecs(bullet_hitbox(bullet), bullet_hitbox(other_bullet)) {
                    fmt.println("hit bullet")

                    remove_bullet(i_bullet)
                    return
                }
            }
        }




        // cleanup
        if bullet.y < -constant.BULLET_SIZE.y || bullet.y > f32(constant.SCREEN_SIZE.y) do remove_bullet(i_bullet)
    }
}

remove_bullet :: proc(i: int) {
    fmt.println("remove bullet")
    unordered_remove(&state.bullet_pos, i)
    unordered_remove(&state.bullet_dir, i)
}

handle_hit :: proc(index: int, damage: i32) {
    state.enemy_hp[index] -= damage

    if state.enemy_hp[index] <= 0 {
        // remove enemy
        unordered_remove(&state.enemy_hp, index)
        unordered_remove(&state.enemy_pos, index)
    }
}

player_bullet_spawn_point :: proc(topleft, size: rl.Vector2) -> rl.Vector2 {
    return rl.Vector2{topleft.x + size.x / 2, topleft.y - constant.BULLET_SIZE.y - 10}
}


enemy_hitbox :: proc(pos: rl.Vector2) -> rl.Rectangle {
    return rl.Rectangle{pos.x, pos.y, constant.ENEMY_SIZE.x, constant.ENEMY_SIZE.y}
}

bullet_hitbox :: proc(pos: rl.Vector2) -> rl.Rectangle {
    return rl.Rectangle{pos.x, pos.y, constant.BULLET_SIZE.x, constant.BULLET_SIZE.y + constant.BULLET_SPEED * constant.TICK_TD}
}

player_hitbox :: proc() -> rl.Rectangle {
    return rl.Rectangle{state.player_pos.x, state.player_pos.y, constant.PLAYER_SIZE.x, constant.PLAYER_SIZE.y}
}

new_wave :: proc() {
    n := i32(rand.int_range(3,6))

    offset := constant.SCREEN_SIZE.x / (n+1)

    for i in 1..=n {
        x := offset * i 
        fmt.println(x)
        new_enemy({f32(x) - constant.ENEMY_SIZE.x / 2, -constant.ENEMY_SIZE.y})
    }

}

new_enemy :: proc(pos: rl.Vector2) {
    fmt.println("SPAWN")
    fmt.println(pos)
    append(&state.enemy_pos, pos)
    append(&state.enemy_hp, constant.ENEMY_BASE_HP)
}

// RENDER 


render :: proc() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        draw_enemies()

        draw_bullets()

        draw_player()
        
        rl.EndDrawing()
}

draw_enemies :: proc() {
    for &enemy, i in state.enemy_pos {
        rl.DrawRectangleV(enemy, constant.ENEMY_SIZE, rl.RED)
    }
}

draw_player :: proc() {
    rl.DrawRectangleV(state.player_pos, constant.PLAYER_SIZE, rl.WHITE)
}

draw_bullets :: proc() {
    for &bullet, i in state.bullet_pos {
        rl.DrawRectangleV(bullet, {constant.BULLET_SIZE.x, constant.BULLET_SIZE.y + constant.BULLET_SPEED * constant.TICK_TD}, rl.YELLOW)
        rl.DrawRectangleV(bullet, constant.BULLET_SIZE, rl.RED)
    }
}