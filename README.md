# reloader.nvim

> :warning: This plugin is still in development. If you find any bug please do not hesitate to create an issue of PR

## Contents

- [Prerequisites](#prerequisits)
- [Description](#description)
- [Installation](#installation)
- [Setup](#setup)
- [Contributing](#contributing)

## Prerequisites

This plugin requires the following plugins to be installed:
 - [jq](https://stedolan.github.io/jq/)
 - [fd](https://github.com/sharkdp/fd) - one some systems it is called `fd-find`, we asseme name `fd`

> **NOTE:** I have decided to drop the dependency on telescope.

If you want to reload the configuration you can use this command `:lua require('clang_reloader').reloader()`.

## Description

This ftplugin can alter the clangd lsp by changing the *compilationDatabasePath*.
Thus, you won't have to change the config and restart the project in neovim.

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
invoke `:lua require('clang_reloader').reloader()` and select
the directory you want to use.

This plugin will firstly parse your working directory and identify directories that
contain file `compile_commands.json`. Then it will list these directories in neovim.
You can select the directory you want to use. If the desired directory is not in the list
you can supply a custom path. If the project is not cross compiled, the compilers in `query-drivers`
will not be set up, but the compilation database will be changed.

The plugin will then change the `compilationDatabasePath` in your clangd lsp config.
So that you do not need to have multiple compilers in your config in the `--query-driver`
flag. This extension will also parse the chosen `compile_commands.json` and extract the
drivers for you.

 > NOTE: I only managed to make the query-drivers work with clangd version 15.0.6.
 > If you know how to do this on other versions please let me know or make a PR.
> But the compilationDatabasePath changing works on all versions.

## Installation

You can install this plugin with your favourite plugin manager. For example with
- lazy.nvim:
```lua
{
	'Fildo7525/reloader.nvim'
},
```
- packer.nvim:
```lua
use 'Fildo7525/reloader.nvim'
```

### Setup

```lua
require('clang_reloader').setup({

	-- These are default directories that will be displayed no matter what.
	directories = {
		vim.fn.getcwd() .. "/.build",
	},

    autocommand = {
        -- This will trigger the reloader when you open a file and the lsp compilationDatabasePath
        -- is not set or is no valid.
        enable = true,
        -- Directories where the autocommand will not be executed.
        forbidden_dirs = { },
    },

	-- Depth of the parsing. -1 means unbounded.
	max_depth = -1,

	-- In the picker is shown '...' instead of the current working directory.
	-- Great if your path is so long it does not fit to the screen.
	shorten_paths = false,

	-- Compilers that are detected in the compile_commands.json file.
	-- If you have a different compiler you can add it here.
	valid_compilers = {
		"clang",
		"clang++",
		"gcc",
		"g++",
		"nvcc",
	},
})
```


## Contributing

If you have any idea how to improve this plugin or you found a bug please do not hesitate to create an issue or PR.

