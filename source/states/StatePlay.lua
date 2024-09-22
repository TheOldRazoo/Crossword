
import 'CoreLibs/object'

class('StatePlay').extends(State)

local pd <const> = playdate
local gfx <const> = pd.graphics

local letters <const> = " ABCDEFGHIJKLMNOPQRSTUVWXYZ"

local musicOn <const> = "music on"
local musicOff <const> = "music off"

local checkErrors <const> = "check errors"
local clearErrors <const> = "clear errors"
local showLetter <const> = "show letter"
local showWord <const> = "show word"
local musicOpt = ""


function StatePlay:init()
    StatePlay.super.init(self)
    self.puz = nil
end

function StatePlay:enter(prevState)
    if options.playMusic then
        musicOpt = musicOff
    else
        musicOpt = musicOn
    end
    self:addMenuItems()
    musicInit()
    if options.playMusic then
        musicPlay()
    end
    local startRowCol = findFirstWord(self.puz, true)
    self.curRow, self.curCol = toRowCol(startRowCol)
    self:setCurLetter()
    self.across = true
    self.prevState = prevState
    initScreen()
    gfx.clear()
    displayTitle(self.puz)
    drawBoard(self.puz, true)
    displayBoard()
    displayClue(self.puz, self.curRow, self.curCol, true)
    self:displayCurrentCell(true)
    if self.puz.err then
        displayMessage(self.puz.err, 1)
    end
end

function StatePlay:exit()
    musicStop()
    pd.getSystemMenu():removeAllMenuItems()
    self:savePuzzle()
end

local ignoreB = false
function StatePlay:update()
    if pd.buttonJustReleased(pd.kButtonA) then
        if pd.getButtonState() & pd.kButtonB > 0 then
            ignoreB = true
            self.curLetter -= 1
            if self.curLetter < 1 then
                self.curLetter = #letters
            end
        else
            self.curLetter = (self.curLetter % #letters) + 1
            ignoreB = false
        end
        self.puz.grid[self.curRow][self.curCol] = string.sub(letters, self.curLetter, self.curLetter)
        self:displayCurrentCell(false)
    elseif pd.buttonJustReleased(pd.kButtonB) then
        if ignoreB then
            ignoreB = false
        else
            self.across = not self.across
            self:displayCurrentCell(true)
        end
    elseif pd.buttonJustReleased(pd.kButtonRight) then
        if pd.getButtonState() & pd.kButtonB > 0 then
            ignoreB = true
            self.curLetter += 10
            if self.curLetter > #letters then
                self.curLetter -= #letters
            end
            self.puz.grid[self.curRow][self.curCol] =
                                string.sub(letters, self.curLetter, self.curLetter)
            self:displayCurrentCell(false)
        else
            ignoreB = false
            drawCell(self.puz, self.curRow, self.curCol)
            self.curCol += 1
            if not isLetterCell(self.puz, self.curRow, self.curCol) then
                self.curRow, self.curCol, self.across =
                        findNextWord(self.puz, self.curRow, self.curCol, self.across)
            end
            self:displayCurrentCell(true)
            self:setCurLetter()
        end
    elseif pd.buttonJustReleased(pd.kButtonLeft) then
        if pd.getButtonState() & pd.kButtonB > 0 then
            ignoreB = true
            self.curLetter -= 10
            if self.curLetter < 1 then
                self.curLetter += #letters
            end
            self.puz.grid[self.curRow][self.curCol] =
                                string.sub(letters, self.curLetter, self.curLetter)
            self:displayCurrentCell(false)
        else
            ignoreB = false
            drawCell(self.puz, self.curRow, self.curCol)
            self.curCol -= 1
            if not isLetterCell(self.puz, self.curRow, self.curCol) then
                self.curRow, self.curCol, self.across =
                        findPrevWord(self.puz, self.curRow, self.curCol, self.across)
                local startRowCol, endRowCol = findWord(self.puz, self.curRow, self.curCol, self.across)
                self.curRow, self.curCol = toRowCol(endRowCol)
            end
            self:displayCurrentCell(true)
            self:setCurLetter()
        end
    elseif pd.buttonJustReleased(pd.kButtonDown) then
        if pd.getButtonState() & pd.kButtonB > 0 then
            ignoreB = true
            self:findBlankCell(true)
        else
            drawCell(self.puz, self.curRow, self.curCol)
            local row = self.curRow + 1
            while not isLetterCell(self.puz, row, self.curCol) do
                if row == self.curRow then
                    row += 1
                    break
                end

                row += 1
                if row > self.puz.height then
                    row = 1
                end
            end

            self.curRow = row
            if not isLetterCell(self.puz, self.curRow, self.curCol) then
                self.curRow, self.curCol, self.across =
                    findNextWord(self.puz, self.curRow, self.curCol, self.across)
            end
            self:displayCurrentCell(true)
            self:setCurLetter()
        end
    elseif pd.buttonJustReleased(pd.kButtonUp) then
        if pd.getButtonState() & pd.kButtonB > 0 then
            ignoreB = true
            self:findBlankCell(false)
        else
            drawCell(self.puz, self.curRow, self.curCol)
            local row = self.curRow - 1
            while not isLetterCell(self.puz, row, self.curCol) do
                if row == self.curRow then
                    row -= 1
                    break
                end

                row -= 1
                if row < 1 then
                    row = self.puz.height
                end
            end

            self.curRow = row
            if not isLetterCell(self.puz, self.curRow, self.curCol) then
                self.curRow, self.curCol, self.across =
                    findPrevWord(self.puz, self.curRow, self.curCol, self.across)
            end
            self:displayCurrentCell(true)
            self:setCurLetter()
        end
    elseif not pd.isCrankDocked() then
        -- crank enhancement by Macoy Madson macoy@macoy.me
        local change = pd.getCrankTicks(12)
        if change ~= 0 then
            if change < 0 then
                self.curLetter -= 1
                if self.curLetter < 1 then
                    self.curLetter = #letters
                end
            else
                self.curLetter = (self.curLetter % #letters) + 1
            end

            self.puz.grid[self.curRow][self.curCol] = string.sub(letters,
                                        self.curLetter, self.curLetter)
            self:displayCurrentCell(false)
            -- print(change, accel, delay)
        end
    end
end

function StatePlay:displayCurrentWord()
    local wordRect = wordBoundingRect(self.puz, self.curRow, self.curCol, self.across)
    local wordImg = getWordImage(wordRect)
    setClipRect()
    wordImg:draw(wordRect.x, wordRect.y)
    gfx.clearClipRect()
end

function StatePlay:displayCurrentCell(redraw)
    scrollToWord(self.puz, self.curRow, self.curCol, self.across)
    scrollToCell(fromRowCol(self.curRow, self.curCol))
    if redraw then
        displayBoard()
        displayClue(self.puz, self.curRow, self.curCol, self.across)
        self:displayCurrentWord()
    end

    setClipRect()
    local img = getCellImage(self.puz, self.curRow, self.curCol):invertedImage()
    gfx.lockFocus(img)
    local color = gfx.getColor()
    gfx.setColor(gfx.getBackgroundColor())
    local w, h = img:getSize()
    gfx.drawRect(3, 3, w - 6, h - 6)
    gfx.setColor(color)
    gfx.unlockFocus()
    img:draw(getScreenCoord(self.curRow, self.curCol))
    gfx.clearClipRect()
end

function StatePlay:setCurLetter()
    local pos = string.find(letters, self.puz.grid[self.curRow][self.curCol], 1, true)
    if pos and pos ~= #letters then
        self.curLetter = pos
    else
        self.curLetter = 1
    end
end

function StatePlay:findBlankCell(nextBlank)
    local puz = self.puz
    local row, col = self.curRow, self.curCol
    drawCell(puz, row, col)

    if nextBlank then
        col += 1
    else
        col -= 1
    end

    while true do
        if col > puz.width then
            row += 1
            col = 1
        elseif col < 1 then
            row -= 1
            col = puz.width
        end

        if row > puz.height then
            row = 1
        elseif row < 1 then
            row = puz.height
        end

        if row == self.curRow and col == self.curCol then
            break
        end

        if puz.grid[row][col] == ' ' then
            self.curRow, self.curCol = row, col
            self:displayCurrentCell(true)
            self:setCurLetter()
            return
        end

        if nextBlank then
            col += 1
        else
            col -= 1
        end
    end

    pauseScrollTimer()
    displayMessage('There are no blank spaces', 1)
end

function StatePlay:checkForErrors()
    local errors, blanks = 0, 0
    local puz = self.puz
    for row = 1, puz.height do
        for col = 1, puz.width do
            if puz.grid[row][col] == " " then
                blanks += 1
            elseif puz.grid[row][col] ~= puz.solution[row][col] then
                errors += 1
            end
        end
    end

    local msg
    if errors == 0 and blanks == 0 then
        msg = 'Puzzle complete.  Congratulations!'
    else
        msg = errors .. ' error'
        if errors ~= 1 then
            msg = msg .. 's'
        end
        msg = msg .. ' and ' .. blanks .. ' blank space'
        if blanks ~= 1 then
            msg = msg .. 's'
        end
    end
    pauseScrollTimer()
    displayMessage(msg, 4)
end

function StatePlay:removeErrors()
    local puz = self.puz
    local errs = 0
    for row = 1, puz.height do
        for col = 1, puz.width do
            if puz.grid[row][col] ~= ' ' and puz.grid[row][col] ~= puz.solution[row][col] then
                puz.grid[row][col] = ' '
                errs += 1
            end
        end
    end

    self:setCurLetter()
    pauseScrollTimer()
    if errs == 0 then
        displayMessage('No errors found', 1)
    else
        drawBoard(puz, false)
        self:displayCurrentCell(true)
        displayMessage(errs .. ' error(s) removed', 4)
    end
end

function StatePlay:showLetter()
    self.puz.grid[self.curRow][self.curCol] = self.puz.solution[self.curRow][self.curCol]
    drawCell(self.puz, self.curRow, self.curCol)
    self:displayCurrentCell(true)
end

function StatePlay:showWord()
    local puz = self.puz
    local startRowCol, endRowCol = findWord(puz, self.curRow,
                                            self.curCol, self.across)
    if startRowCol then
        local row, col = toRowCol(startRowCol)
        local endRow, endCol = toRowCol(endRowCol)
        while (self.across and col <= endCol) or (not self.across and row <= endRow) do
            puz.grid[row][col] = puz.solution[row][col]
            if self.across then
                col += 1
            else
                row += 1
            end
        end
        drawBoard(self.puz, false)
        self:displayCurrentCell(true)
    end
end

function StatePlay:setMusicOption()
    options.playMusic = not options.playMusic
    if options.playMusic then
        musicPlay()
        musicOpt = musicOff
    else
        musicStop()
        musicOpt = musicOn
    end

    pd.getSystemMenu():removeAllMenuItems()
    self:addMenuItems()
end

function StatePlay:setRebusOption(selected)
    options.rebus = selected
    drawBoard(self.puz, false)
    self:displayCurrentCell(true)
end

function StatePlay:exitPuzzle()
    pauseScrollTimer()
    stateManager:setCurrentState(self.prevState)
end

function StatePlay:addMenuItems()
    local menu = pd.getSystemMenu()
    menu:addOptionsMenuItem('opt', {checkErrors, clearErrors, showLetter, showWord, musicOpt},
                function(option)
                    if option == checkErrors then self:checkForErrors()
                    elseif option == clearErrors then self:removeErrors()
                    elseif option == showLetter then self:showLetter()
                    elseif option == showWord then self:showWord()
                    elseif option == musicOpt then self:setMusicOption()
                    end
                end
            )
    menu:addCheckmarkMenuItem('rebus', options.rebus, function(sel) self:setRebusOption(sel) end)
    menu:addMenuItem('exit puzzle', function() self:exitPuzzle() end )
end

function StatePlay:savePuzzle()
    savePuzzle(self.puz)
end

function StatePlay:setPuzzle(puz)
    self.puz = puz
end
