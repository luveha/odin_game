package main

import "core:strconv"
import "core:thread"
import "vendor:sdl2"
import "core:fmt"
import "vendor:sdl2/ttf"
import "core:math/rand"

//Global to draw grid line
drawGrid := false

initSdl :: proc() -> bool {
    if sdl2.Init(sdl2.INIT_VIDEO) < 0 {
        fmt.eprintf("SDL initialization failed: %s\n", sdl2.GetError())
        return false
    }
    
    if ttf.Init() < 0 {
        fmt.eprintf("SDL_ttf initialization failed: %5s\n", ttf.GetError())
        sdl2.Quit()
        return false
    }
    
    return true
}

keyEvents :: proc(running: ^bool, info: ^Information, you: ^Entity, screen: ^Screen) {
    event: sdl2.Event

    for sdl2.PollEvent(&event) {
        if event.type == .QUIT {
            running^ = false
        } else if event.type == .KEYDOWN {
            if !info.game.paused {
                moved: bool = false

                #partial switch event.key.keysym.sym {
                case sdl2.Keycode.W:
                    if you.ypos >= 1 {
                        you.ypos -= 1
                        moved = true
                    } else {
                        y_curr := info.game.chunks.y
                        if((y_curr - 1) >= 0){
                            info.game.chunks.y -= 1
                            you.ypos = info.screen.rows -1
                        }
                    }
                    you.texture = 1
                case sdl2.Keycode.S:
                    if you.ypos + 1 < screen.rows {
                        you.ypos += 1
                        moved = true
                    } else {
                        y_max := info.game.chunks.y_max
                        y_curr := info.game.chunks.y
                        if((y_curr + 1) < y_max){
                            info.game.chunks.y += 1
                            you.ypos = 0
                        }
                    }
                    you.texture = 3
                case sdl2.Keycode.A:
                    if you.xpos >= 1 {
                        you.xpos -= 1
                        moved = true
                    } else {
                        x_curr := info.game.chunks.x
                        if((x_curr - 1) >= 0){
                            info.game.chunks.x -= 1
                            you.xpos = info.screen.cols -1
                        }
                    }
                    you.texture = 4
                case sdl2.Keycode.D:
                    if you.xpos + 1 < screen.cols {
                        you.xpos += 1
                        moved = true
                    } else {
                        x_max := info.game.chunks.x_max
                        x_curr := info.game.chunks.x
                        if((x_curr + 1) < x_max){
                            info.game.chunks.x += 1
                            you.xpos = 0
                        }
                    }
                    you.texture = 2
                }

                if moved {
                    you.cooldown = 0
                }
            }
            if event.key.keysym.sym == sdl2.Keycode.ESCAPE {
                info.game.paused = !info.game.paused
            }
        }
    }
    if you.cooldown >= 50 {
        you.texture = 0
        you.cooldown = 0
    } else {
        you.cooldown += 1
    }
}


draw :: proc(info: ^Information, you: ^Entity, textEntities: []TextEntity ) {
    
    xMapPos := info.game.chunks.x
    yMapPos := info.game.chunks.y

    enemies := info.game.chunks.chunk_enemies[xMapPos][yMapPos].enemies
    renderer := &info.screen.renderer
    background := info.game.chunks.chunk_backgrounds[xMapPos][yMapPos]
    // Clear screen
    sdl2.SetRenderDrawColor(renderer^, 0, 0, 0, 255)
    sdl2.RenderClear(renderer^)


    screen := info.screen
    buf := make([]u8, 32)
    points := strconv.itoa(buf, info.game.points) 

    cell_width := getCellWidth(screen)
    cell_height := getCellHeight(screen)
    // Draw background
    sdl2.RenderCopy(renderer^, background, nil, &sdl2.Rect {
        x = 0,
        y = 0,
        w = screen.height,
        h = screen.width,
    })
    // Draw grid lines
    if(drawGrid) {
        sdl2.SetRenderDrawColor(renderer^, 255, 255, 255, 255)

        // Vertical lines
        for col in 0..=screen.cols {
            x := col * cell_width
            sdl2.RenderDrawLine(renderer^, x, 0, x, screen.height)
        }

        // Horizontal lines
        for row in 0..=screen.rows {
            y := row * cell_height
            sdl2.RenderDrawLine(renderer^, 0, y, screen.width, y)
        }
    }

    dstrect := sdl2.Rect {
        x = you.xpos * cell_width,
        y = you.ypos * cell_height,
        w = cell_width,
        h = cell_height,
    }
    sdl2.RenderCopy(renderer^, you.textures[you.texture], nil, &dstrect)
    
    
    for i in 0..<screen.cols {
        for j in 0..<screen.rows {
            if(enemies[i][j] != nil) {
                if enemies[i][j].texture == nil {
                    fmt.eprintf("Error: Enemy at [%d][%d] has nil texture\n", i, j)
                    enemies[i][j].texture = info.game.textures["rang"]
                }
                dstrect := sdl2.Rect {
                    x = i * cell_width,
                    y = j * cell_height,
                    w = cell_width,
                    h = cell_height,
                }
                sdl2.RenderCopy(renderer^, enemies[i][j].texture, nil, &dstrect)
            }
        }
    }

    if textEntities != nil {
        for textEnt in textEntities {
            text_texture := createTextTexture(renderer^, screen.font, buildString(textEnt.text, points, ""), textEnt.color)

            text_rect := sdl2.Rect {
                x = i32(f32(screen.width) * textEnt.x),
                y = i32(f32(screen.height) * textEnt.y),
                w = textEnt.text_w,
                h = textEnt.text_h,
            }
            sdl2.RenderCopy(renderer^, text_texture, nil, &text_rect)
        }
    }
    //fmt.printfln("%b", info.game.paused)
    if(info.game.paused){
        drawMenu(info)
    }
    // Present the renderer
    sdl2.RenderPresent(renderer^)

    sdl2.Delay(16) // ~60 FPS
}

drawMenu :: proc(info: ^Information) {
    renderer := &info.screen.renderer
    screen := info.screen
    white := sdl2.Color{255, 255, 255, 255}

    // Example meaningful text
    text: cstring = "Paused"
    text_texture := createTextTexture(renderer^, screen.font, text, white)

    text_rect := sdl2.Rect {
        x = i32(f32(screen.width) * 0.5) - 50,
        y = i32(f32(screen.height) * 0.5) - 50,
        w = 100,
        h = 100,
    }
    sdl2.RenderCopy(renderer^, text_texture, nil, &text_rect)
}

eventLoop :: proc(you: ^Entity, info: ^Information) {
    xMapPos := info.game.chunks.x
    yMapPos := info.game.chunks.y

    chunk := info.game.chunks.chunk_enemies[xMapPos][yMapPos]
    enemies := chunk.enemies
    
    if enemies[you.xpos][you.ypos] != nil {
        free(enemies[you.xpos][you.ypos])
        enemies[you.xpos][you.ypos] = nil
        info.game.points += 10
    }
    
    for i in 0..<info.game.chunks.x_max{
        for j in 0..<info.game.chunks.y_max {
            spawnChance := rand.int31_max(1000)
            if spawnChance <= 10 {
                
                
                x := rand.int31_max(info.screen.rows)
                y := rand.int31_max(info.screen.cols)
                
                enemiesSpawn := info.game.chunks.chunk_enemies[i][j].enemies

                isTakenByPlayer : bool = (you.xpos == x) && (you.ypos == y)
                isOccupied : bool = (enemiesSpawn[x][y] != nil)
        
                if(!isTakenByPlayer && !isOccupied) {
                    enemiesSpawn[x][y] = new(Enemy)
                    enemiesSpawn[x][y].texture = info.game.textures["rang"]
                }
            }
        }
    }
}

makePlayer :: proc(you: ^Entity, info: Information) {
    you.ypos = 0
    you.xpos = 0
    you.textures = make([]^sdl2.Texture,5)
    you.textures[0] = makeTexture(info.screen.renderer, makeSurface("sanic/sanic"))
    you.textures[1] = makeTexture(info.screen.renderer, makeSurface("sanic/sanic_ran_up"))
    you.textures[2] = makeTexture(info.screen.renderer, makeSurface("sanic/sanic_ran_right"))
    you.textures[3] = makeTexture(info.screen.renderer, makeSurface("sanic/sanic_ran_down"))
    you.textures[4] = makeTexture(info.screen.renderer, makeSurface("sanic/sanic_ran_left"))
    you.cooldown = 0
}

makeMap :: proc(gameMap: ^Chunks, rows: int, cols: int, info: ^Information) {
    mapCol := 3
    mapRow := 3

    // Allocate matrix for map chunks
    enemiesMatrix := make([][]^Enemies, mapCol)
    for i in 0..<mapCol {
        enemiesMatrix[i] = make([]^Enemies, mapRow)
    }

    // Allocate matrix for backgrounds
    backgrounds := make([][]^sdl2.Texture, mapCol)
    for i in 0..<mapCol {
        backgrounds[i] = make([]^sdl2.Texture, mapRow)
    }

    surfaceB := makeSurface("backgrounds/newBackground")
    textureB := makeTexture(info.screen.renderer, surfaceB)
    //Manually set backgrounds
    backgrounds[0][1] = makeTexture(info.screen.renderer, makeSurface("backgrounds/desert_background"))
    backgrounds[0][2] = makeTexture(info.screen.renderer, makeSurface("backgrounds/ice_background"))
    backgrounds[1][0] = makeTexture(info.screen.renderer, makeSurface("backgrounds/jungle_background"))
    backgrounds[1][1] = makeTexture(info.screen.renderer, makeSurface("backgrounds/gamble_background"))
    backgrounds[1][2] = makeTexture(info.screen.renderer, makeSurface("backgrounds/road_background"))
    //
    for i in 0..<mapCol {
        for j in 0..<mapRow {
            EnemiesArr := make([][]^Enemy, cols)
            for i in 0..<cols {
                EnemiesArr[i] = make([]^Enemy, rows)
            }
            enemiesMatrix[i][j] = new(Enemies)
            enemiesMatrix[i][j].enemies = EnemiesArr
            if(backgrounds[i][j] == nil) {
                backgrounds[i][j] = textureB
            }
        }
    }

    gameMap.x = 0
    gameMap.y = 0
    gameMap.x_max = mapCol
    gameMap.y_max = mapRow
    gameMap.chunk_enemies = enemiesMatrix
    gameMap.chunk_backgrounds = backgrounds
}


main :: proc() {
    // Initialize SDL
    if !initSdl() {
        return
    }
    
    font := createFont()

    defer {
        ttf.Quit() 
        sdl2.Quit()
        ttf.CloseFont(font)
    }
    rows := 10
    cols := 10
    // Grid settings
    info : Information = Information {
        screen = &Screen {
            width = 800,
            height = 800,
            rows = i32(rows),
            cols = i32(cols),
            font = font,
        },
        game = &Game {
            points = 0,
            paused = false,
            textures = make(map[string]^sdl2.Texture),
        }
    }

    info.screen.renderer = createRenderer(createWindow(info.screen))

    TextEntities : []TextEntity = {
        TextEntity{"Points: ", sdl2.Color{255, 255, 255, 255}, 0.0, 0.8, 100, 50},
    }

    

    you := new(Entity)
    makePlayer(you, info)
    chunks := new(Chunks)
    makeMap(chunks, rows,cols, &info)
    info.game.chunks = chunks
    // Load rang
    rangTexture := makeTexture(info.screen.renderer, makeSurface("enemies/rang"))

    info.game.textures["rang"] = rangTexture

    
    //TEST END 

    running := true
    for running {
        keyEvents(&running, &info, you, info.screen)
        if(!info.game.paused){
            eventLoop(you, &info)
        }
        draw(&info, you, TextEntities)
    }
}
