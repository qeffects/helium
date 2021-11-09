local path = string.sub(..., 1, string.len(...) - string.len(".hooks.scrollArea"))
local onSizeC = require(path..'.hooks.onSizeChange')
local state = require(path..'.hooks.state')
local context = require(path.. ".core.stack")

--Makes the container element a scroll area, outside, create 1 or 2 sliders and pass their state object here
--Once you know the size of your needed element/s set the canvasW and canvasH
return function(canvasW, canvasH, offsetX, offsetY, vSliderState, hSliderState)
    offsetX = offsetX or 0
    offsetY = offsetY or 0
	local element = context.getContext().element

    local elW, elH = element:getSize()

    local externalState = state{
        canvasW = canvasW,
        canvasH = canvasH,
        hon = false,
        von = false,
    }
    
    local size = state{
        viewW = elW + offsetX,
        viewH = elH + offsetY,
        offsetX = 0,
        offsetY = 0
    }

    hSliderState.value = 0;
    vSliderState.value = 0;

    hSliderState.callback(function (newState)
        size.offsetX = -newState.value
    end)

    vSliderState.callback(function (newState)
        size.offsetY = -newState.value
    end)

    externalState.callback(function (newState)
        vSliderState.min = 0
        vSliderState.max = newState.canvasH - size.viewH
        hSliderState.min = 0
        hSliderState.max = newState.canvasW - size.viewW

        if newState.canvasW-size.viewW < 1 then
            newState.hon = false
        else
            newState.hon = true
        end

        if newState.canvasH-size.viewH < 1 then
            newState.von = false
        else
            newState.von = true
        end
    end)

    size.callback(function (newSize)
        vSliderState.min = 0
        vSliderState.max = externalState.canvasH - newSize.viewH
        hSliderState.min = 0
        hSliderState.max = externalState.canvasW - newSize.viewW

        if externalState.canvasW-size.viewW < 1 then
            externalState.hon = false
        else
            externalState.hon = true
        end

        if externalState.canvasH-size.viewH < 1 then
            externalState.von = false
        else
            externalState.von = true
        end
    end)

    if externalState.canvasW-size.viewW < 1 then
        externalState.hon = false
    else
        externalState.hon = true
    end

    if externalState.canvasH-size.viewH < 1 then
        externalState.von = false
    else
        externalState.von = true
    end

    onSizeC(function (w, h)
            size.viewW = w + offsetX
            size.viewH = h + offsetY
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