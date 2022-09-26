
--get the addon object
local addonName, scriptLibrary = ...
local _

--load Details! Framework
local DF = _G ["DetailsFramework"]
if (not DF) then
    print ("|cFFFFAA00RuntimeEditor: framework not found, if you just installed or updated the addon, please restart your client.|r")
    return
end

local functionPatternPrototype = "^%s-function%s-%((.-)%)(.-)end%s-$"
function scriptLibrary.IsFunctionNaked(funcString)
    return string.find(funcString,functionPatternPrototype) == nil
end

function scriptLibrary.Compile(funcString, funcName)
    local functionIsNaked = scriptLibrary.IsFunctionNaked(funcString)
    if(functionIsNaked)then
        funcString = "function(...) "..funcString.." end"
    end

    local code = "return " .. funcString
    local compiledCode, errortext = loadstring(code, "Compiling " .. (funcName or ""))

    if (not compiledCode) then
        scriptLibrary:Msg("failed to compile " .. (funcName or "") .. ": " .. errortext)
        return
    else
        compiledCode = compiledCode()
    end

    if (type(compiledCode) ~= "function") then
        -- This should never happen really so error msg is not really important
        scriptLibrary:Msg("Internal error: failed to extract compiled function " .. (funcName or ""))
        return
    end

    return compiledCode
end

function scriptLibrary.ReplaceCode()
    scriptLibrary.ExecuteCode(true)
end

function scriptLibrary.ExecuteCode(onlyReplace)
    if (not scriptLibrary.CurrentScriptObject) then
        return
    end

    if (type(onlyReplace) ~= "boolean") then
        onlyReplace = nil
    end

    scriptLibrary.SaveCode()

    --build function to run
    local functionToRun = scriptLibrary.Compile(scriptLibrary.CurrentScriptObject.Code, scriptLibrary.CurrentScriptObject.Name)
    if (not functionToRun) then
        return
    end

    --build arguments
    local argumentsFunc = scriptLibrary.Compile(scriptLibrary.CurrentScriptObject.Arguments, "Building Arguments for " .. scriptLibrary.CurrentScriptObject.Name)
    if (not argumentsFunc) then
        return
    end

    local addonName = scriptLibrary.CurrentScriptObject.AddonName
    local functionName = scriptLibrary.CurrentScriptObject.FunctionName

    if (addonName ~= "" and _G[addonName]) then
        if (type (_G[addonName]) == "function") then
            _G[addonName] = functionToRun

        elseif (functionName ~= "") then
            if (type (_G[addonName]) == "table") then
                _G[addonName][functionName] = functionToRun
            end
        end
    else
        if (addonName ~= "") then
            scriptLibrary:Msg("global object or global function not found.")
        end
    end

    --run
    if (not onlyReplace) then
        local okay, errortext = pcall(functionToRun, argumentsFunc())
        if (not okay) then
            scriptLibrary:Msg("Code |cFFAAAA22" .. scriptLibrary.CurrentScriptObject.Name .. "|r runtime error: " .. errortext)
        end
    end
end

function scriptLibrary.Reload()
    scriptLibrary.SaveCode()
    local config = scriptLibrary.GetConfig()
    config.auto_open = true
    ReloadUI()
end

function scriptLibrary.SaveCode()
    if (not scriptLibrary.CurrentScriptObject) then
        return
    end

    local f = scriptLibrary.MainFrame
    local cursorPosition = f.CodeEditor.editbox:GetCursorPosition()
    scriptLibrary.CurrentScriptObject.Name = f.CodeNameTextEntry:GetText()
    scriptLibrary.CurrentScriptObject.Icon = f.CodeIconButton:GetIconTexture()
    scriptLibrary.CurrentScriptObject.Desc = f.codeDescTextentry:GetText()
    scriptLibrary.CurrentScriptObject.Code = f.CodeEditor:GetText()
    scriptLibrary.CurrentScriptObject.Time = time()
    scriptLibrary.CurrentScriptObject.AutoRun = f.CodeAutorunCheckbox:GetValue()
    scriptLibrary.CurrentScriptObject.CursorPosition = cursorPosition
    scriptLibrary.CurrentScriptObject.ScrollValue = f.CodeEditor.scroll:GetVerticalScroll()

    scriptLibrary.CurrentScriptObject.Revision = scriptLibrary.CurrentScriptObject.Revision + 1
    scriptLibrary.CurrentScriptObject.AddonName = f.AddonNameTextEntry:GetText()
    scriptLibrary.CurrentScriptObject.FunctionName = f.FunctionNameTextEntry:GetText()
    scriptLibrary.CurrentScriptObject.Arguments = f.ArgumentsTextEntry:GetText()

    f.CodeNameTextEntry:ClearFocus()
    f.codeDescTextentry:ClearFocus()
    f.CodeEditor:ClearFocus()
    f.AddonNameTextEntry:ClearFocus()
    f.FunctionNameTextEntry:ClearFocus()
    f.ArgumentsTextEntry:ClearFocus()

    --refresh the scroll to update name and icon
    scriptLibrary.MainFrame.CodeSelectionScrollBox:Refresh()
end