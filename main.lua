-- main.lua
-- Photoshop-style HSV Color Picker for LÖVE

local sv = { x = 30, y = 40, w = 220, h = 220 }
local hue = { x = 270, y = 40, w = 20, h = 220 }
local rgbInput = {
    x = 30,
    y = 270,
    w = 250,
    h = 24,
    active = false,
    text = ""
}


local color = { h = 0.0, s = 1.0, v = 1.0, a = 1.0 }
local copyBtn = { x = 310, y = 100, w = 50, h = 50, hovered = false }
local svCanvas
local hueCanvas
local draggingSV = false
local draggingHue = false

local function clamp(v, min, max)
    return math.max(min, math.min(max, v))
end
local function rgb_to_hsv(r, g, b)
    local max = math.max(r, g, b)
    local min = math.min(r, g, b)
    local delta = max - min

    local h, s, v
    v = max

    if max == 0 then
        s = 0
    else
        s = delta / max
    end

    if delta == 0 then
        h = 0
    elseif max == r then
        h = ((g - b) / delta) % 6
    elseif max == g then
        h = ((b - r) / delta) + 2
    else
        h = ((r - g) / delta) + 4
    end

    h = h / 6
    if h < 0 then h = h + 1 end

    return h, s, v
end

local function hsv_to_rgb(h, s, v)
    local r, g, b

    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    i = i % 6

    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q end

    return r, g, b
end

-- Canvas generation
local function generateHueCanvas()
    hueCanvas = love.graphics.newCanvas(hue.w, hue.h)
    love.graphics.setCanvas(hueCanvas)

    for y = 0, hue.h - 1 do
        local h = y / (hue.h - 1)
        local r, g, b = hsv_to_rgb(h, 1, 1)
        love.graphics.setColor(r, g, b)
        love.graphics.rectangle("fill", 0, y, hue.w, 1)
    end

    love.graphics.setCanvas()
end

local function generateSVCanvas()
    svCanvas = love.graphics.newCanvas(sv.w, sv.h)
    love.graphics.setCanvas(svCanvas)

    for y = 0, sv.h - 1 do
        for x = 0, sv.w - 1 do
            local s = x / (sv.w - 1)
            local v = 1 - (y / (sv.h - 1))
            local r, g, b = hsv_to_rgb(color.h, s, v)
            love.graphics.setColor(r, g, b)
            love.graphics.points(x, y)
        end
    end

    love.graphics.setCanvas()
end
function love.load()
    love.window.setTitle("HSV Color Picker (Normalized)")
    love.window.setMode(380, 340, { resizable = false })
    generateHueCanvas()
    generateSVCanvas()
end

function love.update(dt)
    local mx, my = love.mouse.getPosition()
    copyBtn.hovered =
        mx >= copyBtn.x and mx <= copyBtn.x + copyBtn.w and
        my >= copyBtn.y and my <= copyBtn.y + copyBtn.h
    if draggingSV and not rgbInput.active then
        color.s = clamp((mx - sv.x) / sv.w, 0, 1)
        color.v = clamp(1 - (my - sv.y) / sv.h, 0, 1)
    end

    if draggingHue then
        color.h = clamp((my - hue.y) / hue.h, 0, 1)
        generateSVCanvas()
    end
end

function love.draw()
    love.graphics.clear(0.1, 0.1, 0.1)

    -- Panels
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle("fill", 20, 30, 280, 260, 10, 10)

    -- SV square
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(svCanvas, sv.x, sv.y)
    love.graphics.rectangle("line", sv.x, sv.y, sv.w, sv.h)

    -- Hue bar
    love.graphics.draw(hueCanvas, hue.x, hue.y)
    love.graphics.rectangle("line", hue.x, hue.y, hue.w, hue.h)

    -- SV selector
    local sx = sv.x + color.s * sv.w
    local sy = sv.y + (1 - color.v) * sv.h
    love.graphics.circle("line", sx, sy, 6)
    love.graphics.circle("line", sx, sy, 7)

    -- Hue selector
    local hy = hue.y + color.h * hue.h
    love.graphics.rectangle("line", hue.x - 2, hy - 2, hue.w + 4, 4)

    -- Preview
    local r, g, b = hsv_to_rgb(color.h, color.s, color.v)
    love.graphics.setColor(r, g, b, color.a)
    love.graphics.rectangle("fill", 310, 40, 50, 50, 6, 6)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 310, 40, 50, 50, 6, 6)

    -- Copy button 
    if copyBtn.hovered then
        love.graphics.setColor(0.45, 0.45, 0.45)
    else
        love.graphics.setColor(0.35, 0.35, 0.35)
    end

    love.graphics.rectangle(
        "fill",
        copyBtn.x, copyBtn.y,
        copyBtn.w, copyBtn.h,
        6, 6
    )

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle(
        "line",
        copyBtn.x, copyBtn.y,
        copyBtn.w, copyBtn.h,
        6, 6
    )

    love.graphics.printf(
        copyBtn.hovered and "Copy :)" or "Copy",
        copyBtn.x,
        copyBtn.y + copyBtn.h / 2 - 6,
        copyBtn.w,
        "center"
    )
    -- Value input field
    love.graphics.setColor(rgbInput.active and 0.2 or 0.15, 0.15, 0.15)
        love.graphics.rectangle(
        "fill",
        rgbInput.x, rgbInput.y,
        rgbInput.w, rgbInput.h,
        4, 4
    )

    love.graphics.setColor(1,1,1)
    love.graphics.rectangle(
        "line",
        rgbInput.x, rgbInput.y,
        rgbInput.w, rgbInput.h,
        4, 4
    )
    --[
        -- local r, g, b = hsv_to_rgb(color.h, color.s, color.v)
        local txt = string.format(
            "( %.3f, %.3f, %.3f, %.3f )",
            r, g, b, color.a
        )
    --]
    
    local displayText = rgbInput.active and rgbInput.text or
        string.format("( %.3f, %.3f, %.3f, %.3f )", r, g, b, color.a)
        
    love.graphics.printf(
        displayText,
        rgbInput.x,
        rgbInput.y + 5,
        rgbInput.w,
        "center"
    )

    love.graphics.setColor(0.7,0.7,0.7)
    -- love.graphics.print("V", rgbInput.x - 14, rgbInput.y + 4)
    love.graphics.print("RGB", rgbInput.x - 30, rgbInput.y + 4)

    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", 30, 300, 330, 30, 6, 6)

    love.graphics.setColor(1, 1, 1)
end

function love.textinput(t)
    if not rgbInput.active then return end

    if t:match("[%d%.]") then
        rgbInput.text = rgbInput.text .. t
    end
end

function love.mousepressed(x, y)
    -- Activate Value input
    if x >= rgbInput.x and x <= rgbInput.x + rgbInput.w
    and y >= rgbInput.y and y <= rgbInput.y + rgbInput.h then
        local r, g, b = hsv_to_rgb(color.h, color.s, color.v)
        rgbInput.active = true
        rgbInput.text = string.format("%.3f, %.3f, %.3f, %.3f", r, g, b, color.a)
        return
    else
        rgbInput.active = false
    end


    if x >= copyBtn.x and x <= copyBtn.x + copyBtn.w
        and y >= copyBtn.y and y <= copyBtn.y + copyBtn.h then
        local r, g, b = hsv_to_rgb(color.h, color.s, color.v)
        local txt = string.format(
            "( %.3f, %.3f, %.3f, %.3f )",
            r, g, b, color.a
        )
        love.system.setClipboardText(txt)
        return
    end

    if x >= sv.x and x <= sv.x + sv.w
        and y >= sv.y and y <= sv.y + sv.h then
        draggingSV = true
    end

    if x >= hue.x and x <= hue.x + hue.w
        and y >= hue.y and y <= hue.y + hue.h then
        draggingHue = true
    end
end

function love.mousereleased()
    draggingSV = false
    draggingHue = false
end
function love.keypressed(key)
    if rgbInput.active then
        if key == "return" then
            local v = tonumber(rgbInput.text)
            if v then
                color.v = clamp(v, 0, 1)
            end
            rgbInput.active = false
            return

        elseif key == "escape" then
            rgbInput.active = false
            return

        elseif key == "backspace" then
            rgbInput.text = rgbInput.text:sub(1, -2)
            return
        end
    end
end

