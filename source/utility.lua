
local pd <const> = playdate
local gfx <const> = pd.graphics

local tinyFont = gfx.font.new('fonts/Pico8')
local letterFont = gfx.font.new('fonts/Roobert-11-Medium')
local clueFont = gfx.font.new('fonts/Roobert-10-Bold')

local wordSprite = nil

function getTinyFont()
    return tinyFont
end

function getLetterFont()
    return letterFont
end

function getClueFont()
    return clueFont
end

