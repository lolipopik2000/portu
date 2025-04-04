local Translator = {}

function Translator:Encode(str)
    str = str:gsub('([^%w%-%.%_%~])', function(c)
        return string.format('%%%02X', string.byte(c))
    end)

    return str
end

function Translator:Translate(input, isoCode)
    shared.info('Got translation request:',input,' |',isoCode)
    local enc =  Translator:Encode(input)
    local req = request({
        Url = 'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=' .. isoCode .. '&dt=t&q=' .. enc,
        Method = 'GET'
    })

    if req and req.StatusCode == 200 then
        local response = shared.HttpService:JSONDecode(req.Body)

        if response then
            local translations = response[1] 
            local fullTranslation = ''

            local lang = typeof(response[3]) == 'string' and response[3] or response[2]
            
            for _, translation in ipairs(translations) do
                fullTranslation = fullTranslation .. translation[1]
            end

            shared.info('Translated',input,'to',fullTranslation)
            shared.translating = false
            return {fullTranslation:match('^%s*(.-)%s*$'), lang}
        else
            shared.info('There was a critical error while translating:', req.StatusCode, response)
        end
    else
        shared.info('Google seems unreachable at the time')
    end
    
    return 'error'
end

return Translator
