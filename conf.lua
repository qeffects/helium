---@class __HELIUM_CONFIG
---@field DEBUG boolean
---@field LOAD_HOOKS boolean
---@field LOAD_LAYOUT boolean
---@field LOAD_SHELL boolean
---@field MANUAL_CACHING boolean

---@type __HELIUM_CONFIG
return {
	DEBUG           = true,  --Reserved for later
	LOAD_HOOKS      = false, --Loads the hooks module in to helium table
	LOAD_LAYOUT     = false, --Loads the layout module in to helium table
	LOAD_SHELL      = false, --Loads the shell mocule in to helium table
	MANUAL_CACHING  = false, --Whether or not to perform automatic caching
	AUTO_INPUT_SUB  = true,  --Whether to inject helium input intermediary functions in to love.handlers
	ATLAS_SIZE_MULT = 1.1,   --The screen size multiplier of caching atlases (bigger means more atlas space)
}