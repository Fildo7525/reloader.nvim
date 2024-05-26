# reloader.nvim

> :warning: This plugin is still in development. If you find any bug please do not hesitate to create an issue of PR

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

This extension will firstly parse your working directory and identify directories that
contain file `compile_commands.json`. Then it will list these directories in telescope.
You can select the directory you want to use and press enter.

 > Note: the first element of the picker is always your current compilationDatabasePath.

The extension will then change the `compilationDatabasePath` in your clangd lsp config.
So that you do not need to have multiple compilers in your config in the `--query-driver`
flag. This extension will also parse the chosen `compile_commands.json` and extract the
drivers for you.

 > WARN: I only managed to do this with clangd version 15.0.6. If you know how to do This
 > on later versions please let me know or make a PR.

### Setup

To make all of this work you need to have the following in your config:
```lua
{
    -- Your clangd lsp config.
	config = require("usr.lsp.settings.clangd"),

    -- Depth of the parsing. -1 means unbounded.
	max_depth = 2,

    -- These are default directories that will be displayed no matter what.
	directories = {
		vim.fn.getcwd(),
	},

    -- This will trigger the reloader when you open a file and the lsp compilationDatabasePath
    -- is not set or is no valid.
	detect_on_startup = true,

    -- Your on_attach funciton and capabilities tables.
	options = {
		on_attach = require("usr.lsp.handlers").on_attach,
		capabilities = require("usr.lsp.handlers").capabilities,
	},
}

```

The on_attach function should look like this:
```lua
M.on_attach = function(client, bufnr)
 	if client.name == "tsserver" then -- or client.name == "jdt.ls" then
 	 	client.server_capabilities.document_formatting = false
 	end
 	if client.name == "clangd" then
 	 	client.server_capabilities.document_formatting = false
 	end

	-- if client.name == "jdt.ls" then
	-- 	require("jdtls").setup_dap { hotcoderpalce = "auto" }
	-- 	require("jdtls.dap").setup_dap_main_class_configs();
	-- end
 	lsp_keymaps(bufnr)
 	lsp_highlight_document(client)
end
```

And the capabilities could look like this:
```lua
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true;

local cmp_nvim_lsp = require("cmp_nvim_lsp")

M.capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
```

