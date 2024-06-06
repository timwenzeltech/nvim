-- Eclipse Java development tools (JDT) Language Server downloaded from:
-- https://www.eclipse.org/downloads/download.php?file=/jdtls/milestones/1.21.0/jdt-language-server-1.21.0-202303161431.tar.gz
local jdtls = require("jdtls")
-- Change or delete this if you don't depend on nvim-cmp for completions.
local cmp_nvim_lsp = require("cmp_nvim_lsp")

-- Change jdtls_path to wherever you have your Eclipse Java development tools (JDT) Language Server downloaded to.
local jdtls_path = vim.fn.stdpath("data") .. "/language-servers/jdt-language-server"
local launcher_jar = vim.fn.glob(jdtls_path .. "/plugins/org.eclipse.equinox.launcher_*.jar")
local workspace_dir = vim.fn.fnamemodify(vim.fn.getcwd(), ":p:h:t")

vim.o.tabstop = 4
vim.o.shiftwidth = 0

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())
local extendedClientCapabilities = jdtls.extendedClientCapabilities
extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

local function get_config_dir()
	if vim.fn.has("linux") == 1 then
		return "config_linux"
	elseif vim.fn.has("mac") == 1 then
		return "config_mac"
	else
		return "config_win"
	end
end

local config = {
	cmd = {
		-- This sample path was tested on Cygwin, a "unix-like" Windows environment.
		-- Please contribute to this Wiki if this doesn't work for another Windows
		-- environment like [Git for Windows](https://gitforwindows.org/) or PowerShell.
		-- JDTLS currently needs Java 17 to work, but you can replace this line with "java"
		-- if Java 17 is on your PATH.
		"C:/Program Files/Java/jdk-17.0.4.1/bin/java",
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.protocol=true",
		"-Dlog.level=ALL",
		"-Xmx1G",
		"--add-modules=ALL-SYSTEM",
		"--add-opens",
		"java.base/java.util=ALL-UNNAMED",
		"--add-opens",
		"java.base/java.lang=ALL-UNNAMED",
		"-jar",
		launcher_jar,
		"-configuration",
		vim.fs.normalize(jdtls_path .. "/" .. get_config_dir()),
		"-data",
		vim.fn.expand("~/.cache/jdtls-workspace/") .. workspace_dir,
	},
	root_dir = vim.fs.dirname(vim.fs.find({ "pom.xml", ".git" }, { upward = true })[1]),
	capabilities = capabilities,
	settings = {
		java = {
			eclipse = {
				downloadSources = true,
			},
			configuration = {
				updateBuildConfiguration = "interactive",
				runtimes = {
					{
						name = "JavaSE-17",
						path = "/usr/lib/jvm/java-17-openjdk/",
					},
					{
						name = "JavaSE-21",
						path = "/usr/lib/jvm/java-21-openjdk/",
					},
				},
			},
			maven = {
				downloadSources = true,
			},
			referencesCodeLens = {
				enabled = true,
			},
			references = {
				includeDecompiledSources = true,
			},
			inlayHints = {
				parameterNames = {
					enabled = "all", -- literals, all, none
				},
			},
			format = {
				enabled = true,
				settings = {
					url = vim.fn.stdpath("config") .. "/lang-servers/intellij-java-google-style.xml",
					profile = "GoogleStyle",
				},
			},
			signatureHelp = { enabled = true },
			completion = {
				favoriteStaticMembers = {
					"org.hamcrest.MatcherAssert.assertThat",
					"org.hamcrest.Matchers.*",
					"org.hamcrest.CoreMatchers.*",
					"org.junit.jupiter.api.Assertions.*",
					"java.util.Objects.requireNonNull",
					"java.util.Objects.requireNonNullElse",
					"org.mockito.Mockito.*",
				},
				importOrder = {
					"java",
					"javax",
					"com",
					"org",
				},
			},
		},
	},
	init_options = {
		bundles = {
			--Debug
			vim.fn.glob(
				"~/.local/share/nvim/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"
			),
			--Test
			vim.fn.glob("~/.local/share/nvim/mason/packages/java-test/extension/server/*.jar"),
		},
		extendedClientCapabilities = extendedClientCapabilities,
	},
}

on_attach = function(client, bufnr)
	-- https://github.com/mfussenegger/dotfiles/blob/833d634251ebf3bf7e9899ed06ac710735d392da/vim/.config/nvim/ftplugin/java.lua#L88-L94
	local opts = { silent = true, buffer = bufnr }
	vim.keymap.set("n", "<leader>co", "<Cmd>lua require'jdtls'.organize_imports()<CR>", { desc = "Organize Imports" })
	vim.keymap.set(
		"n",
		"<leader>crv",
		"<Cmd>lua require('jdtls').extract_variable()<CR>",
		{ desc = "Extract Variable" }
	)
	vim.keymap.set(
		"v",
		"<leader>crv",
		"<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>",
		{ desc = "Extract Variable" }
	)
	vim.keymap.set(
		"n",
		"<leader>crc",
		"<Cmd>lua require('jdtls').extract_constant()<CR>",
		{ desc = "Extract Constant" }
	)
	vim.keymap.set(
		"v",
		"<leader>crc",
		"<Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>",
		{ desc = "Extract Constant" }
	)
	vim.keymap.set(
		"v",
		"<leader>crm",
		"<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>",
		{ desc = "Extract Method" }
	)
	local _, _ = pcall(vim.lsp.codelens.refresh)
	require("jdtls").setup_dap({ hotcodereplace = "auto" })
	-- Comment out the following line if you don't want intellij like inlay hints
	vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
	require("nvimtim.util.lsp_util").on_attach(bufnr)
	local status_ok, jdtls_dap = pcall(require, "jdtls.dap")
	if status_ok then
		jdtls_dap.setup_dap_main_class_configs()
	end
end

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	pattern = { "*.java" },
	callback = function()
		local _, _ = pcall(vim.lsp.codelens.refresh)
	end,
})

require("jdtls").start_or_attach(config)
