local path = string.sub(..., 1, string.len(...) - string.len(".hooks.scrollArea"))
local onSizeC = require(path..'.hooks.onSizeChange')
local state = require(path..'.hooks.state')
local context = require(path.. ".core.stack")

--Makes the container element a scroll area, outside, create 1 or 2 sliders and pass their state object here
--Once you know the size of your needed element/s set the canvasW and canvasH
return function(canvasW, canvasH, vSliderState, hSliderState)
	local element = context.getContext().element

    local elW, elH = element:getSize()

    local externalState = state{
        canvasW = canvasW,
        canvasH = canvasH,
    }
    
    local size = state{
        viewW = elW,
        viewH = elH,
        offsetX = 0,
        offsetY = 0
    }

    hSliderState.callback(function (newState)
        size.offsetY = -newState.value
    end)

    hSliderState.callback(function (newState)
        size.offsetX = -newState.value
    end)

    externalState.callback(function (newState)
        vSliderState.min = 0
        vSliderState.max = newState.canvasH - size.viewH
        hSliderState.min = 0
        hSliderState.max = newState.canvasW - size.viewW
    end)

    size.callback(function (newSize)
        vSliderState.min = 0
        vSliderState.max = externalState.canvasH - newSize.viewH
        hSliderState.min = 0
        hSliderState.max = externalState.canvasW - newSize.viewW
    end)

    onSizeC(function (w, h)
            size.viewW = w
            size.viewH = h
        end)
    
    return {
        scroll = externalState,
        push = function ()
            love.graphics.push()
            love.graphics.translate(size.offsetX, size.offsetY)
        end,
        pop = function ()
            love.graphics.pop()
        end
    }
end