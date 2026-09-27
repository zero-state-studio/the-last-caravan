-- Build Ottavia v1 .aseprite file and spritesheet from checked frames.
-- Usage:
--   "$ASEPRITE_PATH" -b --script-param root=<project root> --script tools/ottavia_v1_aseprite.lua
-- One tag per animation and direction (idle_s, walk_se, ...), frame durations preset.

local root = app.params["root"]
local clean = root .. "/source-assets/pixellab/2026-09-27-ottavia-v1-anim/clean"
local out = root .. "/assets/sprites/ottavia"

local ANIMS = { "idle", "walk" }
local DIRS = { "s", "se", "e", "ne", "n", "nw", "w", "sw" }
local FRAME_MS = { idle = 160, walk = 100 }
local SIZE = 64

local function frame_files(anim, dir)
  local files = {}
  for i = 0, 63 do
    local path = string.format("%s/%s/%s/%02d.png", clean, anim, dir, i)
    if not app.fs.isFile(path) then break end
    files[#files + 1] = path
  end
  return files
end

local spr = Sprite(SIZE, SIZE, ColorMode.RGB)
spr.layers[1].name = "ottavia"
local layer = spr.layers[1]
local index = 0
-- Tags are created after all frames: a tag ending on the last frame grows when frames are appended.
local ranges = {}

for _, anim in ipairs(ANIMS) do
  for _, dir in ipairs(DIRS) do
    local files = frame_files(anim, dir)
    assert(#files > 0, "missing frames for " .. anim .. "_" .. dir)
    local first = index + 1
    for _, path in ipairs(files) do
      index = index + 1
      local frame
      if index == 1 then
        frame = spr.frames[1]
      else
        frame = spr:newEmptyFrame(index)
      end
      frame.duration = FRAME_MS[anim] / 1000.0
      local img = Image { fromFile = path }
      spr:newCel(layer, frame, img, Point(0, 0))
    end
    ranges[#ranges + 1] = { name = anim .. "_" .. dir, from = first, to = index }
  end
end

for _, r in ipairs(ranges) do
  local tag = spr:newTag(r.from, r.to)
  tag.name = r.name
  tag.aniDir = AniDir.FORWARD
end

-- Palette: collect every colour used by the frames and make it the sprite palette.
local seen, colors = {}, {}
for _, cel in ipairs(spr.cels) do
  for it in cel.image:pixels() do
    local v = it()
    if app.pixelColor.rgbaA(v) > 0 then
      local key = v & 0x00FFFFFF
      if not seen[key] then
        seen[key] = true
        colors[#colors + 1] = Color { r = app.pixelColor.rgbaR(v), g = app.pixelColor.rgbaG(v), b = app.pixelColor.rgbaB(v) }
      end
    end
  end
end
local pal = Palette(#colors + 1)
pal:setColor(0, Color { r = 0, g = 0, b = 0, a = 0 })
for i, c in ipairs(colors) do pal:setColor(i, c) end
spr:setPalette(pal)
print("colours=" .. #colors)

app.fs.makeAllDirectories(out)
spr:saveAs(out .. "/ottavia_v1.aseprite")
print("frames=" .. index .. " tags=" .. #spr.tags)
