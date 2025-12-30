local myname, ns = ...
local myfullname = C_AddOns.GetAddOnMetadata(myname, "Title")
local db

function ns.Print(...) print("|cFF33FF99".. myfullname.. "|r:", ...) end

-- events
local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, ...) if ns[event] then return ns[event](ns, event, ...) end end)
function ns:RegisterEvent(...) for i=1,select("#", ...) do f:RegisterEvent((select(i, ...))) end end
function ns:UnregisterEvent(...) for i=1,select("#", ...) do f:UnregisterEvent((select(i, ...))) end end

function setDefaults(options, defaults)
    setmetatable(options, { __index = function(t, k)
        if type(defaults[k]) == "table" then
            t[k] = setDefaults({}, defaults[k])
            return t[k]
        end
        return defaults[k]
    end, })
    -- and add defaults to existing tables
    for k, v in pairs(options) do
        if defaults[k] and type(v) == "table" then
            setDefaults(v, defaults[k])
        end
    end
    return options
end

local defaults = {
    objects = {
        ["Edge of Reality"] = true,
    }
}

function ns:ADDON_LOADED(event, addon)
    if addon == myname then
        _G[myname.."DB"] = setDefaults(_G[myname.."DB"] or {}, defaults)
        db = _G[myname.."DB"]

        if _G.C_TooltipInfo then
            -- Cata-classic has TooltipDataProcessor, but doesn't actually use the new tooltips
            TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Object, function(tooltip, tooltipData)
                if tooltip ~= GameTooltip then return end
                if not (tooltipData and tooltipData.lines) then
                    return
                end
                ns.CheckAndAnnounce(tooltipData.lines[1].leftText)
            end)
        else
            GameTooltip:HookScript("OnShow", function(tooltip)
                if tooltip:GetUnit() or tooltip:GetItem() or tooltip:GetSpell() then return end
                local title = _G[tooltip:GetName() .. "TextLeft1"]
                if not title then return end
                ns.CheckAndAnnounce(title:GetText())
            end)
        end
    end
end
ns:RegisterEvent("ADDON_LOADED")

function ns.CheckAndAnnounce(titleText)
    -- ns.Print("Tooltip shown with title", titleText)
    if not titleText then return end
    if issecretvalue and issecretvalue(titleText) then return end
    if db.objects[titleText] then
        local willPlay, soundHandle = PlaySound(11466, "master", true)
        ns.Print("Seen:", titleText)
    end
end

-- Quick config:

_G["SLASH_".. myname:upper().."1"] = "/objectscanner"
SlashCmdList[myname:upper()] = function(msg)
    msg = msg:trim()
    if msg ~= "" then
        db.objects[msg] = not db.objects[msg]
        ns.Print(db.objects[msg] and "Now" or "No longer", "looking for", msg)
    elseif msg == "" then
        ns.Print("Currently scanning tooltips for:")
        for name in pairs(db.objects) do
            if db.objects[name] then
                ns.Print("-", name)
            end
        end
        for name in pairs(defaults.objects) do
            if rawget(db.objects, name) == nil then
                ns.Print("-", name)
            end
        end
        ns.Print("Toggle with /objectscanner [name]")
    end
end
