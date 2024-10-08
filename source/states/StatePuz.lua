
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
local font = getListFont()
local fontHeight = font:getHeight()
local gridView = grid.new(gridWidth, font:getHeight() + 4)
local displayGridView = false
local version = pd.metadata.version

local puzFiles

function StatePuz:init(puzzleDir, parentState)
    StatePuz.super.init(self)
    self.puzzleDir = puzzleDir
    self.parentState = parentState
    self.deleteCount = 0
end

function StatePuz:enter(prevState)
    initScreen()
    clearScreen()
    font:drawText(version, 400 - font:getTextWidth(version) - 2, 0)
    puzFiles = self:listPuzzleFiles()
    gridView:setNumberOfRows(#puzFiles)
    gridView:setSelection(1, 1, 1)
    gridView:scrollToRow(1, false)
    gridView:setNumberOfSections(1)
end

function StatePuz:update()
    -- crank enhancement by Macoy Madson macoy@macoy.me
    if not pd.isCrankDocked() then
	   local change = pd.getCrankTicks(12)
	   if change > 0 then
		  self.deleteCount = 0
		  displayListMessage(' ')
		  gridView:selectNextRow(true, true, false)
		  displayPuzzleInfo(selectedRow())
	   elseif change < 0 then
		  self.deleteCount = 0
		  displayListMessage(' ')
		  gridView:selectPreviousRow(true)
		  displayPuzzleInfo(selectedRow())
	   end
	end
    -- end enhancement
    if pd.buttonJustReleased(pd.kButtonDown) then
        self.deleteCount = 0
        displayListMessage(' ')
        gridView:selectNextRow(true, true, false)
        displayPuzzleInfo(selectedRow())
    elseif pd.buttonJustReleased(pd.kButtonUp) then
        self.deleteCount = 0
        displayListMessage(' ')
        gridView:selectPreviousRow(true)
        displayPuzzleInfo(selectedRow())
    elseif pd.buttonJustReleased(pd.kButtonLeft) then
        if self.parentState then
            stateManager:setCurrentState(self.parentState)
            return
        end
    elseif pd.buttonJustReleased(pd.kButtonRight) then
        if options.lastPuzzle then
            local puz, err = loadPuzzleFile(options.lastPuzzle)
            if puz then
                restorePuzzle(puz)
                statePlay:setPuzzle(puz)
                stateManager:setCurrentState(statePlay)
            else
                displayListMessage(err)
            end
        end
    elseif pd.buttonJustReleased(pd.kButtonA) then
        self.deleteCount = 0
        local row = selectedRow()

        if puzFiles[row] == '..' and self.parentState then
            stateManager:setCurrentState(self.parentState)
            return
        end

        if pd.file.isdir(puzFiles[row]) then
            stateManager:setCurrentState(StatePuz(puzFiles[row], self))
            return
        end

        local puz, err = loadPuzzleFile(puzFiles[row])
        if puz then
            restorePuzzle(puz)
            statePlay:setPuzzle(puz)
            stateManager:setCurrentState(statePlay)
        else
            displayListMessage(err)
        end
    elseif pd.buttonJustReleased(pd.kButtonB) then
        local row = selectedRow()
        if string.sub(puzFiles[row], 1, 5) == '/puz/' then
            displayListMessage('Cannot delete builtin puzzle file')
        elseif pd.file.isdir(puzFiles[row]) or puzFiles[row] == '..' then
            displayListMessage('Cannot delete folders')
        else
            self.deleteCount += 1
            if self.deleteCount < 3 then
                displayListMessage('Delete ' .. puzFiles[selectedRow()] .. '  **'
                        .. self.deleteCount .. '**')
            else
                pd.file.delete(puzFiles[row])
                pd.file.delete(getSaveFileName(puzFiles[row]))
                table.remove(puzFiles, row)
                gridView:setNumberOfRows(#puzFiles)
                gridView:scrollToRow(1, false)
                gridView:setSelectedRow(1)
                displayGridView = true
                displayListMessage(' ')
                clearPuzzleInfoPane()
            end
        end
    end

    if gridView.needsDisplay or displayGridView then
        drawSaveHeader(gridX, gridY - 18, gridWidth, fontHeight)
        gridView:drawInRect(gridX, gridY, gridWidth, gridHeight - fontHeight)
        gfx.drawRect(gridX - 2, gridY - 20, gridWidth + 4, gridHeight + 4)
        local row = selectedRow()
        displayPuzzleInfo(row)
        displayGridView = false
    end
end

function StatePuz:listPuzzleFiles()
    local puzFiles = {}
    if self.parentState == nil then     -- if top level state list internal puzzles
        local files = playdate.file.listFiles('/puz')
        for i = 1, #files do
            if string.match(files[i], '%.puz$') then
                table.insert(puzFiles, '/puz/' .. files[i])
            end
        end
    else
        table.insert(puzFiles, '..')
    end

    local files = playdate.file.listFiles(self.puzzleDir)
    for i = 1, #files do
        if string.match(files[i], '%.puz$') or pd.file.isdir(self.puzzleDir .. files[i]) then
            table.insert(puzFiles, self.puzzleDir .. files[i])
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
    if row < 1 or row > #puzFiles then
        return
    end
    clearPuzzleInfoPane()
    displayListMessage(' ')
    local file = puzFiles[row]
    displayListMessage(file)
    gfx.setColor(color)
    gfx.setBackgroundColor(backgroundColor)
    if file == '..' then
        font:drawText('** Parent Folder **', puzzleInfoX, puzzleInfoY)
    elseif pd.file.isdir(file) then
        font:drawText('** Folder **', puzzleInfoX, puzzleInfoY)
    else
        local puz = loadPuzzleInfo(file)
        if puz then
            local infoY = puzzleInfoY
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

            if pd.file.exists(getSaveFileName(puzFiles[row]) .. '.json') then
                infoY += puzzleInfoLineHeight * 2
                if isPuzzleComplete(puz) then
                    font:drawText('* Completed *', puzzleInfoX, infoY)
                else
                    font:drawText('* Saved Data *', puzzleInfoX, infoY)
                end
            end
        end
    end
end

function isPuzzleComplete(puz)
    restorePuzzle(puz)
    if not puz.grid then
        return false
    end

    for row = 1, puz.height do
        for col = 1, puz.width do
            if puz.solution[row][col] ~= puz.grid[row][col] then
                return false
            end
        end
    end

    return true
end

function clearPuzzleInfoPane()
    gfx.setColor(backgroundColor)
    gfx.fillRect(puzzleInfoX, puzzleInfoY, puzzleInfoWidth, puzzleInfoHeight)
    gfx.setColor(color)
end

function displayListMessage(msg)
    local color = gfx.getColor()
    gfx.setColor(gfx.getBackgroundColor())
    gfx.fillRect(0, 224, 400, 240)
    gfx.setColor(color)
    font:drawText(msg, 1, 224)

end
