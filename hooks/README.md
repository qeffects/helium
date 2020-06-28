Hooks are additional functions to utilize the element lifecycle more granularly
e.g.

```lua
local onDestroyHook = require("helium/hooks/onDestroy")

return function (param)

    onDestroyHook(function()
        doSomething()
    end)

    return function()
        love.graphics.print("Help")
    end
end

```