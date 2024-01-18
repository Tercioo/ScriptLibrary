
local addonName, scriptLibrary = ...
local detailsFramework = DetailsFramework
local _

---@cast scriptLibrary scriptlibrary
local time = time
local wipe = table.wipe

local defaultCode = [[
	--place your code here
]]

local defaultCodeFirstPage = [[
    function (arg1, arg2)

        --place your code here

    end
]]

---check if a page can be added to the scriptobject passed
---@param scriptObject scriptobject
---@return boolean
function scriptLibrary.ScriptPages.CanCreateNewPage(scriptObject)
    return #scriptObject.Pages < scriptLibrary.ScriptPages.MaxCodePages
end

---create a new script page and return it
---@param scriptObject scriptobject
---@param pageName string|nil
---@return scriptpage
function scriptLibrary.ScriptPages.CreateNewPage(scriptObject, pageName)
    pageName = pageName or ("page " .. scriptLibrary.ScriptPages.GetNumPages(scriptObject) + 1)
    local nextPageId = #scriptObject.Pages + 1

    ---@type scriptpage
    local newPage = {
        Name = pageName,
        Code = nextPageId == 1 and defaultCodeFirstPage or defaultCode,
        CursorPosition = 1,
        ScrollValue = 1,
        EditTime = time(),
    }

    --add the page to the script object
    scriptObject.Pages[nextPageId] = newPage

    --add the page to the page cache
    scriptLibrary.ScriptPages.AddPageToCache(newPage.Code, 1, 1)

    return newPage
end

---get a page from the scriptobject passed
---@param scriptObject scriptobject
---@param pageId number
---@return scriptpage
function scriptLibrary.ScriptPages.GetPage(scriptObject, pageId)
    return scriptObject.Pages[pageId]
end

---remove a page from the passed scriptobject
---@param scriptObject scriptobject
---@param pageId number
---@return boolean
function scriptLibrary.ScriptPages.RemovePage(scriptObject, pageId)
    local selectedPageId = scriptLibrary.ScriptPages.GetSelectedPageId()
    local numPages = scriptLibrary.ScriptPages.GetNumPages(scriptObject)

    local pageRemoved = table.remove(scriptObject.Pages, pageId)
    if (pageRemoved) then
        scriptLibrary.ScriptPages.RemovePageCache(pageId)

        if (pageId == numPages) then --the last page was removed: select the previous one
            if (pageId == selectedPageId) then
                scriptLibrary.ScriptPages.SelectPage(scriptObject, pageId - 1)
            else
                scriptLibrary.ScriptPages.SelectPage(scriptObject, selectedPageId)
            end

        elseif (pageId == selectedPageId) then --the selected page was removed: select the next one
            scriptLibrary.ScriptPages.SelectPage(scriptObject, pageId)

        elseif (selectedPageId > pageId) then --the selected page has an higher index than the removed one: select the previous one
            scriptLibrary.ScriptPages.SelectPage(scriptObject, selectedPageId - 1)
        else
            --reselect the current tab to refresh the tab frames
            scriptLibrary.ScriptPages.SelectPage(scriptObject, selectedPageId)
        end
    end

    return pageRemoved and true
end

---get the number of pages in the scriptobject passed
---@param scriptObject scriptobject
---@return number
function scriptLibrary.ScriptPages.GetNumPages(scriptObject)
    return #scriptObject.Pages
end

---on click the tab frame callback, select the page
---@param self df_tabbutton
function scriptLibrary.ScriptPages.OnClickTabFrameFunc(self)
    --save the page contents to the cache
    local previousSelectedTabId = scriptLibrary.ScriptPages.GetSelectedPageId()
    scriptLibrary.ScriptPages.SetPageCache(previousSelectedTabId)

    --select the page
    local scriptObject = scriptLibrary.GetCurrentScriptObject()
    local pageId = self:GetID()
    scriptLibrary.ScriptPages.SelectPage(scriptObject, pageId)
end

---select the pageId passed, showing the code and setting the cursor and scroll position
---@param scriptObject scriptobject
---@param pageId number
function scriptLibrary.ScriptPages.SelectPage(scriptObject, pageId)
    --set the selected page
    scriptLibrary.ScriptPages.SelectedPage = pageId

    --refresh the code editor and widgets for the scriptObject and pageId passed
    scriptLibrary.Windows.SetupWidgetsForCode(scriptObject, pageId)

    --refresh the tab frames
    scriptLibrary.ScriptPages.RefreshTabFrames(scriptObject)
end

---return the cached code for the pageId passed
---caching the is necessary bacause there's only one editbox for code and code isn't saved by seleting another page
---@param pageId number
---@return pagecache
function scriptLibrary.ScriptPages.GetPageCache(pageId)
    return scriptLibrary.Caches.PagesCode[pageId]
end

---remove a page from the page cache
---@param pageId number
function scriptLibrary.ScriptPages.RemovePageCache(pageId)
    table.remove(scriptLibrary.Caches.PagesCode, pageId)
end

---set the cached code for the pageId passed
---@param pageId number
---@param code string
---@param cursorPosition number
---@param scrollValue number
function scriptLibrary.ScriptPages.SetPageCache(pageId, code, cursorPosition, scrollValue)
    local mainFrame = scriptLibrary.GetMainFrame()
    code = code or mainFrame.CodeEditor:GetText()
    cursorPosition = cursorPosition or mainFrame.CodeEditor.editbox:GetCursorPosition()
    scrollValue = scrollValue or mainFrame.CodeEditor.scroll:GetVerticalScroll()

    ---@type pagecache
    local pageCache = scriptLibrary.ScriptPages.GetPageCache(pageId) --pageId is nil, from SL_Core.111
    pageCache.Code = code
    pageCache.CursorPosition = cursorPosition
    pageCache.ScrollValue = scrollValue
end

---add a new page to the page cache
---@param code string
---@param cursorPosition number
---@param scrollValue number
function scriptLibrary.ScriptPages.AddPageToCache(code, cursorPosition, scrollValue)
    ---@type pagecache
    local pageCache = {Code = code, CursorPosition = cursorPosition, ScrollValue = scrollValue}
    table.insert(scriptLibrary.Caches.PagesCode, pageCache)
end

---called when a new scriptObject is selected
---@param scriptObject scriptobject
function scriptLibrary.ScriptPages.BuildCodeCache(scriptObject)
    --clear the current cache
    wipe(scriptLibrary.Caches.PagesCode)

    --build the new cache
    local numPages = scriptLibrary.ScriptPages.GetNumPages(scriptObject)
    for pageId = 1, numPages do
        local pageObject = scriptLibrary.ScriptPages.GetPage(scriptObject, pageId)
        ---@type pagecache
        local pageCache = {Code = pageObject.Code, CursorPosition = pageObject.CursorPosition, ScrollValue = pageObject.ScrollValue}
        table.insert(scriptLibrary.Caches.PagesCode, pageCache)
    end
end

---create tabs for pages
function scriptLibrary.ScriptPages.CreateTabFrames()
    local mainFrame = scriptLibrary.GetMainFrame()

    scriptLibrary.ScriptPages.AllTabFrames = {}

    for pageId = 1, scriptLibrary.ScriptPages.MaxCodePages do
        ---@type df_tabbutton
        local codePageTabSelector = detailsFramework:CreateTabButton(mainFrame, "$parentCodePageId" .. pageId)
        codePageTabSelector:SetScript("OnClick", scriptLibrary.ScriptPages.OnClickTabFrameFunc)
        codePageTabSelector:SetID(pageId)
        codePageTabSelector.CloseButton:SetSize(8, 8)
        codePageTabSelector.CloseButton:SetAlpha(0.3)
        codePageTabSelector.CloseButton:ClearAllPoints()
        codePageTabSelector.CloseButton:SetPoint("topright", codePageTabSelector, "topright", -1, -1)

        codePageTabSelector.CloseButton:SetScript("OnClick", function(self)
            local scriptObject = scriptLibrary.GetCurrentScriptObject()
            local trueCallback = function()
                --test if the scriptObject is still the same (the user did not selected another script to view)
                local currentScriptObject = scriptLibrary.GetCurrentScriptObject()
                if (scriptObject ~= currentScriptObject) then
                    return
                end

                local bPageRemoved = scriptLibrary.ScriptPages.RemovePage(scriptObject, pageId)
                if (not bPageRemoved) then
                    print("failed to remove page, bPageRemoved is nil")
                end
            end

            local dontOverride = true --won't show another prompt if there's already one showing
            local promptWidth = 300
            local promptName = scriptLibrary.Constants.DeletePagePromptName
            detailsFramework:ShowPromptPanel("Delete Page?", trueCallback, function()end, dontOverride, promptWidth, promptName)
        end)

        scriptLibrary.ScriptPages.AllTabFrames[#scriptLibrary.ScriptPages.AllTabFrames+1] = codePageTabSelector

        if (pageId == 1) then
            codePageTabSelector:SetPoint("bottomleft", mainFrame.CodeEditor, "topleft", 0, 1)
            codePageTabSelector.CloseButton:Hide()
        else
            codePageTabSelector:SetPoint("left", scriptLibrary.ScriptPages.AllTabFrames[pageId-1], "right", 2, 0)
        end

        codePageTabSelector:Hide()
    end

    --create the button to add a new page
    local createNewPageCallback = function()
        local scriptObject = scriptLibrary.GetCurrentScriptObject()
        scriptLibrary.ScriptPages.CreateNewPage(scriptObject)
        scriptLibrary.ScriptPages.RefreshTabFrames(scriptObject)
    end

    local buttonText = ""
    local param1 = false
    local param2 = false
    local buttonTexture = ""
    local buttonMember = false
    local shorteningMethod = false
    local buttonTemplate = detailsFramework:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")

    ---@type df_button
    local newPageButton = detailsFramework:CreateButton(mainFrame, createNewPageCallback, 26, 20, buttonText, param1, param2, buttonTexture, buttonMember, "$parentNewPageButton", shorteningMethod, buttonTemplate)
    newPageButton:SetIcon([[Interface\PaperDollInfoFrame\Character-Plus]], 18, 18, "overlay", {0, 1, 0, 1}, nil, 0, 0, 0, false)
    newPageButton:Hide()
    scriptLibrary.ScriptPages.NewPageButton = newPageButton
end

function scriptLibrary.ScriptPages.GetPageTabFrame(pageId)
    return scriptLibrary.ScriptPages.AllTabFrames[pageId]
end

function scriptLibrary.ScriptPages.GetSelectedPageId()
    return scriptLibrary.ScriptPages.SelectedPage
end

function scriptLibrary.ScriptPages.HideAllPageTabFrames()
    for i = 1, #scriptLibrary.ScriptPages.AllTabFrames do
        scriptLibrary.ScriptPages.AllTabFrames[i]:Reset()
        scriptLibrary.ScriptPages.AllTabFrames[i]:Hide()
    end
    scriptLibrary.ScriptPages.NewPageButton:Hide()
end

---reorder the tab frames to match the order of the pages
---@param scriptObject scriptobject
function scriptLibrary.ScriptPages.RefreshTabFrames(scriptObject)
    --reset all tab frames
    scriptLibrary.ScriptPages.HideAllPageTabFrames()

    --show the tab frames for the pages within the scriptObject
    local numPages = scriptLibrary.ScriptPages.GetNumPages(scriptObject)
    for pageId = 1, numPages do
        local pageTabFrame = scriptLibrary.ScriptPages.GetPageTabFrame(pageId)
        pageTabFrame:SetText(scriptLibrary.ScriptPages.GetPage(scriptObject, pageId).Name)
        pageTabFrame:Show()
    end

    --show the button to add a new page if new pages can be added
    if (scriptLibrary.ScriptPages.CanCreateNewPage(scriptObject)) then
        scriptLibrary.ScriptPages.NewPageButton:Show()
        scriptLibrary.ScriptPages.NewPageButton:ClearAllPoints()
        scriptLibrary.ScriptPages.NewPageButton:SetPoint("left", scriptLibrary.ScriptPages.GetPageTabFrame(numPages), "right", 2, 0)
    else
        scriptLibrary.ScriptPages.NewPageButton:Hide()
    end

    --as the proccess reset all tab frames, reselelect the selected page
    local selectedTabFrame = scriptLibrary.ScriptPages.GetPageTabFrame(scriptLibrary.ScriptPages.GetSelectedPageId())
    selectedTabFrame:SetSelected(true)
end