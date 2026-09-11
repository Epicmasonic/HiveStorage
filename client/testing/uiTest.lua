---@diagnostic disable: undefined-global, undefined-field, trailing-space

---------------------------------------------------
--                     Setup                     --
---------------------------------------------------

local myName
if os.getComputerLabel() then
	myName = os.getComputerLabel()
else
	myName = "Computer ID "..textutils.serialize(os.getComputerID())
end

rednet.open("back")
rednet.broadcast(
	{
		sender = myName,
		command = "getStock"
	},
	"HiveStorage"
)
local message
repeat
	_, message = rednet.receive("HiveStorage")
until message and message.arguments.successful == "getStock"
rednet.close()
local itemList = message.arguments.returnValue
table.sort(itemList, function (a, b)
	return a.count > b.count
end)

---------------------------------------------------
--               Helper functions                --
---------------------------------------------------

local function stamp(x, y, character, backgroundColor, foregroundColor)
	assert(#character == 1)
	term.setCursorPos(x,y)
	term.blit(character, colors.toBlit(backgroundColor), colors.toBlit(foregroundColor))
end

local function drawBorder(startX, startY, width, height, backgroundColor, foregroundColor)
	local screenWidth, screenHeight = term.getSize()
	assert(1 <= startX and startX <= screenWidth)
	assert(1 <= startY and startY <= screenHeight)
	assert(1 < width and width <= screenWidth - startX + 1)
	assert(1 < height and height <= screenHeight - startY + 1)
	
	if not backgroundColor then
		backgroundColor = term.getBackgroundColor()
	end
	if not foregroundColor then
		foregroundColor = term.getTextColor()
	end
	
	local oldX, oldY = term.getCursorPos()

	-- Top line
	stamp(startX, startY, "\x9C", foregroundColor, backgroundColor)
	for i = 1, width - 2 do
		stamp(startX + i, startY, "\x8C", foregroundColor, backgroundColor)
	end
	stamp(startX + width - 1, startY, "\x93", backgroundColor, foregroundColor)
	
	-- Side lines
	for i = 1, height - 2 do
		stamp(startX, startY + i, "\x95", foregroundColor, backgroundColor)
		stamp(startX + width - 1, startY + i, "\x95", backgroundColor, foregroundColor)
	end
	
	-- Bottom line
	stamp(startX, startY + height - 1, "\x8D", foregroundColor, backgroundColor)
	for i = 1, width - 2 do
		stamp(startX + i, startY + height - 1, "\x8C", foregroundColor, backgroundColor)
	end
	stamp(startX + width - 1, startY + height - 1, "\x8E", foregroundColor, backgroundColor)
	
	term.setCursorPos(oldX, oldY)
end

local function borderedPrint(startX, width, line, message, backgroundColor, foregroundColor)
	local screenWidth, screenHeight = term.getSize()
	assert(1 <= startX and startX <= screenWidth)
	assert(1 < width and width <= screenWidth - startX + 1)
	assert(1 <= line and line <= screenHeight)
	assert(1 <= #message and #message <= width - 2)
	
	if not backgroundColor then
		backgroundColor = term.getBackgroundColor()
	end
	if not foregroundColor then
		foregroundColor = term.getTextColor()
	end
	
	local oldX, oldY = term.getCursorPos()
	
	stamp(startX, line, "\x95", foregroundColor, backgroundColor)
	stamp(startX + width - 1, line, "\x95", backgroundColor, foregroundColor)
	term.setCursorPos(startX + 1, line)
	write(message)
	
	term.setCursorPos(oldX, oldY)
end

local function shortenString(message, maxLength)
	if #message <= maxLength then
		while #message < maxLength do
			message = message.." "
		end
		return message
	end
	
	local shortString = ""
	for i = 1, #message do
		if #shortString + 3 >= maxLength then
			return shortString.."..."
		end
		shortString = shortString..string.sub(message, i, i)
	end
	return shortString -- Should never run?
end

local function shortenNumber(amount, size)
	if type(amount) ~= "number" then return "    " end
	if not size then size = " " end
	
	if amount >= 1000 then
		amount = math.floor(amount / 1000)
		if size == " " then
			return shortenNumber(amount, "K")
		elseif size == "K" then
			return shortenNumber(amount, "M")
		elseif size == "M" then
			return shortenNumber(amount, "B")
		elseif size == "B" then
			return shortenNumber(amount, "T")
		else
			return "LOTS"
		end
	end
	
	local amountString
	if amount >= 100 then
		amountString = textutils.serialize(amount)..size
	elseif amount >= 10 then
		amountString = " "..textutils.serialize(amount)..size
	else
		amountString = "  "..textutils.serialize(amount)..size
	end

	if size == " " then
		return " "..string.sub(amountString, 1, 3)
	else
		return amountString
	end
end

local function printItemOverview(line, width, name, amount, selected)
	if type(name) ~= "string" then name = textutils.serialize(name) end
	if selected then name = ">"..name end
	
	borderedPrint(2, width, line + 2, shortenString(name, width - 7).."|"..shortenNumber(amount))
end

local function drawFullItemOverview(startX, startY, width, height, items, selected)
	drawBorder(startX, startY, width, height)
	local pageSize = height - 2
	local currentPage = math.floor((selected - 1) / pageSize)
	local pageOffset = currentPage * pageSize
	
	local modifyedSelected = selected % pageSize
	if modifyedSelected == 0 then modifyedSelected = pageSize end
	
	for i = 1, pageSize do
		-- printItemOverview(i, width, textutils.serialize(modifyedSelected), 1, i == selected)
		local item = items[i + pageOffset]
		
		if item then
			printItemOverview(i, width, item.displayName, item.count, i == modifyedSelected)
		else
			printItemOverview(i, width, "", nil, false)
		end
	end
end

---------------------------------------------------
--       The stuff that will actually run        --
---------------------------------------------------

term.clear()
local screenWidth, screenHeight = term.getSize()
local currentSelection = 1

while true do
	term.clear()
	drawFullItemOverview(2, 2, screenWidth - 2, screenHeight - 2, itemList, currentSelection)

	-- Wait for a key press event
	local event, param = os.pullEvent("key")

	-- Check which key was pressed
	if param == keys.q then
		term.setCursorPos(1, screenHeight)
		write("Quitting program.")
		sleep(1)
		break
	elseif param == keys.r then
		term.setCursorPos(1, screenHeight)
		write("Rebooting.")
		sleep(1)
		os.reboot()
	elseif param == keys.up then
		currentSelection = currentSelection - 1
		if currentSelection <= 0 then currentSelection = #itemList end
	elseif param == keys.down then
		currentSelection = currentSelection + 1
		if currentSelection > #itemList then currentSelection = 1 end
--	elseif param == keys.left then
--		currentSelection = currentSelection - (screenHeight - 4)
--		if currentSelection <= 0 then currentSelection = #itemList end
--	elseif param == keys.right then
--		currentSelection = currentSelection + (screenHeight - 4)
--		if currentSelection > #itemList then currentSelection = 1 end
	elseif param == keys.f then
		rednet.open("back")
		rednet.broadcast(
			{
				sender = myName,
				command = "emptyPocket"
			},
			"HiveStorage"
		)
		rednet.close()
		
		term.setCursorPos(1, screenHeight)
		write("Emptied the pocket")
		sleep(1)
	else
		term.setCursorPos(1, screenHeight)
		write(shortenString("Key code pressed: " .. keys.getName(param), screenWidth))
		sleep(1)
	end
end

term.clear()
term.setCursorPos(1, 1)