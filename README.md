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

The basic structure for an element is:

```lua
return function(param,state,view)
	--Setup zone
	return function()
		--Rendering zone
	end
end
```

[The documentation outgrew this readme, see the github wiki](https://github.com/qfluxstudio/helium/wiki/)