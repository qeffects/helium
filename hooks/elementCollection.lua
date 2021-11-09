--Manages collections of children elements

local collection = {}
collection.__index = collection

--can pass a whole table of children just here
--must have a structure like:
--{HeliumElement,HeliumElement,HeliumElement}
function collection.new(ct)
    local self = {
        setArray = {},
        instanceMap = {},
        nameMap = {},
    }

    if ct then
        for i, s in ipairs(ct) do
            self.setArray[#self.setArray+1] = s.element
            self.instanceMap[s.element] = s.element
            if s.element.id then
                self.nameMap[s.element.id] = s.element
            end
        end
    end

    return setmetatable(self, collection)
end

function collection:add(element, numIndex)
    numIndex = numIndex or #self.setArray+1

    if element.id then
        self.nameMap[element.id] = element
    end

    table.insert(self.setArray, numIndex, element)
end

--either numerical or id or element reference
function collection:remove(index)
    local el, numInd, strInd
    if type(index) == "string" then
        el = self.nameMap[index]
        numInd = self:find(el)
        strInd = index
    elseif type(index) == "number" then
        el = self.setArray[index]
        numInd = index
        strInd = el.id
    elseif type(index) == "table" and index.typeName and index.typeName == "HeliumElement" then
        el = index
        numInd = self:find(index)
        strInd = el.id
    else
        error("Can't index with this variable type", -1)
    end
    if self.nameMap[strInd] then
        self.nameMap[strInd] = nil
    end
    self.instanceMap[el] = nil
    table.remove(self.setArray, numInd)
    el:destroy()
end

function collection:find(el)
    for index, value in ipairs(self.setArray) do
        if value == el then
            return index
        end
    end
    error("element not in collection", -2)
end

--either name or element reference, returns numerical index
function collection:getIndex(index)
    if type(index) == "table" and index.typeName and index.typeName == "HeliumElement" then
        return self:find(index)
    elseif type(index) == "string" then
        return self:find(self.nameMap[index])
    end
end

function collection:pop()
    if #self.setArray > 0 then
        self:remove(#self.setArray)
    end
end

function collection:removeAll()
    for i, e in ipairs(self.setArray) do
        e:destroy()
    end
    self.setArray = {}
    self.nameMap = {}
    self.instanceMap = {}
end

function collection:draw()
    for i, e in ipairs(self.setArray) do
        e:draw()
    end
end

return collection