
--get the addon object
local addonName, scriptLibrary = ...
local _

---@cast scriptLibrary scriptlibrary

local load = function(...) --lua 5.4
    return loadstring(...) --lua 5.1
end

--load Details! Framework
local detailsFramework = _G ["DetailsFramework"]
if (not detailsFramework) then
    print ("|cFFFFAA00RuntimeEditor: framework not found, if you just installed or updated the addon, please restart your client.|r")
    return
end

local functionPatternPrototype = "^%s-function%s-%((.-)%)(.-)end%s-$"
function scriptLibrary.CodeExec.IsFunctionNaked(funcString)
    return string.find(funcString,functionPatternPrototype) == nil
end

function scriptLibrary.CodeExec.Compile(scriptObject)
    local funcString = ""
    local funcName = scriptObject.Name
    local bFoundEntryPoint = false
    local bCompilePagesLeftToRight = true

    --build the function string by combining all the pages together
    local numPages = scriptLibrary.ScriptPages.GetNumPages(scriptObject)
    if (numPages > 1) then
        if (bCompilePagesLeftToRight) then --this compile the script from left to right
            local firstPage = scriptLibrary.ScriptPages.GetPage(scriptObject, 1)
            local firstPageCode = firstPage.Code

            if (not scriptLibrary.CodeExec.IsFunctionNaked(firstPageCode)) then
                local pattern = "function%s*%(.-%)%s*(.-)end%s*$"
                firstPageCode = firstPageCode:match(pattern)
            end

            funcString = firstPageCode .. " "

            for i = 2, numPages do
                local page = scriptLibrary.ScriptPages.GetPage(scriptObject, i)
                local pageCode = page.Code
                funcString = funcString .. pageCode .. " "
            end

            funcString = "function() " .. funcString .. " end"

        else --read the pages from right to left
            --not today
        end
    else
        local page = scriptLibrary.ScriptPages.GetPage(scriptObject, 1)
        funcString = page.Code
        if (scriptLibrary.CodeExec.IsFunctionNaked(funcString)) then
            funcString = "function() " .. funcString .. " end"
        end
    end

    local code = "return " .. funcString
    local compiledCode, errortext = load(code, "Compiling " .. (funcName or ""))

    if (not compiledCode) then
        scriptLibrary:Msg("failed to compile " .. (funcName or "") .. ": " .. errortext)
        return function()end
    else
        compiledCode = compiledCode()
    end

    if (type(compiledCode) ~= "function") then
        -- This should never happen really so error msg is not really important
        scriptLibrary:Msg("Internal error: failed to extract compiled function " .. (funcName or ""))
        return function()end
    end

    return compiledCode
end

function scriptLibrary.CodeExec.ExecuteCode()
    local scriptObject = scriptLibrary:GetCurrentScriptObject()
    if (not scriptObject) then
        return
    end

    scriptLibrary.ScriptObject.Save()

    --build function to run
    local functionToRun = scriptLibrary.CodeExec.Compile(scriptObject)
    if (not functionToRun) then
        return
    end

    --environment
    scriptLibrary.SetFunctionEnvironment(functionToRun)

    --run
    if (scriptObject.UseXPCall) then
        xpcall(functionToRun, geterrorhandler())
    else
        local okay, errortext = pcall(functionToRun)
        if (not okay) then
            scriptLibrary:Msg("Code |cFFAAAA22" .. scriptObject.Name .. "|r runtime error: " .. errortext)
        end
    end
end