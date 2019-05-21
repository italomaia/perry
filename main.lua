-- each of these keys create a new stream
local R_KEYS = {
  kp0 = true,
  kp1 = true,
  kp2 = true,
  kp3 = true,
  kp4 = true,
  kp5 = true,
  kp6 = true,
  kp7 = true,
  kp8 = true,
  kp9 = true,
}

local ARROW_KEYS = {
  up = true,
  down = true,
  left = true,
  right = true,
}

local ARROW_V_KEYS = {
  up = -1,
  down = 1,
}

local ARROW_H_KEYS = {
  left = -1,
  right = 1,
}

-- colors
local GREEN = {0, 1, 0}
local WHITE = {1, 1, 1}

-- some constants
local w_width = 800
local w_height = 600
local font_size = 12
local font_file = 'fonts/courier_prime.ttf'  -- monospaced for simplicity
local font = love.graphics.newFont(font_file, font_size) -- the number denotes the font size

-- some non constants
local recording_device_array = nil
local recording_device = nil
local recording_device_index = 1
local recording_device_name = nil

local stream_index = 1
local streams = {}
local stream_key = nil
local stream_key_array = {}

for k, _ in pairs(R_KEYS) do
  table.insert(stream_key_array, k)
end

table.sort(stream_key_array)

function love.load()
  love.window.setMode(w_width, w_height, {resizable=false})

  recording_device_array = love.audio.getRecordingDevices()
  recording_device = recording_device_array[recording_device_index]
  recording_device_name = recording_device:getName()

  love.graphics.setFont(font)
end

function love.keypressed (key, scancode, isrepeat)
  if R_KEYS[key] then
    if streams[key] then
      love.audio.stop(streams[key])
      print("stopped stream " .. key)
    end

    stream_key = key
    recording_device:start()
    print("started recording stream " .. key)

  elseif ARROW_V_KEYS[key] then
    recording_device_index = recording_device_index + ARROW_V_KEYS[key]
    recording_device_index = math.min(math.max(recording_device_index, 1), #recording_device_array)
    recording_device = recording_device_array[recording_device_index]
    recording_device_name = recording_device:getName()
  elseif ARROW_H_KEYS[key] then
    stream_index = stream_index + ARROW_H_KEYS[key]
    stream_index = math.min(math.max(stream_index, 1), #stream_key_array)
  end
end

function love.keyreleased (key, scancode)
  if key == stream_key and recording_device:isRecording() then
    local sound_data = recording_device:stop()
    local sound_source = love.audio.newSource(sound_data)

    sound_source:setLooping(true)

    streams[stream_key] = sound_source
    print("finished recording stream " .. stream_key)

    love.audio.play(streams[stream_key])
    print("started playing stream " .. stream_key)
  end

  stream_key = nil
end

function draw_recording_device_array (x, y)
  love.graphics.setColor(unpack(WHITE))

  for index, device in pairs(recording_device_array) do
    local pick_str = (index == recording_device_index) and '*' or ' '
    local text = string.format("[%s] %s", pick_str, device:getName())
    local text_y = y + font_size * (index - 1)

    love.graphics.print(text, x, text_y)
  end
end

function draw_channel (index, key, x, y)
  local text_i = index - 1
  local text_x = x + index * font_size * 4
  local text_y = y + font_size
  local base_color = stream_index == index and GREEN or WHITE

  love.graphics.setColor(unpack(base_color))

  love.graphics.print(key, text_x + font_size / 2, y)
  love.graphics.print("[", text_x, text_y)

  if streams[key] then
    love.graphics.print("*", text_x + font_size * 1, text_y)
  end

  love.graphics.print("]", text_x + font_size * 2, text_y)
end

function draw_channel_array (x, y)
  local index = 0

  for _, key in pairs(stream_key_array) do
    index = index + 1
    draw_channel(index, key, x, y)
  end
end

function love.draw()
  draw_channel_array(0, 0)
  draw_recording_device_array(0, w_height - (#recording_device_array * font_size) )
end
