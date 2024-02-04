# reloader.nvim

reloader.nvim is a ftplugin extension for telescope. This plugin can alter the clangd lsp
by changing the *compilationDatabasePath*. Thus, you won't have to change the config
and restart the project in neovim.

Let's say your project is organised as such:

 - MyProject
    - main.cpp
    - x86_build
        - first.cpp
        - first.h
    - arm_build
        - second.cpp
        - second.h
    - build_x86
        - compile_commands.json
        - ... all the other files
    - build_armv8
        - compile_commands.json
        - ... all the other files

In project on x86 build you use x86_build directory and its
files and on arm build you use arm_build directory and its
files. To change between these two build you only need to
invoke `:Telescope clang_reloader`.
