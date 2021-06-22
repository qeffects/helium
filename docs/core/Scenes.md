## Scenes

Scenes are a collection of elements and their associated input subscriptions, they each *can* contain a seperate caching atlas

### Atlas

The caching atlas is an important part of helium's performance optimizations, in practice it's all magick'd away and you don't really have to worry about it besides the consideration, of balancing memory use and performance, if enabled there will be 2 full screen canvases created for a scene. So to balance them out, gauge for how long the scene will be rendered for, if it's a short temporary scene then there's no point of atlassing, if it's the main HUD or something then perhaps there's a point.

### Using scenes

```lua
local testScene = scene.new(cache: boolean)
```

Will return a scene object, cache true or false will disable or enable the atlases



```lua
testScene:activate()
```

Will set this scene as active, after setting it, you can start creating the elements with factories, they will be bound to the current active scene



```lua
testScene:deactivate()
```

Will deactivate this scene



```lua
testScene:reload()
testScene:unload()
```

Unload will destroy the scene, and clear used memory by the scene
Use it together with reload to recreate the scene from new, you'll need to also re-run the element factories and such



```lua
testScene:draw()
testScene:update(dt)
testScene:resize(newW, newH)
```

Put these in the corresponding love callbacks like draw, update and resized

They'll draw, update and resize the scene, you can control the draw order, or draw multiple scenes at once too, the one set with :activate will be the one recieving input subscriptions though.