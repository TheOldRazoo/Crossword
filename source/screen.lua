
local pd <const> = playdate
local gfx <const> = pd.graphics

local cellWidth <const> = 28
local cellHeight <const> = 28
local borderWidth <const> = 1

local boardClipRect = pd.geometry.rect.new(0, 0, 400, 218)
local boardOrigin = pd.geometry.point.new(0, 16)

local boardImage = nil

local function drawCell(puz, row, col)
    local x, y = (col - 1) * cellWidth, (row - 1) * cellHeight
    if puz.grid[row][col] == '.' then
        gfx.fillRect(x, y, cellWidth, cellHeight)
    else
        gfx.drawRect(x, y, cellWidth, cellHeight)
        local clueNum = getClueNumber(puz, row, col)
        if clueNum then
            getTinyFont():drawText(tostring(clueNum), x + borderWidth + 2, y + borderWidth + 2)
        end

        getLetterFont():drawText(puz.grid[row][col], x + borderWidth + 8, y + borderWidth + 6)
    end
end

function drawBoard(puz)
    if boardImage == nil then
        boardImage = gfx.image.new(puz.width * cellWidth, puz.height * cellHeight)
    end

    gfx.lockFocus(boardImage)
    local lineWidth = gfx.getLineWidth()
    gfx.setLineWidth(borderWidth)
    for i = 1, puz.width do
        for j = 1, puz.height do
            drawCell(puz, i, j)
        end
    end
    gfx.setLineWidth(lineWidth)
    gfx.unlockFocus()
end

function displayBoard()
    gfx.setScreenClipRect(boardClipRect)
    boardImage:draw(boardOrigin)
    gfx.clearClipRect()
end

-- across is true for across clue.  otherwise use down clue
function displayClue(puz, row, col, across)
    local clueNum = getClueNumber(puz, row, col)
    local clue = nil
    local dir = nil
    if across and needsAcrossNumber(puz, row, col) then
        clue = puz.clues[puz.acrossClue[clueNum][3]]
        dir = 'A'
    elseif not across and needsDownNumber(puz, row, col) then
        clue = puz.clues[puz.downClues[clueNum][3]]
        dir = 'D'
    end

    if clue then
        clue = clueNum .. dir .. '. ' .. clue
        getClueFont():drawText(clue, 1, 224)
    end
end

function displayTitle(puz)
    getClueFont():drawText(puz.title .. ' by ' .. puz.author, 2, 2)
end