
local pd <const> = playdate
local gfx <const> = pd.graphics

local cellWidth <const> = 28
local cellHeight <const> = 28
local borderWidth <const> = 1

local boardClipRect <const> = pd.geometry.rect.new(0, 16, pd.display.getWidth(), 202)
local boardOrigin <const> =  { x = boardClipRect.x, y = boardClipRect.y }

local boardImage = nil

local function resetBoardOrigin()
    boardOrigin.x = boardClipRect.x
    boardOrigin.y = boardClipRect.y
end

function initScreen()
    boardImage = nil
    resetBoardOrigin()
end

function drawCell(puz, row, col)
    local x, y = (col - 1) * cellWidth, (row - 1) * cellHeight
    local cell = getCellImage(puz, row, col)
    gfx.lockFocus(boardImage)
    cell:draw(x, y)
    gfx.unlockFocus()
end

function getCellImage(puz, row, col)
    local cellImg = gfx.image.new(cellWidth, cellHeight, gfx.getBackgroundColor())
    gfx.lockFocus(cellImg)
    if puz.grid[row][col] == '.' then
        gfx.fillRect(0, 0, cellWidth, cellHeight)
    else
        gfx.drawRect(0, 0, cellWidth, cellHeight)
        local clueNum = getClueNumber(puz, row, col)
        if clueNum then
            getTinyFont():drawText(tostring(clueNum), borderWidth + 2, borderWidth + 2)
        end

        getLetterFont():drawTextAligned(puz.grid[row][col],
            cellWidth // 2, borderWidth + 6, kTextAlignment.center)
    end

    gfx.unlockFocus()
    return cellImg
end

function getWordImage(rect)
    local wordImg = gfx.image.new(rect.width, rect.height)
    gfx.lockFocus(wordImg)
    gfx.drawRect(0, 0, rect.width, rect.height)
    gfx.drawRect(1, 1, rect.width - 2, rect.height - 2)
    gfx.drawRect(2, 2, rect.width - 4, rect.height - 4)
    gfx.unlockFocus()
    return wordImg
end

function clearBoardScreen()
    local color, background = gfx.getColor(), gfx.getBackgroundColor()
    gfx.setColor(background)
    gfx.fillRect(boardClipRect)
    gfx.setColor(color)
end

function drawBoard(puz)
    resetBoardOrigin()
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
    boardImage:draw(boardOrigin.x, boardOrigin.y)
    gfx.clearClipRect()
end

function getScreenCoord(row, col)
    local x = ((col - 1) * cellWidth) + boardOrigin.x
    local y = ((row - 1) * cellHeight) + boardOrigin.y
    return x, y
end

---@param puz the current puzzle
---@param row the current cell row
---@param col the current cell col
---@param across true if across word, false if down word
---@return rect bounding the word cells
function wordBoundingRect(puz, row, col, across)
    local startRowCol, endRowCol = findWord(puz, row, col, across)
    if not startRowCol then
        return nil
    end

    local startX, startY = toRowCol(startRowCol)
    local endX, endY = toRowCol(endRowCol)
    startX, startY = getScreenCoord(startX, startY)
    endX, endY = getScreenCoord(endX, endY)
    endX += cellWidth
    endY += cellHeight

    local rect = pd.geometry.rect.new(startX, startY, endX - startX, endY - startY)
    return rect
end

function scrollToWord(puz, row, col, across)
    local startRowCol, endRowCol = findWord(puz, row, col, across)

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
    local curX = x + boardOrigin.x
    local curY = y + boardOrigin.y
    if curX < boardClipRect.x then
        boardOrigin.x = boardOrigin.x - curX + boardClipRect.x
    end
    if curX + boardOrigin.x + cellWidth > boardClipRect.width then
        boardOrigin.x = boardOrigin.x - (curX + cellWidth - boardClipRect.width)
    end
    if curY < boardClipRect.y then
        boardOrigin.y = boardOrigin.y - curY + boardClipRect.y
    end
    if curY + boardOrigin.y + cellHeight > boardClipRect.height + boardOrigin.y then
        boardOrigin.y = boardOrigin.y - (curY + cellHeight - boardClipRect.height)
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

function displayMessage(msg)
    local color = gfx.getColor()
    gfx.setColor(gfx.getBackgroundColor())
    gfx.fillRect(1, 224, 400, 240)
    gfx.setColor(color)
    getClueFont():drawText(msg, 1, 224)
end

-- across is true for across clue.  otherwise use down clue
function displayClue(puz, row, col, across)
    local clue = nil
    local dir = nil
    local startRowCol = findWord(puz, row, col, across)
    local clueNum = getClueNumber(puz, toRowCol(startRowCol))
    if across and needsAcrossNumber(puz, toRowCol(startRowCol)) then
        clue = getAcrossClue(puz, startRowCol)
        dir = 'a'
    elseif not across and needsDownNumber(puz, toRowCol(startRowCol)) then
        clue = getDownClue(puz, startRowCol)
        dir = 'd'
    end

    if clue then
        local color = gfx.getColor()
        gfx.setColor(gfx.getBackgroundColor())
        gfx.fillRect(1, 224, 400, 240)
        gfx.setColor(color)
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
