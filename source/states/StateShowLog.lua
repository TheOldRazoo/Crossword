
class('StateShowLog').extends(State)

local pd <const> = playdate
local gfx <const> = pd.graphics

function StateShowLog:init(currentDir, parentState)
    StateShowLog.super.init(self)
    self.currentDir = currentDir
    self.parentState = parentState
    self.firstTime = true
end

function StateShowLog:update()
    if self.firstTime then
        self.firstTime = false
        initScreen()
        clearScreen()
        local font = getListFont()
        local logFile = pd.file.open('downloadlog.txt', playdate.file.kFileRead)
        if logFile then
            local line = logFile:readline()
            local y = 0
            while line do
                font:drawText(line, 0, y)
                y += font:getHeight()
                line = logFile:readline()
            end
            logFile:close()
        else
            displayMessage('No log file found')
        end

        displayListMessage('Press A to return to puzzle list')
    end

    if playdate.buttonJustReleased(playdate.kButtonA) then
        stateManager:setCurrentState(StatePuz(self.currentDir, self.parentState))
    end
end
