local socket = require("socket")
local ws_server = require("websocket").server
local pb = require("message_pb")
local Hub = require('hub')
local EventScheduler = require('event_scheduler')

local hub = Hub.new()
local scheduler = EventScheduler.new()
local clients = {}

local function on_client_connect(client)
    print("New client connected: ", client)
    clients[client] = true

    hub:subscribe("example_topic", function(message)
        local serialized_message = message:SerializeToString()
        client:send(serialized_message)  -- Send the message to the client
    end)
end

local function on_message(client, message)
    local parsed_message = pb.BaseMessage()
    parsed_message:ParseFromString(message)

    print("Received message on topic: " .. parsed_message.topic)
    print("Message content: " .. parsed_message.content)

    if parsed_message.topic == "example_topic" then
        hub:publish(parsed_message.topic, parsed_message)  -- Publish to subscribers
    end
end

function love.load()
    local server = ws_server.new({
        port = 8080,
        on_open = on_client_connect,
        on_message = on_message,
        on_close = function(client) clients[client] = nil end
    })

    love.thread.newThread(function() scheduler:run() end):start()
end

function love.update(dt)
    ws_server.update()
end

function love.draw()
    love.graphics.print("Server running. Clients connected: " .. tostring(#clients), 10, 10)
end
