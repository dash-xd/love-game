local Hub = {}
Hub.__index = Hub

function Hub.new()
    local self = setmetatable({}, Hub)
    self.subscribers = {}  -- Stores subscribers for each topic
    return self
end

-- Subscribe a callback to a topic
function Hub:subscribe(topic, callback)
    if not self.subscribers[topic] then
        self.subscribers[topic] = {}
    end
    table.insert(self.subscribers[topic], callback)
end

-- Publish a message to all subscribers of a topic
function Hub:publish(topic, message)
    local subs = self.subscribers[topic]
    if subs then
        for _, callback in ipairs(subs) do
            callback(message)
        end
    end
end

return Hub
