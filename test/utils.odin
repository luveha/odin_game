package main

import "core:strings"

buildString :: proc(first: string, second: string, third: string) -> cstring {
    bString := strings.concatenate({first, second, third})

    cString := strings.clone_to_cstring(bString)
    defer delete(bString)

    return cString
}
getCellWidth :: proc(screen: ^Screen) -> i32 {
    return screen.width / screen.cols
}
getCellHeight:: proc(screen: ^Screen) -> i32 {
    return screen.height / screen.rows   
}
