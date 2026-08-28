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
		command = "emptyPocket"
	},
	"HiveStorage"
)
rednet.close()
