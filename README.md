![alt text](https://i.imgur.com/ZQBQfsa.png "Helium")
# Helium
 ## Major features:
 ### Custom elements
 Write your own elements, and interface with them however you want to,
 Whether you need a generalized button that can have many themes and options or something super specific, it can be done
 ### Efficient rendering & updating
 The elements only update&re-render when state changes
 ### Code hotswap
 Change and save a file loaded through the helium.loader, and see changes immediately

## Basic overview:
Helium is practically more like a UI framework than a fully fledged UI library. 
The idea is to build custom, build simple and build fast, encapsulate.

## Demo's / Practical examples
[There's a repository of examples here](https://github.com/qfluxstudio/helium_demos)

## Getting started:
Load helium with `local helium = require 'helium'`
Create a new file for your awesome element, say 'helloWorld.lua'

The basic structure for an element file is:

```lua
return function(param,state,view)
	--Setup zone
	return function()
		--Rendering zone
	end
end
```

That's it, it's now a correct helium element

So lets make a simple button!

In helloWorld.lua:
```lua
local input = require "helium.core.input" 

return function(param,state,view)
	--Press state
	state.pressed = false
	--The callback for the input subscription
	local callback = function() state.pressed = true end
	--The actual input subscription 
	input.subscribe(0,0,view.w,view.h,'clicked',callback)
		
	return function()
		if state.pressed then
			love.graphics.setColor(0.3,0.3,0.9)
		else
			love.graphics.setColor(0.3,0.3,0.5)
		end
		love.graphics.rectangle('fill', 0, 0, view.w, view.h)
		love.graphics.setColor(1,1,1)
		love.graphics.printf("Pressed? "..tostring(state.pressed),0,view.h/2-5,view.w,'center')
	end
end
```
And in main.lua:
```lua
local helium = require('helium')
local buttonFactory = helium.loader('helloWorld.lua')
local button = buttonFactory({}, 200, 100)
button:draw(10,10)
```
![alt text](https://i.imgur.com/polli7q.jpg "Before")
![alt text](https://i.imgur.com/VGql2He.jpg "After")
	
	

Now theres a lot to explain, but its fairly simple, so lets take it by chunks
Here we import the input module of Helium, so that we can later subscribe to an event:
```lua
local input = require "helium.core.input" 
```

---
Here we create a state field called pressed, think of state as a helium elements self 
It works like a regular table, with the caveat that you shouldnt overwrite it directly like state = {}
```lua
state.pressed = false
```

---
Then we overwrite that state.pressed inside a callback which will be called every time our button is pressed
```lua	
local callback = function() state.pressed = true end
```

---
This is creating an input subscription for the event of your choice
```lua
input.subscribe(0,0,view.w,view.h,'clicked',callback)
```

---
Is the rendering code, it works more or less like a mini window of a love.draw()
```lua
return function()
	if state.pressed then
		love.graphics.setColor(0.3,0.3,0.9)
	else
		love.graphics.setColor(0.3,0.3,0.5)
	end
	love.graphics.rectangle('fill', 0, 0, view.w, view.h)
	love.graphics.setColor(1,1,1)
	love.graphics.printf("Pressed? "..tostring(state.pressed),0,view.h/2-5,view.w,'center')
end
```

## Additional details: 
**view** is a table that holds the information about the position and size of an element
x, y, w, h
Setting this from inside the element works as expected(so you can dynamically resize and reposition the element from inside)

param is the table that you pass in buttonFactory({}, 200, 100), it can be anything you need

there's a configuration file (conf.lua) inside of helium, which has a couple of default settings
AUTO_RUN if true will give you a basic 11.3 version love.run with helium stuff added, if autorun is off then you NEED to place helium.update(dt), helium.render() somewhere

and if you need input, hook it up to the eventHandlers in your own love.run:
```lua
if not(helium.input.eventHandlers[name]) or not(helium.input.eventHandlers[name](a, b, c, d, e, f)) then
	love.handlers[name](a, b, c, d, e, f)
end
```
## Elements in depth
An element is the building block of helium, you create it by using the loader available in helium/loader.lua or setting the `PURE_G=false` in helium/conf.lua to have HeliumLoader available globally, and passing in a file path to your UI element.

The internals are a very open field, you need to have a function that returns a function:
```lua
return function(param,state,view)
	return function()

	end
end
```

The outer function will be ran exactly once, so think of this as a 'load'/ 'init' phase, the inner function will be ran whenever state or param change, and is regarded as the 'rendering' phase

Element nesting works perfectly, updates get bubbled from children elements, position is relative to the parent's position and to boot, it'll all end up drawn on one canvas, cutting back on drawcalls


### Outside
The elements aren't just sandboxed inside, there are a few user access intended fields, like Element.parameters, Element.state, Element.view, they are exactly the thing the internal functions get, so change or use them freely.
(e.g. setting some state from outside, or swapping parameters or getting a buttons status)

to summarize:
```lua
Element
   	:draw(x,y) --Renders the element at a location
	:undraw() --Removes the element from the render buffer
	.state = {} --The current element state, accessible from outside
	.parameters = {} --The current parameters, accessible from outside
	.view = {x=0,y=0,w=0,h=0,locked=false}--The current view state, locked should be set by an element internally, if it's going to change the view table.
```

## Input in depth
Input is the main intended way of using/catching user input, it's all callback based, there are 2 types of input subscriptions: Basic, Advanced


**the basic events**, named after the ones in love, will pass in the same arguments as the love event handlers will, these are one-off events, that simply execute the callback if it falls within the subscription area.

**the advanced events**, are essentially an abstraction layer, to make dragging and clicking and hovering simpler, they all have an optional callback within a callback convention like this

```lua
function(x,y)
	doSomething()
	return function(x,y)
		doSomethingElse()
	end
end
```

so you could subscribe to the 'clicked' event, change `state.clicked` to true, and in the second function change it back to false

the input structure:
```lua
helium.input
    .subscribe(x, y, w, h, subType, callback, startOn)
        subType -- Subscription type
        callback -- Subscription callback on event
        startOn -- a bool to disable a subscription by default
    -> Subscription
        :on() --Turns an inactive subscription on
        :off() --Turns an active subscription off
        
    subType:
        Advanced:
         "clicked" (x,y,btn)--Gets called whenever the subscribed area is pressed, with an optional return callback
		 "dragged" (x,y,deltaX,deltaY)--Gets called whenever the subscribed area is dragged, with an optional 'finish' callback
		 "hover" ()--Gets called whenever a mouse enters the element
        Basic events:
         "mousepressed" (x,y,btn)--Gets called whenever the subscribed area gets pressed
         "mousereleased" (x,y,btn)--Gets called whenever mouse is released in the subscription area
         "mousepressed_outside" (x,y,btn)--This type gets called when mouse is pressed outside the subscription area
         "mousereleased_outside" (x,y,btn)--This type gets called when mouse is released outside the sub area
         "keypressed" (key)--Basic keyboard input
```

## All the user intended interfaces, classes and methods

 ## User facing functions
 ```lua
helium.element(function,reloader,w,h,parameters) 
	->Element --Creates a new element
    	:draw(x,y) --Renders the element at a location
		:undraw() --Removes the element from the render buffer
		.state = {} --The current element state, accessible from outside
		.parameters = {} --The current parameters, accessible from outside
		.view = {x=0,y=0,w=0,h=0,locked=false}--The current view state, locked should be set by an element internally, if it's going to change the view table.

--The intended global loader for element files (supports optional live hotswapping)
HeliumLoader(filepath) -> ElementFactory
ElementFactory(parameters,w,h) -> Element

helium.input
    .subscribe(x, y, w, h, subType, callback, startOn)
        subType -- Subscription type
        callback -- Subscription callback on event
        startOn -- a bool to disable a subscription by default
    -> Subscription
        :on() --Turns an inactive subscription on
        :off() --Turns an active subscription off
        
    subType:
        Advanced:
         "clicked" --Gets called whenever the subscribed area is pressed, with an optional return callback
		 "dragged" --Gets called whenever the subscribed area is dragged, with an optional 'finish' callback
		 "hover" --Gets called whenever a mouse enters the element
        Basic events:
         "mousepressed" --Gets called whenever the subscribed area gets pressed
         "mousereleased" --Gets called whenever mouse is released in the subscription area
         "mousepressed_outside" --This type gets called when mouse is pressed outside the subscription area
         "mousereleased_outside" --This type gets called when mouse is released outside the sub area
         "keypressed" --Basic keyboard input
```