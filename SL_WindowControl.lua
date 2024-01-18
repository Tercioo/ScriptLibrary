
local addonName, scriptLibrary = ...
local detailsFramework = DetailsFramework
local _

---@cast scriptLibrary scriptlibrary

--frame shown by default when opening the main window
scriptLibrary.FrameShown = "mainFrame"

---hide all registered windows above a stack level
---@param stack number the stack
---@param dontHideThisFrame boolean|nil won't hide the frame passed
local hideWindowsOfSameStackOrAbove = function(stack, dontHideThisFrame)
    for ID, frameTable in pairs(scriptLibrary.RegisteredWindows) do
        if (not dontHideThisFrame or (dontHideThisFrame ~= frameTable.frame)) then
            --debug:
            if (type(frameTable.stack) ~= "number") then
                print("debug:", frameTable.stack, frameTable.ID)
            end

            if (frameTable.stack >= stack) then
                if (frameTable.frame:IsShown()) then
                    local func = frameTable.hideCallback
                    if (func) then
                        func(frameTable.frame)
                    end
                    frameTable.frame:Hide()
                end
            end
        end
    end
end

---show all registered windows up to a stack level
---@param stack number the stack
---@param ... any send it to callback show function
function scriptLibrary.Windows.ShowAllWindowsUpToStack(stack, ...)
    for ID, frameTable in pairs(scriptLibrary.RegisteredWindows) do
        if (frameTable.stack <= stack) then
            if (not frameTable.frame:IsShown()) then
                frameTable.frame:SetShown(true)
                local func = frameTable.showCallback
                if (func) then
                    func(frameTable.frame, ...)
                end
            end
        end
    end
end

---show a frame to the user (from the options panel)
---@param ID string how the frame was identified
---@param noStackSaving boolean|nil if true, will not save the current stack
---@param ... any send it to callback show function
---@return boolean
function scriptLibrary.Windows.ShowWindow(ID, noStackSaving, ...)
    local frameTable = scriptLibrary.RegisteredWindows[ID]
    if (not frameTable) then
        scriptLibrary:Msg("could not find a window with ID:", ID)
        return false
    end

    --save current stack before hiding the frames
    if (not noStackSaving) then
        local currentStack = {}
        for frameID, frameTable in pairs(scriptLibrary.RegisteredWindows) do
            if (frameTable.frame:IsShown()) then
                currentStack[#currentStack+1] = frameID
            end
        end
        scriptLibrary.previousStackWindowIDs = currentStack
    end

    --get the stack of the window which was requested to be opened
    local stack = frameTable.stack

    --hide everything above the stack
    hideWindowsOfSameStackOrAbove(stack)

    --show the requested frame
    frameTable.frame:SetShown(true)

    --after the frame is shown, call its callback
    local func = frameTable.showCallback
    if (func) then
        func(frameTable.frame, ...)
    end

    return true
end

---hide a frame from the user (from the options panel)
---@param ID string how the frame was identified
---@param ... any send it to hide callback function
---@return boolean
function scriptLibrary.Windows.HideWindow(ID, ...)
    local frameTable = scriptLibrary.RegisteredWindows[ID]
    if (not frameTable) then
        scriptLibrary:Msg("could not find a window with ID:", ID)
        return false
    end

    local stack = frameTable.stack
    --hide all frames with same stack or above, but do not hide this frame
    hideWindowsOfSameStackOrAbove(stack, frameTable.frame)

    --before the frame is hide, call its callback
    local func = frameTable.hideCallback
    if (func) then
        func(frameTable.frame, ...)
    end

    frameTable.frame:SetShown(false)
    return true
end

---restore the last opened stack of windows
---a stack is saved when ShowWindow is called
function scriptLibrary.Windows.ReopenPreviousWindowStack()
    local windowIDs = scriptLibrary.previousStackWindowIDs
    local windowOrder = {}

    for i, ID in ipairs(windowIDs) do
        local frameTable = scriptLibrary.RegisteredWindows[ID]
        windowOrder[#windowOrder+1] = {ID, frameTable, frameTable.stack}
    end

    --order windows to show again in order of bottom to top
    table.sort(windowOrder, function(t1, t2) return t1[3] < t2[3] end)

    --reopen without calling callbacks, the goal is to have these windows showing the same thing as previously
    for i, windowInformation in ipairs(windowOrder) do
        local frameTable = windowInformation[2]
        if (not frameTable.frame:IsShown()) then
            frameTable.frame:SetShown(true)
        end
    end
end

--internally register a frame, the function above can show registered frames and call their callbacks to update information
---@param ID string frame identification
---@param frame table frame object
---@param stack number how high is this window, hidding a window below the frame stack, make it hide as well
---@param showCallback function|nil optional function run OnShow
---@param hideCallback function|nil optional function run OnHide
function scriptLibrary.Windows.RegisterFrame(ID, frame, stack, showCallback, hideCallback)
    scriptLibrary.RegisteredWindows[ID] = {frame = frame, stack = stack, showCallback = showCallback, hideCallback = hideCallback, ID = ID}
end

---apply a skin into a editor window
function scriptLibrary.Windows.ApplyEditorLayout(frame)
    frame.scroll:SetBackdrop(nil)
    frame.editbox:SetBackdrop(nil)
    frame:SetBackdrop(nil)

    detailsFramework:ReskinSlider(frame.scroll)

    if (not frame.__background) then
        frame.__background = frame:CreateTexture(nil, "background")
    end

    frame:SetBackdrop({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
    frame:SetBackdropBorderColor(0, 0, 0, 1)

    local r, g, b, a = detailsFramework:GetDefaultBackdropColor()

    frame.__background:SetColorTexture(r, g, b, 0.94)
    frame.__background:SetVertexColor(r, g, b, 0.94)
    frame.__background:SetAlpha(0.8)
    frame.__background:SetVertTile(true)
    frame.__background:SetHorizTile(true)
    frame.__background:SetAllPoints()
end

function scriptLibrary.Windows.DisableAllWidgets()
    local mainFrame = scriptLibrary.GetMainFrame()
    mainFrame.CodeNameTextEntry:Disable()
    mainFrame.CodeIconButton:Disable()
    mainFrame.codeDescTextentry:Disable()
    mainFrame.CodeEditor:Disable()
    mainFrame.ExecuteButton:Disable()
    mainFrame.SaveButton:Disable()
    mainFrame.ReloadButton:Disable()
    mainFrame.CodeAutorunCheckbox:Disable()
    mainFrame.UseXPCallCheckbox:Disable()
end

function scriptLibrary.Windows.EnableAllWidgets()
    local mainFrame = scriptLibrary.GetMainFrame()
    mainFrame.CodeNameTextEntry:Enable()
    mainFrame.CodeIconButton:Enable()
    mainFrame.codeDescTextentry:Enable()
    mainFrame.CodeEditor:Enable()
    mainFrame.ExecuteButton:Enable()
    mainFrame.SaveButton:Enable()
    mainFrame.ReloadButton:Enable()
    mainFrame.CodeAutorunCheckbox:Enable()
    mainFrame.UseXPCallCheckbox:Enable()
end

---get all settings from the code table and apply them into all widgets, such as code name, desc etc.
---@param scriptObject scriptobject
---@param pageId number|nil
function scriptLibrary.Windows.SetupWidgetsForCode(scriptObject, pageId)
    pageId = pageId or 1

    local mainFrame = scriptLibrary.GetMainFrame()
    mainFrame.CodeNameTextEntry:SetText(scriptObject.Name)
    mainFrame.CodeIconButton:SetIcon(scriptObject.Icon)
    mainFrame.codeDescTextentry:SetText(scriptObject.Desc)

    --get the page object
    local pageObject = scriptLibrary.ScriptPages.GetPage(scriptObject, pageId)

    mainFrame.CodeEditor:SetText(pageObject.Code)
    mainFrame.CodeEditor.editbox:SetFocus(true)

    if (not pageObject.CursorPosition or pageObject.CursorPosition == 0) then
        --print("pageObject.CursorPosition invalid:", pageObject.CursorPosition)
        pageObject.CursorPosition = 1
    end

    if (not pageObject.ScrollValue or pageObject.ScrollValue == 0) then
        --print("pageObject.ScrollValue invalid:", pageObject.ScrollValue)
        pageObject.ScrollValue = 1
    end

    mainFrame.CodeEditor.editbox:SetCursorPosition(pageObject.CursorPosition)

    mainFrame.CodeAutorunCheckbox:SetValue(scriptObject.AutoRun)
    mainFrame.UseXPCallCheckbox:SetValue(scriptObject.UseXPCall)

    C_Timer.After(.1, function()
        mainFrame.CodeEditor.scroll:SetVerticalScroll(pageObject.ScrollValue)
        mainFrame.CodeEditor.scroll.ScrollBar:SetValue(pageObject.ScrollValue)
    end)
end

--open the main window
function scriptLibrary.OpenEditor()
    if (not scriptLibrary.bFramesBuilt) then
        scriptLibrary.CreateMainOptionsFrame()
    else
        scriptLibrary.MainFrame:Show()
    end

    local config = scriptLibrary.GetConfig()
    scriptLibrary.MainFrame:SetScale(config.options.scale)
end

--close the main  window
function scriptLibrary.CloseEditor()
    if (not scriptLibrary.bFramesBuilt) then
        return
    else
        scriptLibrary.MainFrame:Hide()
    end
end

--toggle the main window
function scriptLibrary.ToggleEditor()
    if (not scriptLibrary.bFramesBuilt) then
        scriptLibrary.CreateMainOptionsFrame()
        scriptLibrary.MainFrame:Show()
        return
    end

    scriptLibrary.MainFrame:SetShown(not scriptLibrary.MainFrame:IsShown())
end