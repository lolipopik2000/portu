local ChatHandler = {}
shared.prefix = '>'

function ChatHandler.ValidISO(input)
    return table.find(shared.isoCodes, input) ~= nil
end

function ChatHandler.ChatNotify(message, color, Size)
    shared.StarterGui:SetCore("ChatMakeSystemMessage", {
        Text = message,
        Color = color or Color3.fromRGB(255, 255, 255),
        Font = Enum.Font.SourceSans,
        FontSize = Size or Enum.FontSize.Size48
    })
end

function ChatHandler.GetState(arg)
    local pos = {
        'on',
        'true',
        '1'
    }

    return table.find(pos, string.lower(arg)) ~= nil
end

local colors = -- THANK YOU :D
{
	Color3.new(253/255, 41/255, 67/255), 
	Color3.new(1/255, 162/255, 255/255), 
	Color3.new(2/255, 184/255, 87/255), 
	BrickColor.new("Bright violet").Color,
	BrickColor.new("Bright orange").Color,
	BrickColor.new("Bright yellow").Color,
	BrickColor.new("Light reddish violet").Color,
	BrickColor.new("Brick yellow").Color,
}

function ChatHandler.getNameHash(name)
	local value = 0
	for i = 1, #name do
		local colorValue = string.byte(string.sub(name, i, i))
		local reverseIndex = #name - i + 1
		if #name%2 == 1 then
			reverseIndex = reverseIndex - 1
		end
		if reverseIndex%4 >= 2 then
			colorValue = -colorValue
	end
		value = value + colorValue
	end
	return value
end

function ChatHandler.getColorfromHash(name)
	return colors[((ChatHandler.getNameHash(name) + 0) % #colors) + 1]
end

function ChatHandler.TextPrefixfromColor3(color)
    local r = math.floor(color.R * 255)
    local g = math.floor(color.G * 255)
    local b = math.floor(color.B * 255)
    return string.format("rgb(%d,%d,%d)", r, g, b)
end

function ChatHandler.HandleCommand(input)
    input = string.gsub(input, '>', '')
    local args = string.split(input, ' ')
    local command = string.lower(args[1])
    table.remove(args, 1)
    shared.info('Handling command:',command,' | ',args[1],args[2])

    if command == 'out' and ChatHandler.ValidISO(string.lower(args[1])) then
        shared.currentISOout = string.lower(args[1])
        shared.info('Output language has been set to:',shared.currentISOout)
        shared.StarterGui:SetCore('SendNotification',{
            Title = 'Output Language', 
            Text = 'Has been changed to: '..shared.currentISOout, 
        })
    end

    if command == 'in' and ChatHandler.ValidISO(string.lower(args[1])) then
        shared.currentISOin = string.lower(args[1])
        shared.info('Input language has been set to:',shared.currentISOin)
        shared.StarterGui:SetCore('SendNotification',{
            Title = 'Input Language', 
            Text = 'Has been changed to: '..shared.currentISOin, 
        })
    end

    if command == 'set' then 
        local state = ChatHandler.GetState(args[2])
        if state == nil then return end 

        if string.lower(args[1]) == 'in' then 
            shared.translateIn = state
            shared.info('Input has been set to',tostring(state))
            shared.StarterGui:SetCore('SendNotification',{
                Title = 'Incoming Messages', 
                Text = 'Incoming Messages '..(state and 'will' or 'will not')..' be translated!', 
            })
        elseif string.lower(args[1]) == 'out' then 
            shared.translateOut = state
            shared.info('Output has been set to',tostring(state))
            shared.StarterGui:SetCore('SendNotification',{
                Title = 'Outgoing Messages', 
                Text = 'Outgoing Messages '..(state and 'will' or 'will not')..' be translated!', 
            })
        end
    end
end

function ChatHandler.HandleTranslation(message, isself)
    if shared.Translator == nil then error('Unable to get Translator!') end
    isself = isself == nil and true or isself
    shared.info('Got HandleTranslation request:',message,' | ',tostring(isself))

    if isself and shared.translateOut then 
        message = shared.Translator:Translate(message, shared.currentISOout)
    elseif isself == false and shared.translateIn then
        message = shared.Translator:Translate(message, shared.currentISOin)
    end

    return message
end

function ChatHandler:Handle(message, speaker)
    message = string.gsub(message, "&gt;", ">")
	message = string.gsub(message, "&lt;", "<")

    shared.info('Handling:',message)
    local result = nil
    local isCommand = string.sub(message, 1, 1) == '>'
    local isSelf = speaker

    if isCommand then 
        ChatHandler.HandleCommand(message)
    else
        result = ChatHandler.HandleTranslation(message, isSelf)
    end

    return result
end


return ChatHandler
