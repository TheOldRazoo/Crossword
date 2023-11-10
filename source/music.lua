
local musicDir <const> = '/music/'
local filePlayer <const> = playdate.sound.fileplayer.new()

function musicInit()
    if not playdate.file.isdir(musicDir) then
        playdate.file.mkdir(musicDir)
    end

    local musicFiles = playdate.file.listFiles(musicDir)
    if musicFiles and #musicFiles > 0 then
        local matchCount = 0
        for i = 1, #musicFiles do
            if string.find(musicFiles[i], '%.[mM][pP]3$') then
                musicFiles[i] = musicDir .. musicFiles[i]
                matchCount += 1
            else
                musicFiles[i] = nil
            end
        end

        if matchCount > 0 then
            local i = math.random(#musicFiles)
            while musicFiles[i] == nil do
                i = math.random(#musicFiles)
            end

            -- load the music file
            filePlayer:load(musicFiles[i])
        end
    end

    return
end

function musicPlay()
    if not filePlayer:isPlaying() then
        filePlayer:play(0)
    end

    return
end

function musicStop()
    if filePlayer:isPlaying() then
        filePlayer:stop()
    end

    return
end