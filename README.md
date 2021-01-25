![alt text](https://i.imgur.com/ZQBQfsa.png "Helium")
# Helium

## Basic overview:
Helium is practically more like a UI framework than a fully fledged UI library. 
The idea is to build custom and build simple.

## Getting started:
Load helium with `local helium = require 'helium'`
or [check out the pre-configured demo repository](https://github.com/qeffects/helium-demo/)

The structure of an element's function is:

```lua
function(param, view)
	--State/setup/load
	return function()
		--Rendering zone
	end
end
```

and you can make that function into an element 'factory' like this:
```lua
elementCreator = helium(function(param, view)

	return function()

	end
end)
```

then you call the element factory with a table of parameters that will get passed to the element and optionally width and height:

```lua
element = elementCreator({text = 'foo-bar'}, 100, 20)
```

this will create a new instance of the element, and then you can draw it to whatever position you wish (x, y):

```lua
element:draw(100, 100)
```

Let's draw a rectangle with text with the previous skeleton and functions:

```lua
local helium = require 'helium'

local elementCreator = helium(function(param, view)

	return function()
		love.graphics.setColor(0.3, 0.3, 0.3)
		love.graphics.rectangle('fill', 0, 0, view.w, view.h)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print('hello world')
	end
end)

local element = elementCreator({text = 'foo-bar'}, 100, 20)
--Needs to be called only once, to draw and then :undraw to stop drawing it onscreen
element:draw(100, 100)
```

As you can see, you can use regular love.graphics functions inside the element's rendering function, furthermore you don't have to worry about coordinates, as x:0,y:0 inside the element's rendering function will always be the element's onscreen x,y, and the element's dimensions are passed in the view table.

Also whatever you pass to the factory here
```lua
local element = elementCreator({text = 'foo-bar'}, 100, 20)
```
is accessible in the param table like so:
```lua
local elementCreator = helium(function(param, view)
	return function()
		love.graphics.setColor(0.3, 0.3, 0.3)
		love.graphics.rectangle('fill', 0, 0, view.w, view.h)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print(param.text)
	end
end)
```

[View the resulting hello world repository here](https://github.com/qeffects/helium-demo/)

Or continue on to the advanced guide: ~~link