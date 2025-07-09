package main

import "vendor:sdl2"
import "core:fmt"
import "vendor:sdl2/ttf"

createWindow :: proc(screen: ^Screen) -> ^sdl2.Window {
    window := sdl2.CreateWindow(
        "Odin Game",
        sdl2.WINDOWPOS_CENTERED, sdl2.WINDOWPOS_CENTERED,
        screen.width, screen.height,
        sdl2.WINDOW_SHOWN
    )
    if window == nil {
        fmt.eprintf("Window creation failed: %s\n", sdl2.GetError())
        return nil
    }

    return window
}

createRenderer:: proc(window: ^sdl2.Window ) -> ^sdl2.Renderer {
    renderer := sdl2.CreateRenderer(window, -1, sdl2.RENDERER_ACCELERATED)
    if renderer == nil {
        fmt.eprintf("Renderer creation failed: %s\n", sdl2.GetError())
        return nil
    }

    return renderer
}

createFont :: proc() -> ^ttf.Font {
    font := ttf.OpenFont("assets/font.ttf", 24)  
    if font == nil {
        fmt.eprintf("Failed to load font: %s\n", ttf.GetError())
        return nil
    }

    return font
}

makeSurface :: proc(asset: string) -> ^sdl2.Surface{
    surface := sdl2.LoadBMP(buildString("assets/", asset, ".bmp"))
    if surface == nil {
        fmt.println("Failed to load BMP: ", sdl2.GetError())
        return nil
    }
    return surface
}

makeTexture :: proc(renderer: ^sdl2.Renderer, surface: ^sdl2.Surface) -> ^sdl2.Texture {
    texture := sdl2.CreateTextureFromSurface(renderer, surface)
    if texture == nil {
        fmt.println("Failed to create texture: ", sdl2.GetError())
        return nil
    }
    return texture
}

createTextTexture :: proc(renderer: ^sdl2.Renderer, font: ^ttf.Font, text: cstring, color: sdl2.Color) -> ^sdl2.Texture {
    // Create surface from text
    surface := ttf.RenderText_Solid(font, text, color)
    if surface == nil {
        fmt.eprintf("Failed to create text surface: %s\n", ttf.GetError())
        return nil
    }
    defer sdl2.FreeSurface(surface)
    
    // Create texture from surface
    texture := sdl2.CreateTextureFromSurface(renderer, surface)
    if texture == nil {
        fmt.eprintf("Failed to create text texture: %s\n", sdl2.GetError())
        return nil
    }
    
    return texture
}