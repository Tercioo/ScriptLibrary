
local addonName, scriptLibrary = ...
local _

---@cast scriptLibrary scriptlibrary

--load Details! Framework
local DF = _G ["DetailsFramework"]
if (not DF) then
    print ("|cFFFFAA00RuntimeEditor: framework not found, if you just installed or updated the addon, please restart your client.|r")
    return
end

local upgradeVersion1ToVersion2 = function(scriptObject)
    --update the object from version 1 to version 2
    scriptObject.Version = 2

    --this version added script pages
    scriptObject.Pages = {}

    --create a default page
    ---@type scriptpage
    local newScriptPage = scriptLibrary.ScriptPages.CreateNewPage(scriptObject, "page 1")

    --transfer the code and other attributes to the new page
    newScriptPage.Code = scriptObject.Code
    newScriptPage.CursorPosition = scriptObject.CursorPosition
    newScriptPage.ScrollValue = scriptObject.ScrollValue

    scriptObject.Pages[1] = newScriptPage

    --delete the Code entry from the script object
    scriptObject.Code = nil
    scriptObject.CursorPosition = nil
    scriptObject.ScrollValue = nil
end

---iterate among all the saved objects and check if they need to be updated due to changes in the addon
---@param scriptObject scriptobject|nil
function scriptLibrary.CheckVersion(scriptObject)
    --get the addon version
    local currentVersion = scriptLibrary.Version

    if (scriptObject) then
        scriptObject.Version = scriptObject.Version or 1
        for versionId = scriptObject.Version, currentVersion do
            if (versionId == 1) then
                upgradeVersion1ToVersion2(scriptObject)
            end
        end
        return
    end

    --get the list of saved objects
    local data = scriptLibrary.GetData()

    for i = 1, #data do
        local thisObject = data[i]
        thisObject.Version = thisObject.Version or 1

        for versionId = thisObject.Version, currentVersion do
            if (versionId == 1) then
                upgradeVersion1ToVersion2(thisObject)
            end
        end
    end
end