local Hub = require('hub')
local create_sender = require('sender')
local create_receiver = require('receiver')
local EventScheduler = require('event_scheduler')
local pb = require("message_pb")

local hub = Hub.new()
local scheduler = EventScheduler.new()

local messages = {}
local input_text = ""

function love.load()
    local socket_path = "/app/socket.sock"

    -- Initialize sender and receiver coroutines
    local sender = create_sender(socket_path, hub, scheduler)
    local receiver = create_receiver(socket_path, hub, scheduler)

    -- Example subscription to a topic
    hub:subscribe("example_topic", function(message)
        table.insert(messages, "Received: " .. message.content)
    end)

    -- Start the sender coroutine
    coroutine.resume(sender)

    -- Start the event scheduler in a separate thread
    love.thread.newThread(function() scheduler:run() end):start()
end

function love.update(dt)
    -- Nothing needed here; everything runs asynchronously with the scheduler
end

function love.draw()
    love.graphics.print("Pub-Sub system running with Unix socket communication", 10, 10)
    for i, message in ipairs(messages) do
        love.graphics.print(message, 10, 30 + i * 20)
    end
    love.graphics.print("Input: " .. input_text, 10, love.graphics.getHeight() - 30)
end

function love.textinput(t)
    input_text = input_text .. t
end

function love.keypressed(key)
    if key == "return" then
        local message = pb.BaseMessage()
        message.type = "publish"
        message.topic = "example_topic"
        message.content = input_text
        message.sender_id = "client"

        local serialized_message = message:SerializeToString()
        coroutine.resume(sender, serialized_message)

        input_text = ""  -- Clear input text after sending
    end
end

function love.quit()
    print("Exiting the game...")
end
