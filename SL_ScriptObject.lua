
--get the addon object
local addonName, scriptLibrary = ...
local _

local detailsFramework = _G ["DetailsFramework"]
if (not detailsFramework) then
	print ("|cFFFFAA00RuntimeEditor: framework not found, if you just installed or updated the addon, please restart your client.|r")
	return
end

local time = time

----------------------------------------------------------------------------------------------------------------------------------------------------------
--> script control

	---create a new script object
	---@return scriptobject
	function scriptLibrary.ScriptObject.CreateNew()
		local newScriptObject = {
			Name = "Your New Script",
			Icon = "",
			Desc = "",
			Time = time(), --creation time
			Revision = 1,
			Pages = {},
			AutoRun = false,
			UseXPCall = false,
			Version = 2,
		}

		scriptLibrary.ScriptPages.CreateNewPage(newScriptObject, "page 1")

		--add it to the database
		local data = scriptLibrary.GetData()
		table.insert(data, newScriptObject)

		--start editing the new script
		scriptLibrary.ScriptObject.Select(#data)

		--refresh the scrollbox showing all codes created
		scriptLibrary.MainFrame.CodeSelectionScrollBox:Refresh()

		return newScriptObject
	end

	---open the first script object found with the name passed, pageId optional (1 if ommited)
	---@param scriptName string
	---@param pageId number|nil
    function scriptLibrary.ScriptObject.SelectByBame(scriptName, pageId)
        local data = scriptLibrary.GetData()
        for i = 1, #data do
            local thisObject = data[i]
            if (thisObject.Name == scriptName) then
                scriptLibrary.ScriptObject.Select(i, pageId or 1)
				return
            end
        end
    end

	---open a script object by passing its ID and pageId
	---@param codeId number
	---@param pageId number|nil
	function scriptLibrary.ScriptObject.Select(codeId, pageId)
		local data = scriptLibrary.GetData()
		local scriptObject = data[codeId]

		--hide the remove page prompt if it's open
		local promptName = scriptLibrary.Constants.DeletePagePromptName
		detailsFramework:HidePromptPanel(promptName)

		--if does not exists, just quit
		if (not scriptObject) then
			scriptLibrary.Windows.DisableAllWidgets()
			scriptLibrary:Msg("code not found.")
			local config = scriptLibrary.GetConfig()
			config.last_opened_script = false
			return
		end

		--if the importing window is open, close it
		--note: this will close the export window and restore the previous window stack
		scriptLibrary.CancelImportingOrExporting()

		if (scriptLibrary.CurrentScriptObject ~= scriptObject) then
			scriptLibrary.ScriptObject.Save()
		end

		scriptLibrary.Windows.EnableAllWidgets()
		scriptLibrary.CurrentScriptObject = scriptObject
		local config = scriptLibrary.GetConfig()
		config.last_opened_script = codeId

		pageId = pageId or 1
		scriptLibrary.ScriptPages.BuildCodeCache(scriptObject)
		scriptLibrary.ScriptPages.RefreshTabFrames(scriptObject)
		scriptLibrary.ScriptPages.SelectPage(scriptObject, pageId)

		--refresh scroll to update the color on the editing code
		scriptLibrary.MainFrame.CodeSelectionScrollBox:Refresh()
	end

	---save the current script object
	function scriptLibrary.ScriptObject.Save()
		local scriptObject = scriptLibrary.GetCurrentScriptObject()
		if (not scriptObject) then
			return
		end

		--get the current selected pageId and set the code to the cache
		local pageId = scriptLibrary.ScriptPages.GetSelectedPageId()
		local mainFrame = scriptLibrary.GetMainFrame()
		scriptLibrary.ScriptPages.SetPageCache(pageId)

		scriptObject.Name = mainFrame.CodeNameTextEntry:GetText()
		scriptObject.Icon = mainFrame.CodeIconButton:GetIconTexture()
		scriptObject.Desc = mainFrame.codeDescTextentry:GetText()
		scriptObject.Time = time()
		scriptObject.AutoRun = mainFrame.CodeAutorunCheckbox:GetValue()
		scriptObject.UseXPCall = mainFrame.UseXPCallCheckbox:GetValue()
		scriptObject.Revision = scriptObject.Revision + 1

		--transfer the code, cursor, scroll value from the cache to the page object
		local numPages = scriptLibrary.ScriptPages.GetNumPages(scriptObject)
		for i = 1, numPages do
			local pageObject = scriptLibrary.ScriptPages.GetPage(scriptObject, i)
			local pageCache = scriptLibrary.ScriptPages.GetPageCache(i)
			pageObject.Code = pageCache.Code
			pageObject.CursorPosition = pageCache.CursorPosition
			pageObject.ScrollValue = pageCache.ScrollValue
		end

		mainFrame.CodeNameTextEntry:ClearFocus()
		mainFrame.codeDescTextentry:ClearFocus()
		mainFrame.CodeEditor:ClearFocus()

		--refresh the scroll to update name and icon
		scriptLibrary.MainFrame.CodeSelectionScrollBox:Refresh()
	end

	---remove a script object by ID
	---@param codeId number
	function scriptLibrary.ScriptObject.Remove(codeId)
		local data = scriptLibrary.GetData()
		local scriptObject = data[codeId]
		if (not scriptObject) then
			return
		end

		if (scriptObject == scriptLibrary.CurrentScriptObject) then
			scriptLibrary.Windows.DisableAllWidgets()
			scriptLibrary.ScriptPages.HideAllPageTabFrames()
		end

		table.remove(data, codeId)
		local config = scriptLibrary.GetConfig()
		config.last_opened_script = false
		scriptLibrary.MainFrame.CodeSelectionScrollBox:Refresh()
	end

	---duplicate a script object by ID
	---@param codeId number
	function scriptLibrary.ScriptObject.Duplicate(codeId)
		local scriptObject = scriptLibrary.GetScriptObject(codeId)
		if (scriptObject) then
			--copy the script
			local copy = detailsFramework.table.copytocompress({}, scriptObject)
			local data = scriptLibrary.GetData()

			--add it to the database
			table.insert(data, copy)

			--start editing the new script
			scriptLibrary.ScriptObject.Select(#data)

			--refresh the scrollbox showing all codes created
			scriptLibrary.MainFrame.CodeSelectionScrollBox:Refresh()

			scriptLibrary:Msg("Script Duplicated!")
		end
	end