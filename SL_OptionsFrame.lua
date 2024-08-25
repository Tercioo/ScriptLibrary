
--get the addon object
local addonName, scriptLibrary = ...
local _
local UIParent = UIParent

---@cast scriptLibrary scriptlibrary

--load Details! Framework
---@type detailsframework
local detailsFramework = _G["DetailsFramework"]
if (not detailsFramework) then
    print("|cFFFFAA00RuntimeEditor: framework not found, if you just installed or updated the addon, please restart your client.|r")
    return
end

local settingsScrollBox = scriptLibrary.FrameSettings.settingsScrollBox
local codeEditorFrameSettings = scriptLibrary.FrameSettings.settingsCodeEditor
local buttonsFrameSettings = scriptLibrary.FrameSettings.settingsButtons
local optionsFrameSettings = scriptLibrary.FrameSettings.settingsOptionsFrame

--get templates
local options_dropdown_template = detailsFramework:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")

function scriptLibrary.CreateMainOptionsFrame()
    --quit if already created
    if (scriptLibrary.bFramesBuilt) then
        return
    end

    scriptLibrary.CheckVersion()

    local config = scriptLibrary.GetConfig()

    --create options frame
    local mainFrame = detailsFramework:CreateSimplePanel(UIParent, optionsFrameSettings.width, optionsFrameSettings.height, "Script Library", "RuntimeEditorMainWindow")
    mainFrame:SetPoint("center", UIParent, "center", 0, 0)
    mainFrame:SetFrameStrata("HIGH")
    DetailsFramework:ApplyStandardBackdrop(mainFrame)
    scriptLibrary.MainFrame = mainFrame

    ---@type df_image
    local bottomGradient = detailsFramework:CreateTexture(mainFrame, {gradient = "vertical", fromColor = {0, 0, 0, 0.4}, toColor = "transparent"}, 1, 120, "artwork", {0, 1, 0, 1}, "bottomGradient")
    bottomGradient:SetPoint("bottoms")

    --register into the window stack
    local onShowWindow = function()
    end
    local onHideWindow = function()
    end
    --window name, frame object, stack, show callback, hide callback
    scriptLibrary.Windows.RegisterFrame("mainFrame", mainFrame, scriptLibrary.FrameStack.mainFrame, onShowWindow, onHideWindow)
    scriptLibrary.Windows.ShowWindow("mainFrame")

    --disable the buil-in mouse integration of the simple panel, doing this to use LibWindow-1.1 as the window management
    mainFrame:SetScript("OnMouseDown", nil)
    mainFrame:SetScript("OnMouseUp", nil)

    --register in the libWindow
    local LibWindow = _G.LibStub:GetLibrary("LibWindow-1.1")
    LibWindow.RegisterConfig(mainFrame, config.main_frame)
    LibWindow.MakeDraggable(mainFrame)
    LibWindow.RestorePosition(mainFrame)

    --scale bar
    ---@type df_scalebar
    local scaleBar = detailsFramework:CreateScaleBar(mainFrame, config.frame_scale)
    mainFrame:SetScale(config.frame_scale.scale)

    --status bar
    local statusBar = detailsFramework:CreateStatusBar(mainFrame)
    statusBar.text = statusBar:CreateFontString(nil, "overlay", "GameFontNormal")
    statusBar.text:SetPoint("left", statusBar, "left", 5, 0)
    statusBar.text:SetText("An addon by Terciob | Built with Details! Framework")
    detailsFramework:SetFontSize(statusBar.text, 11)
    detailsFramework:SetFontColor(statusBar.text, "gray")

    --> create the top left frames which shows the script information like name and description
    --create the frame base of the script info
    local scriptInfoFrame = _G.CreateFrame("frame", "$parentScriptInfo", mainFrame)
    scriptInfoFrame:SetPoint("topleft", mainFrame, "topleft", optionsFrameSettings.scriptInfoX, optionsFrameSettings.scriptInfoY)

    --register into the window stack
    local onShowScriptInfoFrame = function()
    end
    local onHideScriptInfoFrame = function()
    end
    --window name, frame object, stack, show callback, hide callback
    scriptLibrary.Windows.RegisterFrame("scriptInfoFrame", mainFrame, scriptLibrary.FrameStack.scriptInfoFrame, onShowScriptInfoFrame, onHideScriptInfoFrame)
    scriptLibrary.Windows.ShowWindow("scriptInfoFrame")

    --create new code function
    local createNewCode = function()
        scriptLibrary.ScriptObject.CreateNew()
    end

    ---@type df_button
    local createNewCodeButton = detailsFramework:CreateButton(scriptInfoFrame, createNewCode, 32, 32, "", -1, nil, nil, "CreateButton", nil, nil, detailsFramework:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), detailsFramework:GetTemplate("font", "CODE_BUTTON"))
    createNewCodeButton:SetIcon([[Interface\BUTTONS\UI-PlusButton-Up]], 20, 20, "overlay", {0, 1, 0, 1})
    mainFrame.CreateNewCodeButton = createNewCodeButton
    createNewCodeButton.nameLabel = detailsFramework:CreateLabel(createNewCodeButton, "New", 10)
    createNewCodeButton.nameLabel:SetPoint("top", createNewCodeButton, "bottom", 0, -1)

    --create import button
    local openImport = function()
        --show the import window
        scriptLibrary.OpenImportExport(true)
    end

    ---@type df_button
    local importCodeButton = detailsFramework:CreateButton(scriptInfoFrame, openImport, 32, 32, "", -1, nil, nil, "ImportButton", nil, nil, detailsFramework:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), detailsFramework:GetTemplate("font", "CODE_BUTTON"))
    importCodeButton:SetIcon([[Interface\BUTTONS\UI-PlusButton-Up]], 20, 20, "overlay", {0, 1, 0, 1})
    mainFrame.ImportButton = importCodeButton
    importCodeButton.nameLabel = detailsFramework:CreateLabel(importCodeButton, "Import", 10)
    importCodeButton.nameLabel:SetPoint("top", importCodeButton, "bottom", 0, -1)

    --textentry to insert the name of the code
    ---@type df_label
    local codeNameLabel = detailsFramework:CreateLabel(scriptInfoFrame, "Script Name:", detailsFramework:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
    ---@type df_textentry
    local codeNameTextentry = detailsFramework:CreateTextEntry(scriptInfoFrame, function()end, settingsScrollBox.width, 20, "CodeNameTextEntry", _, _, options_dropdown_template)
    codeNameTextentry:SetPoint("topleft", codeNameLabel, "bottomleft", 0, -2)
    mainFrame.CodeNameLabel = codeNameLabel
    mainFrame.CodeNameTextEntry = codeNameTextentry

    --icon selection
    local codeIconCallback = function(texture)
        mainFrame.CodeIconButton:SetIcon(texture)
    end
    ---@type df_label
    local codeIconLabel = detailsFramework:CreateLabel(scriptInfoFrame, "Icon:", detailsFramework:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
    ---@type df_button
    local codeIconButton = detailsFramework:CreateButton(scriptInfoFrame, function() detailsFramework:IconPick(codeIconCallback, true) end, 20, 20, "", 0, nil, nil, nil, nil, nil, detailsFramework:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
    codeIconButton:SetPoint("topleft", codeIconLabel, "bottomleft", 0, -2)
    mainFrame.CodeIconLabel = codeIconLabel
    mainFrame.CodeIconButton = codeIconButton

    --auto run
    local switchAutoRun = function(self, fixedParameter, value)
        return
    end
    ---@type df_checkbox
    local autorunCheckbox, autorunLabel = detailsFramework:CreateSwitch(scriptInfoFrame, switchAutoRun, false, _, _, _, _, _, _, _, _, _, "Auto Run on Login", detailsFramework:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE"), detailsFramework:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
    autorunCheckbox:SetAsCheckBox()
    autorunCheckbox:SetSize(20, 20)
    autorunCheckbox:ClearAllPoints()
    autorunCheckbox:SetPoint("topleft", codeIconLabel, "bottomleft", 100, 10)
    autorunCheckbox:SetValue(false)
    mainFrame.CodeAutorunCheckbox = autorunCheckbox

    autorunLabel:ClearAllPoints()
    autorunLabel:SetPoint("left", autorunCheckbox, "right", 2, 0)
    autorunLabel.text = "Auto Run on Login"

    --use xpcall instead of pcall check box
    local useXPCallCallback = function(self, fixedParameter, value)
        local currentCode = scriptLibrary.GetCurrentScriptObject()
        if (currentCode) then
            currentCode.UseXPCall = value
            print(value)
        end
    end

    ---@type df_checkbox
    local useXPCallCheckbox, useXPCallLabel = detailsFramework:CreateSwitch(scriptInfoFrame, useXPCallCallback, false, _, _, _, _, _, _, _, _, _, "use XPCall", detailsFramework:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE"), detailsFramework:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
    useXPCallCheckbox:SetAsCheckBox()
    useXPCallCheckbox:SetSize(20, 20)
    useXPCallCheckbox:ClearAllPoints()
    useXPCallCheckbox:SetPoint("topleft", autorunCheckbox, "bottomleft", 0, -4)
    useXPCallCheckbox:SetValue(false)
    mainFrame.UseXPCallCheckbox = useXPCallCheckbox

    if (useXPCallLabel) then
        useXPCallLabel:ClearAllPoints()
        useXPCallLabel:SetPoint("left", useXPCallCheckbox, "right", 2, 0)
        useXPCallLabel.text = "Use xpcall"
    end

    --description
    ---@type df_label
    local codeDescLabel = detailsFramework:CreateLabel(scriptInfoFrame, "Description:", detailsFramework:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
    ---@type df_textentry
    local codeDescTextentry = detailsFramework:CreateTextEntry(scriptInfoFrame, function()end, settingsScrollBox.width, 20, "ScriptDescriptionTextEntry", _, _, options_dropdown_template)
    codeDescTextentry:SetPoint("topleft", codeDescLabel, "bottomleft", 0, -2)
    mainFrame.CodeDescLabel = codeDescLabel
    mainFrame.codeDescTextentry = codeDescTextentry

    --> create the script selection scroll box
    --the body of this function is on the file 'SL_ScriptMenu.lua'
    scriptLibrary.CreateScriptSelectionScrollBox()

    --> code editor
    local codeEditorFrame = _G.CreateFrame("frame", "$parentCodeEditor", mainFrame)
    codeEditorFrame:SetSize(1, 1)
    codeEditorFrame:SetPoint("topleft", mainFrame, "topleft", settingsScrollBox.width+40, -080)

    --register into the window stack
    local onShowScriptInfoFrame = function()
    end
    local onHideScriptInfoFrame = function()
    end
    --window name, frame object, stack, show callback, hide callback
    scriptLibrary.Windows.RegisterFrame("codeEditorFrame", codeEditorFrame, scriptLibrary.FrameStack.codeEditorFrame, onShowScriptInfoFrame, onHideScriptInfoFrame)
    scriptLibrary.Windows.ShowWindow("codeEditorFrame")

    ---@type df_luaeditor
    local codeEditor = detailsFramework:NewSpecialLuaEditorEntry(codeEditorFrame, codeEditorFrameSettings.width, codeEditorFrameSettings.height, "CodeEditor", "$parentCodeEditor", false, true)
    codeEditor:SetTextSize(config.options.text_size)
    codeEditor:SetPoint("topleft", codeEditorFrame, "topleft", 0, 0)

    --apply a different skin into the code editor
    scriptLibrary.Windows.ApplyEditorLayout(codeEditor)

    mainFrame.CodeEditor = codeEditor

    --code errors
    local errortextFrame = _G.CreateFrame("frame", nil, codeEditor, "BackdropTemplate")
    errortextFrame:SetPoint("bottomleft", codeEditor, "bottomleft", 1, 1)
    errortextFrame:SetPoint("bottomright", codeEditor, "bottomright", -1, 1)
    errortextFrame:SetHeight(20)
    errortextFrame:SetFrameLevel(codeEditor:GetFrameLevel()+5)
    errortextFrame:SetBackdrop({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
    errortextFrame:SetBackdropBorderColor(0, 0, 0, 1)
    detailsFramework:ApplyStandardBackdrop(errortextFrame, false, 1)
    errortextFrame:SetBackdropColor(.3, .30, .30, .9)

    ---@type df_label
    local errortextLabel = detailsFramework:CreateLabel(errortextFrame, "", detailsFramework:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
    errortextLabel.textcolor = "silver"
    errortextLabel.textsize = 13
    errortextLabel:SetPoint("left", errortextFrame, "left", 3, 0)

    codeEditor.NextCodeCheck = 0.33

    --create the page tab frames
    scriptLibrary.ScriptPages.CreateTabFrames()

    local saveFrame = _G.CreateFrame("frame", nil, codeEditor.editbox)
    saveFrame:SetPropagateKeyboardInput(true)

    local readKeyDownEventsFunc = function(self, keyDown)
        if (keyDown == "S") then
            if (_G.IsControlKeyDown()) then
                scriptLibrary.ScriptObject.Save()
                codeEditor.editbox:SetFocus(true)
                mainFrame.SaveButton.animationHub:Play()
            end

        elseif (keyDown == "R") then
            if (_G.IsControlKeyDown()) then
                scriptLibrary.CodeExec.ReplaceCode()
                codeEditor.editbox:SetFocus(true)
                mainFrame.ReplaceButton.animationHub:Play()
            end
        end
    end

    codeEditor.editbox:HookScript("OnEditFocusGained", function()
        saveFrame:SetScript("OnKeyDown", readKeyDownEventsFunc)
    end)

    codeEditor.editbox:HookScript("OnEditFocusLost", function()
        saveFrame:SetScript("OnKeyDown", nil)
    end)

    codeEditor.editbox:HookScript("OnEnterPressed", function()
        --don't lose the focus of the editor when shift pressed
        if (_G.IsShiftKeyDown()) then
            scriptLibrary.ScriptObject.Save()
            scriptLibrary.CodeExec.ExecuteCode()
            codeEditor.editbox:SetFocus(true)
            mainFrame.SaveButton.animationHub:Play()
            mainFrame.ExecuteButton.animationHub:Play()

        --if ctrl is pressed when the user pressed enter, save the script like if the user has pressed the Save button
        elseif (_G.IsControlKeyDown()) then
            scriptLibrary.ScriptObject.Save()
            codeEditor.editbox:SetFocus(true)
            mainFrame.SaveButton.animationHub:Play()
        else
            codeEditor.editbox:Insert("\n")
        end
    end)

    codeEditor:HookScript("OnUpdate", function (self, deltaTime)
        codeEditor.NextCodeCheck = codeEditor.NextCodeCheck - deltaTime
        if (codeEditor.NextCodeCheck < 0) then
            local script = codeEditor:GetText()

            local functionIsNaked = scriptLibrary.CodeExec.IsFunctionNaked(script)
            if(functionIsNaked)then
                script = "function(...) "..script.." end"
            end

            script = "return " .. script
            local func, errortext = loadstring(script, "Q")
            if (not func) then
                errortext = errortext or ""
                local firstLine = strsplit("\n", script, 2)
                errortext = errortext:gsub(firstLine, "")
                errortext = errortext:gsub("%[string \"", "")
                errortext = errortext:gsub("...\"]:", "")
                errortext = errortext:gsub("Q\"]:", "")
                local lineNumber = tonumber (errortext) or 0
                lineNumber = lineNumber - 2
                errortext = "Line " .. errortext
                errortextLabel.text = errortext
            else
                errortextLabel.text = ""
            end

            codeEditor.NextCodeCheck = 0.33
        end
    end)

    --execute button
    ---@type df_button
    local executeButton = detailsFramework:CreateButton(codeEditor, scriptLibrary.CodeExec.ExecuteCode, buttonsFrameSettings.width, buttonsFrameSettings.height, "Run", -1, nil, nil, nil, nil, nil, detailsFramework:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), detailsFramework:GetTemplate("font", "CODE_BUTTON"))
    executeButton:SetIcon([[Interface\BUTTONS\UI-Panel-BiggerButton-Up]], 20, 20, "overlay", {0.1, .9, 0.1, .9})
    executeButton.tooltip = "execute the code"
    mainFrame.ExecuteButton = executeButton

    --replace button
    ---@type df_button
    local replaceButton = detailsFramework:CreateButton(codeEditor, scriptLibrary.CodeExec.ReplaceCode, buttonsFrameSettings.width, buttonsFrameSettings.height, "Replace", -1, nil, nil, nil, nil, nil, detailsFramework:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), detailsFramework:GetTemplate("font", "CODE_BUTTON"))
    replaceButton:SetIcon([[Interface\BUTTONS\UI-Panel-BiggerButton-Up]], 20, 20, "overlay", {0.1, .9, 0.1, .9})
    replaceButton.tooltip = "replaces the function within the global namespace or addon."
    mainFrame.ReplaceButton = replaceButton

    --save button
    ---@type df_button
    local saveButton = detailsFramework:CreateButton(codeEditor, scriptLibrary.ScriptObject.Save, buttonsFrameSettings.width, buttonsFrameSettings.height, "Save", -1, nil, nil, nil, nil, nil, detailsFramework:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), detailsFramework:GetTemplate("font", "CODE_BUTTON"))
    saveButton:SetIcon([[Interface\BUTTONS\UI-Panel-ExpandButton-Up]], 20, 20, "overlay", {0.1, .9, 0.1, .9})
    mainFrame.SaveButton = saveButton

    --save button
    ---@type df_button
    local reloadButton = detailsFramework:CreateButton(codeEditor, scriptLibrary.Reload, buttonsFrameSettings.width, buttonsFrameSettings.height, "ReloadUI", -1, nil, nil, nil, nil, nil, detailsFramework:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), detailsFramework:GetTemplate("font", "CODE_BUTTON"))
    reloadButton:SetIcon([[Interface\BUTTONS\UI-Panel-ExpandButton-Up]], 20, 20, "overlay", {0.1, .9, 0.1, .9})
    mainFrame.ReloadButton = reloadButton

    --shift + enter to execute
    ---@type df_label
    local executeLabel = detailsFramework:CreateLabel(codeEditor, "[SHIFT + ENTER] to save and execute the code", detailsFramework:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
    executeLabel:SetPoint("left", reloadButton, "right", 30, 1)
    executeLabel.fontsize = 12
    executeLabel.color = {.8, .8, .8, .5}

    --create animations
        local feedbackSaveButton_Texture = saveButton:CreateTexture(nil, "overlay")
        feedbackSaveButton_Texture:SetColorTexture(1, 1, 1)
        feedbackSaveButton_Texture:SetAllPoints()
        feedbackSaveButton_Texture:SetDrawLayer("overlay", 7)
        feedbackSaveButton_Texture:SetAlpha (0)

        local feedbackExecuteButton_Texture = executeButton:CreateTexture(nil, "overlay")
        feedbackExecuteButton_Texture:SetColorTexture(1, 1, 1)
        feedbackExecuteButton_Texture:SetAllPoints()
        feedbackExecuteButton_Texture:SetDrawLayer("overlay", 7)
        feedbackExecuteButton_Texture:SetAlpha (0)

        local feedbackReplaceButton_Texture = replaceButton:CreateTexture(nil, "overlay")
        feedbackReplaceButton_Texture:SetColorTexture(1, 1, 1)
        feedbackReplaceButton_Texture:SetAllPoints()
        feedbackReplaceButton_Texture:SetDrawLayer("overlay", 7)
        feedbackReplaceButton_Texture:SetAlpha (0)

        ---@type animationgroup
        local feedbackSaveButton_FlashAnimation = detailsFramework:CreateAnimationHub(feedbackSaveButton_Texture)
        detailsFramework:CreateAnimation(feedbackSaveButton_FlashAnimation, "Alpha", 1, 0.08, 0, 0.2)
        detailsFramework:CreateAnimation(feedbackSaveButton_FlashAnimation, "Alpha", 2, 0.08, 0.4, 0)

        ---@type animationgroup
        local feedbackExecuteButton_FlashAnimation = detailsFramework:CreateAnimationHub(feedbackExecuteButton_Texture)
        detailsFramework:CreateAnimation(feedbackExecuteButton_FlashAnimation, "Alpha", 1, 0.08, 0, 0.2)
        detailsFramework:CreateAnimation(feedbackExecuteButton_FlashAnimation, "Alpha", 2, 0.08, 0.4, 0)

        ---@type animationgroup
        local feedbackReplaceButton_FlashAnimation = detailsFramework:CreateAnimationHub(feedbackReplaceButton_Texture)
        detailsFramework:CreateAnimation(feedbackReplaceButton_FlashAnimation, "Alpha", 1, 0.08, 0, 0.2)
        detailsFramework:CreateAnimation(feedbackReplaceButton_FlashAnimation, "Alpha", 2, 0.08, 0.4, 0)

        ---@type animationgroup
        local feedbackSaveButton_Animation = detailsFramework:CreateAnimationHub(saveButton, function() feedbackSaveButton_FlashAnimation:Play() end)

        ---@type animationgroup
        local feedbackExecuteButton_Animation = detailsFramework:CreateAnimationHub(executeButton, function() feedbackExecuteButton_FlashAnimation:Play() end)

        ---@type animationgroup
        local feedbackReplaceButton_Animation = detailsFramework:CreateAnimationHub(replaceButton, function() feedbackExecuteButton_FlashAnimation:Play() end)

        local speed = 0.06
        local rotation = 0
        local translation = 7

        detailsFramework:CreateAnimation(feedbackSaveButton_Animation, "Translation", 1, speed, 0, -translation)
        detailsFramework:CreateAnimation(feedbackSaveButton_Animation, "Rotation", 1, speed, -rotation)
        detailsFramework:CreateAnimation(feedbackExecuteButton_Animation, "Translation", 1, speed, 0, -translation)
        detailsFramework:CreateAnimation(feedbackExecuteButton_Animation, "Rotation", 1, speed, -rotation)
        detailsFramework:CreateAnimation(feedbackReplaceButton_Animation, "Translation", 1, speed, 0, -translation)
        detailsFramework:CreateAnimation(feedbackReplaceButton_Animation, "Rotation", 1, speed, -rotation)

        detailsFramework:CreateAnimation(feedbackSaveButton_Animation, "Translation", 2, speed, 0, translation)
        detailsFramework:CreateAnimation(feedbackSaveButton_Animation, "Rotation", 2, speed, rotation)
        detailsFramework:CreateAnimation(feedbackExecuteButton_Animation, "Translation", 2, speed, 0, translation)
        detailsFramework:CreateAnimation(feedbackExecuteButton_Animation, "Rotation", 2, speed, rotation)
        detailsFramework:CreateAnimation(feedbackReplaceButton_Animation, "Translation", 2, speed, 0, translation)
        detailsFramework:CreateAnimation(feedbackReplaceButton_Animation, "Rotation", 2, speed, rotation)

        detailsFramework:CreateAnimation(feedbackSaveButton_Animation, "Rotation", 3, speed, rotation)
        detailsFramework:CreateAnimation(feedbackSaveButton_Animation, "Rotation", 4, speed, -rotation)
        detailsFramework:CreateAnimation(feedbackExecuteButton_Animation, "Rotation", 3, speed, rotation)
        detailsFramework:CreateAnimation(feedbackExecuteButton_Animation, "Rotation", 4, speed, -rotation)
        detailsFramework:CreateAnimation(feedbackReplaceButton_Animation, "Rotation", 3, speed, rotation)
        detailsFramework:CreateAnimation(feedbackReplaceButton_Animation, "Rotation", 4, speed, -rotation)

        saveButton.animationHub = feedbackSaveButton_Animation
        executeButton.animationHub = feedbackExecuteButton_Animation
        replaceButton.animationHub = feedbackReplaceButton_Animation

    --set points
    local xStart = 10
    mainFrame.CreateNewCodeButton:SetPoint("topleft", mainFrame, "topleft", xStart, -27)
    mainFrame.ImportButton:SetPoint("left", mainFrame.CreateNewCodeButton, "right", 5, 0)

    mainFrame.CodeNameLabel:SetPoint("topleft", mainFrame.CreateNewCodeButton, "bottomleft", 0, -15)
    mainFrame.CodeIconLabel:SetPoint("topleft", mainFrame.CodeNameLabel, "bottomleft", 0, -30)
    mainFrame.CodeDescLabel:SetPoint("topleft", mainFrame.CodeIconLabel, "bottomleft", 0, -30)
    mainFrame.SearchScriptLabel:SetPoint("topleft", mainFrame.CodeDescLabel, "bottomleft", 0, -30)

    executeButton:SetPoint("topleft", codeEditor, "bottomleft", 0, -7)
    replaceButton:SetPoint("left", executeButton, "right", 7, 0)
    saveButton:SetPoint("left", replaceButton, "right", 7, 0)
    reloadButton:SetPoint("left", saveButton, "right", 7, 0)

    scriptLibrary.Windows.DisableAllWidgets()

    --> restore position
    local LibWindow = _G.LibStub:GetLibrary("LibWindow-1.1")
    LibWindow.RegisterConfig(mainFrame, config.main_frame)
    LibWindow.RestorePosition(mainFrame)
    LibWindow.MakeDraggable(mainFrame)

    local changeFontSize = function(_, _, delta)
        if (delta) then
            config.options.text_size = math.min(config.options.text_size + 1, 16)
            codeEditor:SetTextSize(config.options.text_size)
        else
            config.options.text_size = math.max(config.options.text_size - 1, 8)
            codeEditor:SetTextSize(config.options.text_size)
        end
    end

    ---@type df_button
    local increaseFontSizeButton = detailsFramework:CreateButton(mainFrame, changeFontSize, 40, 20, "aA", true, nil, nil, "decreaseFontSizeButton", nil, nil, detailsFramework:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), detailsFramework:GetTemplate("font", "CODE_BUTTON"))
    increaseFontSizeButton:SetPoint("bottomright", mainFrame, "bottomright", -32, 38)

    ---@type df_button
    local decreaseFontSizeButton = detailsFramework:CreateButton(mainFrame, changeFontSize, 40, 20, "Aa", false, nil, nil, "decreaseFontSizeButton", nil, nil, detailsFramework:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), detailsFramework:GetTemplate("font", "CODE_BUTTON"))
    decreaseFontSizeButton:SetPoint("right", increaseFontSizeButton, "left", -2, 0)

    --done
    mainFrame:Show()
    scriptLibrary.bFramesBuilt = true

    _G.C_Timer.After(0, function()
        if (config.last_opened_script) then
            scriptLibrary.ScriptObject.Select(config.last_opened_script)
        end
    end)
end