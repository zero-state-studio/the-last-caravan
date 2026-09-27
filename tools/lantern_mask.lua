-- Lantern of Ottavia (19): emission mask of the lantern glass and lantern
-- position for every frame of the spritesheet.
--
-- Usage:
--   "$ASEPRITE_PATH" -b \
--     --script-param sheet=<abs>/ottavia_v1_sheet.png \
--     --script-param data=<abs>/ottavia_v1_sheet.json \
--     --script-param mask=<abs>/ottavia_v1_emission.png \
--     --script tools/lantern_mask.lua
--
-- For every 64x64 cell the glass is the topmost 8-connected group of the
-- bright glass colors (the same yellows also appear lower, on buckle and
-- rope, so the color alone is not enough). Those pixels become white in the
-- mask, everything else stays transparent. The centroid of the group is
-- written into the sheet data as frames[i].lantern = { x, y }, in cell
-- pixels from the top-left corner of the cell (pixel centers at +0.5).

local GLASS_COLORS = {
  [0xFEF88F] = true, -- bright core
  [0xFCBC3C] = true,
  [0xFACC69] = true,
  [0xECC04E] = true,
  [0xED9D2B] = true,
}
local CELL = 64

local pc = app.pixelColor
local sheet_path = app.params["sheet"]
local data_path = app.params["data"]
local mask_path = app.params["mask"]
assert(sheet_path and data_path and mask_path, "missing --script-param sheet=, data= or mask=")

local sprite = app.open(sheet_path)
local flat = Image(sprite.width, sprite.height, ColorMode.RGB)
flat:drawSprite(sprite, 1)
local mask = Image(sprite.width, sprite.height, ColorMode.RGB)
local columns = sprite.width // CELL
local rows = sprite.height // CELL

local function is_glass(x, y)
  local value = flat:getPixel(x, y)
  if pc.rgbaA(value) < 128 then
    return false
  end
  local rgb = (pc.rgbaR(value) << 16) | (pc.rgbaG(value) << 8) | pc.rgbaB(value)
  return GLASS_COLORS[rgb] == true
end

-- The topmost group of glass pixels in the cell at (ox, oy), or nil.
local function find_glass(ox, oy)
  local seen = {}
  local best, best_y = nil, math.huge
  for y = 0, CELL - 1 do
    for x = 0, CELL - 1 do
      local key = y * CELL + x
      if not seen[key] and is_glass(ox + x, oy + y) then
        seen[key] = true
        local group, stack, sum_y = {}, { { x, y } }, 0
        while #stack > 0 do
          local p = table.remove(stack)
          group[#group + 1] = p
          sum_y = sum_y + p[2]
          for dy = -1, 1 do
            for dx = -1, 1 do
              local nx, ny = p[1] + dx, p[2] + dy
              local nkey = ny * CELL + nx
              if nx >= 0 and ny >= 0 and nx < CELL and ny < CELL
                  and not seen[nkey] and is_glass(ox + nx, oy + ny) then
                seen[nkey] = true
                stack[#stack + 1] = { nx, ny }
              end
            end
          end
        end
        if sum_y / #group < best_y then
          best, best_y = group, sum_y / #group
        end
      end
    end
  end
  return best
end

local points = {}
for row = 0, rows - 1 do
  for column = 0, columns - 1 do
    local ox, oy = column * CELL, row * CELL
    local glass = find_glass(ox, oy)
    assert(glass, string.format("no lantern glass in cell row %d column %d", row, column))
    local sum_x, sum_y = 0, 0
    for _, p in ipairs(glass) do
      mask:drawPixel(ox + p[1], oy + p[2], pc.rgba(255, 255, 255, 255))
      sum_x = sum_x + p[1]
      sum_y = sum_y + p[2]
    end
    local function round(v) return math.floor(v * 10 + 0.5) / 10 end
    points[#points + 1] = {
      x = round(sum_x / #glass + 0.5),
      y = round(sum_y / #glass + 0.5),
      pixels = #glass,
    }
  end
end

local out = Sprite(sprite.width, sprite.height, ColorMode.RGB)
out:newCel(out.layers[1], out.frames[1], mask, Point(0, 0))
out:saveAs(mask_path)

local file = assert(io.open(data_path, "r"))
local data = json.decode(file:read("a"))
file:close()
assert(#data.frames == #points, "frame count differs from the grid")
for index, frame in ipairs(data.frames) do
  frame.lantern = { x = points[index].x, y = points[index].y }
end
file = assert(io.open(data_path, "w"))
file:write(json.encode(data))
file:close()
print(string.format("lantern_mask: %d frames, mask %s", #points, mask_path))
