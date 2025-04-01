## Hooks

Hooks are small single purpose modules for interaction with element lifecycle, they must be called inside the element function.

I prefer to use them like this

```lua
local useState = require('helium.hooks.state')

return function(param, view)
	local elementState = useState({foo='bar'})
    return function()

	end
end
```

### /hooks/callback.lua

Allows you to create a callback for this element that will be accessible on the element object

`useCallback(name:string, callback)`

Usage:

```lua
--Name will set the name of the accessible callback
local useCallback = require('helium.hooks.callback')

local element = helium(function(param, view)
	useCallback('fooCallback', function () print('here') end)
    return function()
	end
end)({}, 20, 20)

element.fooCallback()
```

### /hooks/state.lua

Creates an *attached state object*, this function will return a wrapper around the provided table that will re-render this element if any of the fields is changed

**It's important to use the direct table field like fooState.blah, instead of local x = fooState.blah**

**Avoid nested tables inside of states, changing nested table fields will not make elements render**

```lua
local useState = require('helium.hooks.state')

function(param, view)
	local fooState = useState({foo = 'bar',hello = true})
	fooState.hello = false
	print(fooState.foo)
    return function()
	end
end
```

### /hooks/context.lua

Creates a *context attached state object*, this will be a table that can be accessed in children elements, if an indexed field updates the children elements will be rerendered like they should be, so you can use this for communication to adjacent elements (in a form), dynamic style, a repository of game state data to be used for rendering etc. You can and should have multiple contexts

**Just like with state it's important to use the direct table field like fooCtx.blah, instead of local x = fooCtx.blah**

**Avoid nested tables inside of contexts, changing nested table fields will not queue elements for rendering**

`context.use(name, baseTable)` Creates a new context with the default values of baseTable

`context.get(name)` Gets an existing context with the name

Usage:

```lua
local context = require('helium.hooks.context')

--Parent element
function(param, view)
	local fooCtx = context.use('fooCtx',{foo = 'bar', asd = true})
	--Some children element created here
    return function()
	end
end

--Child element
function(param, view)
	local fooCtx = context.get('fooCtx')
	--This change will propogate to all fooCtx instances
	fooCtx.asd = not fooCtx.asd
	print(fooCtx.foo)
    return function()
	end
end
```

### /hooks/onDestroy.lua

Will create a callback that is called when an element is ended with the :destroy() method

`onDestroy(callback)`

Usage:

```lua
local onDestroy = require('helium.hooks.onDestroy')

function(param, view)
	onDestroy(function () print('element ended') end)
    return function()
	end
end
```

### /hooks/onLoad.lua

Will create a callback that is called when an element is loaded

`onLoad(callback)`

Usage:

```lua
--The call signature is (callback)
local onLoad = require('helium.hooks.onLoad')

function(param, view)
	onLoad(function () print('element loaded') end)
    return function()
	end
end
```


### /hooks/onPosChange.lua

Will create a callback that is called when an element is resized

`onPosChange(callback)`

Usage:

```lua
--The call signature is (callback)
local onPosChange = require('helium.hooks.onPosChange')

function(param, view)
	onPosChange(function (xnew, ynew) print('element moved') end)
    return function()
	end
end
```


### /hooks/onSizeChange.lua

Will create a callback that is called when an element is resized

`onSizeChange(callback)`

Usage:

```lua
local onSizeChange = require('helium.hooks.onSizeChange')

function(param, view)
	onSizeChange(function (newW,newH) print('element resized') end)
    return function()
	end
end
```

### /hooks/onUpdate.lua

Will create a callback that is called when an element is updated

There's not much practical benefit besides seperating update code outside of the rendering function

`onUpdate(callback)`

Usage:

```lua
local onUpdate = require('helium.hooks.onUpdate')

function(param, view)
	onUpdate(function () print('element updated') end)
    return function()
	end
end
```

### /hooks/setMinSize.lua

Sets the minimum size of this element, use this to set height from a font, lines of text, images

Mandatory to set at least something for layouting

`setMinSize(w:number, h:number)`

Usage:

```lua
local setMinSize = require('helium.hooks.setMinSize')

function(param, view)
	setMinSize(100, 100)
    return function()
	end
end
```

### /hooks/setPos.lua

Sets the position of the element, this is relative to the root

`setPos(x:number, y:number)`

Usage:

```lua
local setPos = require('helium.hooks.setPos')

function(param, view)
	setPos(100, 100)
    return function()
	end
end
```

### /hooks/setSize.lua

Sets the size of the element (if it's bigger than the minimum set size)

`setSize(w:number, h:number)`

Usage:

```lua
local setSize = require('helium.hooks.setSize')
local setMinSize = require('helium.hooks.setMinSize')

function(param, view)
	setMinSize(10, 10)
	setSize(100, 100)
    return function()
	end
end
```

### /hooks/setCaching.lua

Makes this element get cached, you'll need to set MANUAL_CACHING in config for this to work

Keep in mind that it won't make a magical performance benefit to an element that is being re-rendered by changes in children components, it's own state, resizing or position changes.

`setCaching()`

Usage:

```lua
local setCaching = require('helium.hooks.setCaching')

function(param, view)
	setCaching()
    return function()
	end
end
```