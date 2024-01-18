
---@class _G : table Global namespace
---@field LibStub {GetLibrary: fun(self: table, libraryName: string) : table}
---@field IsShiftKeyDown fun() : boolean
---@field IsControlKeyDown fun() : boolean
---@field loadstring fun(code: string, chunkName: string|nil) : function

---@class pagecache : {Code: string, CursorPosition: number, ScrollValue: number}

---@class scriptobject : table ScriptObject namespace
---@field CreateNew fun() : scriptobject create a new script object
---@field Select fun(scriptObject: scriptobject, pageId: number|nil) select a script object and page, if pageId is omitted, it will select the first page
---@field Save fun() save the current editing object
---@field Remove fun(codeId: number) remove a script object
---@field Duplicate fun(ID: number) duplicate a script object

---@class scriptpages : table ScriptPages namespace
---@field SelectedPage number store the pageId of the selected page
---@field MaxCodePages number amount of pages that can be created for each script object
---@field AllTabFrames df_tabbutton[] all tab frames
---@field RefreshTabFrames fun(scriptObject: scriptobject) refresh the tab frames
---@field CreateTabFrames fun() create tabs for pages
---@field GetPageTabFrame fun(pageId: number) : df_tabbutton get a tab frame for a page
---@field HideAllPageTabFrames fun() hide all page tab frames
---@field CreateNewPage fun(scriptObject: scriptobject, name: string|nil) : scriptpage create a scriptpage
---@field GetPage fun(scriptObject: scriptobject, pageId: number) : scriptpage get a scriptpage
---@field CanCreateNewPage fun(scriptObject: scriptobject) : boolean check if a scriptpage can be created
---@field RemovePage fun(scriptObject: scriptobject, pageId: number) : boolean remove a scriptpage
---@field GetNumPages fun(scriptObject: scriptobject) : number get the number of scriptpages in a scriptobject
---@field GetSelectedPageId fun() : number get the selected page id
---@field GetPageCache fun(pageId: number) : pagecache get the code from the cache
---@field SetPageCache fun(pageId: number, code: string|nil, cursorPosition: number|nil, scrollValue: number|nil) set the code to the cache
---@field RemovePageCache fun(pageId: number) remove the page from the cache
---@field AddPageToCache fun(code: string, cursorPosition: number, scrollValue: number) add a page to the cache
---@field BuildCodeCache fun(scriptObject: scriptobject) build the page code cache

---@class framesettings : table FrameSettings namespace
---@field settingsCodeEditor {width: number, height: number, pointX: number, pointY: number}
---@field settingsButtons {width: number, height: number}
---@field settingsScrollBox {width: number, height: number, lines: number, lineHeight: number, lineBackdropColor: number[], lineBackdropColorSelected: number[]}
---@field settingsOptionsFrame {width: number, height: number, scriptInfoX: number, scriptInfoY: number}

---@class windows : table Windows namespace
---@field ShowAllWindowsUpToStack fun(stack: number, ...) show all windows up to the current stack
---@field ShowWindow fun(ID: string, noStackSaving: boolean|nil, ...) : boolean show a window
---@field HideWindow fun(ID: string, ...) : boolean hide a window
---@field ReopenPreviousWindowStack fun() reopen the previous window stack
---@field RegisterFrame fun(ID: string, frame: frame, stack: number, showCallback: function|nil, hideCallback: function|nil)
---@field ApplyEditorLayout fun(frame: table) apply the editor layout to the frame passed
---@field DisableAllWidgets fun() disable all widgets in the main options frame
---@field EnableAllWidgets fun() enable all widgets in the main options frame
---@field SetupWidgetsForCode fun(scriptObject: scriptobject, pageIndex: number) get all settings from the code table and apply them into all widgets, such as code name, desc etc.

---@class codeexec : table CodeExec namespace
---@field IsFunctionNaked fun(funcString: string) : boolean check if a function is naked, meaning it has no arguments
---@field Compile fun(scriptObject: scriptobject) : function compile the code passed as string on funcString and return the function
---@field ExecuteCode fun() compile and execute the code

---@class framestack : table FrameStack namespace
---@field mainFrame number
---@field scriptInfoFrame number
---@field scriptMenuFrame number
---@field codeEditorFrame number
---@field importExportFrame number

---@class constants : table Constants namespace
---@field DeletePagePromptName string

---@class caches : table Caches namespace
---@field PagesCode table<number, pagecache> store the code of each page, hold the code until the scriptLibrary.ScriptObject.Save() is called

---@class scriptlibrary : table main addon object
---@field ScriptObject scriptobject namespace
---@field ScriptPages scriptpages namespace
---@field FrameSettings framesettings namespace
---@field Windows windows namespace
---@field CodeExec codeexec namespace
---@field FrameStack framestack namespace
---@field Constants constants namespace
---@field Caches caches namespace
---@field CurrentScriptObject scriptobject maintain a reference to the current script object (selected)
---@field MainFrame table
---@field bFramesBuilt boolean true if the addon frames were built
---@field Version number script version, used to update scripts when theres a change in the addon
---@field RegisteredWindows table
---@field ImportExport table
---@field GetMainFrame fun() : table get the main frame of the addon
---@field Reload fun() save, reload the user interface and reopen the editor
---@field GetData fun() : scriptobject[] get all saved script objects
---@field GetConfig fun() : table get the saved configuration
---@field Msg fun(...) print a message to the chat
---@field CreateMainOptionsFrame fun() create the main options frame
---@field OpenEditor fun() open the main frame of the addon, calling CreateMainOptionsFrame() if needed, this show the MainFrame
---@field CloseEditor fun() close the main frame of the addon, this hide the MainFrame
---@field ToggleEditor fun() toggle the main frame of the addon
---@field GetCurrentScriptObject fun() : scriptobject get the current script object (selected)
---@field GetScriptObject fun(scriptId: number) : scriptobject get a script object by id
---@field CheckVersion fun(scriptObject: scriptobject|nil) check if the script object version is the same as the addon version, if not it'll apply the necessary changes

---@class scriptpage : table page object
---@field Name string page name
---@field Code string code
---@field ScrollValue number scroll value of the code editor, this make the code editor scroll to the last position when the code is edited
---@field CursorPosition number cursor position of the code editor, this make the code editor be positioned at the last known position when the code is edited
---@field EditTime number time where the code was edit

---@class scriptobject : table script object
---@field Name string script name
---@field Icon string icon path or icon texture id
---@field Desc string script description
---@field Time number when the script was created
---@field Revision number how many times this script got changed
---@field Pages scriptpage[] list of script pages, these pages are shown in tabs in the code editor
---@field AutoRun boolean if auto run is enabled for this script, it'll run when the addon is loaded
---@field AddonName string addon name in the global namespace, used to replace a function in the addon namespace
---@field FunctionName string function name within the addon namespace
---@field Arguments string list of arguments to pass to the function
---@field Version number script version, used to update scripts when theres a change in the addon
---@field UseXPCall boolean if true, the script will run using xpcall instead of pcall
