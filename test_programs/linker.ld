/* A simple linker script, which ensures that _start is placed at 0x0, and all other functions are placed after it. */
SECTIONS {
    .text 0x0000 : {
        *(.text._start)
        *(.text)
        *(.text.*)
    }
    .note.gnu.build-id (NOLOAD) : {
        *(.note.gnu.build-id)
    }
}
