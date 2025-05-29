local ShuffleBag = {}
ShuffleBag.__index = ShuffleBag

-- Constructor: accepts a source table to draw from
function ShuffleBag.new(source)
    local bag = {
        source = source,
        items = {},
        index = 1
    }
    setmetatable(bag, ShuffleBag)
    bag:reshuffle()
    return bag
end

-- Fisher-Yates shuffle
function ShuffleBag:reshuffle()
    self.items = {}
    for _, item in ipairs(self.source) do
        table.insert(self.items, item)
    end
    for i = #self.items, 2, -1 do
        local j = math.random(i)
        self.items[i], self.items[j] = self.items[j], self.items[i]
    end
    self.index = 1
end

-- Get the next item, and reshuffle when exhausted
function ShuffleBag:next()
    local item = self.items[self.index]
    self.index = self.index + 1
    if self.index > #self.items then
        self:reshuffle()
    end
    return item
end

return ShuffleBag
