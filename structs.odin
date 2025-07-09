package main

import "vendor:sdl2"
import "vendor:sdl2/ttf"

Information :: struct {
    screen : ^Screen,
    game : ^Game,
}
Entity :: struct {
    ypos: i32,
    xpos: i32,
    texture: i32,
    textures: []^sdl2.Texture,
    cooldown: int
}
Map :: struct {
    background: [][]^sdl2.Texture,
    enemies: [][]^Enemies,
    y: int,
    x: int,
    y_max: int,
    x_max: int,
}
Enemy :: struct {
    texture: ^sdl2.Texture
}
Enemies :: struct {
    enemies: [][]^Enemy,
}

TextEntity :: struct {
    text: string,
    color: sdl2.Color,
    y: f32,
    x: f32,
    text_w: i32, 
    text_h: i32
}

Screen :: struct {
    width: i32,
    height: i32,
    rows: i32,
    cols: i32,
    renderer: ^sdl2.Renderer,
    font: ^ttf.Font,
    background: ^sdl2.Texture,
}
Game :: struct {
    points: int,
    paused: bool,
    textures: map[string]^sdl2.Texture,
    gMap: ^Map
}