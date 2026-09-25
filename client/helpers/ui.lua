---@diagnostic disable: undefined-global, undefined-field, trailing-space

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

return {
--	stamp = stamp,
	drawBorder = drawBorder,
	borderedPrint = borderedPrint,
	shortenString = shortenString,
	shortenNumber = shortenNumber
}