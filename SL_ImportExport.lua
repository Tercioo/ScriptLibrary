
--get the addon object
local addonName, scriptLibrary = ...
local _

---@cast scriptLibrary scriptlibrary

--load Details! Framework
local DF = _G ["DetailsFramework"]
if (not DF) then
    print ("|cFFFFAA00RuntimeEditor: framework not found, if you just installed or updated the addon, please restart your client.|r")
    return
end

--templates
local options_text_template = DF:GetTemplate("font", "OPTIONS_FONT_TEMPLATE")
local options_button_template = DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")

--create on demand the import frame
--this function only creates the frame, the logic on opening the frame is below this function
local createImportExportFrame = function()
    local mainFrame = scriptLibrary.GetMainFrame()
    local codeEditorFrameSettings = scriptLibrary.FrameSettings.settingsCodeEditor
    local buttonsFrameSettings = scriptLibrary.FrameSettings.settingsButtons

    local importExportFrame = _G.CreateFrame("frame", "$parentImportExport", mainFrame)
    importExportFrame:SetSize(1, 1)
    importExportFrame:SetPoint("topleft", mainFrame, "topleft", codeEditorFrameSettings.pointX, codeEditorFrameSettings.pointY)
    mainFrame.importExportFrame = importExportFrame

    --register into the window stack
    local onShow = function()
    end
    local onHide = function()
    end

    --window name, frame object, stack, show callback, hide callback
    scriptLibrary.Windows.RegisterFrame("importExportFrame", importExportFrame, scriptLibrary.FrameStack.importExportFrame, onShow, onHide)

    --editor
    local bigTextEditor = DF:NewSpecialLuaEditorEntry(importExportFrame, codeEditorFrameSettings.width, codeEditorFrameSettings.height, "ImportExportEditor", "$parentImportExportEditor", true, false)
    bigTextEditor:SetPoint("topleft", importExportFrame, "topleft", 0, 0)
    mainFrame.importExportEditor = bigTextEditor

    bigTextEditor.editbox:SetScript("OnEscapePressed", function()
        scriptLibrary.CancelImportingOrExporting()
    end)

    --apply a different skin into the code editor
    scriptLibrary.Windows.ApplyEditorLayout(bigTextEditor)

    --okay and cancel buttons
    local okayButton = DF:CreateButton(importExportFrame, scriptLibrary.ImportScript, buttonsFrameSettings.width, buttonsFrameSettings.height, "Okay", -1, nil, nil, nil, nil, nil, options_button_template, options_text_template)
    local cancelButton = DF:CreateButton(importExportFrame, scriptLibrary.CancelImportingOrExporting, buttonsFrameSettings.width, buttonsFrameSettings.height, "Cancel", -1, nil, nil, nil, nil, nil, options_button_template, options_text_template)
    --these are the same icons used on import stuff on Plater
    okayButton:SetIcon([[Interface\BUTTONS\UI-Panel-BiggerButton-Up]], 20, 20, "overlay", {0.1, .9, 0.1, .9})
    cancelButton:SetIcon([[Interface\BUTTONS\UI-Panel-MinimizeButton-Up]], 20, 20, "overlay", {0.1, .9, 0.1, .9})

    okayButton:SetPoint("topleft", bigTextEditor, "bottomleft", 0, -2)
    cancelButton:SetPoint("left", okayButton, "right", 2, 0)
end

function scriptLibrary.ImportScript()
    local mainFrame = scriptLibrary.GetMainFrame()
    local bigTextEditor = mainFrame.importExportEditor

    --if the frame is shown to export a script, the 'Okay' button changes its behavior and hides the frame instead
    if (mainFrame.isExport) then
        scriptLibrary.CancelImportingOrExporting()
        return
    end

    local text = bigTextEditor:GetText()
    scriptLibrary.CancelImportingOrExporting()
    scriptLibrary.ImportExport.StringToScript(text)
end

function scriptLibrary.CancelImportingOrExporting()
    if (not scriptLibrary.ImportExportFrameCreated) then
        return
    end

    local mainFrame = scriptLibrary.GetMainFrame()
    if (not mainFrame.importExportFrame:IsShown()) then
        return
    end

    scriptLibrary.Windows.HideWindow("importExportFrame")
    local bigTextEditor = mainFrame.importExportEditor
    bigTextEditor.editbox:ClearFocus()
    scriptLibrary.Windows.ReopenPreviousWindowStack()
end

--show the import / export text editor
function scriptLibrary.OpenImportExport(isImport, isExport, scriptObjectToExport)
    --create the frames if not created yet
    if (not scriptLibrary.ImportExportFrameCreated) then
        createImportExportFrame()
        scriptLibrary.ImportExportFrameCreated = true
    end

    scriptLibrary.Windows.ShowWindow("importExportFrame", true)

    local mainFrame = scriptLibrary.GetMainFrame()
    local bigTextEditor = mainFrame.importExportEditor

    mainFrame.isImport = isImport
    mainFrame.isExport = isExport

    bigTextEditor:SetText("")

    if (isImport) then
        --just wait the player paste the string and hit okay
        bigTextEditor:SetFocus(true)

    elseif (isExport) then
        local exportString = scriptLibrary.ImportExport.ScriptToString(scriptObjectToExport)
        bigTextEditor:SetText(exportString)
        bigTextEditor:SetFocus(true)
        bigTextEditor.editbox:HighlightText()
    end
end

local checkType = function(object, objectType)
    if (type(object) == objectType) then
        return true
    end
end

local validateArgument = function(validArgument, errorText)
    if (not validArgument) then
        scriptLibrary:Msg(errorText)
        return false
    else
        return true
    end
end

---get a script object and convert to a readable string
---@param scriptObject scriptobject
---@return string
function scriptLibrary.ImportExport.ScriptToString(scriptObject)
    if (not scriptObject) then
        return "fail on scriptLibrary.GetStringToExportScript()"
    end

    local tableToExport = DF.table.copytocompress({}, scriptObject)

    local LibAceSerializer = _G.LibStub:GetLibrary("AceSerializer-3.0")
    local LibDeflate = _G.LibStub:GetLibrary("LibDeflate")

    --update the script
    tableToExport.Version = tableToExport.Version or 1
    tableToExport.CursorPosition = nil
    tableToExport.ScrollValue = nil

    --stringify
    if (LibDeflate and LibAceSerializer) then
        local dataSerialized = LibAceSerializer:Serialize(tableToExport)
        if (dataSerialized) then
            local dataCompressed = LibDeflate:CompressDeflate(dataSerialized, {level = 9})
            if (dataCompressed) then
                local dataEncoded = LibDeflate:EncodeForPrint(dataCompressed)
                return dataEncoded
            end
        end
    end

    return "something went wrong on scriptLibrary.GetStringToExportScript()"
end

---get a string pasted into the import text entry and attempt to convert the string into a script
---@param str string a string to import
---@return boolean
function scriptLibrary.ImportExport.StringToScript(str)
    local LibAceSerializer = _G.LibStub:GetLibrary("AceSerializer-3.0")
    local LibDeflate = _G.LibStub:GetLibrary("LibDeflate")

    local dataCompressed = LibDeflate:DecodeForPrint(str)
    if (not dataCompressed) then
        scriptLibrary:Msg("invalid data to import (1).")
        return false
    end

    local dataSerialized = LibDeflate:DecompressDeflate(dataCompressed)
    if (not dataSerialized) then
        scriptLibrary:Msg("invalid data to import (2).")
        return false
    end

    local okay, scriptObject = LibAceSerializer:Deserialize(dataSerialized)
    if (not okay) then
        scriptLibrary:Msg("invalid data to import (3).")
        return false
    end

    --validate the received data

    --icon
    if (type(scriptObject.Icon) ~= "string" and type(scriptObject.Icon) ~= "number") then
        scriptObject.Icon = ""
    end

    --name
    if (not validateArgument(checkType(scriptObject.Name, "string"), "Imported string with invalid name.")) then
        return false
    end

    --description
    if (not validateArgument(checkType(scriptObject.Desc, "string"), "Imported string with invalid description.")) then
        return false
    end

    --cretion time
    if (not validateArgument(checkType(scriptObject.Time, "number"), "Imported string with invalid creation time.")) then
        return false
    end

    --revision
    if (not validateArgument(checkType(scriptObject.Revision, "number"), "Imported string with invalid revision.")) then
        return false
    end

    --auto run
    if (not validateArgument(checkType(scriptObject.AutoRun, "boolean"), "Imported string with invalid auto run parameter.")) then
        return false
    end

    --addon name
    if (not validateArgument(checkType(scriptObject.AddonName, "string"), "Imported string with invalid addon name.")) then
        return false
    end

    --function name
    if (not validateArgument(checkType(scriptObject.FunctionName, "string"), "Imported string with invalid function name.")) then
        return false
    end

    --arguments
    if (not validateArgument(checkType(scriptObject.Arguments, "string"), "Imported string with invalid arguments.")) then
        return false
    end

    --version
    if (not validateArgument(checkType(scriptObject.Version, "number"), "Imported string with invalid version.")) then
        return false
    end

    local version = scriptObject.Version
    if (version == 1) then
        --check if the code is valid
        if (not validateArgument(checkType(scriptObject.Code, "string"), "Imported string with invalid code.")) then
            return false
        end

    elseif (version == 2) then
        --iterate through the pages and check if they're valid
        for i = 1, #scriptObject.Pages do
            local scriptPage = scriptObject.Pages[i]
            if (not validateArgument(checkType(scriptPage, "table"), "Imported string with invalid page.")) then
                return false
            end

            --check if the page has a name
            if (not validateArgument(checkType(scriptPage.Name, "string"), "Imported string with invalid page name.")) then
                return false
            end

            --check if the page has a code
            if (not validateArgument(checkType(scriptPage.Code, "string"), "Imported string with invalid page code.")) then
                return false
            end

            --check if the page has a edit time
            if (not validateArgument(checkType(scriptPage.EditTime, "number"), "Imported string with invalid page edit time.")) then
                return false
            end

            scriptPage.CursorPosition = 1
            scriptPage.ScrollValue = 1
        end
    end

    scriptLibrary.CheckVersion(scriptObject)

    local data = scriptLibrary.GetData()

    --add it to the database
    table.insert(data, scriptObject)

    --start editing the new script
    scriptLibrary.ScriptObject.Select(#data)

    --refresh the scrollbox showing all codes created
    scriptLibrary.MainFrame.CodeSelectionScrollBox:Refresh()

    scriptLibrary:Msg("Script imported!")
    return true
end