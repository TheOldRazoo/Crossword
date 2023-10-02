
local pd <const> = playdate
local pdfile <const> = pd.file

local function cksumRegion(data, start, len, cksum)
    for i = 1, len do
        cksum = cksum & 0xffff
        if cksum & 0x0001 == 1 then
            cksum = (cksum >> 1) + 0x8000
        else
            cksum = cksum >> 1
        end

        cksum += string.unpack("b", data, start + i - 1)
    end

    return cksum
end

local zeroByte <const> = string.pack("b", 0)

local function calcCheckSum(fileData, puz)
    local cksum = cksumRegion(fileData, 0x0f, 8, 0)
    cksum = cksumRegion(fileData, 0x35, puz.width * puz.height * 2, cksum)
    if #puz.title > 0 then
        cksum = cksumRegion(puz.title, 1, #puz.title, cksum)
        cksum = cksumRegion(zeroByte, 1, 1, cksum)
    end

    if #puz.author > 0 then
        cksum = cksumRegion(puz.author, 1, #puz.author, cksum)
        cksum = cksumRegion(zeroByte, 1, 1, cksum)
    end

    if #puz.copyright > 0 then
        cksum = cksumRegion(puz.copyright, 1, #puz.copyright, cksum)
        cksum = cksumRegion(zeroByte, 1, 1, cksum)
    end

    for i = 1, puz.numclues do
        cksum = cksumRegion(puz.clues[i], 1, #puz.clues[i], cksum)
    end

    if #puz.notes > 0 then
        cksum = cksumRegion(puz.notes, 1, #puz.notes, cksum)
        cksum = cksumRegion(zeroByte, 1, 1, cksum)
    end

    return cksum
end

function fromRowCol(row, col)
    return row * 1000 + col
end

function toRowCol(rowcol)
    return rowcol // 1000, rowcol % 1000
end

function loadPuzzleFile(name)
    local file, err = pdfile.open(name)
    if file == nil then
        return nil, err
    end

    local fileSize = pdfile.getSize(name)
    local fileData = file:read(fileSize)
    local puz = {}
    puz.chksum = string.unpack("<I2", fileData, 1)
    puz.version = string.unpack("z", fileData, 25)
    puz.width = string.unpack("I1", fileData, 45)
    puz.height = string.unpack("I1", fileData, 46)
    puz.numclues = string.unpack("<I2", fileData, 47)

    puz.solution = {}
    puz.grid = {}
    local solutionRow = {}
    local gridRow = {}
    local pos = 53
    for i = 1, puz.height do
        for j = 1, puz.width do
            solutionRow[j], pos = string.unpack("c1", fileData, pos)
            if solutionRow[j] == '.' then
                gridRow[j] = '.'
            else
                gridRow[j] = ' '
            end
        end

        puz.solution[i] = solutionRow
        puz.grid[i] = gridRow
        solutionRow, gridRow = {}, {}
    end

    pos += puz.width * puz.height
    puz.title, pos = string.unpack("z", fileData, pos)
    puz.author, pos = string.unpack("z", fileData, pos)
    puz.copyright, pos = string.unpack("z", fileData, pos)

    puz.clues = {}
    for i = 1, puz.numclues do
        puz.clues[i], pos = string.unpack("z", fileData, pos)
    end

    puz.notes, pos = string.unpack("z", fileData, pos)

    local acrossClue, downClue = {}, {}
    local clueNum = 1
    local clueUsed = false
    for i = 1, puz.height do
        for j = 1, puz.width do
            if needsAcrossNumber(puz, i, j) then
                acrossClue[#acrossClue + 1] = { clueNum, fromRowCol(i, j) }
                clueUsed = true
            end

            if needsDownNumber(puz, i, j) then
                downClue[#downClue + 1] = { clueNum, fromRowCol(i, j) }
                clueUsed = true
            end

            if clueUsed then
                clueNum += 1
                clueUsed = false
            end
        end
    end

    for i = 1, #acrossClue do
        table.insert(acrossClue[i], i)
    end

    for i = 1, #downClue do
        table.insert(downClue[i], i + #acrossClue)
    end

    puz.acrossClue = acrossClue
    puz.downClue = downClue

    local cksum = calcCheckSum(fileData, puz)

    file:close()
    return puz, nil
end

function loadPuzzleInfo(name)
    local file, err = pdfile.open(name)
    if file == nil then
        return nil, err
    end

    local fileSize = pdfile.getSize(name)
    local fileData = file:read(fileSize)
    local puz = {}
    puz.chksum = string.unpack("<I2", fileData, 1)
    puz.version = string.unpack("z", fileData, 25)
    puz.width = string.unpack("I1", fileData, 45)
    puz.height = string.unpack("I1", fileData, 46)

    local pos = 53 + puz.width * puz.height * 2
    puz.title, pos = string.unpack("z", fileData, pos)
    puz.author, pos = string.unpack("z", fileData, pos)
    puz.copyright, pos = string.unpack("z", fileData, pos)
    file:close()
    return puz, nil
end

-- get the clue number for a cell, if any.
-- returns clue number or nil for none
function getClueNumber(puz, row, col)
    local rowcol = fromRowCol(row, col)
    for i = 1, #puz.acrossClue do
        if rowcol == puz.acrossClue[i][2] then
            return puz.acrossClue[i][1]
        end
    end

    for i = 1, #puz.downClue do
        if rowcol == puz.downClue[i][2] then
            return puz.downClue[i][1]
        end
    end

    return nil
end

-- determine if the passed cell needs an across clue number.
-- return true or false.
function needsAcrossNumber(puz, row, col)
    return puz.grid[row][col] ~= '.'
            and (col == 1 or puz.grid[row][col - 1] == '.')
            and col + 1 < puz.width
            and puz.grid[row][col + 1] ~= '.'
end

-- determine if the passed cell needs a down clue number.
-- return true or false.
function needsDownNumber(puz, row, col)
    return puz.grid[row][col] ~= '.'
            and (row == 1 or puz.grid[row - 1][col] == '.')
            and row + 1 < puz.height
            and puz.grid[row + 1][col] ~= '.'
end

-- find the start and end cell for an across word.  returns two
-- rowcol integers representing the bounds of the word.  returns
-- nil if the passed cell is not part of an across word.
function findAcrossWord(puz, row, col)
    local startRowCol, endRowCol = nil, nil
    if puz.solution[row][col] == '.' then
        return startRowCol, endRowCol
    end

    if needsAcrossNumber(puz, row, col) then
        startRowCol = fromRowCol(row, col)
    else
        local c = col
        while true do
            c -= 1
            if needsAcrossNumber(puz, row, c) then
                startRowCol = fromRowCol(row, c)
                break
            end

            if c == 1 or puz.solution[row][c] == '.' then
                break
            end
        end
    end

    if startRowCol then
        for c = col, puz.width + 1 do
            if puz.solution[row][c] == '.' then
                endRowCol = fromRowCol(row, c - 1)
                break
            end

            if c == puz.width then
                endRowCol = fromRowCol(row, c)
                break
            end
        end
    end

    return startRowCol, endRowCol
end

-- find the start and end cell for a down word.  returns two
-- rowcol integers representing the bounds of the word.  returns
-- nil if the passed cell is not part of a down word.
function findDownWord(puz, row, col)
    local startRowCol, endRowCol = nil, nil
    if puz.solution[row][col] == '.' then
        return startRowCol, endRowCol
    end

    if needsDownNumber(puz, row, col) then
        startRowCol = fromRowCol(row, col)
    else
        local r = row
        while true do
            r -= 1
            if needsDownNumber(puz, r, col) then
                startRowCol = fromRowCol(r, col)
                break
            end

            if r == 1 or puz.solution[r][col] == '.' then
                break
            end
        end
    end

    if startRowCol then
        for r = row, puz.height + 1 do
            if puz.solution[r][col] == '.' then
                endRowCol = fromRowCol(r - 1, col)
                break
            end

            if r == puz.height then
                endRowCol = fromRowCol(r, col)
                break
            end
        end
    end

    return startRowCol, endRowCol
end

function isLetterCell(puz, row, col)
    if row > puz.height or row < 1 or col > puz.width or col < 1 then
        return false
    end

    return puz.grid[row][col] ~= '.'
end

function findNextWord(puz, row, col, across)
    if col > puz.width or col < 1 then
        col = 1
        row += 1
    end
    if row > puz.height or row < 1 then
        row = 1
    end

    while true do
        if across and needsAcrossNumber(puz, row, col) then
            return row, col, across
        end

        if not across and needsDownNumber(puz, row, col) then
            return row, col, across
        end

        col += 1
        if col > puz.width then
            col = 1
            row += 1
            if row > puz.height then
                across = not across
                row = 1
            end
        end
    end
end

function findPrevWord(puz, row, col, across)
    if col > puz.width or col < 1 then
        col = puz.width
        row -= 1
    end
    if row > puz.height or row < 1 then
        row = puz.height
    end

    while true do
        if across and needsAcrossNumber(puz, row, col) then
            return row, col, across
        end

        if not across and needsDownNumber(puz, row, col) then
            return row, col, across
        end

        col -= 1
        if col < 1 then
            col = puz.width
            row -= 1
            if row < 1 then
                across = not across
                row = puz.height
            end
        end
    end
end