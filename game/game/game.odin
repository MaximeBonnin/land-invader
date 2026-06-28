package game

import rl "vendor:raylib"
import "core:fmt"
import "core:math/rand"
import "../input"
import "../constant"
import "../scoreboard"
import "../error"

frame_collector: f32
show_tutorial:= true
game_over: bool
state : State

State :: struct {
    tick: i32,
    player_pos: rl.Vector2,
    player_hp: i32,
    enemy_pos: [dynamic]rl.Vector2,
    enemy_hp: [dynamic]i32,
    bullet_pos: [dynamic]rl.Vector2, 
    bullet_dir: [dynamic]constant.owner,
    score: i64,
    scoreboard: scoreboard.Scoreboard,
}


main_loop :: proc() {
    rl.InitWindow(constant.SCREEN_SIZE.x, constant.SCREEN_SIZE.y, "Land Invaders")
    init()


    for !rl.WindowShouldClose() {
        free_all(context.temp_allocator)
        if running() {
            frame_collector += rl.GetFrameTime()

            for frame_collector >= constant.TICK_TD {
                // fmt.println(rl.GetFPS())
                update(constant.TICK_TD)
                frame_collector -= constant.TICK_TD
            }

            render()
        } else {

            render_end()
            if input.restart() {
                game_over = false
                init()
            }
        }
    }

    rl.CloseWindow()
}

// SETUP 

init :: proc() {
    rl.SetTargetFPS(constant.FPS)

    state = State{}
    frame_collector = 0
    state.player_pos = rl.Vector2{f32(constant.SCREEN_SIZE.x) / 2, f32(constant.SCREEN_SIZE.y) - constant.PLAYER_SIZE.y}
    state.player_hp = constant.PLAYER_HP
}


// LOGIC

running :: proc() -> bool {
    return !rl.WindowShouldClose() && !game_over
}

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
    append(&state.bullet_pos, pos)
    append(&state.bullet_dir, owner)
}

move_player :: proc(delta: f32) {
    if input.up() do state.player_pos.y -= constant.PLAYER_SPEED * delta
    if input.down() do state.player_pos.y += constant.PLAYER_SPEED * delta
    if input.left() do state.player_pos.x -= constant.PLAYER_SPEED * delta
    if input.right() do state.player_pos.x += constant.PLAYER_SPEED * delta

    if state.player_pos.x < 0 do state.player_pos.x = 0
    if state.player_pos.x > f32(constant.SCREEN_SIZE.x) - constant.PLAYER_SIZE.x do state.player_pos.x = f32(constant.SCREEN_SIZE.x) - constant.PLAYER_SIZE.x
    if state.player_pos.y < 0 do state.player_pos.y = 0
    if state.player_pos.y > f32(constant.SCREEN_SIZE.y) - constant.PLAYER_SIZE.y do state.player_pos.y = f32(constant.SCREEN_SIZE.y) - constant.PLAYER_SIZE.y
}

move_enemies :: proc(delta: f32) {
    #reverse for &enemy in state.enemy_pos {
        enemy.y += constant.ENEMY_SPEED * delta

        if enemy.y >= f32(constant.SCREEN_SIZE.y) - constant.ENEMY_SIZE.y {
            handle_game_over()
            return
        }

        if state.tick % constant.ENEMY_SHOOT_DELAY == 0 {
            spawn_bullet({enemy.x, enemy.y + constant.ENEMY_SIZE.y}, constant.owner.ENEMY)
        }
    }
}

handle_game_over :: proc() {
    game_over = true

    scoreboard.post(
        scoreboard.Score{
            name = "dev",
            score = state.score,
        }
    )

    // get score
    board, err := scoreboard.get()
    if err != error.Error.None {
        fmt.println("broblem")
    }
    state.scoreboard = board
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
                state.player_hp -= 1
                if state.player_hp <= 0 {
                    handle_game_over()
                }
                remove_bullet(i_bullet)
                return
            }


            // check bullet collision
            #reverse for &other_bullet, i in state.bullet_pos {
                if state.bullet_dir[i] == constant.owner.ENEMY do continue

                if rl.CheckCollisionRecs(bullet_hitbox(bullet), bullet_hitbox(other_bullet)) {

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
    unordered_remove(&state.bullet_pos, i)
    unordered_remove(&state.bullet_dir, i)
}

handle_hit :: proc(index: int, damage: i32) {
    state.enemy_hp[index] -= damage

    if show_tutorial do show_tutorial = false

    if state.enemy_hp[index] <= 0 {
        state.score += 1
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
        new_enemy({f32(x) - constant.ENEMY_SIZE.x / 2, -constant.ENEMY_SIZE.y})
    }

}

new_enemy :: proc(pos: rl.Vector2) {
    append(&state.enemy_pos, pos)
    append(&state.enemy_hp, constant.ENEMY_BASE_HP)
}

// RENDER 


render :: proc() {
    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    if show_tutorial {
        draw_tutorial()
    }

    draw_enemies()

    draw_bullets()

    draw_player()

    draw_ui()
    
    rl.EndDrawing()
}

draw_enemies :: proc() {
    for &enemy in state.enemy_pos {
        rl.DrawRectangleV(enemy, constant.ENEMY_SIZE, rl.RED)
    }
}

draw_player :: proc() {
    rl.DrawRectangleV(state.player_pos, constant.PLAYER_SIZE, rl.WHITE)
}

draw_bullets :: proc() {
    for &bullet in state.bullet_pos {
        rl.DrawRectangleV(bullet, {constant.BULLET_SIZE.x, constant.BULLET_SIZE.y + constant.BULLET_SPEED * constant.TICK_TD}, rl.YELLOW)
        rl.DrawRectangleV(bullet, constant.BULLET_SIZE, rl.RED)
    }
}

draw_ui :: proc() {
    rl.DrawText(fmt.ctprintf("Player HP: %d", state.player_hp), 10, 10, 20, rl.WHITE)
    rl.DrawText(fmt.ctprintf("Score: %d", state.score), 10, 35, 20, rl.WHITE)
}

draw_tutorial :: proc () {
    size : i32 = 20
    x := (constant.SCREEN_SIZE.x - rl.MeasureText(constant.TUTORIAL_MESSAGE, size)) / 2
    y := constant.SCREEN_SIZE.y / 2

    rl.DrawText(constant.TUTORIAL_MESSAGE, x, y, size, rl.GRAY)
}

// ENDSCREEN

end_visible :: proc() -> bool {
    return !rl.WindowShouldClose()
}

render_end :: proc () {
    rl.BeginDrawing()
    rl.ClearBackground(rl.BLACK)

    draw_score()
    draw_scoreboard()
    
    rl.EndDrawing()
}

draw_score :: proc() {

    score_msg := fmt.ctprintf("Score: %d", state.score)
    size : i32 = 40
    x := (constant.SCREEN_SIZE.x - rl.MeasureText(score_msg, size)) / 2
    y := constant.SCREEN_SIZE.y / 4

    rl.DrawText(score_msg, x, y, size, rl.WHITE)


    total := state.tick / constant.TICK_RATE   // whole seconds (i32)
    mins  := total / 60
    secs  := total % 60
    time_msg := fmt.ctprintf("%02d:%02d", mins, secs)

    rl.DrawText(time_msg, x, y + 45, 20, rl.WHITE)

    
    rl.DrawText(fmt.ctprintf("Press ENTER to restart."), x, constant.SCREEN_SIZE.y - 30, 20, rl.WHITE)
}

draw_scoreboard :: proc () {

    size : i32 = 25
    offset := size + 5

    board_msg := fmt.ctprintf("Leaderboard")
    rl.DrawText(
        board_msg, 
        (constant.SCREEN_SIZE.x - rl.MeasureText(board_msg, size)) / 2 , 
        constant.SCREEN_SIZE.y / 2, 
        size, rl.WHITE
    )

    if len(state.scoreboard) <= 0 {
        unavail_msg := fmt.ctprintf("currently unavailable")
        rl.DrawText(
            unavail_msg, 
            (constant.SCREEN_SIZE.x - rl.MeasureText(unavail_msg, size)) / 2, 
            constant.SCREEN_SIZE.y / 2 + offset, 
            size, rl.GRAY
        )
    }

    for i in 0..<len(state.scoreboard) {
        score := state.scoreboard[i]

        score_msg := fmt.ctprintf("%s | %d",score.name, score.score)
        x := (constant.SCREEN_SIZE.x - rl.MeasureText(score_msg, size)) / 2
        y := constant.SCREEN_SIZE.y / 2 + offset * i32(i + 1)

        rl.DrawText(score_msg, x, y, size, rl.WHITE)
    }
}