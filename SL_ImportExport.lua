
--get the addon object
local addonName, scriptLibrary = ...
local _

--load Details! Framework
local DF = _G ["DetailsFramework"]
if (not DF) then
    print ("|cFFFFAA00RuntimeEditor: framework not found, if you just installed or updated the addon, please restart your client.|r")
    return
end

--templates
local options_text_template = DF:GetTemplate("font", "OPTIONS_FONT_TEMPLATE")
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
local options_switch_template = DF:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE")
local options_slider_template = DF:GetTemplate("slider", "OPTIONS_SLIDER_TEMPLATE")
local options_button_template = DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")

--create on demand the import frame
--this function only creates the frame, the logic on opening the frame is below this function
local createImportExportFrame = function()
    local mainFrame = scriptLibrary.MainFrame
    local codeEditorFrameSettings = scriptLibrary.FrameSettings.settingsCodeEditor
    local buttonsFrameSettings = scriptLibrary.FrameSettings.settingsButtons

    local importExportFrame = CreateFrame("frame", "$parentImportExport", mainFrame)
    importExportFrame:SetSize(1, 1)
    importExportFrame:SetPoint("topleft", mainFrame, "topleft", codeEditorFrameSettings.pointX, codeEditorFrameSettings.pointY)
    mainFrame.importExportFrame = importExportFrame

    --register into the window stack
    local onShow = function()
    end
    local onHide = function()
    end

    --window name, frame object, stack, show callback, hide callback
    scriptLibrary.RegisterFrame("importExportFrame", importExportFrame, scriptLibrary.FrameStack.importExportFrame, onShow, onHide)

    --editor
    local bigTextEditor = DF:NewSpecialLuaEditorEntry(importExportFrame, codeEditorFrameSettings.width, codeEditorFrameSettings.height, "ImportExportEditor", "$parentImportExportEditor", true, false)
    bigTextEditor:SetPoint("topleft", importExportFrame, "topleft", 0, 0)
    mainFrame.importExportEditor = bigTextEditor

    bigTextEditor.editbox:SetScript("OnEscapePressed", function()
        scriptLibrary.CancelImportingOrExporting()
    end)

    --apply a different skin into the code editor
    scriptLibrary.ApplyEditorLayout(bigTextEditor)

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
    local mainFrame = scriptLibrary.MainFrame
    local bigTextEditor = mainFrame.importExportEditor

    --if the frame is shown to export a script, the 'Okay' button hides the frame
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

    local mainFrame = scriptLibrary.MainFrame
    if (not mainFrame.importExportFrame:IsShown()) then
        return
    end

    scriptLibrary.HideWindow("importExportFrame")
    local bigTextEditor = mainFrame.importExportEditor
    bigTextEditor.editbox:ClearFocus()
    scriptLibrary.ReopenPreviousWindowStack()
end

--show the import / export text editor
function scriptLibrary.OpenImportExport(isImport, isExport, scriptObjectToExport)
    --create the frames if not created yet
    if (not scriptLibrary.ImportExportFrameCreated) then
        createImportExportFrame()
        scriptLibrary.ImportExportFrameCreated = true
    end

    scriptLibrary.ShowWindow("importExportFrame", true)

    local mainFrame = scriptLibrary.MainFrame
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
