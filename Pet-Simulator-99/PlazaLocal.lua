local timer = tick()
if not game:IsLoaded() then 
    game.Loaded:Wait()
end

local PS99 = {Pro = 15588442388, Normal = 15502339080}
local PETSGO = {Pro = 133783083257328, Normal = 19006211286}

local StartingTime = os.time()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local LogService = game:GetService("LogService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
repeat task.wait() 
    LocalPlayer = Players.LocalPlayer
until LocalPlayer and LocalPlayer.GetAttribute and LocalPlayer:GetAttribute("__LOADED")
if not LocalPlayer.Character then 
    LocalPlayer.CharacterAdded:Wait() 
end
local HumanoidRootPart = LocalPlayer.Character.HumanoidRootPart

--// GLOBAL
local NLibrary = ReplicatedStorage.Library
local PlayerSave = require(NLibrary.Client.Save) 
local TradingPlazaCmds = require(NLibrary.Client.TradingPlazaCmds)
local Abstract = require(NLibrary.Items.AbstractItem)
local Types = require(NLibrary.Items.Types)
local ParseAssetId = require(NLibrary.Functions.ParseAssetId)
local Directory = require(NLibrary.Directory)
local PlayerScripts = LocalPlayer.PlayerScripts.Scripts
local Rarities = table.clone(require(NLibrary.Directory.Rarity))
local Mailbox = require(NLibrary.Types.Mailbox)
--// PS99
if table.find({PS99.Normal, PS99.Pro}, game.PlaceId) then
    if #TradingPlazaCmds.GetAvailable() > 1 then
        CanUsePro = true
    end
    Constants = require(NLibrary.Balancing.Constants)
end


--// PETS GO
if table.find({PETSGO.Normal, PETSGO.Pro}, game.PlaceId) then
    UpgradeCmds = require(NLibrary.Client.UpgradeCmds)
    Variables = require(NLibrary.Shared.Variables)
end

local LoadModules = function(Path, LoadTable)
    for _,v in next, Path:GetChildren() do
        if v:IsA("ModuleScript") and not v:GetAttribute("NOLOAD") then
            local Status, Module = pcall(require, v)
            if Status then
                LoadTable[v.Name] = Module
            end
        end
    end
end
if not getgenv().Library then
    getgenv().Library = {}
    LoadModules(NLibrary.Client, getgenv().Library)
    LoadModules(NLibrary, getgenv().Library)
end

local Booths, ClaimedBooths, BoothsInteractive, Interacts
if table.find({PS99.Pro, PS99.Normal, PETSGO.Normal, PETSGO.Pro}, game.PlaceId) then
    repeat task.wait() 
        Booths = getsenv(NLibrary.Client:FindFirstChild("BoothCmds") or LocalPlayer.PlayerScripts.Scripts.Game["Trading Plaza"]["Booths Frontend"]).getState
    until Booths
    Booths = getupvalues(Booths)
    repeat task.wait() 
        Interacts = getsenv(NLibrary.Client:FindFirstChild("BoothCmds") or LocalPlayer.PlayerScripts.Scripts.Game["Trading Plaza"]["Booths Frontend"]).updateAllInteracts
    until Interacts
    ClaimedBooths = getupvalues(Interacts)[1]
    BoothsInteractive = getupvalues(Interacts)[3]
end


--// File Setup
local DefaultSettings = {Sniper = false, Seller = false}
local FileSettings = {}
local OGFileSettings = {}
local FolderPath = "System Exodus/" .. (table.find({PETSGO.Normal, PETSGO.Pro}, game.PlaceId) and "PETS GO" or "Pet Simulator 99")
local FileName = FolderPath .. "/" .. LocalPlayer.Name .. " Plaza Plus.cfg"
if not isfolder("System Exodus") then makefolder("System Exodus") end
if not isfolder(FolderPath) then makefolder(FolderPath) end
if not isfile(FileName) then writefile(FileName, HttpService:JSONEncode(DefaultSettings)) end
local function LoadSettings()
    local success, result = pcall(function()
        local content = readfile(FileName)
        return HttpService:JSONDecode(content)
    end)
    if success and typeof(result) == "table" then
        return result
    else
        writefile(FileName, HttpService:JSONEncode(DefaultSettings))
        return DefaultSettings
    end
end
OGFileSettings = LoadSettings()
local function Save()
    writefile(FileName, HttpService:JSONEncode(OGFileSettings))
end
setmetatable(FileSettings, {
    __index = OGFileSettings,
    __newindex = function(_, key, value)
        if OGFileSettings[key] ~= value then
            OGFileSettings[key] = value
            Save()
        end
    end
})

local SuffixesLower = {"k", "m", "b", "t"}
local SuffixesUpper = {"K", "M", "B", "T"}
local function AddSuffix(Amount)
    if not Amount or type(Amount) ~= "number" then
        return "UNKNOWN"
    end
    if Amount == 0 then
        return "0"
    end
    local IsNegative = Amount < 0
    Amount = math.abs(Amount)
    local a = math.floor(math.log(Amount, 1e3))
    local b = math.pow(10, a * 3)
    return (IsNegative and "-" or "")..("%.2f"):format(Amount / b):gsub("%.?0+$", "") .. (SuffixesLower[a] or "")
end
local function RemoveSuffix(Amount)
	local a, Suffix = Amount:gsub("%a", ""), Amount:match("%a")	
	local b = table.find(SuffixesUpper, Suffix) or table.find(SuffixesLower, Suffix) or 0
	return tonumber(a) * math.pow(10, b * 3)
end

local function RemoveSuffix(Amount)
	local Number, Suffix = Amount:gsub("%a", ""), Amount:match("%a")	
	local Type = table.find(SuffixesUpper, Suffix) or table.find(SuffixesLower, Suffix) or 0
	return tonumber(Number) * math.pow(10, Type * 3)
end

local UI = {}
local function SetUISettings(Type)
    for Name, Params in next, Type do
        if type(Params) ~= "table" then continue end
        if Name == "Switch Servers" and Params.Active then
            UI["Switch Servers"] = true
            UI["Teleport Delay"] = Params.SecondDelay or Params.MinuteDelay and Params.MinuteDelay*60
            UI["Only Pro"] = Params.OnlyPRO
        end
        if Name == "Webhook" and Params.Active and Params.URL ~= "" then
            UI["URL"] = Params.URL
        end
        if Name == "Kill Switch" then
            for InsideName, Value in next, Params do
                if not Value then continue end
                if InsideName:find("Switch To") then 
                    UI["Switch To "..InsideName:split("To ")[2]] = Value
                elseif InsideName:find("Minutes Timer") then
                    UI["Minutes Timer"] = tonumber(InsideName:split(" Minutes")[1])*60
                elseif InsideName:find("Diamonds Hit") then
                    UI["Diamonds Hit"] = RemoveSuffix(InsideName:split("Diamonds Hit: ")[2])
                else
                    UI[InsideName] = Value
                end
            end
        end
        if Name == "Diamonds Sendout" and Params.Active then
            UI["Diamonds Sendout"] = {Username = Params.Username, Amount = RemoveSuffix(Params.Amount)}
        end
    end
end
if (Settings.Sniper and Settings.Sniper.Active) and (Settings.Seller and Settings.Seller.Active) and not (FileSettings.Sniper or FileSettings.Seller) then
    FileSettings.Sniper = true
end
if (Settings.Sniper and Settings.Sniper.Active) and (Settings.Seller and not Settings.Seller.Active) or not Settings.Seller then
    FileSettings.Sniper = true
elseif (Settings.Seller and Settings.Seller.Active) and (Settings.Sniper and not Settings.Sniper.Active) or not Settings.Sniper then
    FileSettings.Seller = true
end
if Settings.Sniper and Settings.Sniper.Active and FileSettings.Sniper then
    SetUISettings(Settings.Sniper)
end
if Settings.Seller and Settings.Seller.Active and FileSettings.Seller then
    SetUISettings(Settings.Seller)
end

local function ColorizeConsole()
    local Console = CoreGui:FindFirstChild("DevConsoleMaster", true)
    if not Console then return end
    local ClientLog = Console:FindFirstChild("ClientLog", true)
    if not ClientLog then return end
    for _, Frame in ipairs(ClientLog:GetChildren()) do
        if Frame:IsA("Frame") then
            local Label = Frame:FindFirstChildOfClass("TextLabel")
            if Label and not Frame:GetAttribute("Colorized") then
                Label.RichText = true
                local Text = Label.Text
                if not Text:find("<font") then
                    Text = Text:gsub("(Found:%s*)(.-)@", function(found, itemName)
                        return found .. "<font color='rgb(230, 215, 123)'>" .. itemName .. "</font> @"
                    end)
                    Text = Text:gsub("Found", "<font color='rgb(212, 153, 230)'>Found</font>")
                    Text = Text:gsub("(%d+%.?%d*)%% (ABOVE RAP)", function(percent)
                        return "<font color='rgb(207, 94, 94)'>" .. percent .. "% ABOVE RAP</font>"
                    end)
                    Text = Text:gsub("(%d+%.?%d*)%% (BELOW RAP)", function(percent)
                        return "<font color='rgb(65, 223, 65)'>" .. percent .. "% BELOW RAP</font>"
                    end)
                    Text = Text:gsub("Manipulated", "<font color='rgb(230, 70, 70)'>Manipulated</font>")
                    Text = Text:gsub("(Sniping:)( x%d+%s*)([^\n]*)", function(sniping, count, itemName)
                        return "<font color='rgb(33, 239, 253)'>" .. sniping .. "</font>" .. 
                               "<font color='rgb(230, 215, 123)'>" .. count .. itemName .. "</font>"
                    end)
                    Label.Text = Text
                end
                Frame:SetAttribute("Colorized", true)
            end
        end
    end
end

task.spawn(function()
    while task.wait() do
        ColorizeConsole()
    end
end)

if PlayerScripts.Core["Server Closing"] then
    PlayerScripts.Core["Server Closing"].Enabled = false
end
if PlayerScripts.Core["Idle Tracking"] then
    PlayerScripts.Core["Idle Tracking"].Enabled = false
end
Library.Network.Fire("Idle Tracking: Stop Timer")
LocalPlayer.Idled:Connect(function()
    game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

--// Some Misc Functions \\--
local RomanNumerals = {
    I = 1, V = 5, X = 10, L = 50, C = 100, D = 500, M = 1000
}
local function ConvertRoman(Number)
    local result = ""
    local sortedNumerals = {}
    for k, v in pairs(RomanNumerals) do
        table.insert(sortedNumerals, {v, k})
    end
    table.sort(sortedNumerals, function(a, b) return a[1] > b[1] end)

    for _, value in ipairs(sortedNumerals) do
        while Number >= value[1] do
            result = result .. value[2]
            Number = Number - value[1]
        end
    end
    
    return result
end
local function ConvertNumerals(Roman)
    local Total = 0
    local OldValue = 0
    for i = #Roman, 1, -1 do
        local CurrentValue = RomanNumerals[Roman:sub(i, i)]
        if CurrentValue < OldValue then
            Total = Total - CurrentValue
        else
            Total = Total + CurrentValue
        end
        OldValue = CurrentValue
    end
    return Total
end
local function AddCommas(Amount)
    local SuffixAdd = Amount
    while task.wait() do  
        SuffixAdd, b = string.gsub(SuffixAdd, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (b == 0) then
            break
        end
    end
    return SuffixAdd
end
local TempClasses = require(NLibrary.Items.Types).Types
local Classes = {}
for Name, Junk in next, TempClasses do
    Classes[Name] = {}
end
Classes.Currency = nil
Classes.Page = nil
local ItemList = Classes
local DirectoryClasses = {}
for Name, Info in next, Classes do
    Continue = false
    for _, Class in next, NLibrary.Directory:GetChildren() do
        if tostring(Class):find(Name) then
            Continue = true
        end
    end
    if not Continue then
        Classes[Name] = nil
        continue 
    end
    if Name == "Misc" or Name == "Card" then
        DirectoryClasses[Name] = Name.."Items"
    elseif Name == "Lootbox" or Name == "Box" then
        DirectoryClasses[Name] = Name.."es"
    else
        DirectoryClasses[Name] = Name.."s"
    end
end
    for Class, Info in next, Classes do
        pcall(function()
            for Item, Info in next, require(NLibrary.Directory[DirectoryClasses[Class]]) do
            if Info.DisplayName and type(Info.DisplayName) == "function" then
                for i = Info.BaseTier, Info.MaxTier do
                    ItemList[Class][Info.DisplayName(i)] = 
                    {
                        ["ID"] = Item, 
                        ["Display"] = Info.DisplayName(i),
                        ["Power"] = Info.Power(i),
                        ["Rarity"] = Info.Rarity(i),
                        ["Tier"] = i,
                        ["Icon"] = type(Info.Icon) == "function" and Info.Icon(i) or Info.Icon
                    }
                end
            else
                if Info.Tiers then
                    for i = 1, #Info.Tiers do
                        Display, Icon, Rarity, Power = nil
                        if Info.Tiers[i].Effect and Info.Tiers[i].Effect.Type.Tiers[i] then
                            if Info.Tiers[i].Effect.Type.Tiers[i].Name then
                                Display = Info.Tiers[i].Effect.Type.Tiers[i].Name
                            else
                                Display = (Info.DisplayName and type(Info.Displayname) ~= "function" and Info.DisplayName) or (Info.name and type(Info.name) ~= "function" and Info.name) or (Info.Name and type(Info.Name) ~= "function" and Info.Name) or (Info.DisplayName and type(Info.DisplayName) == "function" and Info.DisplayName(i))
                                if (not Display:find("%d") or not Display:find("(%u+)$")) and #Info.Tiers > 1 then
                                    Display = Display.." "..ConvertRoman(i)
                                end
                            end
                            Icon = Info.Tiers[i].Effect.Type.Tiers[i].Icon
                            Rarity = Info.Tiers[i].Effect.Type.Tiers[i].Rarity
                            Power = Info.Tiers[i].Effect.Type.Tiers[i].Power
                        else
                            Display = (Info.DisplayName and type(Info.Displayname) ~= "function" and Info.DisplayName) or (Info.name and type(Info.name) ~= "function" and Info.name) or (Info.Name and type(Info.Name) ~= "function" and Info.Name) or (Info.DisplayName and type(Info.DisplayName) == "function" and Info.DisplayName(i))
                            if (not Display:find("%d") or not Display:find("(%u+)$")) and #Info.Tiers > 1 then
                                Display = Display.." "..ConvertRoman(i)
                            end
                        end
                        ItemList[Class][Display] = 
                        {
                            ["ID"] = Item,
                            ["Display"] = Display,
                            ["Tier"] = i,
                            ["Icon"] = Info.Tiers[i].Icon or Icon,
                            ["Power"] = Info.Tiers[i].Power or Power,
                            ["Rarity"] = Info.Tiers[i].Rarity or Rarity,
                        }
                    end
                else
                    if Info.instant_purchase then continue end
                    ItemList[Class][(Info.DisplayName and type(Info.Displayname) ~= "function" and Info.DisplayName) or (Info.name and type(Info.name) ~= "function" and Info.name) or (Info.Name and type(Info.Name) ~= "function" and Info.Name) or (Info.DisplayName and type(Info.DisplayName) == "function" and Info.DisplayName(1))] =
                    {
                        ["ID"] = Item,
                        ["Display"] = (Info.DisplayName and type(Info.Displayname) ~= "function" and Info.DisplayName) or (Info.name and type(Info.name) ~= "function" and Info.name) or (Info.Name and type(Info.Name) ~= "function" and Info.Name) or (Info.DisplayName and type(Info.DisplayName) == "function" and Info.DisplayName(1)),
                        ["Tier"] = Info.Tier,
                        ["Icon"] = Info.Icon or Info.thumbnail,
                        ["Power"] = Info.Power,
                        ["Rarity"] = Info.Rarity,
                    }

                end
            end
        end
    end)
end

local IDs = {}
local function GrabIDs(PlaceId)
    if UI["Only Pro"] and CanUsePro then
        if table.find({PETSGO.Pro, PETSGO.Normal}, game.PlaceId) then
            PlaceId = PETSGO.Pro
        elseif table.find({PS99.Pro, PS99.Normal}, game.PlaceId) then
            PlaceId = PS99.Pro
        end
    else
        if table.find({PETSGO.Pro, PETSGO.Normal}, game.PlaceId) then
            PlaceId = CanUsePro and PETSGO[math.random(1,2)] or PETSGO.Normal
        elseif table.find({PS99.Pro, PS99.Normal}, game.PlaceId) then
            PlaceId = CanUsePro and PS99[math.random(1,2)] or PS99.Normal
        end
    end
    if FileSettings.CanJoinServers then
        local Servers = FileSettings.CanJoinServers
        for Name, Server in next, Servers do
            if type(Server) ~= "table" then continue end
            table.insert(IDs, {PlaceID = Server.PlaceID, JobID = Server.JobID})
        end
        if Servers.HaveJoined >= 5 or (os.time() - Servers.Time) >= 300 then
            Servers = nil
        else
            Servers.HaveJoined = Servers.HaveJoined + 1
        end
        FileSettings.CanJoinServers = Servers
        return Save()
    end
    local Site, Cursor
    local Url = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Desc&limit=100", PlaceId or game.PlaceId)
    if Cursor then
        Url = Url .. "&cursor=" .. Cursor
    end 
    local Success, Response = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(Url))
    end)
    if not Success or not Response then
        task.wait(5)
        return GrabIDs(PlaceId)
    end
    Site = Response
    Cursor = Site.nextPageCursor    
    if Cursor == "null" or not Cursor then
        Cursor = nil
    end
    if Site.data then
        for _,Server in next, Site.data do
            if Server.maxPlayers > Server.playing and Server.id ~= game.JobId and Server.playing >= (FileSettings.Sniper and 5 or 15) then
                table.insert(IDs, {PlaceID = PlaceId or game.PlaceId, JobID = Server.id})
            end
        end
    elseif Site.errors and Site.errors[1] and Site.errors[1].message == "Too many requests" then
        warn("[Plaza Plus]: Roblox is rate-limiting you... waiting 15 seconds.")
        task.wait(15)
        return GrabIDs(PlaceId)
    end 
    FileSettings.Servers = {
        HaveJoined = 1,
        Time = os.time(),
        IDs
    }   
    return Save()
end
local function Serverhop(NotPlaza)
    repeat task.wait() until (((os.time() - StartingTime) >= UI["Teleport Delay"]) or NotPlaza) and #IDs >= 1
    while task.wait() do
        local RandomServer = IDs[Random.new():NextInteger(1, #IDs)]
        if not FileSettings.LastJoinedServers then
            FileSettings.LastJoinedServers = {}
        end
        local Servers = FileSettings.LastJoinedServers
        if table.find(Servers, RandomServer.JobID) then
            continue
        end
        if #Servers >= 7 then
            table.remove(Servers, table.find(Servers, Servers[1]))
        end
        table.insert(Servers, RandomServer.JobID)
        FileSettings.LastJoinedServers = Servers
        Save()
        
        TeleportService:TeleportToPlaceInstance(RandomServer.PlaceID, RandomServer.JobID, LocalPlayer)        
		task.wait(1.5)
    end
end
if not table.find({PS99.Normal, PS99.Pro, PETSGO.Normal, PETSGO.Pro}, game.PlaceId) then
    warn("[Plaza Plus]: Incorrect Server, serverhopping...")
    while task.wait() do
        task.spawn(function()
            Library.Network.Invoke("Travel to Trading Plaza")
        end)
        task.wait(5)
    end
    return
end
task.spawn(function()
    if UI["Teleport Delay"] then
        while task.wait(UI["Teleport Delay"] + 120) and UI["Switch Servers"] and FileSettings.Sniper do
            warn("[Plaza Plus]: +120s delay override, serverhopping...")
            GrabIDs()
            Serverhop()
        end
    end
end)




local function ValidateItem(BoothItem, WantedItem)
    if WantedItem.ID:find("All Huges") then
        if not BoothItem.IsHuge then
            return false
        end
    elseif WantedItem.ID:find("All Titanics") then
        if not BoothItem.IsTitanic then
            return false
        end
    elseif WantedItem.ID:find("All Exclusives") then
        if (not BoothItem.IsExclusive or BoothItem.IsHuge or BoothItem.IsTitanic) or BoothItem.Class ~= "Pet" then
            return false
        end
    end

    if WantedItem.ID:find("All Rarity") then
        if BoothItem.Class ~= "Pet" or not BoothItem.Rarity or (BoothItem.Rarity:gsub(" ", "") ~= WantedItem.ID:split(":")[2]:gsub(" ", "")) then
            return false
        end
    elseif WantedItem.ID:find("All Class") then
        if not BoothItem.Class or (BoothItem.Class ~= WantedItem.ID:split(":")[2]:gsub(" ", "")) then
            return false
        end
    elseif WantedItem.ID:find("RAP Above") then
        if BoothItem.Class ~= "Pet" or not BoothItem.RAP or (tonumber(BoothItem.RAP) < tonumber(RemoveSuffix(WantedItem.ID:split(":")[2]:gsub(" ", "")))) then
            return false
        end
    elseif WantedItem.ID:find("Difficulty Above") then
        if BoothItem.Class ~= "Pet" or not BoothItem.Difficulty or (tonumber(BoothItem.Difficulty) < tonumber(RemoveSuffix(WantedItem.ID:split(":")[2]:gsub(" ", "")))) then
            return false
        end
    elseif WantedItem.ID:find("Name Find") then
        local Match = WantedItem.ID:split(": ")[2] 
        if not BoothItem.ID:find(Match) then
            return false
        end
    elseif WantedItem.ID ~= BoothItem.ID then
        return false
    end

    if WantedItem.Class ~= nil and WantedItem.Class ~= BoothItem.Class then
        return false
    end

    if not WantedItem.AllTypes then
        if (WantedItem.Shiny and not BoothItem.Shiny) or (not WantedItem.Shiny and BoothItem.Shiny) then
            return false
        end
        if (WantedItem.Rainbow and not BoothItem.Rainbow) or (BoothItem.Rainbow and not WantedItem.Rainbow) then
            return false
        end
        if (WantedItem.Golden and not BoothItem.Golden) or (BoothItem.Golden and not WantedItem.Golden) then
            return false
        end
    end

    if not WantedItem.AllTiers and (WantedItem.Tier and BoothItem.Tier) then
        if tonumber(WantedItem.Tier) ~= tonumber(BoothItem.Tier) then
            return false
        end
    end
    return true
end

local function GenerateFindInfo(Name, Data)
    local FindInfo = {Class, Rainbow, Golden, Shiny, Tier, ID, Display, AllTypes}
    FindInfo.ID = Name
    FindInfo.AllTypes = Data and Data.AllTypes and Data.AllTypes or nil
    FindInfo.AllTiers = Data and Data.AllTiers and Datal.AllTiers or nil
    
    if not Name:find("Board") and not Name:find("Gem") then
        local RainbowPosition = Name:find("Rainbow")
        local HugePosition = Name:find("Huge")
        FindInfo.Rainbow = (RainbowPosition and (not HugePosition or RainbowPosition < HugePosition)) and true
        FindInfo.Golden = Name:find("Golden") and true
        FindInfo.Shiny = Name:find("Shiny") and true
        Name = FindInfo.ID:gsub((FindInfo.Rainbow and "Rainbow " or FindInfo.Golden and "Golden ") or "", ""):gsub(FindInfo.Shiny and "Shiny " or "", "")
    end
    if Name:find("RAP Above") or Name:find("Difficulty Above") then
        return FindInfo
    end
    local Main, Tier = Name:match("(.+)%s+(%d+)%s*$")
    if Tier then
        FindInfo.Tier = tonumber(Tier)
        Name = Main.." "..ConvertRoman(FindInfo.Tier)
    elseif Name:find("(%u+)%s*$") then
        FindInfo.Tier = tonumber(ConvertNumerals(Name:match("(%u+)%s*$")))
    end
    FindInfo.Display = Name
    for Class, List in next, ItemList do
        if ItemList[Class][Name] then
            Data = ItemList[Class][Name]
            FindInfo.Class = Class
            FindInfo.ID = Data.ID
            FindInfo.Icon = Data.Icon
            if Class ~= "Pet" and Class ~= "Hoverboard" and Class ~= "Card" and Class ~= "Fruit" then
                FindInfo.Rainbow = nil
                FindInfo.Golden = nil
                FindInfo.Shiny = nil
                if Data.Tier and not FindInfo.Tier then
                    FindInfo.Tier = Data.Tier
                end
            end
            break
        end
    end
    return FindInfo
end


local function CalculatePercent(GlobalRAP, ItemPrice)
    local WholeValue = ((ItemPrice - GlobalRAP) / GlobalRAP) * 100
    WholeValue = math.floor(WholeValue * 2 + 0.5) / 2
    return WholeValue < 0 and math.abs(WholeValue) or WholeValue * -1
end

local function GetDiamonds(ReturnUID)
    for i,v in next, PlayerSave.Get()["Inventory"].Currency do
        if v.id == "Diamonds" then
            return ReturnUID and i or (v._am or 0)
        end
    end
    return 0
end

local MANIPULATION_THRESHOLD = 10
local function ReturnDaily(Data)
    local DayStart = os.time() - (24 * 60 * 60)
    local Average = {}
    for i = #Data, 1, -1 do
        if Data[i][1] / 1000 >= DayStart then
            table.insert(Average, Data[i])
        else
            break
        end
    end
    return Average
end
local function CalcAverageRap(Data, n)
    local sum = 0
    local count = math.min(#Data, n)
    for i = #Data, #Data - count + 1, -1 do
        sum = sum + Data[i][2]
    end
    return sum / count
end
local function DetermineTrend(Data)
    if #Data <= 1 then
        return "Unknown"
    end
    local CurrentRAP = Data[#Data][2]
    local Daily = ReturnDaily(Data)
    local StartingRAP = (Daily[#Daily] and Daily[#Daily][2]) or CurrentRAP
    local AvgRAP = CalcAverageRap(Data, 30)
    local deviation = ((CurrentRAP - AvgRAP) / math.max(AvgRAP, 1)) * 100
    if math.abs(deviation) > MANIPULATION_THRESHOLD then
        return "Manipulated"
    end
    if math.abs(CurrentRAP - StartingRAP) <= 0.1 * StartingRAP then
        return "Stable"
    elseif CurrentRAP > StartingRAP then
        return "Increasing"
    else
        return "Decreasing"
    end
end

local function FindItemsInBooth(Name, Class)
    local ItemCount = 0
    local BoothCount = 0
    for _, Users in next, Booths do
        for Username, Booth in next, Users do
            for BoothInfo, InfoValues in next, Booth do
                if BoothInfo == "Listings" and tostring(Username):find(LocalPlayer.Name) then
                    for a,b in next, InfoValues do
                        BoothCount = BoothCount + 1
                    end
                    if Name and Class then
                        for PetUID, PetInfo in next, InfoValues do
                            local PetData = PetInfo.Item._data
                            if PetData["id"] == Name and PetInfo.Item.Class.Name == Class then
                                if PetData["_am"] then
                                    ItemCount = ItemCount + PetData["_am"]
                                else
                                    ItemCount = ItemCount + 1
                                end
                            end
                        end
                    end
                    return BoothCount, ItemCount
                end
            end
        end
    end
    return nil
end

local function IsSpecialCase(item, keyword)
    local keywordParts = keyword:split(":")
    local keywordValue = keywordParts[2] and keywordParts[2]:gsub(" ", "")

    local SpecialCases = {
        ["All Huges"] = item.IsHuge,
        ["All Titanics"] = item.IsTitanic,
        ["All Exclusives"] = item.IsExclusive,
        ["All Items"] = true,
        ["All Rarity"] = item.Rarity and item.Rarity:gsub(" ", "") == keywordValue,
        ["All Class"] = item.Class and item.Class == keywordValue,
        ["RAP Above"] = item.RAP and tonumber(item.RAP) >= tonumber(RemoveSuffix(keywordValue or "")),
        ["Difficulty Above"] = item.Difficulty and tonumber(item.Difficulty) >= tonumber(RemoveSuffix(keywordValue or ""))
    }

    return SpecialCases[keywordParts[1]] or false
end

local function GetInventoryByClass(class)
    return Library.InventoryCmds.State().container._store._byType[class]
end
local LastUIDs = {}
local BlacklistedUIDs = {}
local function FindItem(Data, ReturnAmount)
    local Count = 0
    local Inventories = {}
    if Data.ID:find("All Huges") or Data.ID:find("All Titanics") then
        table.insert(Inventories, GetInventoryByClass("Pet"))
    elseif Data.Class then
        table.insert(Inventories, GetInventoryByClass(Data.Class))
    else
        for class, _ in pairs(Library.InventoryCmds.State().container._store._byType) do
            table.insert(Inventories, GetInventoryByClass(class))
        end
    end

    for _, Inventory in pairs(Inventories) do
        if not Inventory or not Inventory._byUID then
            print("[Plaza Plus]: Cannot scan for: " .. (Data.Class or "All Classes"))
            return
        end

        for UID, ItemTable in pairs(Inventory._byUID) do
            if not ReturnAmount then
                LastUIDs = LastUIDs or {}
                if table.find(LastUIDs, UID) then
                    local BoothCount, ItemCount = FindItemsInBooth(ItemTable.GetId and ItemTable:GetId(), ItemTable.GetClass and ItemTable:GetClass() or ItemTable.Class and ItemTable.Class.Name or Data.Class or "Pet")
                    if ItemCount >= 1 then
                        continue
                    else
                        table.remove(LastUIDs, table.find(LastUIDs, UID))
                    end
                    task.wait(0.1)
                end
            end

            local ItemInfo = {
                UID = UID,
                ID = ItemTable.GetId and ItemTable:GetId() or nil,
                Class = ItemTable.GetClass and ItemTable:GetClass() or ItemTable.Class and ItemTable.Class.Name or Data.Class or "Pet",
                Rainbow = ItemTable.IsRainbow and ItemTable:IsRainbow() or false,
                Golden = ItemTable.IsGolden and ItemTable:IsGolden() or false,
                Shiny = ItemTable.IsShiny and ItemTable:IsShiny() or false,
                IsHuge = ItemTable.IsHuge and ItemTable:IsHuge() or false,
                IsTitanic = ItemTable.IsTitanic and ItemTable:IsTitanic() or false,
                IsExclusive = ItemTable.GetRarity and ItemTable:GetRarity()._id == "Exclusive" or false,
                NotTradeable = (ItemTable.AbstractIsTradable and ItemTable:AbstractIsTradable() == false),
                IsLocked = ItemTable._data["_lk"],
                Amount = ItemTable._data["_am"] or 1,
                Tier = ItemTable._data["tn"],
                Color = ItemTable.GetColorVariant and ItemTable:GetColorVariant() or nil,
                Difficulty = ItemTable.GetDifficulty and ItemTable:GetDifficulty(),
                Rarity = ItemTable.GetRarity and ItemTable:GetRarity()._id,
                Display = "",
            }

            if ItemInfo.Shiny then
                ItemInfo.Display = "Shiny"
            end
            if ItemInfo.Rainbow then
                ItemInfo.Display = (ItemInfo.Display ~= "" and ItemInfo.Display .. " " or "") .. "Rainbow"
            end
            if ItemInfo.Golden then
                ItemInfo.Display = (ItemInfo.Display ~= "" and ItemInfo.Display .. " " or "") .. "Golden"
            end
            ItemInfo.Display = (ItemInfo.Display ~= "" and ItemInfo.Display .. " " or "") .. ItemInfo.ID

            if ItemInfo.IsLocked or ItemInfo.NotTradeable or BlacklistedUIDs[UID] or not UID then
                continue
            end
            if ReturnAmount then
                if ValidateItem(ItemInfo, Data) then
                    Count = ItemInfo.Amount + Count
                else
                    continue
                end
            end
            if ValidateItem(ItemInfo, Data) and not ReturnAmount then
                table.insert(LastUIDs, UID)
                return UID, ItemInfo
            end
        end
    end
    return ReturnAmount and Count or nil
end


local Values = {}
local function ReturnValue(Pet)
    if Values[Pet] then
        return RemoveSuffix(Values[Pet])
    end
    if table.find({PETSGO.Pro, PETSGO.Normal}, game.PlaceId) then
        Search = game:HttpGet("https://petsgovalues.com/details.php?Name="..Pet:gsub(" ", "+"))
    else
        Search = game:HttpGet("https://petsimulatorvalues.com/details.php?Name="..Pet:gsub(" ", "+"))
    end
    Value = Search:split('value</Span><Span class="float-right">')[2]
    if Value then
        Value = Value:split("</Span>")[1]
        if Value:find("%d") then
            Value = RemoveSuffix(Value)
            Values[Pet] = Value
            return Value
        end 
    end
    return nil
end




local function GetMailCost()
    if table.find({PETSGO.Pro, PETSGO.Normal}, game.PlaceId) then
        return Variables.MailboxCoinsCost * (Library.UpgradeCmds.IsUnlocked("Cheaper Mailbox") and 0.75 or 1)
    end
    local BaseCost = Constants.MailboxDiamondCost
    if not PlayerSave.Get() then
        return BaseCost
    end
    local ShouldReset = not (PlayerSave.Get().MailboxResetTime and PlayerSave.Get().MailboxResetTime >= workspace:GetServerTimeNow())
    if ShouldReset then
        return BaseCost
    end
    local Cost = BaseCost * math.pow(Mailbox.DiamondCostGrowthRate, PlayerSave.Get().MailboxSendsSinceReset)
    Cost = math.min(Cost, Mailbox.DiamondCostCap)
    if PlayerSave.Get().Gamepasses.VIP or LocalPlayer:GetAttribute("Partner") then
        return BaseCost
    end
    return Cost
end

local AdjectiveList = {
    "Bold", "Quick", "Happy", "Sad", "Tiny", "Big", 
    "Brave", "Clever", "Gentle", "Fierce", "Mighty", "Swift",
    "Calm", "Loyal", "Bright", "Wise", "Fearless", "Vivid"
}

local NounList = {
    "Lion", "Castle", "Book", "Phone", "Cloud", "Mountain", 
    "Tiger", "Forest", "River", "Sword", "Shield", "Phoenix",
    "Galaxy", "Ocean", "Eagle", "Dragon", "Star", "Knight"
}

local function GenerateDescription()
    local Adjective = AdjectiveList[math.random(#AdjectiveList)]
    local Noun = NounList[math.random(#NounList)]
    return Adjective .. " " .. Noun
end

task.spawn(function()
    while task.wait(30) do
        Library.Network.Invoke("Mailbox: Claim All")
        if UI["Diamonds Sendout"] and UI["Diamonds Sendout"].Username ~= "" and GetDiamonds() >= UI["Diamonds Sendout"].Amount then
            local Cost = GetMailCost()
            if Library.CurrencyCmds.CanAfford(table.find({PETSGO.Pro, PETSGO.Normal}, game.PlaceId) and "Coins" or "Diamonds", math.floor(Cost)) then
                Library.Network.Invoke("Mailbox: Send", UI["Diamonds Sendout"].Username, GenerateDescription(), "Currency", GetDiamonds(true), GetDiamonds()-Cost)
            end
        end
    end
end)

local function GlobalNotification(CurrentInfo, FindInfo, Percent)
    local Color = tonumber("0x"..Rarities[CurrentInfo.Rarity].Color:ToHex())
    local Description = {
        "**<:Box:1239350602413375591> Received:** `"..CurrentInfo.Display..(CurrentInfo.Difficulty and " (1/"..AddSuffix(CurrentInfo.Difficulty)..")" or "").." x"..CurrentInfo.Bought.."`",
        "**<:Diamond:1235403834969296896> Spent:** `"..AddSuffix(CurrentInfo.Bought*CurrentInfo.Cost)..(CurrentInfo.Amount > 1 and " ("..AddSuffix(CurrentInfo.Cost).." per)`" or "`"),
        "**<:Money:1295946554338705438> "..("RAP:** `"..AddSuffix(CurrentInfo.RAP).." ("..Percent.."% off)`"),
        "**<:Profit:1295945416273301576> Profit:** `"..AddSuffix((CurrentInfo.Bought*CurrentInfo.RAP) - (CurrentInfo.Bought*CurrentInfo.Cost))..(CurrentInfo.Amount > 1 and " ("..AddSuffix(CurrentInfo.RAP-CurrentInfo.Cost).." per)`" or "`")
    }

    local Message = {
		["username"] = "System Exodus | Plaza Plus",
		["avatar_url"] = "https://i.gyazo.com/dbefd0df338c7ff9c08fc85ecea0df94.png",
        --["content"] = (tonumber(DiscordUserId) and "» <@"..tostring(DiscordUserId)..">" or ""),
        ["content"] = "",
        ["embeds"] = {
            {
                ["color"] = Color,
                ["title"] = (table.find({PS99.Normal, PS99.Pro}, game.PlaceId) and "(PS99)" or "(PETS GO)").." User has sniped an item!",
                ["description"] = table.concat(Description, "\n"),
                ["timestamp"] = DateTime.now():ToIsoDate(),
                ["footer"] = {
                    ["icon_url"] = "https://i.gyazo.com/ea76480f147f22311488a92dc8efc208.jpg",
                    ["text"] = "CIHUY GEMING"
                },
                ["thumbnail"] = { 
                    ["url"] = "https://biggamesapi.io/image/"..Library.Functions.ParseAssetId(CurrentInfo.Icon)
                },
            },
        },
    }
end

local function SniperNotification(CurrentInfo, FindInfo, Percent)
    local Color = tonumber("0x"..Rarities[CurrentInfo.Rarity].Color:ToHex())
    local Description = {
        "**<:Box:1239350602413375591> Received:** `"..CurrentInfo.Display..(CurrentInfo.Difficulty and " (1/"..AddSuffix(CurrentInfo.Difficulty)..")" or "").." x"..CurrentInfo.Amount.."`",
        "**<:Diamond:1235403834969296896> Spent:** `"..AddSuffix(CurrentInfo.Bought*CurrentInfo.Cost)..(CurrentInfo.Amount > 1 and " ("..AddSuffix(CurrentInfo.Cost).." per)`" or "`"),
        "**<:Money:1295946554338705438> "..("RAP:** `"..AddSuffix(CurrentInfo.RAP).." ("..Percent.."% off)`"),
        "",
        "**<:Misc:1236020543082463253> Inventory Count:** `"..AddCommas(FindItem(FindInfo, true)).."`",
        "**<:Bank:1295944894698754102> Diamonds Left:** `"..AddSuffix(GetDiamonds()).."`",
        "**<:Profit:1295945416273301576> Profit Made:** `"..AddSuffix((CurrentInfo.Bought*CurrentInfo.RAP) - (CurrentInfo.Bought*CurrentInfo.Cost))..(CurrentInfo.Amount > 1 and " ("..AddSuffix(CurrentInfo.RAP-CurrentInfo.Cost).." per)`" or "`")
    }

    local Message = {
		["username"] = "System Exodus | Plaza Plus",
		["avatar_url"] = "https://i.gyazo.com/dbefd0df338c7ff9c08fc85ecea0df94.png",
        ["embeds"] = {
            {
                ["color"] = Color,
                ["title"] = "||"..LocalPlayer.Name.."|| has sniped an item!",
                ["description"] = table.concat(Description, "\n"),
                ["timestamp"] = DateTime.now():ToIsoDate(),
                ["footer"] = {
                    ["icon_url"] = "https://i.gyazo.com/ea76480f147f22311488a92dc8efc208.jpg",
                    ["text"] = "CIHUY GEMING"
                },
                ["thumbnail"] = { 
                    ["url"] = "https://biggamesapi.io/image/"..Library.Functions.ParseAssetId(CurrentInfo.Icon)
                },
            },
        },
    }
    request({
		Url = UI["URL"],
		Method = "POST",
		Headers = {["Content-Type"] = "application/json"}, 
		Body = HttpService:JSONEncode(Message)
	})
end

local function SellerNotification(CurrentInfo)
    local BoothCount, ItemCount = FindItemsInBooth(CurrentInfo.ID, CurrentInfo.Class)
    local Description = {
        "**<:Box:1239350602413375591> Sold:** `"..CurrentInfo.Name.." x"..CurrentInfo.Amount.."`",
        "**<:Diamond:1235403834969296896> Gained:** `"..AddSuffix(CurrentInfo.Spent)..(CurrentInfo.Amount > 1 and " ("..AddSuffix(CurrentInfo.Spent / CurrentInfo.Amount).." per)`" or "`"),
        "**<:Booth:1239350605294604378> Booth Count:** `"..AddCommas(ItemCount).."`",
        "**<:Bank:1295944894698754102> Current Diamonds:** `"..AddSuffix(GetDiamonds()).."`",
    }

    local Message = {
		["username"] = "System Exodus | Plaza Plus",
		["avatar_url"] = "https://i.gyazo.com/dbefd0df338c7ff9c08fc85ecea0df94.png",
        ["embeds"] = {
            {
                ["color"] = 12035327,
                ["title"] = "||"..LocalPlayer.Name.."|| has sold an item!",
                ["description"] = table.concat(Description, "\n"),
                ["timestamp"] = DateTime.now():ToIsoDate(),
                ["footer"] = {
                    ["icon_url"] = "https://i.gyazo.com/ea76480f147f22311488a92dc8efc208.jpg",
                    ["text"] = "CIHUY GEMING"
                },
                ["thumbnail"] = { 
                    ["url"] = "https://biggamesapi.io/image/"..Library.Functions.ParseAssetId(CurrentInfo.Icon)
                },
            },
        },
    }
	local thing = request({
		Url = UI["URL"],
		Method = "POST",
		Headers = {["Content-Type"] = "application/json"}, 
		Body = HttpService:JSONEncode(Message)
	})
end

local TempRAP = {}
local function ProcessItem(CurrentInfo, Data, Booth)
    FindInfo = Data.FindInfo
    Percent = nil
    Result = nil
    if CurrentInfo.RAP then
        if not Data.UseCosmicValues and not Data.DetectManipulation then
            Percent = CalculatePercent(CurrentInfo.RAP, CurrentInfo.Cost)
        elseif Data.UseCosmicValues then
            local CosmicValues = FileSettings.UseCosmicValues or {Time = os.time()}
            local CosmicValue = CosmicValues[CurrentInfo.Display]
            if CosmicValue and CosmicValue ~= "nil" then
                CurrentInfo.Value = CosmicValue
                Percent = CalculatePercent(CosmicValue, CurrentInfo.Cost)
            elseif not CosmicValue and CosmicValue ~= "nil" then
                ItemValue = ReturnValue(CurrentInfo.Display)
                if ItemValue then
                    CurrentInfo.Value = ItemValue
                    Percent = CalculatePercent(ItemValue, CurrentInfo.Cost)
                    CosmicValues[CurrentInfo.Display] = ItemValue
                else
                    CosmicValues[CurrentInfo.Display] = "nil"
                end
            end
            if os.time() - CosmicValues.Time >= 7200 then
                CosmicValues.Time = os.time()
            end
            FileSettings.UseCosmicValues = CosmicValues
            Save()
        elseif Data.DetectManipulation then
            local ManipulationData = FileSettings.DetectManipulation or {Time = os.time()}
            local ManipulatedInfo = ManipulationData[CurrentInfo.Display]
            if ManipulatedInfo and ManipulatedInfo.RAP == CurrentInfo.RAP then
                Result = ManipulatedInfo.Result
                TempRAP[CurrentInfo.Display] = Result
            else
                pcall(function()
                    RAPData = HttpService:JSONDecode(game:HttpGet("https://ps99rap.com/api/get/rap?id=" .. CurrentInfo.Display:lower():gsub(" ", "%%20"))).data
                end)
                if RAPData then
                    Result = DetermineTrend(RAPData)
                    TempRAP[CurrentInfo.Display] = Result
                    ManipulationData[CurrentInfo.Display] = {Result = Result, RAP = CurrentInfo.RAP}
                end
            end
            if os.time() - ManipulationData.Time >= 7200 then
                ManipulationData.Time = os.time()
            end
            FileSettings.DetectManipulation = ManipulationData
            Percent = (Result and Result ~= "Manipulated") and CalculatePercent(CurrentInfo.RAP, CurrentInfo.Cost) or nil
            Save()
        end
    end
    if Percent and Percent < 0 then 
        TempPercent = math.abs(Percent).."% ABOVE RAP" 
    elseif Percent and Percent > 0 then
        TempPercent = Percent.."% BELOW RAP" 
    else
        TempPercent = "N/A%"
    end
    print("[Plaza Plus]: Found: " .. CurrentInfo.Display .. " @ " .. TempPercent .. " (" .. tostring(CurrentInfo.Value or CurrentInfo.Cost) .. ") ".."("..tostring(Result)..")")

    local PriceData = {
        IsPercentage = type(Data.Price) == "string" and Data.Price:find("%%"),
        AboveRAP = type(Data.Price) == "string" and Data.Price:find("+"),
        --NegativePrice = (type(Data.Price) == "number" and Data.Price < 0) or (type(Data.Price) == "string" and Data.Price:find("^%-")),
    }
    PriceData.RealPrice = tonumber(type(Data.Price) == "string" and (not PriceData.IsPercentage and RemoveSuffix(Data.Price) or Data.Price:gsub("%D", "")) or Data.Price)

    local HasEnoughDiamonds = GetDiamonds() >= CurrentInfo.Cost
    local IsValidPrice = false


    if PriceData.IsPercentage and type(Percent) == "number" then
        IsValidPrice = PriceData.AboveRAP and Percent >= tonumber("-" .. PriceData.RealPrice) or Percent >= PriceData.RealPrice
    else
        IsValidPrice = PriceData.RealPrice and PriceData.RealPrice - CurrentInfo.Cost >= 0
    end
    if Result == "Manipulated" then
        return
    end

    if HasEnoughDiamonds and IsValidPrice and (not Data.MaxPrice or Data.MaxPrice >= CurrentInfo.Cost) then
        local CanBuyCount = math.floor(GetDiamonds() / CurrentInfo.Cost)
        local TrueBuyCount = math.min(CurrentInfo.Amount, CanBuyCount)
        if Data.InventoryLimit then
            TrueBuyCount = math.min(TrueBuyCount, Data.InventoryLimit - FindItem(CurrentInfo, true))
        end
        if Data.MaxAmount then
            TrueBuyCount = math.min(TrueBuyCount, Data.MaxAmount)
        end
        if TrueBuyCount <= 0 then return end
        warn("[Plaza Plus]: Sniping: x" .. TrueBuyCount .. " " .. CurrentInfo.Display .. ".")
        HumanoidRootPart.CFrame = BoothsInteractive[Booth.BoothID]:WaitForChild("Interact", 7).CFrame * CFrame.new(0,-2, -6)
        task.wait(0.5)

        local Thing = {
            ["Caller"] = {
                ["LineNumber"] = 532,
                ["ParameterCount"] = 2,
                ["Variadic"] = false,
                ["Traceback"] = "ReplicatedStorage.Library.Client.BoothCmds:532 function PromptPurchase2\nReplicatedStorage.Library.Client.BoothCmds:659 function promptOtherPlayerBooth2\nReplicatedStorage.Library.Client.BoothCmds:998",
                ["ScriptPath"] = "ReplicatedStorage.Library.Client.BoothCmds",
                ["ScriptClass"] = "ModuleScript",
                ["Handle"] = "function: 0xc3ef3e0bb3f1ea43",
                ["FunctionName"] = "PromptPurchase2",
                ["ScriptType"] = "Instance",
                ["SourceIdentifier"] = "ReplicatedStorage.Library.Client.BoothCmds"
            }
        }

        local Success, Thing, Thing2, Thing3 = Library.Network.Invoke("Booths_RequestPurchase", Booth.PlayerID, {[CurrentInfo.UID] = TrueBuyCount}, Thing)
        if Success then
            CurrentInfo.Bought = TrueBuyCount
            GlobalNotification(CurrentInfo, FindInfo, Percent)
            if UI["URL"] then
                SniperNotification(CurrentInfo, FindInfo, Percent)
            end
        end
    end
end
local function ProcessBooth(Booth, Data)
    for BoothInfo, InfoValues in next, Booth do
        if BoothInfo ~= "Listings" then continue end
        for ItemUID, ItemInfo in next, InfoValues do
            local ItemData = ItemInfo.Item._data
            local CurrentInfo = {
                UID = ItemUID,
                ID = ItemData.id,
                Display = ItemData.id,
                Class = ItemInfo.Item.Class.Name,
                Rainbow = ItemInfo.Item.IsRainbow and ItemInfo.Item:IsRainbow(),
                Golden = ItemInfo.Item.IsGolden and ItemInfo.Item:IsGolden(),
                Shiny = ItemInfo.Item.IsShiny and ItemInfo.Item:IsShiny(),
                
                Amount = ItemData["_am"] or 1,
                Tier = ItemData["tn"],
                Cost = ItemInfo.DiamondCost,
                RAP = (table.find({PS99.Normal, PS99.Pro}, game.PlaceId) and ItemInfo.Item.GetDevRAP and ItemInfo.Item:GetDevRAP()) or ItemInfo.Item.GetRAP and ItemInfo.Item:GetRAP(), 
                
                IsHuge = ItemInfo.Item.IsHuge and ItemInfo.Item:IsHuge() or false,
                IsTitanic = ItemInfo.Item.IsTitanic and ItemInfo.Item:IsTitanic() or false,
                IsExclusive = ItemInfo.Item.GetRarity and ItemInfo.Item:GetRarity()._id == "Exclusive",
                
                Icon = ItemInfo.Item.GetIcon and ItemInfo.Item:GetIcon(),
                Rarity = ItemInfo.Item.GetRarity and ItemInfo.Item:GetRarity()._id,
            }
            if CurrentInfo.Rainbow then
                CurrentInfo.Display = "Rainbow "..CurrentInfo.Display
            elseif CurrentInfo.Golden then
                CurrentInfo.Display = "Golden "..CurrentInfo.Display
            end
            if CurrentInfo.Shiny then
                CurrentInfo.Display = "Shiny "..CurrentInfo.Display
            end
            if CurrentInfo.Tier then
                CurrentInfo.Display = CurrentInfo.Display.." "..CurrentInfo.Tier
            end
            for Name, Data in next, Settings.Sniper.Items do
                if Name == "SearchTerminal" then continue end
                if not Data.FindInfo then
                    FindInfo = GenerateFindInfo(Name, Data)
                    Data.FindInfo = FindInfo
                else
                    FindInfo = Data.FindInfo
                end
                if ValidateItem(CurrentInfo, FindInfo) then
                    ProcessItem(CurrentInfo, Data, Booth)
                end
            end
        end
    end
end

local Servers = {}
local function SearchTerminal(Class, Encoded, SearchQuery)
    local FoundServer;
    local Data = Encoded
    
    -- Skip jika item tidak punya data lengkap
    if not SearchQuery.id or (Class ~= "Misc" and Class ~= "Card" and not SearchQuery.tn) then
        return
    end
    
    pcall(function()
        FoundServer = game.ReplicatedStorage.Network.TradingTerminal_Search:InvokeServer(Class, Data, nil, false) or nil
    end)
    if not FoundServer then
        return
    end
    if type(FoundServer) == "table" and FoundServer["place_id"] and FoundServer["job_id"] then
        if (CanUsePro and table.find({PS99.Pro, PETSGO.Pro}, FoundServer["place_id"])) or (not UI["Only Pro"] and table.find({PS99.Normal, PETSGO.Normal}, FoundServer["place_id"])) then
            table.insert(Servers, {["PlaceID"] = FoundServer["place_id"], ["JobID"] = FoundServer["job_id"]})
        end
    end
end

local function OrderedTable(tbl, order)
    local encodedParts = {}
    
    for _, key in ipairs(order) do
        local value = tbl[key]
        local formattedValue

        if type(value) == "string" then
            formattedValue = '"' .. value .. '"'
        elseif type(value) == "boolean" or type(value) == "number" then
            formattedValue = tostring(value)
        end
        if formattedValue ~= nil then
            table.insert(encodedParts, '"' .. key .. '":' .. formattedValue)
        end
    end

    return "{" .. table.concat(encodedParts, ",") .. "}"
end

local LimitCounts = 0
local ReachedLimits = 0
task.spawn(function()
    if Settings.Sniper and Settings.Sniper.Active and FileSettings.Sniper then
        for Name, Data in next, Settings.Sniper.Items do
            if type(Name) ~= "string" or Name == "SearchTerminal" then continue end
            warn("[Plaza Plus]: Searching for: "..Name..".")
        end
        if Settings.Sniper.Items.SearchTerminal then
            for Name, Data in next, Settings.Sniper.Items.SearchTerminal do
                if type(Name) ~= "string" then continue end
                warn("[Plaza Plus]: Searching for: "..Name..".")
            end
        end
    end
    while task.wait() and Settings.Sniper and Settings.Sniper.Active and FileSettings.Sniper and Settings.Sniper.Items.SearchTerminal and UI["Switch Servers"] do
        if Settings.Sniper.Items.SearchTerminal then
            task.spawn(function()
                for Name, Data in next, Settings.Sniper.Items.SearchTerminal do
                    if type(Name) ~= "string" then continue end
                    local FindInfo = GenerateFindInfo(Name, Data)
                    if not FindInfo.Class then continue end
                    --local SearchQuery = HttpService:JSONEncode({id = FindInfo.ID, pt = FindInfo.Golden and 1 or FindInfo.Rainbow and 2, sh = FindInfo.Shiny, tn = FindInfo.Tier})

                    local searchTable = {
                        id = FindInfo.ID,
                        pt = FindInfo.Golden and 1 or FindInfo.Rainbow and 2,
                        sh = FindInfo.Shiny,
                        tn = FindInfo.Tier
                    }

                    local keyOrder = {"id", "pt", "sh", "tn"}
                    local SearchQuery = OrderedTable(searchTable, keyOrder)
                
                    SearchTerminal(FindInfo.Class, SearchQuery, HttpService:JSONDecode(SearchQuery))
                    Settings.Sniper.Items[Name] = Settings.Sniper.Items[Name] or Data
                end
            end)
        end
        if UI["Limits Reached"] and LimitCounts == ReachedLimits and LimitCounts ~= 0 then
            if UI["Switch To Selling"] and FileSettings.Sniper and Settings.Seller and Settings.Seller.Active then
                FileSettings.Sniper = false
                FileSettings.Seller = true
            else
                FileSettings.Sniper = false
                return LocalPlayer:Kick("[Plaza Plus]: Limits Reached")
            end
        end
        if UI["Diamonds Hit"] then
            if GetDiamonds() <= UI["Diamonds Hit"] then
                if UI["Switch To Selling"] and FileSettings.Sniper and Settings.Seller and Settings.Seller.Active then
                    FileSettings.Sniper = false
                    FileSettings.Seller = true
                else
                    FileSettings.Sniper = false
                    return LocalPlayer:Kick("[Plaza Plus]: Diamonds Reached")
                end
            end
        end
        if UI["Minutes Timer"] then
            if FileSettings.SniperTime then
                if (os.time() - FileSettings.SniperTime) >= (UI["Minutes Timer"]) and (os.time() - FileSettings.SniperTime) <= 21600 then
                    if UI["Switch To Selling"] and Settings.Seller and Settings.Seller.Active then
                        FileSettings.Sniper = false
                        FileSettings.Seller = true
                        FileSettings.SniperTime = nil
                    else
                        FileSettings.SniperTime = nil
                        FileSettings.Sniper = false
                        return LocalPlayer:Kick("[Plaza Plus]: Timer Reached")
                    end
                elseif (os.time() - FileSettings.SniperTime) > 21600 then
                    FileSettings.SniperTime = os.time()
                end
            else
                FileSettings.SniperTime = os.time()
            end
        end
        if not FileSettings.Sniper then
            GrabIDs()
            return Serverhop()
        end
        for Name, Data in next, Settings.Sniper.Items do
            local FindInfo = GenerateFindInfo(Name, Data)
            if not FindInfo.Class then continue end
            if Data.InventoryLimit then
                LimitCounts = LimitCounts + 1
                if FindItem(FindInfo, true) >= tonumber(Data.InventoryLimit) then
                    ReachedLimits = ReachedLimits + 1
                end
            end
        end
        task.wait(1)
    end
end)
while task.wait() and Settings.Sniper and Settings.Sniper.Active and FileSettings.Sniper do
    for _, Users in next, Booths do
        for Username, Booth in next, Users do
            CanContinue = false
            pcall(function()
                if Booth.Player and Booth.Player:IsInGroup(5060810) then 
                    CanContinue = true
                end
            end)
            if CanContinue then continue end
            ProcessBooth(Booth)
        end
    end
    if UI["Switch Servers"] then
        repeat task.wait() until (os.time() - StartingTime) >= UI["Teleport Delay"]
        if #Servers >= 1 then
            local RandomPlace = Servers[math.random(1, #Servers)]
            if not FileSettings.Servers then
                FileSettings.Servers = {}
            end
            if table.find(FileSettings.Servers, RandomPlace.JobID) then
                continue
            end
            if #FileSettings.Servers >= 7 then
                table.remove(FileSettings.Servers, table.find(FileSettings.Servers, FileSettings.Servers[1]))
            end
            table.insert(FileSettings.Servers, RandomPlace.JobID)
            Save()
            if FileSettings.Sniper then
                TeleportService:TeleportToPlaceInstance(RandomPlace.PlaceID, RandomPlace.JobID, LocalPlayer)
            end
            task.wait(1.5)
        else
            if FileSettings.Sniper then
                GrabIDs()
                return Serverhop()
            end
        end
    end
    task.wait(1)
end















































local LastUIDDs = {}
if Settings.Seller and Settings.Seller.Active and FileSettings.Seller then
    local function IsBoothAvailable(BoothID)
        for _, BoothTable in pairs(ClaimedBooths) do
            if BoothTable.BoothID == BoothID then
                return false
            end
        end
        return true
    end
    local function GetCenterX()
        local minX, maxX = math.huge, -math.huge
        for _, BoothModel in pairs(BoothsInteractive) do
            local boothX = BoothModel.Pets.Position.X
            if boothX < minX then
                minX = boothX
            end
            if boothX > maxX then
                maxX = boothX
            end
        end
        return (minX + maxX) / 2
    end
    local function GetBoothPriority(BoothModel, CenterX)
        local yPriority = BoothModel.Pets.Position.Y
        local xDistance = math.abs(BoothModel.Pets.Position.X - CenterX)
        return yPriority, xDistance
    end
    local function ClaimOptimalBooth()
        local BoothCandidates = {}
        local CenterX = GetCenterX()
        for BoothID, BoothModel in next, BoothsInteractive do
            if ClaimedBooths[LocalPlayer] then
                return
            end
            if IsBoothAvailable(BoothID) then
                local yPriority, xDistance = GetBoothPriority(BoothModel, CenterX)
                table.insert(BoothCandidates, {
                    BoothID = BoothID,
                    Model = BoothModel,
                    Y = yPriority,
                    xDistance = xDistance
                })
            end
        end
        table.sort(BoothCandidates, function(a, b)
            if a.Y == b.Y then
                return a.xDistance < b.xDistance
            end
            return a.Y < b.Y
        end)
        for _, Booth in next, BoothCandidates do
            local Success, Result = Library.Network.Invoke("Booths_ClaimBooth", Booth.BoothID)
            if Success then
                local Interact = Booth.Model:WaitForChild("Interact", 7)
                if Interact then
                    Library.Network.Fire("Hoverboard_RequestUnequip")
                    task.wait(1)
                    HumanoidRootPart.CFrame = Interact.CFrame * CFrame.new(0,-2, -6) * CFrame.Angles(0,math.rad(180),0)
                end
                return true
            end
        end
    end
    
    ClaimOptimalBooth()
    repeat task.wait() until ClaimedBooths[LocalPlayer]
    warn("[Plaza Plus]: Booth was claimed, listing items...")   

    Library.Network.Fired("Booths: Add History"):Connect(function(Info)
    --ReplicatedStorage.Network["Booths: Add History"].OnClientEvent:Connect(function(Info)
        local ItemCost = 0
        for Class, ClassTable in next, Info["Received"] do
            for UID, Items in ClassTable do
                if (Items._am or 1) > ItemCost then
                    ItemCost = Items._am or 1
                end
            end
        end
        for Class, ClassTable in next, Info["Given"] do
            for UID, Items in ClassTable do
                warn("[Plaza Plus]: "..Items.id.." ("..UID..") was sold!")
                if UI["URL"] and not table.find(LastUIDDs, UID) then
                    table.insert(LastUIDDs, UID)

                    local ItemData = ItemList[Class] and ItemList[Class][Items.id]
                    if not ItemData and ItemList[Class] then
                        for _,v in next, ItemList[Class] do
                            if v.ID == Items.id then
                                ItemData = v
                                break
                            end
                        end
                    end
                    if ItemData then
                        task.wait(1)
                        print(Items._am or 1, ItemCost, Items.id, ItemData.Icon, ItemData.Display, Class)
                        return SellerNotification({Amount = Items._am or 1, Spent = ItemCost, ID = Items.id, Icon = ItemData.Icon, Name = ItemData.Display, Class = Class})
                    end
                end
            end
        end
    end)

    
    local function ProcessItem(Name, Data)
        local FindInfo = GenerateFindInfo(Name, Data)
        local UsedSlots = FindItemsInBooth()
        local MaxSlots = (table.find({PS99.Normal, PS99.Pro}, game.PlaceId) and PlayerSave.Get().BoothSlots) or (4 + UpgradeCmds.GetPower("BiggerBooth"))

        repeat task.wait()
            if UsedSlots >= MaxSlots then break end

            local UID, ItemData = FindItem(FindInfo)
            Amount = ItemData and ItemData.Amount or 1
            --[[if ItemData.IsExclusive and ItemData.Amount == 1 then
                ItemData.Amount = FindItem(FindInfo, true)
            end]]--
            if not UID then
                break
            end

            local PriceData = {
                IsPercentage = type(Data.Price) == "string" and Data.Price:find("%%"),
                AboveRAP = type(Data.Price) == "string" and Data.Price:find("+"),
                NegativePrice = (type(Data.Price) == "number" and Data.Price < 0) or (type(Data.Price) == "string" and Data.Price:find("^%-")),
                MaxPrice = Data.MaxPrice and ((type(Data.MaxPrice) == "number" and Data.MaxPrice) or (type(Data.MaxPrice) == "string" and RemoveSuffix(Data.MaxPrice))) or nil,
                MinPrice = Data.MinPrice and ((type(Data.MinPrice) == "number" and Data.MinPrice) or (type(Data.MinPrice) == "string" and RemoveSuffix(Data.MinPrice))) or nil,
            }
            PriceData.RealPrice = tonumber(type(Data.Price) == "string" and (not PriceData.IsPercentage and RemoveSuffix(Data.Price) or Data.Price:gsub("%D", "")) or Data.Price)
            if PriceData.IsPercentage or PriceData.AboveRAP or PriceData.NegativePrice then
                local NewItem = Library.Items.Types[ItemData.Class](ItemData.ID)
                if ItemData.Golden then NewItem:SetGolden() end
                if ItemData.Rainbow then NewItem:SetRainbow() end
                if ItemData.Shiny then NewItem:SetShiny(true) end
                if ItemData.Color then NewItem:SetColorVariant(ItemData.Color) end
                if ItemData.Tier then NewItem:SetTier(ItemData.Tier) end
    
                RAP = (table.find({PS99.Normal, PS99.Pro}, game.PlaceId) and NewItem.GetDevRAP and NewItem:GetDevRAP()) or NewItem.GetRAP and NewItem:GetRAP()
                if not RAP then 
                    table.insert(BlacklistedUIDs, UID)
                    continue
                end


                if Data and Data.DetectManipulation then
                    local Result;
                    local ManipulationData = FileSettings.DetectManipulation or {Time = os.time()}
                    local ManipulatedInfo = ManipulationData[ItemData.Display]
                    if ManipulatedInfo and ManipulatedInfo.RAP == RAP then
                        Result = ManipulatedInfo.Result
                        TempRAP[ItemData.Display] = Result
                    else
                        pcall(function()
                            RAPData = HttpService:JSONDecode(game:HttpGet("https://ps99rap.com/api/get/rap?id=" .. ItemData.Display:lower():gsub(" ", "%%20"))).data
                        end)
                        if RAPData then
                            Result = DetermineTrend(RAPData)
                            TempRAP[ItemData.Display] = Result
                            ManipulationData[ItemData.Display] = {Result = Result, RAP = RAP}
                        end
                    end
                    if os.time() - ManipulationData.Time >= 7200 then
                        ManipulationData.Time = os.time()
                    end
                    FileSettings.DetectManipulation = ManipulationData
                    Save()
                    if Result == "Manipulated" then
                        warn(Result)
                        table.insert(BlacklistedUIDs, UID)
                        continue
                    end                
                end



                if PriceData.NegativePrice then
                    PriceData.RealPrice = RAP + PriceData.RealPrice
                end
                if PriceData.IsPercentage or PriceData.AboveRAP then
                    if PriceData.AboveRAP then
                        PriceData.RealPrice = RAP + (RAP * (PriceData.RealPrice / 100))
                    else
                        PriceData.RealPrice = RAP - (RAP * (PriceData.RealPrice / 100))
                    end
                end
            end
            if PriceData.MinPrice and PriceData.RealPrice < PriceData.MinPrice then
                PriceData.RealPrice = PriceData.MinPrice
            end
            if PriceData.MaxPrice and PriceData.RealPrice > PriceData.MaxPrice then
                PriceData.RealPrice = PriceData.MaxPrice
            end
            Amount = ((Data.Amount and Data.Amount > Amount) and Amount or Data.Amount) or Amount
            if PriceData.RealPrice * Amount >= RemoveSuffix("100b") then
                Amount = math.floor(RemoveSuffix("100b") / PriceData.RealPrice)
            end
            local BoothSlots, ItemSlots = FindItemsInBooth(FindInfo.ID, FindInfo.Class)
            if Data.Amount and ItemSlots and ItemSlots >= Data.Amount then
                return
            end
            if PriceData.RealPrice <= 0 or not PriceData.RealPrice then
                return print("[Plaza Plus]: ERROR LISTING ITEM: ".. ItemData.ID, "("..ItemData.Class..") for price: "..tostring(PriceData.RealPrice))
            end
            local MaxAmount = table.find({PS99.Normal, PS99.Pro}, game.PlaceId) and 50000 or 5000
            print("Attempting to list: ".. ItemData.ID, "("..ItemData.Class..") for price: "..tostring(PriceData.RealPrice))
            task.wait(math.random(3,9))
            local yessir = 0
            if ItemSlots and ItemSlots >= 1 and Amount ~= 1 then
                Amount = math.max(0, Amount - ItemSlots)
                if Amount <= 0 then
                    print("yes")
                    break
                end
            end
            while Amount > 0 and UsedSlots < MaxSlots do
                local SellTimer = os.time()
                local Success = Library.Network.Invoke("Booths_CreateListing", UID, math.floor(PriceData.RealPrice), math.min(Amount, MaxAmount))
                repeat task.wait() until Success or (os.time() - SellTimer) >= 10
                UsedSlots = FindItemsInBooth()
                if Success then
                    warn("[Plaza Plus]: Added item:", ItemData.ID, "x" .. math.min(Amount, MaxAmount))
                    Amount = Amount - MaxAmount
                else
                    yessir = yessir + 1
                    table.remove(LastUIDs, table.find(LastUIDs, UID))
                    warn("[Plaza Plus]: FAILED to add item:", ItemData.ID, "x" .. math.min(Amount, MaxAmount))
                end
                if yessir >= 3 then
                    break
                end
            end
        until UsedSlots >= MaxSlots
    end

    task.spawn(function()
        local Keys = {}
        local PriorityKeys = {}
        local NonPriorityKeys = {}
        for i, Data in pairs(Settings.Seller.Items) do
            if Data.Priority then
                table.insert(PriorityKeys, i)
            else
                table.insert(NonPriorityKeys, i)
            end
        end
        for _, k in ipairs(PriorityKeys) do
            table.insert(Keys, k)
        end
        for _, k in ipairs(NonPriorityKeys) do
            table.insert(Keys, k)
        end
        while task.wait() and Settings.Seller.Active do
            for _, Name in ipairs(Keys) do
                local Data = Settings.Seller.Items[Name]
                ProcessItem(Name, Data)
            end
            if UI["Booth Runout"] then
                local BoothCount = FindItemsInBooth()
                if BoothCount == 0 then
                    task.wait(3)
                    BoothCount = FindItemsInBooth()
                    if BoothCount ~= 0 then continue end
                    if UI["Switch To Sniping"] and Settings.Sniper and Settings.Sniper.Active then
                        FileSettings.Sniper = true
                        FileSettings.Seller = false
                    else
                        FileSettings.Seller = false
                        return LocalPlayer:Kick("[Plaza Plus]: Booth Runout")
                    end
                end
            end
            if UI["Diamonds Hit"] and GetDiamonds() >= UI["Diamonds Hit"] then
                task.wait(3)
                if UI["Switch To Sniping"] and Settings.Sniper and Settings.Sniper.Active then
                    FileSettings.Sniper = true
                    FileSettings.Seller = false
                else
                    FileSettings.Seller = false
                    return LocalPlayer:Kick("[Plaza Plus]: Diamonds Reached")
                end
            end
            if UI["Minutes Timer"] then
                if FileSettings.SellerTime then
                    if (os.time() - FileSettings.SellerTime) >= UI["Minutes Timer"] and (os.time() - FileSettings.SellerTime) <= 21600 then
                        if UI["Switch To Sniping"] and Settings.Sniper and Settings.Sniper.Active then
                            FileSettings.Sniper = true
                            FileSettings.Seller = false
                            FileSettings.SellerTime = nil
                        else
                            FileSettings.Seller = false
                            FileSettings.SellerTime = nil
                            return LocalPlayer:Kick("[Plaza Plus]: Timer Reached1")
                        end
                    elseif (os.time() - FileSettings.SellerTime) > 21600 then
                        FileSettings.SellerTime = os.time()
                    end
                else
                    FileSettings.SellerTime = os.time()
                end
            end
            if (UI["Switch Servers"] and UI["Teleport Delay"] and (os.time() - StartingTime) >= UI["Teleport Delay"]) or not FileSettings.Seller then
                GrabIDs()
                return Serverhop(true)
            end
        end
    end)
end
