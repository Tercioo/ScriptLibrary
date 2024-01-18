
--get the addon object
local addonName, scriptLibrary = ...
local _

---@cast scriptLibrary scriptlibrary

local date = date
local unpack = unpack
local CreateFrame = CreateFrame

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

--whern the player right click a script button in the left menu (where the scripts are selected)
local openContextMenuForScript = function(button)
    local ID = button.ID

    --generates a floating context menu and show it to the player
    GameCooltip:Preset(2)
    GameCooltip:SetType("menu")
    GameCooltip:SetOption("TextSize", 10)
    GameCooltip:SetOption("FixedWidth", 200)
    GameCooltip:SetOption("ButtonsYModSub", -1)
    GameCooltip:SetOption("YSpacingModSub", -4)
    GameCooltip:SetOwner(button, "topleft", "topright", 2, 0)
    GameCooltip:SetFixedParameter(ID)

    local scriptObject = scriptLibrary.GetScriptObject(ID)
    if (scriptObject) then
        --duplicate the script
        GameCooltip:AddLine("Duplicate")
        GameCooltip:AddMenu(1, function() scriptLibrary.ScriptObject.Duplicate(ID) end, "Duplicate", button)
        GameCooltip:AddIcon([[Interface\AddOns\Plater\images\icons]], 1, 1, 16, 16, 3/512, 21/512, 215/512, 233/512)

        --export script
        GameCooltip:AddLine("Export as Text")
        GameCooltip:AddIcon([[Interface\BUTTONS\UI-GuildButton-MOTD-Up]], 1, 1, 16, 16, 1, 0, 0, 1)
        GameCooltip:AddMenu(1, function() scriptLibrary.OpenImportExport(false, true, scriptObject) end, "Export", button)

        GameCooltip:SetOption("SubFollowButton", true)
        GameCooltip:Show()
    end
end

---create the left scroll frame, where the scripts are listed
---this scroll allow the user to select which script to edit
function scriptLibrary.CreateScriptSelectionScrollBox()
    local mainFrame = scriptLibrary.GetMainFrame()
    local settingsScrollBox = scriptLibrary.FrameSettings.settingsScrollBox
    local data = scriptLibrary.GetData()

    local codeScrollLabel = DF:CreateLabel(mainFrame, "Your Scripts:", DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
    codeScrollLabel:SetPoint("topleft", mainFrame, "topleft", 10, -250)
    mainFrame.CodeScrollLabel = codeScrollLabel

    local menuFrame = CreateFrame("frame", "$parentMenuFrame", mainFrame)
    menuFrame:SetPoint("topleft", codeScrollLabel.widget, "bottomleft", 0, -2)
    menuFrame:SetSize(1, 1)

    --register into the window stack
    local onShowScriptInfoFrame = function()
    end
    local onHideScriptInfoFrame = function()
    end

    --window name, frame object, stack, show callback, hide callback
    scriptLibrary.Windows.RegisterFrame("scriptMenuFrame", menuFrame, scriptLibrary.FrameStack.scriptMenuFrame, onShowScriptInfoFrame, onHideScriptInfoFrame)
    scriptLibrary.Windows.ShowWindow("scriptMenuFrame")

    ---refresh scroll function
    ---@param self scrollframe
    ---@param data table
    ---@param offset number
    ---@param totalLines number
    local refreshCodeScrollBox = function(self, data, offset, totalLines)
        --alphabetical order - note: alphabetical might not be a good idea in the future

        local data = scriptLibrary.GetData()

        ---@type {key1: number, key2: scriptobject, key3: string}[]
        local dataInOrder = {}

        if (mainFrame.SearchString ~= "" and type(mainFrame.SearchString) == "string") then
            mainFrame.SearchString = mainFrame.SearchString:lower()
            for i = 1, #data do
                if (data[i].Name:lower():find(mainFrame.SearchString)) then
                    dataInOrder[#dataInOrder+1] = {i, data[i], data[i].Name}
                end
            end
        else
            for i = 1, #data do
                dataInOrder[#dataInOrder+1] = {i, data[i], data[i].Name}
            end
        end

        table.sort(dataInOrder, function(t1, t2) return t1[3] < t2[3] end)

        local currentCode = scriptLibrary.GetCurrentScriptObject()

        --update the scroll
        for i = 1, totalLines do
            local index = i + offset
            local thisData = dataInOrder[index]
            if (thisData) then
                --get the data
                local codeId = thisData[1]
                local scriptObject = thisData[2]

                --update the line
                local line = self:GetLine(i)
                line:UpdateLine(codeId, scriptObject)

                if (scriptObject == currentCode) then
                    line:SetBackdropColor(unpack(settingsScrollBox.lineBackdropColorSelected))
                else
                    line:SetBackdropColor(unpack(settingsScrollBox.lineBackdropColor))
                end
            end
        end
    end

    local codeScrollBox = DF:CreateScrollBox(mainFrame, "$parentScrollBox", refreshCodeScrollBox, data, settingsScrollBox.width, settingsScrollBox.height, settingsScrollBox.lines, settingsScrollBox.lineHeight)
    DF:ReskinSlider(codeScrollBox)
    codeScrollBox:SetPoint("topleft", codeScrollLabel.widget, "bottomleft", 0, -2)
    mainFrame.CodeSelectionScrollBox = codeScrollBox

    local onEnterScrollLine = function(self)
        self:SetBackdropBorderColor(.5, .5, .5, 1)
    end
    local onLeaveScrollLine = function(self)
        self:SetBackdropBorderColor(0, 0, 0, 1)
    end
    local onClickScrollLine = function(self, button)
        if (button == "LeftButton") then
            scriptLibrary.ScriptObject.Select(self.ID)

        elseif (button == "RightButton") then
            openContextMenuForScript(self)
        end
    end
    local onClickRemoveButton = function(self)
        scriptLibrary.ScriptObject.Remove(self:GetParent().ID)
    end

    local updateLineFunction = function(self, ID, data)
        self.ID = ID
        self.CodeName.text = data.Name
        self.Icon:SetTexture(data.Icon)
        self.RunOnLabel.text = data.AutoRun and "run on login" or ""
    end

    local cooltipScriptsScrollbox = function(self, fixed_parameter)
        GameCooltip:Preset(2)
        GameCooltip:SetOption("TextSize", 10)
        GameCooltip:SetOption("FixedWidth", 200)

        local codeID = self.ID
        local scriptObject = scriptLibrary.GetScriptObject(codeID)
        if (not scriptObject) then
            return
        end

        --name
        GameCooltip:AddLine(scriptObject.Name, nil, 1, "yellow", "yellow", 11, "Friz Quadrata TT", "OUTLINE")

        --icon
        if (scriptObject.Icon ~= "") then
            GameCooltip:AddIcon(scriptObject.Icon)
        end

        --last edited
        local lastEdited = date("%d/%m/%Y", scriptObject.Time)
        GameCooltip:AddLine("Last Edited:", lastEdited)

        if (scriptObject.Desc and scriptObject.Desc ~= "") then
            GameCooltip:AddLine(scriptObject.Desc, "", 1, "gray")
        end
    end

    local cooltip_inject_table_scriptsscrollbox = {
        Type = "tooltip",
        BuildFunc = cooltipScriptsScrollbox,
        ShowSpeed = 0.016,
        MyAnchor = "topleft",
        HisAnchor = "topright",
        X = 10,
        Y = 0,
    }

    --create the scrollbox lines
    for i = 1, settingsScrollBox.lines do
        codeScrollBox:CreateLine(function(self, index)
            ---@type button
            local line = CreateFrame("button", "$parentLine" .. index, self, "BackdropTemplate")

            --set its parameters
            line:SetPoint("topleft", self, "topleft", 0, - ((index - 1) * (settingsScrollBox.lineHeight + 1)) - 0)
            line:SetSize(settingsScrollBox.width - 0, settingsScrollBox.lineHeight)
            line:RegisterForClicks("LeftButtonDown", "RightButtonDown")

            line:SetScript("OnEnter", onEnterScrollLine)
            line:SetScript("OnLeave", onLeaveScrollLine)
            line:SetScript("OnClick", onClickScrollLine)

            line.CoolTip = cooltip_inject_table_scriptsscrollbox
            GameCooltip:CoolTipInject(line)

            line:SetBackdrop({bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tileSize = 64, tile = true, edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
            line:SetBackdropColor(unpack(settingsScrollBox.lineBackdropColor))
            line:SetBackdropBorderColor(0, 0, 0, 1)

            local icon = line:CreateTexture("$parentIcon", "overlay")
            icon:SetSize(settingsScrollBox.lineHeight - 4, settingsScrollBox.lineHeight - 4)
            icon:SetTexCoord(.1, .9, .1, .9)

            local codeName = DF:CreateLabel(line, "", DF:GetTemplate ("font", "CODE_SCRIPTS_NAME"))
            local runOnLabel = DF:CreateLabel(line, "", DF:GetTemplate ("font", "CODE_SCRIPTS_RUNON"))

            ---@type button
            local removeButton = CreateFrame("button", "$parentRemoveButton", line, "UIPanelCloseButton")
            removeButton:SetSize(12, 12)
            removeButton:SetScript("OnClick", onClickRemoveButton)
            removeButton:SetPoint("topright", line, "topright", -3, -3)
            removeButton:GetNormalTexture():SetDesaturated(true)
            removeButton:SetAlpha(.4)

            --run button
            local runCodeFunc = function()
                local config = scriptLibrary.GetConfig()
                local currentlyOpen = config.last_opened_script
                scriptLibrary.ScriptObject.Select(line.ID)
                scriptLibrary.CodeExec.ExecuteCode()

                if (currentlyOpen) then
                    scriptLibrary.ScriptObject.Select(currentlyOpen)
                end

                C_Timer.After(.1, function()
                    mainFrame.CodeEditor:ClearFocus()
                end)
            end

            ---@type df_button
            local runButton = DF:CreateButton(line, runCodeFunc, 20, 18, nil, -1)
            runButton:SetIcon([[Interface\MONEYFRAME\Arrow-Right-Down]], 16, 16)
            runButton:SetPoint("bottomright", line, "bottomright", 13, 0)

            --setup anchors
            icon:SetPoint("left", line, "left", 2, 0)
            codeName:SetPoint("topleft", icon, "topright", 2, -2)
            runOnLabel:SetPoint("topleft", codeName, "bottomleft", 0, -2)

            line.Icon = icon
            line.CodeName = codeName
            line.RemoveButton = removeButton
            line.RunButton = runButton
            line.RunOnLabel = runOnLabel

            line.UpdateLine = updateLineFunction

            return line
        end)
    end

    ---search box callback when the text changes
    function mainFrame.OnSearchBoxTextChanged()
        local outputText = mainFrame.ScriptSearchTextEntry:GetText()
        mainFrame.SearchString = outputText:lower()
        codeScrollBox:Refresh()
    end

    local searchBoxTextentry = DF:CreateTextEntry(mainFrame, function()end, 200, 20, "ScriptSearchTextEntry", _, _, options_dropdown_template)
    searchBoxTextentry:SetHook("OnChar", mainFrame.OnSearchBoxTextChanged)
    searchBoxTextentry:SetHook("OnTextChanged", mainFrame.OnSearchBoxTextChanged)
    searchBoxTextentry:SetAsSearchBox()

    local searchScriptLabel = DF:CreateLabel(mainFrame, "Search:", DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"))
    searchBoxTextentry:SetPoint("topleft", searchScriptLabel, "bottomleft", 0, -2)
    mainFrame.SearchScriptLabel = searchScriptLabel
end