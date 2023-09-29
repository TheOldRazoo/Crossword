
local pd <const> = playdate
local gfx <const> = pd.graphics

local cellWidth <const> = 28
local cellHeight <const> = 28
local borderWidth <const> = 1

local boardClipRect <const> = pd.geometry.rect.new(0, 16, pd.display.getWidth(), 202)
local boardOrigin <const> = pd.geometry.point.new(boardClipRect.x, boardClipRect.y)
local curBoardOrigin = boardOrigin

local boardImage = nil

local function drawCell(puz, row, col)
    gfx.lockFocus(boardImage)
    local lineWidth = gfx.getLineWidth()
    gfx.setLineWidth(borderWidth)

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

    gfx.setLineWidth(lineWidth)
    gfx.unlockFocus()
end

function clearBoardScreen()
    local color, background = gfx.getColor(), gfx.getBackgroundColor()
    gfx.setColor(background)
    gfx.fillRect(boardClipRect)
    gfx.setColor(color)
end

function drawBoard(puz)
    if boardImage == nil then
        boardImage = gfx.image.new(puz.width * cellWidth, puz.height * cellHeight)
    end

    for i = 1, puz.width do
        for j = 1, puz.height do
            drawCell(puz, i, j)
        end
    end
end

function displayBoard()
    gfx.setScreenClipRect(boardClipRect)
    clearBoardScreen()
    boardImage:draw(curBoardOrigin)
    gfx.clearClipRect()
end

function scrollToWord(puz, row, col, across)
    local startRowCol, endRowCol
    if across then
        startRowCol, endRowCol = findAcrossWord(puz, row, col)
    else
        startRowCol, endRowCol = findDownWord(puz, row, col)
    end

    if startRowCol then
        if willWordFitOnScreen(startRowCol, endRowCol) then
            scrollToCell(startRowCol)
            scrollToCell(endRowCol)
        else
            scrollToCell(fromRowCol(row, col))
        end
    end

    displayBoard()
end

function scrollToCell(rowcol)
    local y, x = toRowCol(rowcol)
    x = (x - 1) * cellWidth
    y = (y - 1) * cellHeight
    local curX = x + curBoardOrigin.x
    local curY = y + curBoardOrigin.y
    if curX < boardClipRect.x then
        curBoardOrigin.x = curBoardOrigin.x - curX
    end
    if curX + curBoardOrigin.x + cellWidth > boardClipRect.width then
        curBoardOrigin.x = curBoardOrigin.x - (curX + cellWidth - boardClipRect.width)
    end
    if curY < boardClipRect.y then
        curBoardOrigin.y = curBoardOrigin.y - curY
    end
    if curY + curBoardOrigin.y + cellHeight > boardClipRect.height then
        curBoardOrigin.y = curBoardOrigin.y - (curY + cellHeight - boardClipRect.height)
    end
end

function willWordFitOnScreen(startRowCol, endRowCol)
    local wordSize
    local startY, startX = toRowCol(startRowCol)
    local endY, endX = toRowCol(endRowCol)
    if startX == endX then      -- is across word
        wordSize = endX + cellWidth - startX
        return wordSize < boardClipRect.width
    end

    wordSize = endY + cellHeight - startY
    return wordSize < boardClipRect.height
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

function rowcolToXY(rowcol)
    local row, col = toRowCol(rowcol)
    local x, y = (row - 1) * cellHeight, (col - 1) * cellWidth
    return x, y
end
