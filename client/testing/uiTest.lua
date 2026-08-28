---@diagnostic disable: undefined-global, undefined-field, trailing-space

local function stamp(x, y, character, background, foreground)
	assert(#character == 1)
	term.setCursorPos(x,y)
	term.blit(character, colors.toBlit(background), colors.toBlit(foreground))
end

local function drawBoarder(startX, startY, width, height, backgroundColor, foregroundColor)
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

term.clear()
local screenWidth, screenHeight = term.getSize()
drawBoarder(2, 2, screenWidth - 2, screenHeight - 2, colors.black, colors.white)