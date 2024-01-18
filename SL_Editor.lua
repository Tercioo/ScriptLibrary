
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

local availableWidgets = {
    {type = "frame", UIObject = "Frame", createFunc = function(parent, name) return CreateFrame("frame", name, parent, "BackdropTemplate") end},
    {type = "texture", UIObject = "Texture", createFunc = function(parent, name) return parent:CreateTexture(name, "overlay") end},
    {type = "fontstring", UIObject = "FontString", createFunc = function(parent, name) return parent:CreateFontString(name, "overlay", "GameFontNormal") end},
    {type = "statusbar", UIObject = "StatusBar", createFunc = function(parent, name) return CreateFrame("StatusBar", name, parent, "BackdropTemplate") end},
    
}

function scriptLibrary.CreateFrameEditor()
    local mainFrame = scriptLibrary.GetMainFrame()

    local espessuraRARA = 50

    local editorFrame = CreateFrame("frame", nil, UIParent)
    DF:ApplyStandardBackdrop(editorFrame)

    editorFrame:SetSize(espessuraRARA, espessuraRARA)
    editorFrame:SetSize("center", UIParent, "center", 300, 300)

    local verticalLine = CreateFrame("frame", nil, editorFrame, "BackdropTemplate")
    verticalLine:SetSize(espessuraRARA, 300)
    verticalLine:SetPoint("top", editorFrame, "bottom", 0, 0)
    DF:ApplyStandardBackdrop(verticalLine)

    local horizontalLine = CreateFrame("frame", nil, editorFrame, "BackdropTemplate")
    horizontalLine:SetSize(espessuraRARA, 300)
    horizontalLine:SetPoint("right", editorFrame, "left", 0, 0)
    DF:ApplyStandardBackdrop(horizontalLine)


    
end

function scriptLibrary.ShowFrameEditor()

end