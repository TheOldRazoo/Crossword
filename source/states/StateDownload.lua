
class('StateDownload').extends(State)

local gfx <const> = playdate.graphics
local pd <const> = playdate

local startX <const> = 70
local startY <const> = 50
local dayWidth <const> = 40
local dayHeight <const> = 30
local cursorWidth <const> = 20
local cursorHeight <const> = 20
local monthNames <const> = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
local dayNames <const> = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"}

local calendar = Calendar()

function StateDownload:init()
    StateDownload.super.init(self)
end

function StateDownload:enter(prevState)
    self.prevState = prevState
    self.firstTime = true
    self.currDate = pd.getTime()
    self.grid = calendar:generateMonth(self.currDate.year, self.currDate.month)
end

-- Return the screen coordinates for the given row and column
local function calcScreenCoord(row, col)
    local x = startX + (col - 1) * dayWidth
    local y = startY + (row - 1) * dayHeight
    return x, y
end

-- Find the requested day in the month grid.  Return row, col.
local function findDay(self, day)
    for row = 1, #self.grid do
        for col = 1, #self.grid[row] do
            if day == self.grid[row][col] then
                return row, col
            end
        end
    end
    return findDay(self, 1)
end

-- Returns the last day of the current month
local function lastDayForMonth(self)
    local row = #self.grid
    for col = #self.grid[row], 1, -1 do
        if self.grid[row][col] > 0 then
            return self.grid[row][col]
        end
    end
    assert(false, "No last day found for month")
end

-- Highlight the current day on the calendar
local function showCursor(self)
    local drawMode = gfx.getImageDrawMode()
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    local row, col = findDay(self, self.currDate.day)
    local x, y = calcScreenCoord(row, col)
    gfx.fillRect(x - 4, y, cursorWidth, cursorHeight)
    gfx.drawText(self.grid[row][col], x, y)
    gfx.setImageDrawMode(drawMode)
end

local function displayScreen(self)
    gfx.clear()
    gfx.drawTextInRect(monthNames[self.currDate.month] .. ' ' .. tostring(self.currDate.year),
                        0, 0, 400, 20, nil, nil, kTextAlignment.center, gfx.getFont(gfx.font.kVariantBold))
    local x = startX - 8
    for i , dayName in ipairs(dayNames) do
        gfx.drawText(dayName, x, 25)
        x = x + dayWidth
    end
    for row = 1, #self.grid do
        for col = 1, #self.grid[row] do
            local day = self.grid[row][col]
            if day > 0 then
                local x, y = calcScreenCoord(row, col)
                gfx.drawText(tostring(day), x, y)
            end
        end
    end
    showCursor(self)
    displayListMessage('Select date.  Press (A) to download, (B) to exit.')
end

local function moveCursor(self, offset)
    self.currDate.day = self.currDate.day + offset
    if self.currDate.day > lastDayForMonth(self) then
        self.currDate.month = self.currDate.month + 1
        self.currDate.day = 1
        if self.currDate.month > 12 then
            self.currDate.year = self.currDate.year + 1
            self.currDate.month = 1
        end
    elseif self.currDate.day < 1 then
        self.currDate.month = self.currDate.month - 1
        if self.currDate.month < 1 then
            self.currDate.year = self.currDate.year - 1
            self.currDate.month = 12
        end
        self.grid = calendar:generateMonth(self.currDate.year, self.currDate.month)
        self.currDate.day = lastDayForMonth(self)
    end
    self.grid = calendar:generateMonth(self.currDate.year, self.currDate.month)
    local row, col = findDay(self, self.currDate.day)
    if col == 1 then
        self.currDate.weekday = 7
    else
        self.currDate.weekday = col - 1
    end
    displayScreen(self)
end

function StateDownload:update()
    if self.firstTime then
        self.firstTime = false
        displayScreen(self)
        return
    end

    if pd.buttonJustReleased(pd.kButtonRight) then
        moveCursor(self, 1)
    elseif pd.buttonJustReleased(pd.kButtonLeft) then
        moveCursor(self, -1)
    elseif pd.buttonJustReleased(pd.kButtonUp) then
        self.currDate.month = self.currDate.month - 1
        if self.currDate.month < 1 then
            self.currDate.year = self.currDate.year - 1
            self.currDate.month = 12
        end
        self.currDate.day = 1
        self.grid = calendar:generateMonth(self.currDate.year, self.currDate.month)
        displayScreen(self)
    elseif pd.buttonJustReleased(pd.kButtonDown) then
        self.currDate.month = self.currDate.month + 1
        if self.currDate.month > 12 then
            self.currDate.year = self.currDate.year + 1
            self.currDate.month = 1
        end
        self.currDate.day = 1
        self.grid = calendar:generateMonth(self.currDate.year, self.currDate.month)
        displayScreen(self)
    elseif pd.buttonJustReleased(pd.kButtonB) then
        stateManager:setCurrentState(self.prevState)
    elseif pd.buttonJustReleased(pd.kButtonA) then
        displayListMessage('Downloading puzzles...')
        local count, attempts, log = checkPuzzleDownload(self.currDate)
        if #log > 0 then
            local logFile = pd.file.open('downloadlog.txt', playdate.file.kFileWrite)
            for i = 1, #log do
                logFile:write(log[i] .. '\n')
            end
            logFile:close()
        end
        self.prevState.downloadMessage = 'Downloaded ' .. count .. ' of ' .. attempts .. ' puzzle file(s)'
        stateManager:setCurrentState(self.prevState)
    end
end