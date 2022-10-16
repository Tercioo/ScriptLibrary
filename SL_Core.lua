
--get the addon object
local addonName, scriptLibrary = ...
local _

local DF = _G ["DetailsFramework"]
if (not DF) then
	print ("|cFFFFAA00RuntimeEditor: framework not found, if you just installed or updated the addon, please restart your client.|r")
	return
end

local bIsDebugging = false


--this holds the object currently editing
scriptLibrary.CurrentScriptObject = nil

----------------------------------------------------------------------------------------------------------------------------------------------------------
--> script control

	local defaultCode = [[
	function (arg1, arg2)

		--paste your script here, between the 'function' and 'end' lines.


	end
	]]

	local defaultArguments = [[
	function()
		--insert here the arguments to be passed into the function name declared above
		return "arg1", "arg2";
	end
	]]

	--build a template table to be used as a new script object
	function scriptLibrary.CreateNewScript()
		local newScriptObject = {
			Name = "Your New Script",
			Icon = "",
			Desc = "",
			Time = time(), --creation time
			Revision = 1,
			Code = defaultCode,
			CursorPosition = 1,
			ScrollValue = 1,
			AutoRun = false,
			--the addon name in the global namespace
			AddonName = "",
			--function name within the addon namespace
			FunctionName = "",
			--list of arguments to pass to the function
			Arguments = defaultArguments,
			Version = 1,
		}

		--add it to the database
		local data = scriptLibrary.GetData()
		tinsert(data, newScriptObject)

		--start editing the new script
		scriptLibrary.SelectCode(#data)

		--refresh the scrollbox showing all codes created
		scriptLibrary.MainFrame.CodeSelectionScrollBox:Refresh()
	end

	function scriptLibrary.SelectCode(codeID)
		local data = scriptLibrary.GetData()
		local scriptObject = data[codeID]

		--if does not exists, just quit
		if (not scriptObject) then
			scriptLibrary.DisableAllWidgets()
			scriptLibrary:Msg("code not found.")
			local config = scriptLibrary.GetConfig()
			config.last_opened_script = false
			return
		end

		--if the importing window is open, close it
		--note: this will close the export window and restore the previous window stack
		scriptLibrary.CancelImportingOrExporting()

		if (scriptLibrary.CurrentScriptObject ~= scriptObject) then
			scriptLibrary.SaveCode()
		end

		scriptLibrary.EnableAllWidgets()
		scriptLibrary.CurrentScriptObject = scriptObject
		local config = scriptLibrary.GetConfig()
		config.last_opened_script = codeID
		scriptLibrary.SetupWidgetsForCode(scriptObject)

		--refresh scroll to update the color on the editing code
		scriptLibrary.MainFrame.CodeSelectionScrollBox:Refresh()
	end

	function scriptLibrary.RemoveCode(codeID)
		local data = scriptLibrary.GetData()
		local scriptObject = data[codeID]
		if (not scriptObject) then
			return
		end

		if (scriptObject == scriptLibrary.CurrentScriptObject) then
			scriptLibrary.DisableAllWidgets()
		end

		tremove(data, codeID)
		local config = scriptLibrary.GetConfig()
		config.last_opened_script = false
		scriptLibrary.MainFrame.CodeSelectionScrollBox:Refresh()
	end

	function scriptLibrary.GetScriptObject(ID)
		local data = scriptLibrary.GetData()
		return data[ID]
	end

	function scriptLibrary.GetCurrentScriptObject()
		return scriptLibrary.CurrentScriptObject
	end

	function scriptLibrary.DuplicateScriptObject(ID)
		local scriptObject = scriptLibrary.GetScriptObject(ID)
		if (scriptObject) then
			--copy the script
			local copy = DF.table.copytocompress({}, scriptObject)
			local data = scriptLibrary.GetData()

			--add it to the database
			tinsert(data, copy)

			--start editing the new script
			scriptLibrary.SelectCode(#data)

			--refresh the scrollbox showing all codes created
			scriptLibrary.MainFrame.CodeSelectionScrollBox:Refresh()

			scriptLibrary:Msg("Script Duplicated!")
		end
	end

	--get a script object and convert to a readable string
	function scriptLibrary.ImportExport.ScriptToString(scriptObject)
		if (not scriptObject) then
			return "fail on scriptLibrary.GetStringToExportScript()"
		end

		local tableToExport = DF.table.copytocompress({}, scriptObject)

		local LibAceSerializer = LibStub:GetLibrary ("AceSerializer-3.0")
		local LibDeflate = LibStub:GetLibrary ("LibDeflate")

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

	--get a string pasted into the import text entry and attempt to convert the string into a script
	function scriptLibrary.ImportExport.StringToScript(str)
		local LibAceSerializer = LibStub:GetLibrary ("AceSerializer-3.0")
		local LibDeflate = LibStub:GetLibrary ("LibDeflate")

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

		--add parameters removed on export
		scriptObject.CursorPosition = 1
		scriptObject.ScrollValue = 1

		--validate the received data

		--icon
		if (type(scriptObject.Icon) ~= "string" and type(scriptObject.Icon) ~= "number") then
			scriptObject.Icon = ""
		end

		--name
		if (not validateArgument(checkType(scriptObject.Name, "string"), "Imported string with invalid name.")) then
			return
		end

		--description
		if (not validateArgument(checkType(scriptObject.Desc, "string"), "Imported string with invalid description.")) then
			return
		end

		--cretion time
		if (not validateArgument(checkType(scriptObject.Time, "number"), "Imported string with invalid creation time.")) then
			return
		end

		--revision
		if (not validateArgument(checkType(scriptObject.Revision, "number"), "Imported string with invalid revision.")) then
			return
		end

		--code
		if (not validateArgument(checkType(scriptObject.Code, "string"), "Imported string with invalid code.")) then
			return
		end

		--auto run
		if (not validateArgument(checkType(scriptObject.AutoRun, "boolean"), "Imported string with invalid auto run parameter.")) then
			return
		end

		--addon name
		if (not validateArgument(checkType(scriptObject.AddonName, "string"), "Imported string with invalid addon name.")) then
			return
		end

		--function name
		if (not validateArgument(checkType(scriptObject.FunctionName, "string"), "Imported string with invalid function name.")) then
			return
		end

		--arguments
		if (not validateArgument(checkType(scriptObject.Arguments, "string"), "Imported string with invalid arguments.")) then
			return
		end

		--version
		if (not validateArgument(checkType(scriptObject.Version, "number"), "Imported string with invalid version.")) then
			return
		end

		local version = scriptObject.Version

		if (version == 1) then
			--it's all good, we're in version 1
		end

		local data = scriptLibrary.GetData()

		--add it to the database
		tinsert(data, scriptObject)

		--start editing the new script
		scriptLibrary.SelectCode(#data)

		--refresh the scrollbox showing all codes created
		scriptLibrary.MainFrame.CodeSelectionScrollBox:Refresh()

		scriptLibrary:Msg("Script imported!")
		return true
	end

----------------------------------------------------------------------------------------------------------------------------------------------------------
--> widget control

	--frame shown by default when opening the main window
	scriptLibrary.FrameShown = "mainFrame"

	--hide all registered windows above a stack level
	--@stack: the stack (number)
	--@dontHideThisFrame: won't hide the frame passed
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

	--show all registered windows up to a stack level
	--@stack: the stack (number)
	--@payload: send it to callback show function
	function scriptLibrary.ShowAllWindowsUpToStack(stack, ...)
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

	--show a frame to the user (from the options panel)
	--@ID: how the frame was identified
	--@payload: send it to callback show function
	function scriptLibrary.ShowWindow(ID, noStackSaving, ...)
		local frameTable = scriptLibrary.RegisteredWindows[ID]
		if (not frameTable) then
			scriptLibrary:Msg("could not find a window with ID:", ID)
			return
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

	--hide a frame from the user (from the options panel)
	--@ID: how the frame was identified
	--@payload: send it to hide callback function
	function scriptLibrary.HideWindow(ID, ...)
		local frameTable = scriptLibrary.RegisteredWindows[ID]
		if (not frameTable) then
			scriptLibrary:Msg("could not find a window with ID:", ID)
			return
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

	--restore the last opened stack of windows
	--a stack is saved when ShowWindow is called
	function scriptLibrary.ReopenPreviousWindowStack()
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
	--@ID: anything to identify the frame
	--@frame: frame object
	--@stack: how high is this window, hidding a window below the frame stack, make it hide as well
	--@showCallback: optional function run OnShow
	--@hideCallback: optional function run OnHide
    function scriptLibrary.RegisterFrame(ID, frame, stack, showCallback, hideCallback)
        scriptLibrary.RegisteredWindows[ID] = {frame = frame, stack = stack, showCallback = showCallback, hideCallback = hideCallback, ID = ID}
    end


    --apply a skin into a editor window
	function scriptLibrary.ApplyEditorLayout(frame)
		frame.scroll:SetBackdrop(nil)
		frame.editbox:SetBackdrop(nil)
		frame:SetBackdrop(nil)

		DF:ReskinSlider(frame.scroll)

		if (not frame.__background) then
			frame.__background = frame:CreateTexture(nil, "background")
		end

		frame:SetBackdrop({edgeFile = [[Interface\Buttons\WHITE8X8]], edgeSize = 1})
		frame:SetBackdropBorderColor(0, 0, 0, 1)

		local r, g, b, a = DF:GetDefaultBackdropColor()

		frame.__background:SetColorTexture(r, g, b, 0.94)
		frame.__background:SetVertexColor(r, g, b, 0.94)
		frame.__background:SetAlpha(0.8)
		frame.__background:SetVertTile(true)
		frame.__background:SetHorizTile(true)
		frame.__background:SetAllPoints()
	end


	function scriptLibrary.DisableAllWidgets()
		local f = scriptLibrary.MainFrame
		f.CodeNameTextEntry:Disable()
		f.CodeIconButton:Disable()
		f.codeDescTextentry:Disable()
		f.CodeEditor:Disable()
		f.ExecuteButton:Disable()
		f.SaveButton:Disable()
		f.ReloadButton:Disable()
		f.AddonNameTextEntry:Disable()
		f.FunctionNameTextEntry:Disable()
		f.ArgumentsTextEntry:Disable()
		f.CodeAutorunCheckbox:Disable()
		f.UseXPCallCheckbox:Disable()
	end

	function scriptLibrary.EnableAllWidgets()
		local f = scriptLibrary.MainFrame
		f.CodeNameTextEntry:Enable()
		f.CodeIconButton:Enable()
		f.codeDescTextentry:Enable()
		f.CodeEditor:Enable()
		f.ExecuteButton:Enable()
		f.SaveButton:Enable()
		f.ReloadButton:Enable()
		f.AddonNameTextEntry:Enable()
		f.FunctionNameTextEntry:Enable()
		f.ArgumentsTextEntry:Enable()
		f.CodeAutorunCheckbox:Enable()
		f.UseXPCallCheckbox:Enable()
	end

	--get all settings from the code table and apply them into all widgets, such as code name, desc etc.
	function scriptLibrary.SetupWidgetsForCode (scriptObject)
		local f = scriptLibrary.MainFrame
		f.CodeNameTextEntry:SetText (scriptObject.Name)
		f.CodeIconButton:SetIcon (scriptObject.Icon)
		f.codeDescTextentry:SetText (scriptObject.Desc)

		f.CodeEditor:SetText (scriptObject.Code)
		f.CodeEditor.editbox:SetFocus(true)
		f.CodeEditor.editbox:SetCursorPosition(scriptObject.CursorPosition)

		f.CodeAutorunCheckbox:SetValue(scriptObject.AutoRun)
		f.UseXPCallCheckbox:SetValue(scriptObject.UseXPCall)

		f.AddonNameTextEntry:SetText (scriptObject.AddonName)
		f.FunctionNameTextEntry:SetText (scriptObject.FunctionName)
		f.ArgumentsTextEntry:SetText (scriptObject.Arguments)

		C_Timer.After (.1, function()
			f.CodeEditor.scroll:SetVerticalScroll (scriptObject.ScrollValue)
			f.CodeEditor.scroll.ScrollBar:SetValue (scriptObject.ScrollValue)
		end)
	end

		--> open the main window
		function scriptLibrary.OpenEditor()
			if (not scriptLibrary.bFramesBuilt) then
				scriptLibrary.CreateMainOptionsFrame()
			else
				scriptLibrary.Frame:Show()
			end

			local config = scriptLibrary.GetConfig()
			scriptLibrary.Frame:SetScale(config.options.scale)
		end

		--> close the main  window
		function scriptLibrary.CloseEditor()
			if (not scriptLibrary.bFramesBuilt) then
				return
			else
				scriptLibrary.Frame:Hide()
			end
		end

		--> toggle the main window
		function scriptLibrary.ToggleEditor()
			if (not scriptLibrary.bFramesBuilt) then
				scriptLibrary.CreateMainOptionsFrame()
				scriptLibrary.Frame:Show()
				return
			end

			scriptLibrary.Frame:SetShown (not scriptLibrary.Frame:IsShown())
		end

		function scriptLibrary.OnInit()
			--hello world!

			--this is the obejct currently being edited
			scriptLibrary.CurrentEditingObject = false

			local config = scriptLibrary.GetConfig()
			if (config.auto_open) then
				C_Timer.After(0.5, function()
					scriptLibrary.OpenEditor()
					config.auto_open = false
					C_Timer.After(0.3, function()
						if (config.last_opened_script) then
							scriptLibrary.SelectCode(config.last_opened_script)
						end
					end)
				end)
			end

			--auto run code
			C_Timer.After(0.5, function()
				local data = scriptLibrary.GetData()
				for i = 1, #data do 
					local thisObject = data[i]
					if (thisObject.AutoRun) then
						local codeCompiled = scriptLibrary.Compile(thisObject.Code, thisObject.Name)
						if (type(codeCompiled) == "function") then
							local funcToRun = codeCompiled
							if (type(funcToRun) == "function") then
								local okay, errortext = pcall(funcToRun)
								if (not okay) then
									scriptLibrary:Msg("Code |cFFAAAA22" .. thisObject.Name .. "|r runtime error: " .. errortext)
								end
							end
						end
					end
				end
			end)
		end

		function scriptLibrary.GetCurrentObject()
			return scriptLibrary.CurrentEditingObject
		end

	C_Timer.After(0.1, function()
		if (bIsDebugging) then
			scriptLibrary.OpenEditor()
		end
	end)

	function OpenScriptLibrary() --global
		scriptLibrary.OpenEditor()
	end

	SLASH_SCRIPTLIBRARY1 = "/lua"
	SLASH_SCRIPTLIBRARY2 = "/code"
	SLASH_SCRIPTLIBRARY3 = "/scripts"

	function SlashCmdList.SCRIPTLIBRARY(msg, editbox)
		scriptLibrary.OpenEditor()
	end
