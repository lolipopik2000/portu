shared.import = function(path)
    local import
    local success, res = pcall(function()
        import = loadstring(
            game:HttpGetAsync(
                ("https://raw.githubusercontent.com/%s/%s/%s"):format(shared.user, shared.repo, path)
            )
        )()
    end)

    if not success then error(res) end
    return import
end

shared.info = function(...)
    if shared.debugMode == true then return print('[DEBUG]',...) end
end

local Services = shared.import('modules/Services.lua')
Services:GetServices(
    {
        'HttpService',
        'Players',
        'Workspace',
        'ReplicatedStorage',
        'TextChatService',
        'StarterGui'
    }
)

local BloxstrapRPC = shared.import('modules/BloxstrapRPC.lua')
shared.BloxstrapRPC = BloxstrapRPC

local Connections = shared.import('modules/Connections.lua')

local ExploitSupport = shared.import('modules/ExploitSupport.lua')

if not ExploitSupport:Test(hookmetamethod, false) or not ExploitSupport:Test(hookfunction, false) or not ExploitSupport:Test(request, false) then
    error('Exploit is not supported!')
end

shared.info('Everything mandatory is now imported. Beginning...')

local isoCodes = shared.import('modules/isoCodes.lua')
shared.info('Currently supported isoCodes:', shared.HttpService:JSONEncode(shared.isoCodes))

shared.currentISOin = 'pt'
shared.translateIn = true
shared.currentISOout = 'ru'
shared.translateOut = true

local Translator = shared.import('modules/Translator.lua')
shared.Translator = Translator

local TestRequest = shared.Translator:Translate('Hallo', shared.currentISOout)
if TestRequest == 'error' then 
    error('Translation does not seem to work right now!')
end

shared.info('Translation is imported and working!')

local ChatHandler = shared.import('modules/ChatHandler.lua')
shared.ChatHandler = ChatHandler

shared.info('Starting hooks...')

shared.pending = false

function hookmetamethod(obj, met, func)
    setreadonly(getrawmetatable(game), false)
    local old = getrawmetatable(game).__namecall
    getrawmetatable(game).__namecall = newcclosure(function(self, ...)
        local args = {...}
        if getnamecallmethod() == met and self == obj and not checkcaller() and shared.pending == false then
            return func(unpack(args))
        end
        return old(self, ...)
    end)
    setreadonly(getrawmetatable(game), true)
end

local function handleTranslation(msg, isLocalPlayer)
    
    if isLocalPlayer then
        shared.currentISOin = 'ru'
        shared.currentISOout = 'pt'
    else
        
        shared.currentISOin = 'pt'
        shared.currentISOout = 'ru'
    end
    
    local result = ChatHandler:Handle(msg)
    shared.info('Got result from ChatHandler:', result)
    if result ~= nil and next(result) ~= nil then
        return result[1]
    end
    return msg
end

if shared.Players.LocalPlayer.PlayerGui:FindFirstChild('Chat') then 
    local events = shared.ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    local sayMessageRequest = events:FindFirstChild('SayMessageRequest') 
    assert(events, 'Chat events were not found!')
    assert(sayMessageRequest, 'Chat events were not found!')

    shared.info('Game is using old chat method...')

    function sayMsg(msg, to)
        shared.pending = true
        sayMessageRequest:FireServer(msg, to)
        shared.pending = false
    end

    events:WaitForChild("OnMessageDoneFiltering").OnClientEvent:Connect(function(data)
        if data == nil then return end
        if data.FromSpeaker == shared.Players.LocalPlayer.Name then return end 

        shared.info('Intercepted message:', data.Message, ' | ', data.FromSpeaker)

        local msg = data.Message

        if msg:sub(1, 3) == '>ru' then
            shared.currentISOin = 'ru'
            shared.currentISOout = 'ru'
            shared.info('Language set to Russian.')
            return
        elseif msg:sub(1, 3) == '>pt' then
            shared.currentISOin = 'pt'
            shared.currentISOout = 'pt'
            shared.info('Language set to Portuguese.')
            return
        end

        local result = handleTranslation(msg, false)

        if result ~= nil then
            ChatHandler.ChatNotify(`[Translation] {result}`)
        end
    end)

    hookmetamethod(sayMessageRequest, "FireServer", function(msg, to)
        shared.info('Intercepted message:', msg, ' | ', to)
        shared.pending = true
        local result = handleTranslation(msg, true)
        if result ~= nil then
            sayMsg(result, to)
        end
        shared.pending = false
        return
    end)
else
    local main_channel = shared.TextChatService.TextChannels.RBXGeneral

    assert(main_channel, 'Unable to find Main-Channel!')

    shared.info('Game is using new chat method...')

    main_channel.OnIncomingMessage = function(msg)
        if msg.Metadata == 'system' then return end 

        if msg.Text == '' then return end

        shared.info('Intercepted message:', msg.Text, ' | ', tostring(msg.TextSource))

        local md = ChatHandler.TextPrefixfromColor3(ChatHandler.getColorfromHash(tostring(msg.TextSource)))
        msg.PrefixText = `<font color="{md}">{tostring(msg.TextSource)}:</font>`

        local isSelf = tostring(msg.TextSource) == shared.Players.LocalPlayer.Name

        if isSelf then 
            local result = handleTranslation(msg.Text, true)
            shared.info('Got result from ChatHandler:', result)
            if result ~= nil and next(result) ~= nil then
                msg.Text = result
            else
                msg.Text = ''
            end
        else
            local result = handleTranslation(msg.Text, false)
            shared.info('Got result from ChatHandler:', result)
            if result ~= nil and next(result) ~= nil then
                local text = result
                task.delay(0.5, function()
                    main_channel:DisplaySystemMessage(`[Translation] {text}`, 'system')
                end)
            end
        end
        shared.pending = false
    end
end

shared.StarterGui:SetCore('SendNotification',{
    Title = 'Chat-Translator', 
    Text = 'The Translator is initiated and running!', 
})
