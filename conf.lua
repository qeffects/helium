return {
    HOTSWAP = true, --Deprecated
    AUTO_RUN = true, --Replaces the default love.run
	DEBUG = true, --Reserved for later
	PURE_G = true, --whether to keep _G pure
	HARD_ERROR = true, --Whether to display element errors inside or hard cras
	AUTO_CACHING = true, --Enable for cache money
	CACHING_CANVASES = 2, --How many fullscreen atlas canvases to create (change if auto_caching is enabled, to suit your needs, more means more texturememory)
}