
import 'CoreLibs/object'

class('StatePlay').extends(State)

local pd <const> = playdate
local gfx <const> = pd.graphics

local letters <const> = " ABCDEFGHIJKLMNOPQRSTUVWXYZ"

function StatePlay:init()
    StatePlay.super.init(self)
    self.puz = nil
    self.curRow = 1
    self.curCol = 1
    self.curLetter = 1
    self.across = true
end

function StatePlay:enter(prevState)
    gfx.clear()
    displayTitle(self.puz)
    drawBoard(self.puz)
    displayBoard()
    displayClue(self.puz, 1, 1, true)
    self:displayCurrentCell(true)
end

function StatePlay:update()
    if pd.buttonJustPressed(pd.kButtonA) then
        self.curLetter = (self.curLetter % #letters) + 1
        self.puz.grid[self.curRow][self.curCol] = string.sub(letters, self.curLetter, self.curLetter)
        self:displayCurrentCell(false)
    elseif pd.buttonJustPressed(pd.kButtonB) then
        self.across = not self.across
        self:displayCurrentCell(true)
    elseif pd.buttonJustPressed(pd.kButtonRight) then
        drawCell(self.puz, self.curRow, self.curCol)
        self.curCol += 1
        if not isLetterCell(self.puz, self.curRow, self.curCol) then
            self.curRow, self.curCol, self.across =
                    findNextWord(self.puz, self.curRow, self.curCol, self.across)
        end
        self:displayCurrentCell(true)
        self:setCurLetter()
    elseif pd.buttonJustPressed(pd.kButtonLeft) then
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
    elseif pd.buttonJustPressed(pd.kButtonDown) then
        drawCell(self.puz, self.curRow, self.curCol)
        self.curRow += 1
        if not isLetterCell(self.puz, self.curRow, self.curCol) then
            self.curRow, self.curCol, self.across =
                findNextWord(self.puz, self.curRow, self.curCol, self.across)
        end
        self:displayCurrentCell(true)
        self:setCurLetter()
    elseif pd.buttonJustPressed(pd.kButtonUp) then
        drawCell(self.puz, self.curRow, self.curCol)
        self.curRow -= 1
        if not isLetterCell(self.puz, self.curRow, self.curCol) then
            self.curRow = self.puz.height
            self.curRow, self.curCol, self.across =
                findNextWord(self.puz, self.curRow, self.curCol, self.across)
        end
        self:displayCurrentCell(true)
        self:setCurLetter()
    end
end

function StatePlay:displayCurrentWord()
    local wordRect = wordBoundingRect(self.puz, self.curRow, self.curCol, self.across)
    local wordImg = getWordImage(wordRect)
    wordImg:draw(wordRect.x, wordRect.y)
end

function StatePlay:displayCurrentCell(redraw)
    scrollToWord(self.puz, self.curRow, self.curCol, self.across)
    if redraw then
        displayBoard()
        displayClue(self.puz, self.curRow, self.curCol, self.across)
        self:displayCurrentWord()
    end

    local img = getCellImage(self.puz, self.curRow, self.curCol):invertedImage()
    -- img = img:blurredImage(1, 1, gfx.image.kDitherTypeBayer2x2, false)
    img:draw(getScreenCoord(self.curRow, self.curCol))
end

function StatePlay:setCurLetter()
    local pos = string.find(letters, self.puz.grid[self.curRow][self.curCol], 1, true)
    if pos and pos ~= #letters then
        self.curLetter = pos
    else
        self.curLetter = 1
    end
end

function StatePlay:setPuzzle(puz)
    self.puz = puz
end
