# Helium
 ## user facing functions
 ```lua
Element(function,reloader,w,h,parameters) --Creates a new element
    :draw(x,y) --Renders the element at a location
    :undraw() --Removes the element from the render buffer

--The intended loader for element files (supports optional live hotswapping)
HeliumLoader(filepath) -> ElementFactory
ElementFactory(w,h,parameters) -> Element

Input
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
        Basic events:
         "mousepressed" --Gets called whenever the subscribed area gets pressed
         "mousereleased" --Gets called whenever mouse is released in the subscription area
         "mousepressed_outside" --This type gets called when mouse is pressed outside the subscription area
         "mousereleased_outside" --This type gets called when mouse is released outside the sub area
         "keypressed" --Basic keyboard input
```

## Basic overview:
Helium is practically more like a UI framework than a fully fledged UI library. 
The idea is to build custom, build simple and build fast, encapsulate.

## Getting started:
Load helium with helium = require 'helium'
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
local buttonFactory = HeliumLoader('helloWorld.lua')
local button = buttonFactory({}, 200, 100)
button:draw(10,10)
```
![alt text](https://i.imgur.com/polli7q.jpg "Before")
![alt text](https://i.imgur.com/VGql2He.jpg "After")
	
	

Now theres a lot to explain, but its fairly simple, so lets take it by chunks
```lua
local input = require "helium.core.input" 
```
Here we import the input module of Helium, so that we can later subscribe to an event

---
```lua
state.pressed = false
```
Here we create a state field called pressed, think of state as a helium elements self 
It works like a regular table, with the caveat that you shouldnt overwrite it directly like state = {}

---
```lua	
local callback = function() state.pressed = true end
```
Then we overwrite that state.pressed inside a callback which will be called every time our button is pressed

---
```lua
input.subscribe(0,0,view.w,view.h,'clicked',callback)
```
This is creating an input subscription for the event of your choice

---
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
Is the rendering code, it works more or less like a mini window of a love.draw()

### Additional details: 
**view** is a table that holds the information about the position and size of an element
x, y, w, h
Setting this from inside the element works as expected(so you can dynamically resize and reposition the element from inside)

param is the table that you pass in buttonFactory({}, 200, 100), it can be anything you need

there's a configuration table inside of helium, which has a couple of default settings
if autorun is off then you NEED to place helium.update(dt), helium.render() somewhere

and if you need input, hook it up to the eventHandlers in your own love.run:
```lua
if not(helium.input.eventHandlers[name]) or not(helium.input.eventHandlers[name](a, b, c, d, e, f)) then
	love.handlers[name](a, b, c, d, e, f)
end
```
