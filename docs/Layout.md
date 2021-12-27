## Layout

Layouts are modules to help you laying elements out within a viewport, note they can only be used within elements themselves

Current layout schemes are:

### Column

Very basic column layout, it'll place one element after the next in a column

### Row

Very basic row layout, it'll place one element after the next in a row

### Container

Use this to position a single element within a parent container 

### Grid

Something akin to CSS grids, can create responsive layouts

Use em inside an element like:

```lua
local layoutScheme = require('helium.layout.column')
local someChildElementFactory

function ()
	local someChildElement = someChildElementFactory({}, 20, 20)
	return function()
		local layout = layoutScheme.new()
		someChildElement:draw()
		layout:draw()
	end
end
```

Each of these layout schemes will return a generic layout object which has a bunch of chainable methods, for setting padding, layout size etc.    
Some of the methods follow the size scheme of 0-1 = relative to the container (0-100%) and above = pixels, so that's something to keep in mind    
Layouts have some defaults set, like covering the whole width and height of the conteiner by default.    

```lua
local layoutScheme = require('helium.layout.column')
local someChildElementFactory

function ()
	local someChildElement = someChildElementFactory({}, 20, 20)
	return function()
		local layout = layoutScheme.new():width(300):height(300)
		someChildElement:draw()
		layout:draw()
	end
end
```