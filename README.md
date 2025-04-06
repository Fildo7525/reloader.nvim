# reloader.nvim

> :warning: This plugin is still in development. If you find any bug please do not hesitate to create an issue of PR

## Contents

- [Prerequisites](#prerequisits)
- [Description](#description)
- [Installation](#installation)
- [Setup](#setup)
	- [With telescope](#with-telescope)
	- [Without telescope](#without-telescope)
	- [Common seutp](#common-setup)
- [Contributing](#contributing)

## Prerequisites

This plugin requires the following plugins to be installed:
 - [jq](https://stedolan.github.io/jq/)
 - [fd](https://github.com/sharkdp/fd) - one some systems it is called `fd-find`, we asseme name `fd`
 - **OPTIONAL**: [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

In the newest version of this plugin you can decide if you want to use telescope or not.
If you do not want to use telescope you can use the function `:lua require('reloader').reloader()`.
The setup is done the same way as with telescope.

:warning:  You have to set the flag `use_telescope` to **false**. Otherwise the plugin will not work.

```lua
local reloader = require("clang_reloader")
reloader.setup{
	use_telescope = false,
}
```
more in the [Without telescope](#without-telescope) section.

## Description

reloader.nvim is a ftplugin extension for telescope. This plugin can alter the clangd lsp
by changing the *compilationDatabasePath*. Thus, you won't have to change the config
and restart the project in neovim.

![clang_reloader](https://github.com/Fildo7525/reloader.nvim/assets/59179935/75a4a63d-7461-47d3-9118-767567767169)

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
invoke `:Telescope clang_reloader` or `:lua require('telescope').extensions.clang_reloader.clang_reloader()`.

This extension will firstly parse your working directory and identify directories that
contain file `compile_commands.json`. Then it will list these directories in telescope.
You can select the directory you want to use. If the desired directory is not in the list
you can supply a custom path. If the project is not cross compiled, the compilers in `query-drivers`
will not be set up, but the compilation database will be changed.

 > NOTE: the first element of the picker is always your current compilationDatabasePath.

The extension will then change the `compilationDatabasePath` in your clangd lsp config.
So that you do not need to have multiple compilers in your config in the `--query-driver`
flag. This extension will also parse the chosen `compile_commands.json` and extract the
drivers for you.

 > NOTE: I only managed to do this with clangd version 15.0.6 and 18.1.3. If you know how to do this
 > on other versions please let me know or make a PR.

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

#### With telescope

:warning: I guess everyone has a different setup so you need to change the config to your needs. \
The default config is as follows:
```lua
local telescope = require("telescope")
telescope.setup{
	extensions = {
		clang_reloader = {
			-- This is the default value. If you want to use telescope do not change this.
			use_telescope = true,

			---------------------------------------------
			-- These you will probably need to change. --
			---------------------------------------------

			-- Your clangd lsp config.
			config = require("usr.lsp.settings.clangd"),

			-- Your on_attach function and capabilities table.
			options = {
				on_attach = require("usr.lsp.handlers").on_attach,
				capabilities = require("usr.lsp.handlers").capabilities,
			},

			-------------------------------
			-- These are not mandatory.  --
			-------------------------------

			-- Directories where the autocommand will not be executed.
			forbidden_dirs = { },

			-- These are default directories that will be displayed no matter what.
			directories = {
				vim.fn.getcwd() .. "/.build",
			},

			-- This will trigger the reloader when you open a file and the lsp compilationDatabasePath
			-- is not set or is no valid.
			detect_on_startup = true,

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
		},
	}
}
telescope.load_extension('clang_reloader')

```

#### Without telescope

```lua
require('clang_reloader').setup({
	-- You have to set this to false if you do not want to use telescope.
	use_telescope = false,
	---------------------------------------------
	-- These you will probably need to change. --
	---------------------------------------------

	-- Your clangd lsp config.
	config = require("usr.lsp.settings.clangd"),

	-- Your on_attach function and capabilities table.
	options = {
		on_attach = require("usr.lsp.handlers").on_attach,
		capabilities = require("usr.lsp.handlers").capabilities,
	},

	-------------------------------
	-- These are not mandatory.  --
	-------------------------------

	-- Directories where the autocommand will not be executed.
	forbidden_dirs = { },

	-- These are default directories that will be displayed no matter what.
	directories = {
		vim.fn.getcwd() .. "/.build",
	},

	-- This will trigger the reloader when you open a file and the lsp compilationDatabasePath
	-- is not set or is no valid.
	detect_on_startup = true,

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

#### Common setup

The on_attach function should look like this:
```lua
M.on_attach = function(client, bufnr)
 	if client.name == "clangd" then
		-- setup server capabilities
 	end

 	lsp_keymaps(bufnr)
end
```

And the capabilities could look like this:
```lua
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true;

local cmp_nvim_lsp = require("cmp_nvim_lsp")

M.capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
```



## Contributing

If you have any idea how to improve this plugin or you found a bug please do not hesitate to create an issue or PR.

