
--get the addon object
local addonName, scriptLibrary = ...
local _

--load Details! Framework
local DF = _G ["DetailsFramework"]
if (not DF) then
    print ("|cFFFFAA00RuntimeEditor: framework not found, if you just installed or updated the addon, please restart your client.|r")
    return
end

local settingsScrollBox = scriptLibrary.FrameSettings.settingsScrollBox
local codeEditorFrameSettings = scriptLibrary.FrameSettings.settingsCodeEditor
local buttonsFrameSettings = scriptLibrary.FrameSettings.settingsButtons
local optionsFrameSettings = scriptLibrary.FrameSettings.settingsOptionsFrame

--get templates
local options_dropdown_template = DF:GetTemplate ("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")

function scriptLibrary.CreateMainOptionsFrame()
    --quit if already created
    if (scriptLibrary.bFramesBuilt) then
        return
    end

    local config = scriptLibrary.GetConfig()

    --> create the main window
        --create options frame
        local mainFrame = DF:CreateSimplePanel(UIParent, optionsFrameSettings.width, optionsFrameSettings.height, "Script Library", "RuntimeEditorMainWindow", panel_options, db)
        mainFrame:SetPoint("center", UIParent, "center", 0, 0)
        mainFrame:SetFrameStrata("LOW")
        --register into the window stack
        local onShowWindow = function()
        end
        local onHideWindow = function()
        end
        --window name, frame object, stack, show callback, hide callback
        scriptLibrary.RegisterFrame("mainFrame", mainFrame, scriptLibrary.FrameStack.mainFrame, onShowWindow, onHideWindow)
        scriptLibrary.ShowWindow("mainFrame")

        --disable the buil-in mouse integration of the simple panel, doing this to use LibWindow-1.1 as the window management
        mainFrame:SetScript("OnMouseDown", nil)
        mainFrame:SetScript("OnMouseUp", nil)

        --register in the libWindow
        local LibWindow = LibStub("LibWindow-1.1")
        LibWindow.RegisterConfig(mainFrame, config.main_frame)
        LibWindow.MakeDraggable(mainFrame)
        LibWindow.RestorePosition(mainFrame)

        --scale bar
        local scaleBar = DF:CreateScaleBar(mainFrame, config.frame_scale)
        mainFrame:SetScale(config.frame_scale.scale)

        --status bar
        local statusBar = DF:CreateStatusBar(mainFrame)
        statusBar.text = statusBar:CreateFontString(nil, "overlay", "GameFontNormal")
        statusBar.text:SetPoint("left", statusBar, "left", 5, 0)
        statusBar.text:SetText("An addon by Terciob | Built with Details! Framework")
        DF:SetFontSize(statusBar.text, 11)
        DF:SetFontColor(statusBar.text, "gray")

        scriptLibrary.MainFrame = mainFrame



    --> create the top left frames which shows the script information like name and description
        --create the frame base of the script info
        local scriptInfoFrame = CreateFrame("frame", "$parentScriptInfo", mainFrame)
        scriptInfoFrame:SetPoint("topleft", mainFrame, "topleft", optionsFrameSettings.scriptInfoX, optionsFrameSettings.scriptInfoY)

        --register into the window stack
        local onShowScriptInfoFrame = function()
        end
        local onHideScriptInfoFrame = function()
        end
        --window name, frame object, stack, show callback, hide callback
        scriptLibrary.RegisterFrame("scriptInfoFrame", mainFrame, scriptLibrary.FrameStack.scriptInfoFrame, onShowScriptInfoFrame, onHideScriptInfoFrame)
        scriptLibrary.ShowWindow("scriptInfoFrame")

        --create new code function
        local createNewCode = function()
            scriptLibrary.CreateNewScript()
        end
        local createNewCodeButton = DF:CreateButton(scriptInfoFrame, createNewCode, 40, 40, "", -1, nil, nil, "CreateButton", nil, nil, DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), DF:GetTemplate("font", "CODE_BUTTON"))
        createNewCodeButton:SetIcon([[Interface\BUTTONS\UI-PlusButton-Up]], 20, 20, "overlay", {0, 1, 0, 1})
        mainFrame.CreateNewCodeButton = createNewCodeButton
        createNewCodeButton.nameLabel = DF:CreateLabel(createNewCodeButton, "NEW")
        createNewCodeButton.nameLabel:SetPoint("top", createNewCodeButton, "bottom", 0, -1)

        --create import button
        local openImport = function()
            --show the import window
            scriptLibrary.OpenImportExport(true)
        end
        local importCodeButton = DF:CreateButton(scriptInfoFrame, openImport, 40, 40, "", -1, nil, nil, "ImportButton", nil, nil, DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), DF:GetTemplate("font", "CODE_BUTTON"))
        importCodeButton:SetIcon([[Interface\BUTTONS\UI-PlusButton-Up]], 20, 20, "overlay", {0, 1, 0, 1})
        mainFrame.ImportButton = importCodeButton
        importCodeButton.nameLabel = DF:CreateLabel(importCodeButton, "IMPORT")
        importCodeButton.nameLabel:SetPoint("top", importCodeButton, "bottom", 0, -1)

        --textentry to insert the name of the code
        local codeNameLabel = DF:CreateLabel(scriptInfoFrame, "Script Name:", DF:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
        local codeNameTextentry = DF:CreateTextEntry(scriptInfoFrame, function()end, settingsScrollBox.width, 20, "CodeNameTextEntry", _, _, options_dropdown_template)
        codeNameTextentry:SetPoint("topleft", codeNameLabel, "bottomleft", 0, -2)
        mainFrame.CodeNameLabel = codeNameLabel
        mainFrame.CodeNameTextEntry = codeNameTextentry

        --icon selection
        local codeIconCallback = function(texture)
            mainFrame.CodeIconButton:SetIcon(texture)
        end
        local codeIconLabel = DF:CreateLabel(scriptInfoFrame, "Icon:", DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
        local codeIconButton = DF:CreateButton(scriptInfoFrame, function() DF:IconPick(codeIconCallback, true) end, 20, 20, "", 0, nil, nil, nil, nil, nil, DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"))
        codeIconButton:SetPoint("topleft", codeIconLabel, "bottomleft", 0, -2)
        mainFrame.CodeIconLabel = codeIconLabel
        mainFrame.CodeIconButton = codeIconButton

        --auto run
        local switchAutoRun = function(self, fixedParameter, value)
            return
        end
        local autorunCheckbox, autorunLabel = DF:CreateSwitch(scriptInfoFrame, switchAutoRun, false, _, _, _, _, _, _, _, _, _, "Auto Run on Login", DF:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE"), DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
        autorunCheckbox:SetAsCheckBox()
        autorunCheckbox:SetSize(20, 20)
        autorunCheckbox:ClearAllPoints()
        autorunCheckbox:SetPoint("topleft", codeIconLabel, "bottomleft", 100, -2)
        autorunCheckbox:SetValue(false)
        mainFrame.CodeAutorunCheckbox = autorunCheckbox

        autorunLabel:ClearAllPoints()
        autorunLabel:SetPoint("left", autorunCheckbox, "right", 2, 0)
        autorunLabel.text = "Auto Run on Login"

        --description
        local codeDescLabel = DF:CreateLabel(scriptInfoFrame, "Description:", DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
        local codeDescTextentry = DF:CreateTextEntry(scriptInfoFrame, function()end, settingsScrollBox.width, 20, "ScriptDescriptionTextEntry", _, _, options_dropdown_template)
        codeDescTextentry:SetPoint("topleft", codeDescLabel, "bottomleft", 0, -2)
        mainFrame.CodeDescLabel = codeDescLabel
        mainFrame.codeDescTextentry = codeDescTextentry



    --> create the script selection scroll box
        --the body of this function is on the file 'SL_ScriptMenu.lua'
        scriptLibrary.CreateScriptSelectionScrollBox()



    --> code editor
        local codeEditorFrame = CreateFrame("frame", "$parentCodeEditor", mainFrame)
        codeEditorFrame:SetSize(1, 1)
        codeEditorFrame:SetPoint("topleft", mainFrame, "topleft", settingsScrollBox.width+40, -180)

        --register into the window stack
        local onShowScriptInfoFrame = function()
        end
        local onHideScriptInfoFrame = function()
        end
        --window name, frame object, stack, show callback, hide callback
        scriptLibrary.RegisterFrame("codeEditorFrame", codeEditorFrame, scriptLibrary.FrameStack.codeEditorFrame, onShowScriptInfoFrame, onHideScriptInfoFrame)
        scriptLibrary.ShowWindow("codeEditorFrame")

        local codeEditor = DF:NewSpecialLuaEditorEntry(codeEditorFrame, codeEditorFrameSettings.width, codeEditorFrameSettings.height, "CodeEditor", "$parentCodeEditor", false, true)
        codeEditor:SetTextSize(config.options.text_size)
        codeEditor:SetPoint("topleft", codeEditorFrame, "topleft", 0, 0)

        --apply a different skin into the code editor
        scriptLibrary.ApplyEditorLayout(codeEditor)

        mainFrame.CodeEditor = codeEditor

        --code errors
        local errortextFrame = CreateFrame("frame", nil, codeEditor, "BackdropTemplate")
        errortextFrame:SetPoint("bottomleft", codeEditor, "bottomleft", 1, 1)
        errortextFrame:SetPoint("bottomright", codeEditor, "bottomright", -1, 1)
        errortextFrame:SetHeight(20)
        errortextFrame:SetFrameLevel(codeEditor:GetFrameLevel()+5)
        errortextFrame:SetBackdrop({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1, bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true})
        errortextFrame:SetBackdropBorderColor(0, 0, 0, 1)
        DF:ApplyStandardBackdrop(errortextFrame, false, 1)
        errortextFrame:SetBackdropColor(.3, .30, .30, .9)

        local errortextLabel = DF:CreateLabel(errortextFrame, "", DF:GetTemplate ("font", "ORANGE_FONT_TEMPLATE"))
        errortextLabel.textcolor = "silver"
        errortextLabel.textsize = 13
        errortextLabel:SetPoint("left", errortextFrame, "left", 3, 0)

        codeEditor.NextCodeCheck = 0.33

        codeEditor.editbox:HookScript("OnEnterPressed", function()
            --don't lose the focus of the editor when shift pressed
            if (IsShiftKeyDown()) then
                scriptLibrary.SaveCode()
                scriptLibrary.ExecuteCode()
                codeEditor.editbox:SetFocus (true)
                mainFrame.SaveButton.animationHub:Play()
                mainFrame.ExecuteButton.animationHub:Play()

            --if ctrl is pressed when the user pressed enter, save the script like if the user has pressed the Save button
            elseif (IsControlKeyDown()) then
                scriptLibrary.SaveCode()
                codeEditor.editbox:SetFocus (true)
                mainFrame.SaveButton.animationHub:Play()
            else
                codeEditor.editbox:Insert ("\n")
            end
        end)

        codeEditor:HookScript("OnUpdate", function (self, deltaTime)
            codeEditor.NextCodeCheck = codeEditor.NextCodeCheck - deltaTime
            if (codeEditor.NextCodeCheck < 0) then
                local script = codeEditor:GetText()
                script = "return " .. script
                local func, errortext = loadstring (script, "Q")
                if (not func) then
                    local firstLine = strsplit ("\n", script, 2)
                    errortext = errortext:gsub (firstLine, "")
                    errortext = errortext:gsub ("%[string \"", "")
                    errortext = errortext:gsub ("...\"]:", "")
                    errortext = errortext:gsub ("Q\"]:", "")
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
        local executeButton = DF:CreateButton(codeEditor, scriptLibrary.ExecuteCode, buttonsFrameSettings.width, buttonsFrameSettings.height, "Run", -1, nil, nil, nil, nil, nil, DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), DF:GetTemplate("font", "CODE_BUTTON"))
        executeButton:SetIcon([[Interface\BUTTONS\UI-Panel-BiggerButton-Up]], 20, 20, "overlay", {0.1, .9, 0.1, .9})
        executeButton.tooltip = "execute the code"
        mainFrame.ExecuteButton = executeButton

        local replaceButton = DF:CreateButton(codeEditor, scriptLibrary.ReplaceCode, buttonsFrameSettings.width, buttonsFrameSettings.height, "Replace", -1, nil, nil, nil, nil, nil, DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), DF:GetTemplate("font", "CODE_BUTTON"))
        replaceButton:SetIcon([[Interface\BUTTONS\UI-Panel-BiggerButton-Up]], 20, 20, "overlay", {0.1, .9, 0.1, .9})
        replaceButton.tooltip = "replaces the function within the global namespace or addon."
        mainFrame.ReplaceButton = replaceButton

        --save button
        local saveButton = DF:CreateButton(codeEditor, scriptLibrary.SaveCode, buttonsFrameSettings.width, buttonsFrameSettings.height, "Save", -1, nil, nil, nil, nil, nil, DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), DF:GetTemplate("font", "CODE_BUTTON"))
        saveButton:SetIcon([[Interface\BUTTONS\UI-Panel-ExpandButton-Up]], 20, 20, "overlay", {0.1, .9, 0.1, .9})
        mainFrame.SaveButton = saveButton

        --save button
        local reloadButton = DF:CreateButton(codeEditor, scriptLibrary.Reload, buttonsFrameSettings.width, buttonsFrameSettings.height, "ReloadUI", -1, nil, nil, nil, nil, nil, DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), DF:GetTemplate("font", "CODE_BUTTON"))
        reloadButton:SetIcon([[Interface\BUTTONS\UI-Panel-ExpandButton-Up]], 20, 20, "overlay", {0.1, .9, 0.1, .9})
        mainFrame.ReloadButton = reloadButton

        --shift + enter to execute
        local executeLabel = DF:CreateLabel(codeEditor, "[SHIFT + ENTER] to save and execute the code", DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
        executeLabel:SetPoint("left", reloadButton, "right", 100, 0)
        executeLabel.fontsize = 14
        executeLabel.color = {.8, .8, .8, .5}

        --addon name
        local addonNameLabel = DF:CreateLabel(codeEditor, "Addon Name within Global Namespace:", DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
        local addonNameTextentry = DF:CreateTextEntry(codeEditor, function()end, 200, 20, "AddonNameTextEntry", _, _, options_dropdown_template)
        addonNameTextentry:SetPoint("left", addonNameLabel, "right", 2, 0)

        --function name
        local functionNameLabel = DF:CreateLabel(codeEditor, "Function Name within Addon Namespace:", DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
        local functionNameTextentry = DF:CreateTextEntry(codeEditor, function()end, 200, 20, "FunctionNameTextEntry", _, _, options_dropdown_template)
        functionNameTextentry:SetPoint("left", functionNameLabel, "right", 2, 0)

        --arguments func
        local argumentsLabel = DF:CreateLabel(codeEditor, "Arguments to Pass to the Function:", DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
        local argumentsTextentry = DF:NewSpecialLuaEditorEntry(codeEditor, codeEditorFrameSettings.width, 60, "ArgumentsEditor", "$parentArgumentsEditor")

        --apply a different skin into the code editor
        scriptLibrary.ApplyEditorLayout(argumentsTextentry)

        argumentsTextentry:SetPoint("topleft", argumentsLabel.widget, "bottomleft", 0, -2)

        mainFrame.AddonNameTextEntry = addonNameTextentry
        mainFrame.FunctionNameTextEntry = functionNameTextentry
        mainFrame.ArgumentsTextEntry = argumentsTextentry

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

            local feedbackSaveButton_FlashAnimation = DF:CreateAnimationHub(feedbackSaveButton_Texture)
            DF:CreateAnimation(feedbackSaveButton_FlashAnimation, "alpha", 1, 0.08, 0, 0.2)
            DF:CreateAnimation(feedbackSaveButton_FlashAnimation, "alpha", 2, 0.08, 0.4, 0)

            local feedbackExecuteButton_FlashAnimation = DF:CreateAnimationHub(feedbackExecuteButton_Texture)
            DF:CreateAnimation(feedbackExecuteButton_FlashAnimation, "alpha", 1, 0.08, 0, 0.2)
            DF:CreateAnimation(feedbackExecuteButton_FlashAnimation, "alpha", 2, 0.08, 0.4, 0)

            local feedbackSaveButton_Animation = DF:CreateAnimationHub(saveButton, function() feedbackSaveButton_FlashAnimation:Play() end)
            local feedbackExecuteButton_Animation = DF:CreateAnimationHub(executeButton, function() feedbackExecuteButton_FlashAnimation:Play() end)

            local speed = 0.06
            local rotation = 0
            local translation = 7

            DF:CreateAnimation(feedbackSaveButton_Animation, "translation", 1, speed, 0, -translation)
            DF:CreateAnimation(feedbackSaveButton_Animation, "rotation", 1, speed, -rotation)
            DF:CreateAnimation(feedbackExecuteButton_Animation, "translation", 1, speed, 0, -translation)
            DF:CreateAnimation(feedbackExecuteButton_Animation, "rotation", 1, speed, -rotation)

            DF:CreateAnimation(feedbackSaveButton_Animation, "translation", 2, speed, 0, translation)
            DF:CreateAnimation(feedbackSaveButton_Animation, "rotation", 2, speed, rotation)
            DF:CreateAnimation(feedbackExecuteButton_Animation, "translation", 2, speed, 0, translation)
            DF:CreateAnimation(feedbackExecuteButton_Animation, "rotation", 2, speed, rotation)

            DF:CreateAnimation(feedbackSaveButton_Animation, "rotation", 3, speed, rotation)
            DF:CreateAnimation(feedbackSaveButton_Animation, "rotation", 4, speed, -rotation)
            DF:CreateAnimation(feedbackExecuteButton_Animation, "rotation", 3, speed, rotation)
            DF:CreateAnimation(feedbackExecuteButton_Animation, "rotation", 4, speed, -rotation)

            saveButton.animationHub = feedbackSaveButton_Animation
            executeButton.animationHub = feedbackExecuteButton_Animation

        --set points
        local xStart = 10
        mainFrame.CreateNewCodeButton:SetPoint("topleft", mainFrame, "topleft", xStart, -30)
        mainFrame.ImportButton:SetPoint("left", mainFrame.CreateNewCodeButton, "right", 2, 0)

        mainFrame.CodeNameLabel:SetPoint("topleft", mainFrame.CreateNewCodeButton, "bottomleft", 0, -15)
        mainFrame.CodeIconLabel:SetPoint("topleft", mainFrame.CodeNameLabel, "bottomleft", 0, -30)
        mainFrame.CodeDescLabel:SetPoint("topleft", mainFrame.CodeIconLabel, "bottomleft", 0, -30)
        mainFrame.CodeSearchLabel:SetPoint("topleft", mainFrame.CodeDescLabel, "bottomleft", 0, -30)

        addonNameLabel:SetPoint("bottomleft", codeEditor, "topleft", 0, 120)
        functionNameLabel:SetPoint("bottomleft", addonNameLabel, "topleft", 0, -32)
        argumentsLabel:SetPoint("bottomleft", functionNameLabel, "topleft", 0, -32)

        executeButton:SetPoint("topleft", codeEditor, "bottomleft", 0, -7)
        replaceButton:SetPoint("left", executeButton, "right", 7, 0)
        saveButton:SetPoint("left", replaceButton, "right", 7, 0)
        reloadButton:SetPoint("left", saveButton, "right", 7, 0)

        scriptLibrary.DisableAllWidgets()

    --> restore position
        local LibWindow = LibStub("LibWindow-1.1")
        LibWindow.RegisterConfig(mainFrame, config.main_frame)
        LibWindow.RestorePosition(mainFrame)
        LibWindow.MakeDraggable(mainFrame)

    scriptLibrary.Frame = mainFrame

    local changeFontSize = function(_, _, delta)
        if (delta) then
            config.options.text_size = min(config.options.text_size + 1, 16)
            codeEditor:SetTextSize(config.options.text_size)
        else
            config.options.text_size = max(config.options.text_size - 1, 8)
            codeEditor:SetTextSize(config.options.text_size)
        end
    end

    local increaseFontSizeButton = DF:CreateButton(mainFrame, changeFontSize, 40, 20, "aA", true, nil, nil, "decreaseFontSizeButton", nil, nil, DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), DF:GetTemplate("font", "CODE_BUTTON"))
    increaseFontSizeButton:SetPoint("bottomright", mainFrame, "bottomright", -32, 40)

    local decreaseFontSizeButton = DF:CreateButton(mainFrame, changeFontSize, 40, 20, "Aa", false, nil, nil, "decreaseFontSizeButton", nil, nil, DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE"), DF:GetTemplate("font", "CODE_BUTTON"))
    decreaseFontSizeButton:SetPoint("right", increaseFontSizeButton, "left", -2, 0)

    --done
    mainFrame:Show()
    scriptLibrary.bFramesBuilt = true
end