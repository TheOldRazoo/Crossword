
local pd <const> = playdate
local gfx <const> = pd.graphics

local tinyFont = gfx.font.new('fonts/Pico8')
local letterFont = gfx.font.new('fonts/Roobert-11-Medium')
local clueFont = gfx.getSystemFont(gfx.font.kVariantBold)
local listFont = gfx.font.new('fonts/Roobert-10-Bold')

local menuImg = gfx.image.new('/images/menu')

function getTinyFont()
    return tinyFont
end

function getLetterFont()
    return letterFont
end

function getClueFont()
    return clueFont
end

function getListFont()
    return listFont
end

function getMenuImage()
    return menuImg
end

function clearScreen()
    gfx.clear(gfx.getBackgroundColor())
end

function getBaseFileName(name)
    if string.find(name, '/$') then
        name = string.sub(name, 1, #name - 1)
    end

    local first, last = 1, 0
    local slash = 1
    while first do
        first, last = string.find(name, '/', first, true)
        if first then
            first += 1
            slash = first
        end
    end
    last = string.find(name, '.puz', slash, true)
    if last then
        name = string.sub(name, slash, last - 1)
    else
        name = string.sub(name, slash)
    end

    return name
end

function getSaveFileName(name)
    name = string.gsub(name, '.puz$', '')
    name = string.gsub(name, '^/puzzles/', '/saves/')
    name = string.gsub(name, '^/puz/', '/saves/')
    return name
end

function wrapText(text, font, width)
    local line = ''
    local lines = {}
    local pos = 0
    while pos do
        local word
        pos += 1
        local startPos, endPos = string.find(text, ' +', pos)
        if startPos then
            word = string.sub(text, pos, endPos)
        else
            word = string.sub(text, pos)
        end

        if font:getTextWidth(line .. word .. ' ') < width then
            line = line .. word .. ' '
        else
            table.insert(lines, line)
            line = ''
        end

        pos = endPos
    end

    if #line > 0 then
        table.insert(lines, line)
    end

    return lines
end
