## Element

The element is helium's basic building block, in practice it consists of 2 nested functions, the basic pattern looks like this


```lua
element = function()
	return function()

	end
end
```

So, what's what?

Well this outer part is what i call the loader function, it runs once per created element

```lua
element = function()

end
```

It's where you'll set up variables for later, callbacks and state

```lua
element = function()
	local x = 'blah'
end
```

Of course, the variables in this first function become attached to the 'closure'

```lua
element = function()
	local x = 'blah'
	return function()
		--so you can use X in here
		print(x)
	end
end
```

So now we have a function, but this isn't an element yet, to create an element you need to import helium and call the function with helium

```lua
local helium = require('helium')

local elementFactory = helium(function()
	return function()

	end
end)
```

This returns a new 'factory', that is a function that will create a new element when called:

```lua
	local element = elementFactory(params, width, height, flags)
```

Param is an arbitrary table that you can pass in for the element to use, width and height are the 'minimum' dimensions of the new element and flags is an arbitrary table of flags, currently only used in layout.

Now that we've learned about params, the first function gets passed them and another table:

```lua
element = function(param, view)
	return function()

	end
end
```

The first parameter is what got passed to the factory, view table looks like : {x, y, w, h} and it contains the size and coordinates of the element.

so: 

```lua
local elementFactory = helium(function(param, view)
	print(param.x)
	return function()

	end
end)

elementFactory({x = 10}, 10, 10)
```

### Methods

The element has a few methods meant for user interaction, these are:

`Element:draw(x, y, w, h)`

Use this to draw something onscreen, you can also call this every frame if it's something that moves with your game objects     
This checks equality to the current viewport so it'll only get re-rendered if something actually changes, furthermore translations don't cause re-renders.

This method performs slightly differently inside an element and outside

Outside it inserts the element in to the buffer if it isn't already there, and will render at the scene:draw()

Inside it renders immediately, so you can put it inbetween other graphics operations.

---

`Element:destroy()`

Use destroy to completely and irreversibly remove this element from the scene

---

`Element:undraw()`

Use undraw to hide this element for now with the intention of re-drawing it sometime later, to do that just :draw() it again

---

`Element:setParam(newParam)`

Use setParam to pass new parameters to this element


### Nested/Child Elements

Within helium you can use nested/child elements without any special provisions, everything will work just like if it was outside    
(Only difference is that inside :draw will be immediate, and also you should create the element in the element you intend to draw it in)

```lua
local childElementFactory = helium(function(param, view)
	return function()
		love.graphics.rectangle('fill', 0, 0, view.w, view.h)
	end
end)

local elementFactory = helium(function(param, view)
    local child = childElementFactory({x = 10}, 20, 20)

	return function()
		child:draw(100, 100)
	end
end)
```

