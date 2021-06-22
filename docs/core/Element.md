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
