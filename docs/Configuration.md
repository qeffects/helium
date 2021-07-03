## Configuration

Helium offers some configuration values, exposed to you, the user with HELIUM_CONFIG table.

To start configuring, create a global table before the first helium require like this:

```lua
HELIUM_CONFIG = {
	LOAD_SHELL = true
}

local helium = require('helium')
```

If the configuration isn't working, you're probably not defining the `HELIUM_CONFIG` table early enough
After the first require it's safe to remove `HELIUM_CONFIG` as the values will be copied to an internal table.

## The current configuration values

the default value is indicated with () around em:

options: `other / (default)`

### LOAD_SHELL

options: `true / (false)`

This is an optional config that starts off by default, but it will load all of the ./shell/ modules in to the helium table
so you can use it like this later:

```lua
local helium = require('helium')
--
helium.shell.button()
```

The table structure mirrors the folders exactly, so, instead of

```lua
local checkbox = require('helium.shell.checkbox')
```

You can do 

```lua
local helium = require('helium')
--
helium.shell.checkbox()
```

### LOAD_LAYOUT

options: `true / (false)`

This one is extremely similar to LOAD_SHELL, the result is exactly the same, except it loads the ./layout/ folder, and it's also off by default

so you can do

```lua
local helium = require('helium')
--
helium.layout.container.new()
```

### LOAD_HOOKS

options: `true / (false)`

This one is similar to LOAD_LAYOUT and LOAD_SHELL, the result is the same, except it loads the modules in ./hook/ folder, and it's also off by default

so you can do

```lua
local helium = require('helium')
--
helium.hooks.state({blah = false})
```

### MANUAL_CACHING

options: `true / (false)`

Manual caching can be enabled if you want manual control over which elements are atlassed, use together with the `setCaching()` hook

Make sure to enable caching for the scenes you intend to use your element class for.

[Read about the set caching hook here](https://github.com/qeffects/helium/blob/layout/docs/Hooks.md#hookssetcachinglua)
