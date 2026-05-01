motdWindow = nil
local OPCODE_ID = 86

function init()
	connect(g_game, {
		onGameStart = online,
		onGameEnd = offline,
		onTextMessage = onTextMessage
	})
	ProtocolGame.registerExtendedOpcode(OPCODE_ID, onExtendedOpcode)
	scheduleEvent(function ()
		autoRequestStorage()
	end, 100)

	motdWindow = g_ui.displayUI("motd")

	motdWindow:hide()
end

function terminate()
	disconnect(g_game, {
		onGameStart = online,
		onGameEnd = offline,
		onTextMessage = onTextMessage
	})
	ProtocolGame.unregisterExtendedOpcode(OPCODE_ID, onExtendedOpcode)
	scheduleEvent(function ()
		autoRequestStorage()
	end, 100)
	offline()

	if motdWindow then
		motdWindow:destroy()
	end
end

function toggle()
	if not motdWindow then
		motdWindow = g_ui.displayUI("motd")

		motdWindow:hide()
	end

	if motdWindow:isVisible() then
		motdWindow:hide()
	else
		motdWindow:show()
		autoRequestStorage()
	end
end

function offline()
	if motdWindow then
		motdWindow:destroy()

		motdWindow = nil
	end
end

function onTextMessage(mode, text)
	if text:lower() == "!motd" then
		toggle()

		return true
	end
end

function autoRequestStorage()
	local protocolGame = g_game.getProtocolGame()

	if not protocolGame then
		return
	end

	protocolGame:sendExtendedOpcode(OPCODE_ID, "request")

	if not motdWindow or not motdWindow:isVisible() then
		return
	end
end

function onExtendedOpcode(protocol, opcode, buffer)
	if opcode ~= OPCODE_ID then
		return
	end

	local ok, data = pcall(function ()
		return json.decode(buffer)
	end)

	if not ok then
		return
	end

	if not motdWindow then
		motdWindow = g_ui.displayUI("motd")
	end

	local motdText = motdWindow:getChildById("motdText")

	if motdText then
		local displayText = data.motdText:gsub("\\n", "<br>")

		motdText:setText(displayText)
	end
end
