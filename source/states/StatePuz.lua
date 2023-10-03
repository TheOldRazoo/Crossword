
import 'CoreLibs/object'
import 'CoreLibs/ui'

class('StatePuz').extends(State)

local pd <const> = playdate
local gfx <const> = pd.graphics
local grid <const> = pd.ui.gridview

local color = gfx.getColor()
local backgroundColor = gfx.getBackgroundColor()

local gridX = 4
local gridY = 24
local gridWidth = 110
local gridHeight = 212
local puzzleInfoX = gridX + gridWidth + 8
local puzzleInfoY = gridY
local puzzleInfoWidth = 400 - puzzleInfoX
local puzzleInfoHeight = 240 - puzzleInfoY
local puzzleInfoLineHeight = 14
local font = getClueFont()
local fontHeight = font:getHeight()
local gridView = grid.new(gridWidth, font:getHeight() + 4)

local puzFiles


function StatePuz:init()
    StatePuz.super.init(self)
end

function StatePuz:enter(prevState)
    clearScreen()
    puzFiles = self:listPuzzleFiles()
    gridView:setNumberOfRows(#puzFiles)
    gridView:setSelection(1, 1, 1)
    gridView:scrollToRow(1, false)
    gridView:setNumberOfSections(1)
end

function StatePuz:update()
    if pd.buttonJustReleased(pd.kButtonDown) then
        gridView:selectNextRow(true, true, false)
        displayPuzzleInfo(selectedRow())
    elseif pd.buttonJustReleased(pd.kButtonUp) then
        gridView:selectPreviousRow(true)
        displayPuzzleInfo(selectedRow())
    elseif pd.buttonJustReleased(pd.kButtonA) then
        local row = selectedRow()
        selectedFilename = puzFiles[row]
    elseif pd.buttonJustReleased(pd.kButtonB) then
    end

    if gridView.needsDisplay then
        drawSaveHeader(gridX, gridY - 18, gridWidth, fontHeight)
        gridView:drawInRect(gridX, gridY, gridWidth, gridHeight - fontHeight)
        gfx.drawRect(gridX - 2, gridY - 20, gridWidth + 4, gridHeight + 4)
        displayPuzzleInfo(selectedRow())
    end
end

function StatePuz:listPuzzleFiles()
    local puzFiles = {}
    local files = playdate.file.listFiles('/puz')
    for i = 1, #files do
        if string.match(files[i], '%.puz$') then
            table.insert(puzFiles, '/puz/' .. files[i])
        end
    end

    files = playdate.file.listFiles('/puzzles')
    for i = 1, #files do
        if string.match(files[i], '%.puz$') then
            table.insert(puzFiles, '/puzzles/' .. files[i])
        end
    end

    return puzFiles
end

function gridView:drawCell(section, row, col, selected, x, y, width, height)
    local c, b
    if selected then
        gfx.setImageDrawMode(gfx.kDrawModeInverted)
        b = color
        c = backgroundColor
    else
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        b = backgroundColor
        c = color
    end

    gfx.setColor(b)
    gfx.fillRect(x, y, width, height)
    gfx.setColor(c)
    gfx.setBackgroundColor(b)
    font:drawText(getBaseFileName(puzFiles[row]), x + 4, y + 2)
    gfx.setColor(color)
    gfx.setBackgroundColor(backgroundColor)
end


function drawSaveHeader(x, y, width, height)
    gfx.setColor(backgroundColor)
    gfx.fillRect(x, y, width, height)
    gfx.setColor(color)
    font:drawText("Puzzle Files", x, y)
end

function selectedRow()
    local section, row, col = gridView:getSelection()
    return row
end

function displayPuzzleInfo(row)
    clearPuzzleInfoPane()
    local file = puzFiles[row]
    local puz = loadPuzzleInfo(file)
    if puz then
        local infoY = puzzleInfoY
        gfx.setColor(color)
        gfx.setBackgroundColor(backgroundColor)
        local lines = wrapText(puz.title, font, puzzleInfoWidth)
        for i = 1, #lines do
            font:drawText(lines[i], puzzleInfoX, infoY)
            infoY += puzzleInfoLineHeight
        end

        infoY += puzzleInfoLineHeight
        lines = wrapText(puz.author, font, puzzleInfoWidth)
        for i = 1, #lines do
            font:drawText(lines[i], puzzleInfoX, infoY)
            infoY += puzzleInfoLineHeight
        end

        infoY += puzzleInfoLineHeight
        lines = wrapText(puz.copyright, font, puzzleInfoWidth)
        for i = 1, #lines do
            font:drawText(lines[i], puzzleInfoX, infoY)
            infoY += puzzleInfoLineHeight
        end

        if pd.file.exists('/saves/' .. getBaseFileName(puzFiles[row]) .. '.json') then
            infoY += puzzleInfoLineHeight * 2
            font:drawText('* Saved Data *', puzzleInfoX, infoY)
        end
    end
end

function clearPuzzleInfoPane()
    gfx.setColor(backgroundColor)
    gfx.fillRect(puzzleInfoX, puzzleInfoY, puzzleInfoWidth, puzzleInfoHeight)
    gfx.setColor(color)
end
