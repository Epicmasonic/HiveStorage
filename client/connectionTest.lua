---@diagnostic disable: undefined-global, undefined-field, trailing-space

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
		command = "ping"
	},
	"HiveStorage")

local started = os.epoch("utc")
local id, message

repeat
	local remaining = 1000 - (os.epoch("utc") - started)
	if remaining <= 0 then
		break
	end
	
	id, message = rednet.receive("HiveStorage", remaining / 1000)
until message and message.arguments.successful == "ping"

local finished = os.epoch("utc") - started

if message and message.arguments.successful == "ping" then
	print("Reached the server (Computer ID "..(id or "was missing?")..") in "..finished.." ms")
else
	print("Failed to reach the server :(")
end

rednet.close()