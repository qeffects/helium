# State and Input

This guide assumes you already have read the getting started in [README.md](../README.md)  
And will use the [hello world repo](https://github.com/qeffects/helium-demo/) as a starting point

## State

UI elements tend to have various state, be it a button being pressed, a scroll bar's current value, current open tab, animations etc.

In helium you introduce state to your elements by importing the state module like this:

Note that you can have other values in the top level function(obviously), but changing them doesn't guarantee a display update

```lua
local useState = require 'helium.hooks.state'
```

And then using it inside the element like:

```lua
local elementCreator = helium(function(param, view)
	--Note that changing elementState.var now will re-render the element with this new elementState
	local elementState = useState({var = 10})
	--Changing this value will not update the element, but it can be used nonetheless:
	local notState = {var = 10}
.
	return function()

	end
end)
```

Now you can change the values of `elementState` and see the value update:

```lua
local elementCreator = helium(function(param, view)
	local elementState = useState({var = 10})

	return function()
		elementState.var = elementState.var + 1
		love.graphics.setColor(1, 1, 1)
		love.graphics.print('elementState.var: '..elementState.var)
	end
end)
```

This is where 
## Input
comes in

Input is a convenient module for various input subscriptions, import it like this:
```lua
local input = require 'helium.core.input'
```

Now you can use it in conjunction with state in your element like this:
```lua
local elementCreator = helium(function(param, view)
	local elementState = useState({down = false})
	input('clicked', function()
		elementState.down = not elementState.down
	end)

	return function()
		if elementState.down then
			love.graphics.setColor(1, 0, 0)
		else
			love.graphics.setColor(0, 1, 1)
		end
		love.graphics.print('button text')
	end
end)
```

The text now should toggle between 2 colors whenever pressed

The full call signature of input is:
`local sub = input(eventType, callback, startOn, x, y, w, h)`

See the demo repository with this example here: [Demo repo](https://github.com/qeffects/helium-input-state-demo)    
See all event types explained here: [Input events](./core/Input-events.md)    
There are a few pre-made hooks that abstract away state management, see here: [Shell](./Shell.md)     
For a more general overview of the whole library: [Module index](./Modules-Index.md)    