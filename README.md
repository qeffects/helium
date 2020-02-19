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
```lua
local input = require "helium.core.input" 

local button = function(param,state,view)
	--Press state
	state.pressed = false
	--The callback for the input subscription
	local callback = function() state.pressed = true end
	--The actual input subscription 
	input('clicked', callback)
		
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

local helium = require('helium')
local buttonFactory = helium(button)
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
This is the new shorthand subscription model, where you only need to specify type and callback, for it to cover the whole element
```lua
input('clicked',callback)
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


`view = {`


fairly self explanatory:


`x=1, y=1, w=1, h=1`


Locks the element being moved from the outside with :draw(x,y)


`lock,`


An additonal callback, called whenever element is resized or repositioned


`onChange}`

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

**state.onUpdate, state.onDestroy, state.onFirstDraw**
are optional callbacks you can supply and will be called at the appropriate time for the element's lifecycle

**onUpdate** called when state changes

**onDestroy** called just before the element is about to be :undraw()

**onFirstDraw** called just before the first render


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
The Input module is the main intended way of using/catching user input, it's all callback based, there are 2 types of input subscriptions: Basic, Advanced


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


**Relative vs absolute sizing**
When you subscribe to an element, you can chose how the subscription is sized,
`x,y,w,h` all support this format of 0-1 = 0-100%, and 1-inf = 1px - infpx
Now, where this might matter is in dynamically sized elements, say a window

My reccomendation from experience:
Stick to relative sizing for the subscriptions inside elements, and encapsulate all 
subscriptions inside independent elements (so say you have a window, encapsulate the taskbar, close buttons etc)

**Windowing**
`helium.input.newWindow(x,y,w,h)`
Say you need multiple layers of inputs in your UI, use this command to create a 'backdrop' for your modal element
x,y work the same as subscriptions
One thing to be careful about is, that as long as this element exists, it will block that region of screen from inputs,
So use **state.onFirstDraw** and **state.onDestroy**


## All the user intended interfaces, classes and methods
### Classes
#### Element
```lua
    :draw(x,y) --Renders the element at a location
	:undraw() --Removes the element from the render buffer
	.state = {} --The current element state, accessible from outside
	.parameters = {} --The current parameters, accessible from outside
	.view = {x=0,y=0,w=0,h=0,locked=false}--The current view state, locked should be set by an element internally, if it's going to change the view table.
```

#### Subscription
```lua
	:on() --Turns an inactive subscription on
	:off() --Turns an active subscription off
```

#### Misc
```lua
ElementFactory(param, w, h) -> Element--Available either by calling helium directly or through HeliumLoader
helium.element.newProxy({}) --Creates a new proxy table, that's tracked by the current element (changes inside will trigger a rerender)
HeliumLoader(filepath) -> ElementFactory--Global
```

#### User endpoints
```lua
helium(function)->ElementFactory --Calling the library directly with a function will create a new factory

helium.input(subType,callback,starton,x,y,w,h) -- The new, preffered way of creating a subscription, if no x,y,w,h provided will cover whole element

helium.input.newWindow(x, y, w, h) --Creates an input block (nothing behind will be triggered)

helium.input.subscribe(x, y, w, h, subType, callback, startOn) --Old input method
        subType -- Subscription type
        callback -- Subscription callback on event
        startOn -- a bool to disable a subscription by default
```

#### Subscription Types: 
```lua
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