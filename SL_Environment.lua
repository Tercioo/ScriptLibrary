
--get the addon object
local addonName, scriptLibrary = ...
local _

--load Details! Framework
local detailsFramework = _G ["DetailsFramework"]
if (not detailsFramework) then
    print ("|cFFFFAA00RuntimeEditor: framework not found, if you just installed or updated the addon, please restart your client.|r")
    return
end

local setfenv = setfenv
local _ENV = {}

local forbiddenFunction = {
    --block mail, trades, action house, banks
    ["C_AuctionHouse"] 	= true,
    ["C_Bank"] = true,
    ["C_GuildBank"] = true,
    ["SetSendMailMoney"] = true,
    ["SendMail"]		= true,
    ["SetTradeMoney"]	= true,
    ["AddTradeMoney"]	= true,
    ["PickupTradeMoney"]	= true,
    ["PickupPlayerMoney"]	= true,
    ["AcceptTrade"]		= true,

    --frames
    ["BankFrame"] 		= true,
    ["TradeFrame"]		= true,
    ["GuildBankFrame"] 	= true,
    ["MailFrame"]		= true,
    ["EnumerateFrames"] = true,

    --block run code inside code
    ["RunScript"] = true,
    ["securecall"] = true,
    ["setfenv"] = true,
    ["getfenv"] = true,
    ["loadstring"] = true,
    ["pcall"] = true,
    ["xpcall"] = true,
    ["getglobal"] = true,
    ["setmetatable"] = true,
    ["DevTools_DumpCommand"] = true,
    ["ChatEdit_SendText"] = true,

    --avoid creating macros
    ["SetBindingMacro"] = true,
    ["CreateMacro"] = true,
    ["EditMacro"] = true,
    ["hash_SlashCmdList"] = true,
    ["SlashCmdList"] = true,

    --block guild commands
    ["GuildDisband"] = true,
    ["GuildUninvite"] = true,

    --other things
    ["C_GMTicketInfo"] = true,

    --deny messing addons with script support
    ["PlaterDB"] = true,
    ["_detalhes_global"] = true,
    ["WeakAurasSaved"] = true,
}

local C_RestrictedSubFunctions = {
    ["C_GuildInfo"] = {
        ["RemoveFromGuild"] = true,
    },
}


local C_SubFunctionsTable = {}
for globalTableName, functionTable in pairs(C_RestrictedSubFunctions) do
    C_SubFunctionsTable[globalTableName] = {}
    for functionName, functionObject in pairs(_G[globalTableName]) do
        if (not functionTable[functionName]) then
            C_SubFunctionsTable[globalTableName][functionName] = functionObject
        end
    end
end

local secureScriptEnvironmentHandle = {
    __index = function(env, key)
        if (forbiddenFunction[key]) then
            return nil

        elseif (key == "_G") then
            --return env
            return _G

        elseif (C_SubFunctionsTable[key]) then
            return C_SubFunctionsTable[key]
        end

        return _G[key]
    end
}

setmetatable(_ENV, secureScriptEnvironmentHandle)

scriptLibrary.SetFunctionEnvironment = function(func)
    setfenv(func, _ENV)
end