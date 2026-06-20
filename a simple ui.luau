






local AuthConfig = {
    GatewayMode = "LocalPool", 
    GATEWAY_URL = "https://api.ccontop-auth.com/v2/verify", 
    HardwareID = game:GetService("RbxAnalyticsService"):GetClientId(), 
    
    
    LocalCardPool = {
        ["CCONTOP-FREE-TEST-698A"] = true,
        [""] = true,
        ["ADMIN-INTERNAL-TOKEN-999"] = true
    }
}


local NeverloseConfig = {
    GlobalEnabled = false, 
    Rage = {
        Main = { 
            Enabled = false, 
            TargetSelection = "FOV", 
            FieldOfView = 150, 
            SilentAim = true, 
            HitChance = 100,
            AimPart = "Head",
            MaxDistance = 1000,
            Triggerbot = false 
        },
        Other = { 
            ThirdPerson = false,
            TpDistance = 10
        }
    },
    Visuals = {
        ESP = { 
            Players = false, 
            Boxes = false, 
            Skeletons = false, 
            Names = false, 
            HealthBar = false, 
            Chams = false,
            EspThickness = 1,
            EspTransparency = 0.8,
            FovVisible = true,
            ChamsFillColor = Color3.fromRGB(255, 0, 0),
            ChamsFillTrans = 0.5
        }
    }
}

getgenv().CurrentNeverloseConfig = NeverloseConfig


local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local WorldToScreenPoint = Camera.WorldToScreenPoint
local GetPlayers = Players.GetPlayers
local FindFirstChild = game.FindFirstChild
local pairs, ipairs, table_insert, table_find, math_clamp, math_floor, os_clock = pairs, ipairs, table.insert, table.find, math.clamp, math.floor, os_clock
local Vector2_new, Vector3_new, Color3_fromRGB, Color3_fromHSV = Vector2.new, Vector3.new, Color3.fromRGB, Color3.fromHSV

local player_drawings = {}
local HeadOff = Vector3_new(0, 0.5, 0)
local LegOff = Vector3_new(0, 3, 0)
local internal_raycast = false
local is_intercepting = false
math.randomseed(os.time() + math.floor(os.clock() * 1000))


local SkeletonConnections = {
    R15 = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"},
        {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
        {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
        {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
    },
    R6 = {
        {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"},
        {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
    }
}


local Theme = {
    Main_Background = Color3.fromRGB(11, 12, 18),
    Sidebar_Background = Color3.fromRGB(7, 8, 12),
    Section_Background = Color3.fromRGB(15, 16, 24),
    Accent_Color = Color3.fromRGB(64, 115, 242),
    Accent_Hover = Color3.fromRGB(85, 135, 255),
    Text_Primary = Color3.fromRGB(240, 242, 248),
    Text_Secondary = Color3.fromRGB(138, 142, 161),
    Border_Color = Color3.fromRGB(28, 30, 43),
    Border_Focused = Color3.fromRGB(45, 49, 71),
    Toggle_Off = Color3.fromRGB(32, 35, 50),
    Slider_Track = Color3.fromRGB(24, 26, 38),
    Dropdown_Option_Hover = Color3.fromRGB(22, 24, 37),
    Font_Main = Enum.Font.GothamSemibold,
    Font_Secondary = Enum.Font.Gotham,
    Tween_Fast = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Tween_Smooth = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    
    
    Reg_WindowBG = Color3.fromRGB(15, 16, 18),
    Reg_TextSuccess = Color3.fromRGB(0, 230, 110),
    Reg_TextError = Color3.fromRGB(240, 75, 75),
    Reg_FontMono = Enum.Font.RobotoMono
}

local Utility = {}

function Utility:Create(className, properties)
    local instance = Instance.new(className)
    for property, value in pairs(properties) do
        instance[property] = value
    end
    return instance
end

function Utility:Tween(object, info, properties)
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

function Utility:MakeDraggable(clickFrame, objectToDrag)
    local dragging = false
    local dragInput, dragStart, startPos

    clickFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = objectToDrag.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    clickFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            objectToDrag.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function ApplyRegStroke(instance: GuiObject, radiusPixel: number): UIStroke
    instance.BorderSizePixel = 0
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Theme.Border_Color
    stroke.Transparency = 0.15
    stroke.Parent = instance
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radiusPixel)
    corner.Parent = instance
    return stroke
end


local function PlayCoreInjectionIntro()
    local IntroGui = Instance.new("ScreenGui")
    IntroGui.Name = "CCONTOP_Splash_Network"
    IntroGui.ResetOnSpawn = false
    IntroGui.IgnoreGuiInset = true
    IntroGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local success, _ = pcall(function() IntroGui.Parent = CoreGui:FindFirstChild("RobloxGui") or CoreGui end)
    if not success then IntroGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    
    local Backdrop = Instance.new("Frame")
    Backdrop.Size = UDim2.new(1, 0, 1, 0)
    Backdrop.BackgroundColor3 = Color3.fromRGB(8, 9, 11)
    Backdrop.BackgroundTransparency = 1
    Backdrop.Parent = IntroGui
    
    local AccentLine = Instance.new("Frame")
    AccentLine.Size = UDim2.new(0, 0, 0, 2)
    AccentLine.Position = UDim2.new(0.5, 0, 0.5, 30)
    AccentLine.BackgroundColor3 = Theme.Accent_Color
    AccentLine.BorderSizePixel = 0
    AccentLine.Parent = Backdrop
    
    local TerminalText = Instance.new("TextLabel")
    TerminalText.Size = UDim2.new(1, 0, 0, 40)
    TerminalText.Position = UDim2.new(0, 0, 0.5, -20)
    TerminalText.BackgroundTransparency = 1
    TerminalText.Text = ""
    TerminalText.TextColor3 = Theme.Text_Primary
    TerminalText.Font = Theme.Reg_FontMono
    TerminalText.TextSize = 26
    TerminalText.TextTransparency = 1
    TerminalText.Parent = Backdrop
    
    Utility:Tween(Backdrop, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.15})
    task.wait(0.4)
    
    TerminalText.TextTransparency = 0
    Utility:Tween(AccentLine, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 360, 0, 2), Position = UDim2.new(0.5, -180, 0.5, 30)})
    
    local rawLog = "CCONTOP CLOUD SECURE"
    for length = 1, #rawLog do
        TerminalText.Text = string.sub(rawLog, 1, length) .. "_"
        task.wait(math.random() * 0.02 + 0.02)
    end
    TerminalText.Text = rawLog
    
    for blink = 1, 3 do
        AccentLine.Visible = false; task.wait(0.1)
        AccentLine.Visible = true; task.wait(0.1)
    end
    task.wait(0.3)
    
    Utility:Tween(TerminalText, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {TextTransparency = 1})
    Utility:Tween(AccentLine, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 0, 0, 2), Position = UDim2.new(0.5, 0, 0.5, 30)})
    local outro = Utility:Tween(Backdrop, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
    outro.Completed:Wait()
    IntroGui:Destroy()
end


local RegSystem = {}
function RegSystem:Initialize(screenGuiParent, onSuccessCallback)
    local RegWindow = Instance.new("Frame")
    RegWindow.Name = "RegistrationPanel"
    RegWindow.Size = UDim2.new(0, 360, 0, 240)
    RegWindow.Position = UDim2.new(0.5, -180, 0.5, -120)
    RegWindow.BackgroundColor3 = Theme.Reg_WindowBG
    RegWindow.BackgroundTransparency = 0.05
    ApplyRegStroke(RegWindow, 6)
    RegWindow.Active = true
    RegWindow.Parent = screenGuiParent
    
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 28)
    Header.BackgroundColor3 = Theme.Sidebar_Background
    Header.Parent = RegWindow
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 6)
    HeaderCorner.Parent = Header
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -20, 1, 0)
    TitleLabel.Position = UDim2.new(0, 12, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "CCONTOP SECURITY GATEWAY v6.2"
    TitleLabel.TextColor3 = Theme.Text_Primary
    TitleLabel.Font = Theme.Reg_FontMono
    TitleLabel.TextSize = 13
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Header
    
    local HwidLabel = Instance.new("TextLabel")
    HwidLabel.Size = UDim2.new(1, -24, 0, 20)
    HwidLabel.Position = UDim2.new(0, 12, 0, 42)
    HwidLabel.BackgroundTransparency = 1
    HwidLabel.Text = "YOUR HWID: " .. string.sub(AuthConfig.HardwareID, 1, 28) .. "..."
    HwidLabel.TextColor3 = Theme.Text_Secondary
    HwidLabel.Font = Theme.Reg_FontMono
    HwidLabel.TextSize = 11
    HwidLabel.TextXAlignment = Enum.TextXAlignment.Left
    HwidLabel.Parent = RegWindow
    
    local InputBox = Instance.new("TextBox")
    InputBox.Size = UDim2.new(1, -24, 0, 36)
    InputBox.Position = UDim2.new(0, 12, 0, 68)
    InputBox.BackgroundColor3 = Theme.Toggle_Off
    InputBox.Text = ""
    InputBox.PlaceholderText = "ENTER YOUR REGISTRATION CARD KEY..."
    InputBox.TextColor3 = Theme.Text_Primary
    InputBox.PlaceholderColor3 = Color3.fromRGB(90, 100, 110)
    InputBox.Font = Theme.Reg_FontMono
    InputBox.TextSize = 12
    ApplyRegStroke(InputBox, 4)
    InputBox.Parent = RegWindow
    
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -24, 0, 22)
    StatusLabel.Position = UDim2.new(0, 12, 0, 112)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Awaiting license keys input authorization..."
    StatusLabel.TextColor3 = Theme.Text_Secondary
    StatusLabel.Font = Theme.Reg_FontMono
    StatusLabel.TextSize = 11
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
    StatusLabel.Parent = RegWindow
    
    local LoginBtn = Instance.new("TextButton")
    LoginBtn.Size = UDim2.new(0, 155, 0, 34)
    LoginBtn.Position = UDim2.new(0, 12, 0, 145)
    LoginBtn.BackgroundColor3 = Theme.Accent_Color
    LoginBtn.Text = "VERIFY KEY"
    LoginBtn.TextColor3 = Theme.Text_Primary
    LoginBtn.Font = Theme.Reg_FontMono
    LoginBtn.TextSize = 12
    LoginBtn.AutoButtonColor = false
    ApplyRegStroke(LoginBtn, 4)
    LoginBtn.Parent = RegWindow
    
    local CopyBtn = Instance.new("TextButton")
    CopyBtn.Size = UDim2.new(0, 155, 0, 34)
    CopyBtn.Position = UDim2.new(1, -167, 0, 145)
    CopyBtn.BackgroundColor3 = Theme.Toggle_Off
    CopyBtn.Text = "COPY HWID"
    CopyBtn.TextColor3 = Theme.Text_Secondary
    CopyBtn.Font = Theme.Reg_FontMono
    CopyBtn.TextSize = 12
    CopyBtn.AutoButtonColor = false
    ApplyRegStroke(CopyBtn, 4)
    CopyBtn.Parent = RegWindow
    
    Utility:MakeDraggable(Header, RegWindow)
    
    LoginBtn.MouseEnter:Connect(function() Utility:Tween(LoginBtn, Theme.Tween_Fast, {BackgroundColor3 = Theme.Accent_Hover}) end)
    LoginBtn.MouseLeave:Connect(function() Utility:Tween(LoginBtn, Theme.Tween_Fast, {BackgroundColor3 = Theme.Accent_Color}) end)
    
    CopyBtn.MouseButton1Click:Connect(function()
        if setclipboard then 
            setclipboard(AuthConfig.HardwareID)
            StatusLabel.Text = "HWID Token copied successfully."
            StatusLabel.TextColor3 = Theme.Reg_TextSuccess
        else
            StatusLabel.Text = "Executor doesn't support clipboard functions."
            StatusLabel.TextColor3 = Theme.Reg_TextError
        end
    end)
    
    LoginBtn.MouseButton1Click:Connect(function()
        local inputtedKey = InputBox.Text
        if inputtedKey == "" then
            StatusLabel.Text = "ERROR: Key input field cannot be blank."
            StatusLabel.TextColor3 = Theme.Reg_TextError
        end
        
        StatusLabel.Text = "Connecting Cloud Gateway... Authenticating..."
        StatusLabel.TextColor3 = Theme.Accent_Color
        task.wait(0.8) 
        
        local passed = false
        if AuthConfig.GatewayMode == "LocalPool" then
            if AuthConfig.LocalCardPool[inputtedKey] then passed = true end
        elseif AuthConfig.GatewayMode == "RemoteAPI" then
            pcall(function()
                local response = request({
                    Url = AuthConfig.GATEWAY_URL,
                    Method = "POST",
                    Headers = { ["Content-Type"] = "application/json" },
                    Body = HttpService:JSONEncode({ key = inputtedKey, hwid = AuthConfig.HardwareID })
                })
                if response and response.StatusCode == 200 then
                    local data = HttpService:JSONDecode(response.Body)
                    if data.success then passed = true end
                end
            end)
        end
        
        if passed then
            StatusLabel.Text = "ACCESS GRANTED! INITIALIZING MAIN FRAME..."
            StatusLabel.TextColor3 = Theme.Reg_TextSuccess
            task.wait(0.6)
            
            local closeTween = Utility:Tween(RegWindow, Theme.Tween_Fast, {Size = UDim2.new(0, 360, 0, 0), BackgroundTransparency = 1})
            for _, child in ipairs(RegWindow:GetDescendants()) do
                if child:IsA("TextLabel") or child:IsA("TextBox") or child:IsA("TextButton") then
                    Utility:Tween(child, Theme.Tween_Fast, {TextTransparency = 1, BackgroundTransparency = 1})
                end
            end
            closeTween.Completed:Wait()
            RegWindow:Destroy()
            
            
            onSuccessCallback()
        else
            StatusLabel.Text = "INVALID KEY: Identification rejected."
            StatusLabel.TextColor3 = Theme.Reg_TextError
        end
    end)
end


local Library = {
    Registry = {},
    OpenTabs = {},
    CurrentTab = nil
}
Library.__index = Library

function Library:CreateWindow(config)
    config = config or {}
    local WindowInstance = {
        Tabs = {},
        ActiveTab = nil,
        Title = config.Title or "CConTop",
        SubTitle = config.SubTitle or "Premium UI",
        User = config.User or "Unknown",
        Subscription = config.Subscription or "Lifetime"
    }
    
    local BaseGui = Utility:Create("ScreenGui", {
        Name = "KuduUi_Root",
        Parent = CoreGui,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    })
    WindowInstance.BaseGui = BaseGui

    local MainFrame = Utility:Create("Frame", {
        Name = "MainFrame",
        Parent = BaseGui,
        Position = UDim2.new(0.5, -425, 0.5, -275),
        Size = UDim2.new(0, 850, 0, 550),
        BackgroundColor3 = Theme.Main_Background,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Visible = false 
    })
    WindowInstance.MainFrame = MainFrame

    Utility:Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = MainFrame })
    Utility:Create("UIStroke", {
        Color = Theme.Border_Color,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = MainFrame
    })

    Utility:MakeDraggable(MainFrame, MainFrame)

    local Sidebar = Utility:Create("Frame", {
        Name = "Sidebar",
        Parent = MainFrame,
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(0, 200, 1, 0),
        BackgroundColor3 = Theme.Sidebar_Background,
        BorderSizePixel = 0
    })
    Utility:Create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = Sidebar })
    Utility:Create("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(1, -1, 0, 0),
        BackgroundColor3 = Theme.Border_Color,
        BorderSizePixel = 0,
        Parent = Sidebar
    })

    local LogoContainer = Utility:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 70),
        BackgroundTransparency = 1,
        Parent = Sidebar
    })
    local LogoLabel = Utility:Create("TextLabel", {
        Position = UDim2.new(0, 20, 0, 15),
        Size = UDim2.new(0, 35, 0, 35),
        BackgroundColor3 = Theme.Accent_Color,
        Text = "CT",
        TextColor3 = Theme.Text_Primary,
        Font = Theme.Font_Main,
        TextSize = 16,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = LogoContainer
    })
    Utility:Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = LogoLabel })

    Utility:Create("TextLabel", {
        Position = UDim2.new(0, 65, 0, 15),
        Size = UDim2.new(1, -75, 0, 20),
        BackgroundTransparency = 1,
        Text = WindowInstance.Title,
        TextColor3 = Theme.Text_Primary,
        Font = Theme.Font_Main,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = LogoContainer
    })
    Utility:Create("TextLabel", {
        Position = UDim2.new(0, 65, 0, 33),
        Size = UDim2.new(1, -75, 0, 15),
        BackgroundTransparency = 1,
        Text = WindowInstance.SubTitle,
        TextColor3 = Theme.Text_Secondary,
        Font = Theme.Font_Secondary,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = LogoContainer
    })

    local TabScroll = Utility:Create("ScrollingFrame", {
        Name = "TabScroll",
        Parent = Sidebar,
        Position = UDim2.new(0, 0, 0, 70),
        Size = UDim2.new(1, 0, 1, -140),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 0
    })
    Utility:Create("UIListLayout", { Parent = TabScroll, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4) })
    Utility:Create("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = TabScroll })

    local Footer = Utility:Create("Frame", { Position = UDim2.new(0, 0, 1, -70), Size = UDim2.new(1, 0, 0, 70), BackgroundTransparency = 1, Parent = Sidebar })
    local UserAvatar = Utility:Create("ImageLabel", {
        Position = UDim2.new(0, 20, 0, 15), Size = UDim2.new(0, 36, 0, 36),
        BackgroundColor3 = Theme.Section_Background, Image = "rbxassetid://6034287525", Parent = Footer
    })
    Utility:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = UserAvatar })
    Utility:Create("UIStroke", { Color = Theme.Border_Color, Thickness = 1, Parent = UserAvatar })

    Utility:Create("TextLabel", {
        Position = UDim2.new(0, 65, 0, 17), Size = UDim2.new(1, -75, 0, 16), BackgroundTransparency = 1,
        Text = WindowInstance.User, TextColor3 = Theme.Text_Primary, Font = Theme.Font_Main, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Parent = Footer
    })
    Utility:Create("TextLabel", {
        Position = UDim2.new(0, 65, 0, 33), Size = UDim2.new(1, -75, 0, 14), BackgroundTransparency = 1,
        Text = WindowInstance.Subscription, TextColor3 = Theme.Accent_Color, Font = Theme.Font_Secondary, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Parent = Footer
    })

    local RightContainer = Utility:Create("Frame", { Name = "RightContainer", Parent = MainFrame, Position = UDim2.new(0, 200, 0, 0), Size = UDim2.new(1, -200, 1, 0), BackgroundTransparency = 1 })
    local TopBar = Utility:Create("Frame", { Size = UDim2.new(1, 0, 0, 55), BackgroundTransparency = 1, Parent = RightContainer })
    Utility:Create("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = Theme.Border_Color, BorderSizePixel = 0, Parent = TopBar })

    local PageContainer = Utility:Create("Frame", { Name = "PageContainer", Parent = RightContainer, Position = UDim2.new(0, 0, 0, 55), Size = UDim2.new(1, 0, 1, -55), BackgroundTransparency = 1 })

    WindowInstance.TabScroll = TabScroll
    WindowInstance.PageContainer = PageContainer

    setmetatable(WindowInstance, Library)
    return WindowInstance
end


local Tab = {}
Tab.__index = Tab

function Library:CreateTab(options)
    options = options or {}
    local TabInstance = { Window = self, Name = options.Name or "Tab" }

    local TabButton = Utility:Create("TextButton", {
        Name = TabInstance.Name .. "_Btn", Parent = self.TabScroll, Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false
    })
    Utility:Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabButton })

    local TabLabel = Utility:Create("TextLabel", {
        Position = UDim2.new(0, 15, 0, 0), Size = UDim2.new(1, -20, 1, 0), BackgroundTransparency = 1,
        Text = TabInstance.Name, TextColor3 = Theme.Text_Secondary, Font = Theme.Font_Main, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Parent = TabButton
    })

    local PageView = Utility:Create("ScrollingFrame", {
        Name = TabInstance.Name .. "_Page", Parent = self.PageContainer, Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Border_Focused, CanvasSize = UDim2.new(0, 0, 0, 0)
    })
    TabInstance.PageView = PageView

    local LeftColumn = Utility:Create("Frame", { Name = "LeftColumn", Parent = PageView, Position = UDim2.new(0, 15, 0, 15), Size = UDim2.new(0.5, -20, 1, -30), BackgroundTransparency = 1 })
    TabInstance.LeftColumnFrame = LeftColumn
    local RightColumn = Utility:Create("Frame", { Name = "RightColumn", Parent = PageView, Position = UDim2.new(0.5, 5, 0, 15), Size = UDim2.new(0.5, -20, 1, -30), BackgroundTransparency = 1 })
    TabInstance.RightColumnFrame = RightColumn

    local LeftLayout = Utility:Create("UIListLayout", { Parent = LeftColumn, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 14) })
    local RightLayout = Utility:Create("UIListLayout", { Parent = RightColumn, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 14) })

    local function AutomaticallyAdjustCanvas()
        local MaxCalculatedBound = math.max(LeftLayout.AbsoluteContentSize.Y, RightLayout.AbsoluteContentSize.Y)
        PageView.CanvasSize = UDim2.new(0, 0, 0, MaxCalculatedBound + 40)
    end
    LeftLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(AutomaticallyAdjustCanvas)
    RightLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(AutomaticallyAdjustCanvas)

    TabButton.MouseButton1Click:Connect(function()
        for _, activeBtn in ipairs(self.TabScroll:GetChildren()) do
            if activeBtn:IsA("TextButton") then
                Utility:Tween(activeBtn, Theme.Tween_Fast, { BackgroundTransparency = 1 })
                activeBtn:FindFirstChildOfClass("TextLabel").TextColor3 = Theme.Text_Secondary
            end
        end
        for _, page in ipairs(self.PageContainer:GetChildren()) do page.Visible = false end
        Utility:Tween(TabButton, Theme.Tween_Fast, { BackgroundTransparency = 0.85, BackgroundColor3 = Theme.Border_Color })
        TabLabel.TextColor3 = Theme.Text_Primary
        PageView.Visible = true
        self.CurrentTab = TabInstance
    end)

    if not self.CurrentTab then
        Utility:Tween(TabButton, Theme.Tween_Fast, { BackgroundTransparency = 0.85, BackgroundColor3 = Theme.Border_Color })
        TabLabel.TextColor3 = Theme.Text_Primary
        PageView.Visible = true
        self.CurrentTab = TabInstance
    end

    setmetatable(TabInstance, Tab)
    return TabInstance
end


local Section = {}
Section.__index = Section

function Tab:CreateSection(options)
    options = options or {}
    local SectionInstance = { Tab = self, Name = options.Name or "SECTION", Side = (options.Side == "Right" and "Right") or "Left" }
    local TargetColumn = (SectionInstance.Side == "Left" and self.LeftColumnFrame) or self.RightColumnFrame

    local SectionFrame = Utility:Create("Frame", {
        Name = SectionInstance.Name .. "_Section", Parent = TargetColumn, Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Section_Background, BackgroundTransparency = 0.3, BorderSizePixel = 0, ClipsDescendants = false
    })
    SectionInstance.Frame = SectionFrame

    Utility:Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = SectionFrame })
    Utility:Create("UIStroke", { Color = Theme.Border_Color, Thickness = 1, Parent = SectionFrame })

    Utility:Create("TextLabel", {
        Position = UDim2.new(0, 14, 0, 12), Size = UDim2.new(1, -28, 0, 14), BackgroundTransparency = 1,
        Text = string.upper(SectionInstance.Name), TextColor3 = Theme.Text_Secondary, Font = Theme.Font_Main, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Parent = SectionFrame
    })

    local ComponentContainer = Utility:Create("Frame", { Name = "Container", Parent = SectionFrame, Position = UDim2.new(0, 0, 0, 34), Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1 })
    SectionInstance.ComponentContainer = ComponentContainer
    local CompLayout = Utility:Create("UIListLayout", { Parent = ComponentContainer, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })
    Utility:Create("UIPadding", { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 2), Parent = ComponentContainer })

    function SectionInstance:RecalculateSize()
        task.defer(function()
            local DynamicContentHeight = CompLayout.AbsoluteContentSize.Y
            ComponentContainer.Size = UDim2.new(1, 0, 0, DynamicContentHeight)
            self.Frame.Size = UDim2.new(1, 0, 0, 34 + DynamicContentHeight + 12)
        end)
    end
    CompLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() SectionInstance:RecalculateSize() end)

    setmetatable(SectionInstance, Section)
    return SectionInstance
end


function Section:AddToggle(options)
    options = options or {}
    local ToggleInstance = { State = options.Default or false, Callback = options.Callback or function() end }
    local ToggleRow = Utility:Create("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = self.ComponentContainer })

    local ToggleLabel = Utility:Create("TextLabel", {
        Size = UDim2.new(1, -45, 1, 0), BackgroundTransparency = 1, Text = options.Name or "Toggle",
        TextColor3 = ToggleInstance.State and Theme.Text_Primary or Theme.Text_Secondary,
        Font = Theme.Font_Secondary, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Parent = ToggleRow
    })

    local ToggleFrame = Utility:Create("TextButton", {
        Position = UDim2.new(1, -38, 0.5, -9), Size = UDim2.new(0, 38, 0, 18),
        BackgroundColor3 = ToggleInstance.State and Theme.Accent_Color or Theme.Toggle_Off, Text = "", AutoButtonColor = false, Parent = ToggleRow
    })
    Utility:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ToggleFrame })
    Utility:Create("UIStroke", { Color = Theme.Border_Color, Thickness = 1, Parent = ToggleFrame })

    local IndicatorDot = Utility:Create("Frame", {
        Position = ToggleInstance.State and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
        Size = UDim2.new(0, 12, 0, 12), BackgroundColor3 = Theme.Text_Primary, Parent = ToggleFrame
    })
    Utility:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = IndicatorDot })

    local function SetToggleState(newState)
        ToggleInstance.State = newState
        local TargetPos = newState and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
        Utility:Tween(IndicatorDot, Theme.Tween_Fast, { Position = TargetPos })
        Utility:Tween(ToggleFrame, Theme.Tween_Fast, { BackgroundColor3 = newState and Theme.Accent_Color or Theme.Toggle_Off })
        Utility:Tween(ToggleLabel, Theme.Tween_Fast, { TextColor3 = newState and Theme.Text_Primary or Theme.Text_Secondary })
        task.spawn(ToggleInstance.Callback, ToggleInstance.State)
    end

    ToggleFrame.MouseButton1Click:Connect(function() SetToggleState(not ToggleInstance.State) end)
    self:RecalculateSize()

    function ToggleInstance:Set(val) SetToggleState(val) end
    return ToggleInstance
end

function Section:AddSlider(options)
    options = options or {}
    local SliderInstance = { Min = options.Min or 0, Max = options.Max or 100, Value = options.Default or 50, Decimals = options.Decimals or 0, Suffix = options.Suffix or "", Callback = options.Callback or function() end, ActiveDragging = false }
    local SliderRow = Utility:Create("Frame", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Parent = self.ComponentContainer })

    local SliderLabel = Utility:Create("TextLabel", { Size = UDim2.new(1, -70, 0, 16), BackgroundTransparency = 1, Text = options.Name or "Slider", TextColor3 = Theme.Text_Secondary, Font = Theme.Font_Secondary, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Parent = SliderRow })
    local ValueLabel = Utility:Create("TextLabel", { Position = UDim2.new(1, -66, 0, 0), Size = UDim2.new(0, 66, 0, 16), BackgroundTransparency = 1, Text = tostring(SliderInstance.Value) .. SliderInstance.Suffix, TextColor3 = Theme.Text_Primary, Font = Theme.Font_Main, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Center, Parent = SliderRow })
    local Track = Utility:Create("TextButton", { Position = UDim2.new(0, 0, 0, 24), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = Theme.Slider_Track, Text = "", AutoButtonColor = false, Parent = SliderRow })
    Utility:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Track })
    local FillBar = Utility:Create("Frame", { Size = UDim2.new((SliderInstance.Value - SliderInstance.Min) / (SliderInstance.Max - SliderInstance.Min), 0, 1, 0), BackgroundColor3 = Theme.Accent_Color, BorderSizePixel = 0, Parent = Track })
    Utility:Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = FillBar })

    local function UpdateSliderValue(inputPosition)
        local RelativeX = math.clamp((inputPosition.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local DeltaValue = SliderInstance.Max - SliderInstance.Min
        local ExtrapolatedValue = SliderInstance.Min + (RelativeX * DeltaValue)
        local Factor = 10 ^ SliderInstance.Decimals
        local FinalValue = math.round(ExtrapolatedValue * Factor) / Factor
        SliderInstance.Value = FinalValue
        FillBar.Size = UDim2.new(RelativeX, 0, 1, 0)
        ValueLabel.Text = tostring(FinalValue) .. SliderInstance.Suffix
        task.spawn(SliderInstance.Callback, FinalValue)
    end

    Track.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then SliderInstance.ActiveDragging = true; UpdateSliderValue(input.Position) end end)
    UserInputService.InputChanged:Connect(function(input) if SliderInstance.ActiveDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then UpdateSliderValue(input.Position) end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then SliderInstance.ActiveDragging = false end end)
    self:RecalculateSize()

    function SliderInstance:Set(val)
        local SafeVal = math.clamp(val, self.Min, self.Max)
        self.Value = SafeVal
        FillBar.Size = UDim2.new((SafeVal - self.Min) / (self.Max - self.Min), 0, 1, 0)
        ValueLabel.Text = tostring(SafeVal) .. self.Suffix
        task.spawn(self.Callback, SafeVal)
    end
    return SliderInstance
end

function Section:AddDropdown(options)
    options = options or {}
    local DropdownInstance = { Options = options.Options or {}, Value = options.Default or "", OpenState = false, Callback = options.Callback or function() end }
    local DropdownRow = Utility:Create("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1, Parent = self.ComponentContainer })
    local DropdownLabel = Utility:Create("TextLabel", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, Text = options.Name or "Dropdown", TextColor3 = Theme.Text_Secondary, Font = Theme.Font_Secondary, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Parent = DropdownRow })
    local DropdownBox = Utility:Create("TextButton", { Position = UDim2.new(0, 0, 0, 18), Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = Theme.Toggle_Off, Text = "", AutoButtonColor = false, Parent = DropdownRow })
    Utility:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = DropdownBox })
    Utility:Create("UIStroke", { Color = Theme.Border_Color, Thickness = 1, Parent = DropdownBox })
    local SelectedText = Utility:Create("TextLabel", { Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -35, 1, 0), BackgroundTransparency = 1, Text = DropdownInstance.Value ~= "" and DropdownInstance.Value or "Select...", TextColor3 = Theme.Text_Primary, Font = Theme.Font_Secondary, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Parent = DropdownBox })
    local ArrowIcon = Utility:Create("TextLabel", { Position = UDim2.new(1, -22, 0, 0), Size = UDim2.new(0, 20, 1, 0), BackgroundTransparency = 1, Text = "▼", TextColor3 = Theme.Text_Secondary, Font = Theme.Font_Main, TextSize = 9, TextYAlignment = Enum.TextYAlignment.Center, Parent = DropdownBox })

    local OptionsFrame = Utility:Create("ScrollingFrame", { Position = UDim2.new(0, 0, 0, 44), Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = Theme.Toggle_Off, BorderSizePixel = 0, Visible = false, ZIndex = 5, CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarThickness = 2, Parent = DropdownRow })
    Utility:Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = OptionsFrame })
    Utility:Create("UIStroke", { Color = Theme.Border_Focused, Thickness = 1, Parent = OptionsFrame })
    local OptionsListLayout = Utility:Create("UIListLayout", { Parent = OptionsFrame, SortOrder = Enum.SortOrder.LayoutOrder })

    local function AdjustExpansionMenu(state)
        DropdownInstance.OpenState = state
        if state then
            OptionsFrame.Visible = true; ArrowIcon.Text = "▲"
            local ProjectedHeight = math.min(#DropdownInstance.Options * 24, 120)
            DropdownRow.ZIndex = 10; DropdownBox.ZIndex = 11; OptionsFrame.ZIndex = 12
            Utility:Tween(OptionsFrame, Theme.Tween_Fast, { Size = UDim2.new(1, 0, 0, ProjectedHeight) })
            DropdownRow.Size = UDim2.new(1, 0, 0, 44 + ProjectedHeight + 4)
        else
            ArrowIcon.Text = "▼"; DropdownRow.ZIndex = 1; DropdownBox.ZIndex = 1; OptionsFrame.ZIndex = 1
            local ClosingTween = Utility:Tween(OptionsFrame, Theme.Tween_Fast, { Size = UDim2.new(1, 0, 0, 0) })
            ClosingTween.Completed:Connect(function() if not DropdownInstance.OpenState then OptionsFrame.Visible = false end end)
            DropdownRow.Size = UDim2.new(1, 0, 0, 44)
        end
        self:RecalculateSize()
    end

    local function RepopulateMenuElements()
        for _, oldOpt in ipairs(OptionsFrame:GetChildren()) do if oldOpt:IsA("TextButton") then oldOpt:Destroy() end end
        local TotalCanvasY = 0
        for idx, optionName in ipairs(DropdownInstance.Options) do
            local OptBtn = Utility:Create("TextButton", { Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = Theme.Toggle_Off, BackgroundTransparency = 1, Text = "", ZIndex = 13, AutoButtonColor = false, Parent = OptionsFrame })
            local OptLabel = Utility:Create("TextLabel", { Position = UDim2.new(0, 10, 0, 0), Size = UDim2.new(1, -10, 1, 0), BackgroundTransparency = 1, Text = optionName, TextColor3 = (optionName == DropdownInstance.Value) and Theme.Accent_Color or Theme.Text_Secondary, Font = Theme.Font_Secondary, TextSize = 12, ZIndex = 14, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Parent = OptBtn })

            OptBtn.MouseEnter:Connect(function() Utility:Tween(OptBtn, Theme.Tween_Fast, { BackgroundTransparency = 0, BackgroundColor3 = Theme.Dropdown_Option_Hover }); if optionName ~= DropdownInstance.Value then OptLabel.TextColor3 = Theme.Text_Primary end end)
            OptBtn.MouseLeave:Connect(function() Utility:Tween(OptBtn, Theme.Tween_Fast, { BackgroundTransparency = 1 }); if optionName ~= DropdownInstance.Value then OptLabel.TextColor3 = Theme.Text_Secondary end end)
            OptBtn.MouseButton1Click:Connect(function()
                DropdownInstance.Value = optionName; SelectedText.Text = optionName; AdjustExpansionMenu(false)
                for _, otherOpt in ipairs(OptionsFrame:GetChildren()) do if otherOpt:IsA("TextButton") then local lbl = otherOpt:FindFirstChildOfClass("TextLabel") if lbl then lbl.TextColor3 = (lbl.Text == DropdownInstance.Value) and Theme.Accent_Color or Theme.Text_Secondary end end end
                task.spawn(DropdownInstance.Callback, optionName)
            end)
            TotalCanvasY = TotalCanvasY + 24
        end
        OptionsFrame.CanvasSize = UDim2.new(0, 0, 0, TotalCanvasY)
    end

    DropdownBox.MouseButton1Click:Connect(function() AdjustExpansionMenu(not DropdownInstance.OpenState) end)
    RepopulateMenuElements()
    self:RecalculateSize()

    function DropdownInstance:Set(val)
        self.Value = val; SelectedText.Text = val
        for _, otherOpt in ipairs(OptionsFrame:GetChildren()) do if otherOpt:IsA("TextButton") then local lbl = otherOpt:FindFirstChildOfClass("TextLabel") if lbl then lbl.TextColor3 = (lbl.Text == val) and Theme.Accent_Color or Theme.Text_Secondary end end end
        task.spawn(self.Callback, val)
    end
    return DropdownInstance
end


if getgenv()._fov_circle_instance then pcall(function() getgenv()._fov_circle_instance:Remove() end) end
local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 32
fov_circle.Radius = NeverloseConfig.Rage.Main.FieldOfView
fov_circle.Filled = false
fov_circle.Transparency = 0.5
fov_circle.Color = Theme.Accent_Color
getgenv()._fov_circle_instance = fov_circle

RunService.RenderStepped:Connect(function()
    if fov_circle then
        local is_visible = NeverloseConfig.GlobalEnabled and NeverloseConfig.Visuals.ESP.FovVisible and NeverloseConfig.Rage.Main.SilentAim
        fov_circle.Visible = is_visible
        if is_visible then
            fov_circle.Radius = NeverloseConfig.Rage.Main.FieldOfView
            fov_circle.Position = Vector2_new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        end
    end
end)

local function isEnemy(player)
    return player.Team ~= LocalPlayer.Team
end

local function GetClosestPlayer()
    if not NeverloseConfig.GlobalEnabled or not NeverloseConfig.Rage.Main.SilentAim then return nil end
    local Closest, Distance = nil, NeverloseConfig.Rage.Main.FieldOfView
    local MousePos = Vector2_new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local myChar = LocalPlayer.Character
    local myRoot = myChar and FindFirstChild(myChar, "HumanoidRootPart")
    
    for _, Player in next, GetPlayers(Players) do
        if Player ~= LocalPlayer and isEnemy(Player) then
            local Character = Player.Character
            local TargetPart = Character and FindFirstChild(Character, NeverloseConfig.Rage.Main.AimPart)
            local Humanoid = Character and FindFirstChild(Character, "Humanoid")
            
            if TargetPart and (Humanoid and Humanoid.Health > 0) then
                if myRoot and (myRoot.Position - TargetPart.Position).Magnitude > NeverloseConfig.Rage.Main.MaxDistance then continue end
                local Position, IsVisible = WorldToScreenPoint(Camera, TargetPart.Position)
                if IsVisible then
                    local _Distance = (MousePos - Vector2_new(Position.X, Position.Y)).Magnitude
                    if _Distance <= Distance then
                        Closest = TargetPart
                        Distance = _Distance
                    end
                end
            end
        end
    end
    return Closest
end


RunService.PostSimulation:Connect(function()
    if NeverloseConfig.GlobalEnabled and NeverloseConfig.Rage.Main.Triggerbot then
        local unitRay = Camera:ViewportPointToRay(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
        
        internal_raycast = true
        local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * NeverloseConfig.Rage.Main.MaxDistance, raycastParams)
        internal_raycast = false
        
        if result and result.Instance then
            local model = result.Instance:FindFirstAncestorOfClass("Model")
            if model then
                local player = Players:GetPlayerFromCharacter(model)
                if player and player ~= LocalPlayer and isEnemy(player) then
                    local cache = player_drawings[player]
                    if cache and cache.humanoid and cache.humanoid.Health > 0 then
                        VirtualUser:CaptureController()
                        VirtualUser:Button1Down(Vector2_new(0, 0))
                        task.wait(0.01)
                        VirtualUser:Button1Up(Vector2_new(0, 0))
                    end
                end
            end
        end
    end
end)


RunService.RenderStepped:Connect(function()
    if NeverloseConfig.GlobalEnabled and NeverloseConfig.Rage.Other.ThirdPerson and LocalPlayer.Character then
        LocalPlayer.CameraMode = Enum.CameraMode.Classic
        LocalPlayer.CameraMaxZoomDistance = NeverloseConfig.Rage.Other.TpDistance
        LocalPlayer.CameraMinZoomDistance = NeverloseConfig.Rage.Other.TpDistance
    end
end)


local function clearChams(character)
    if character then local old = character:FindFirstChild("ImGuiChams") if old then pcall(function() old:Destroy() end) end end
end

local function setupCharacterCache(player, character)
    if not character then return end
    local cache = player_drawings[player]
    if not cache then return end
    clearChams(character)
    cache.character = character
    cache.humanoid = character:WaitForChild("Humanoid", 5)
    cache.Head = character:WaitForChild("Head", 5)
    cache.HumanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
    if cache.humanoid then
        local isR15 = cache.humanoid.RigType == Enum.HumanoidRigType.R15
        for _, conn in pairs(SkeletonConnections[isR15 and "R15" or "R6"]) do
            cache[conn[1]] = character:FindFirstChild(conn[1])
            cache[conn[2]] = character:FindFirstChild(conn[2])
        end
    end
    if NeverloseConfig.Visuals.ESP.Chams and isEnemy(player) then
        local chams = Instance.new("Highlight")
        chams.Name = "ImGuiChams"
        chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        chams.Parent = character
        cache.chamsInstance = chams
    end
end

local function createDrawingObjects(player)
    local box = Drawing.new("Square"); box.Visible = false; box.Filled = false
    local hpbar = Drawing.new("Line"); hpbar.Visible = false
    local name = Drawing.new("Text"); name.Visible = false; name.Color = Color3_fromRGB(240, 240, 240)
    name.Size = 13; name.Center = true; name.Outline = true; name.OutlineColor = Color3_fromRGB(10, 10, 10)
    local bones = {}
    for i = 1, 15 do local line = Drawing.new("Line"); line.Visible = false; table_insert(bones, line) end
    player_drawings[player] = { box = box, hpbar = hpbar, name = name, bones = bones, last_thickness = -1, last_transparency = -1 }
    if player.Character then setupCharacterCache(player, player.Character) end
    player.CharacterAdded:Connect(function(char) setupCharacterCache(player, char) end)
end

local function removeDrawingObjects(player)
    local cache = player_drawings[player]
    if cache then
        pcall(function()
            cache.box:Remove(); cache.hpbar:Remove(); cache.name:Remove()
            for i = 1, #cache.bones do cache.bones[i]:Remove() end
            clearChams(cache.character)
        end)
        player_drawings[player] = nil
    end
end

RunService.RenderStepped:Connect(function()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local thickness = NeverloseConfig.Visuals.ESP.EspThickness
    local trans = NeverloseConfig.Visuals.ESP.EspTransparency
    local espEnabled = NeverloseConfig.GlobalEnabled and NeverloseConfig.Visuals.ESP.Players

    for player, cache in pairs(player_drawings) do
        local character = cache.character
        local root = cache.HumanoidRootPart
        local head = cache.Head
        local humanoid = cache.humanoid

        if espEnabled and isEnemy(player) and character and root and head and humanoid and humanoid.Health > 0 then
            local inRange = true
            if myRoot and (myRoot.Position - root.Position).Magnitude > NeverloseConfig.Rage.Main.MaxDistance then inRange = false end
            
            if NeverloseConfig.Visuals.ESP.Chams then
                local chams = cache.chamsInstance
                if not chams or chams.Parent ~= character then setupCharacterCache(player, character); chams = cache.chamsInstance end
                if chams and inRange then
                    chams.Enabled = true; chams.FillColor = NeverloseConfig.Visuals.ESP.ChamsFillColor
                    chams.FillTransparency = NeverloseConfig.Visuals.ESP.ChamsFillTrans; chams.OutlineColor = player.TeamColor.Color
                elseif chams then chams.Enabled = false end
            elseif cache.chamsInstance then cache.chamsInstance.Enabled = false end

            if not inRange then
                cache.box.Visible = false; cache.hpbar.Visible = false; cache.name.Visible = false
                for i = 1, #cache.bones do cache.bones[i].Visible = false end; continue
            end

            local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                if cache.last_thickness ~= thickness or cache.last_transparency ~= trans then
                    cache.box.Thickness = thickness; cache.box.Transparency = trans
                    cache.hpbar.Thickness = thickness + 0.5; cache.hpbar.Transparency = trans
                    cache.name.Transparency = trans
                    for i = 1, #cache.bones do cache.bones[i].Thickness = thickness; cache.bones[i].Transparency = trans end
                    cache.last_thickness, cache.last_transparency = thickness, trans
                end

                if NeverloseConfig.Visuals.ESP.Skeletons then
                    local connections = SkeletonConnections[humanoid.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"]
                    
                    for idx, conn in ipairs(connections) do
                        local partA, partB = cache[conn[1]], cache[conn[2]]
                        local lineObj = cache.bones[idx]
                        if partA and partB and lineObj then
                            local pA, sA = Camera:WorldToViewportPoint(partA.Position)
                            local pB, sB = Camera:WorldToViewportPoint(partB.Position)
                            if sA and sB then
                                lineObj.From = Vector2_new(pA.X, pA.Y); lineObj.To = Vector2_new(pB.X, pB.Y)
                                lineObj.Color = player.TeamColor.Color; lineObj.Visible = true
                            else lineObj.Visible = false end
                        end
                    end
                else for i = 1, #cache.bones do cache.bones[i].Visible = false end end

                local headPos = Camera:WorldToViewportPoint(head.Position + HeadOff)
                local legPos = Camera:WorldToViewportPoint(root.Position - LegOff)
                local sizeX = 1000 / rootPos.Z
                local sizeY = headPos.Y - legPos.Y
                cache.box.Size = Vector2_new(sizeX, sizeY)
                cache.box.Position = Vector2_new(rootPos.X - sizeX / 2, rootPos.Y - sizeY / 2)
                cache.box.Color = player.TeamColor.Color
                local hp = humanoid.Health / humanoid.MaxHealth
                cache.hpbar.From = Vector2_new(cache.box.Position.X - 6, cache.box.Position.Y + sizeY * (1 - hp))
                cache.hpbar.To = Vector2_new(cache.box.Position.X - 6, cache.box.Position.Y + sizeY)
                cache.hpbar.Color = Color3_fromHSV(hp * 0.35, 0.9, 0.85)
                cache.name.Position = Vector2_new(cache.box.Position.X + sizeX / 2, cache.box.Position.Y - 15)
                cache.name.Text = player.Name
                cache.box.Visible = NeverloseConfig.Visuals.ESP.Boxes
                cache.hpbar.Visible = NeverloseConfig.Visuals.ESP.HealthBar
                cache.name.Visible = NeverloseConfig.Visuals.ESP.Names
                continue
            end
        end
        cache.box.Visible = false; cache.hpbar.Visible = false; cache.name.Visible = false
        for i = 1, #cache.bones do cache.bones[i].Visible = false end
    end
end)


local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    if is_intercepting or internal_raycast then return oldNamecall(...) end

    if Arguments[1] == workspace and Method == "Raycast" then
        if typeof(Arguments[#Arguments]) ~= "RaycastParams" then return oldNamecall(...) end
        if not NeverloseConfig.GlobalEnabled or not NeverloseConfig.Rage.Main.SilentAim then return oldNamecall(...) end

        if NeverloseConfig.Rage.Main.HitChance < 100 then
            if math.random(1, 100) > NeverloseConfig.Rage.Main.HitChance then return oldNamecall(...) end
        end

        is_intercepting = true
        local HitPart = GetClosestPlayer()
        is_intercepting = false
        if HitPart then
            Arguments[3] = (HitPart.Position - Arguments[2]).Unit * (Arguments[2] - HitPart.Position).Magnitude
            return oldNamecall(unpack(Arguments))
        end
    end
    return oldNamecall(...)
end)


task.spawn(function() PlayCoreInjectionIntro() end)
task.wait(1.8)

local Window = Library:CreateWindow({
    Title = "CConTop", SubTitle = "Roblox Pro", User = LocalPlayer.Name, Subscription = "Lifetime"
})


RegSystem:Initialize(Window.BaseGui, function()
    
    NeverloseConfig.GlobalEnabled = true
    Window.MainFrame.Visible = true
end)




local RageTab = Window:CreateTab({ Name = "Rage" })

local MainSection = RageTab:CreateSection({ Name = "MAIN", Side = "Left" })
MainSection:AddToggle({
    Name = "Enabled (Silent Aim)", Default = NeverloseConfig.Rage.Main.SilentAim,
    Callback = function(state) NeverloseConfig.Rage.Main.SilentAim = state end
})
MainSection:AddDropdown({
    Name = "Target Selection", Options = { "FOV", "Distance", "Highest Damage" }, Default = NeverloseConfig.Rage.Main.TargetSelection,
    Callback = function(selected) NeverloseConfig.Rage.Main.TargetSelection = selected end
})
MainSection:AddSlider({
    Name = "Field of View", Min = 0, Max = 500, Default = NeverloseConfig.Rage.Main.FieldOfView, Decimals = 0, Suffix = "°",
    Callback = function(value) NeverloseConfig.Rage.Main.FieldOfView = value end
})

local SelectionSection = RageTab:CreateSection({ Name = "SELECTION", Side = "Left" })
SelectionSection:AddDropdown({
    Name = "Hitboxes Target", Options = { "Head", "HumanoidRootPart" }, Default = NeverloseConfig.Rage.Main.AimPart,
    Callback = function(selected) NeverloseConfig.Rage.Main.AimPart = selected end
})
SelectionSection:AddSlider({
    Name = "Hit Chance", Min = 10, Max = 100, Default = NeverloseConfig.Rage.Main.HitChance, Decimals = 0, Suffix = "%",
    Callback = function(value) NeverloseConfig.Rage.Main.HitChance = value end
})
SelectionSection:AddSlider({
    Name = "Max Lock Distance", Min = 100, Max = 3000, Default = NeverloseConfig.Rage.Main.MaxDistance, Decimals = 0, Suffix = " studs",
    Callback = function(value) NeverloseConfig.Rage.Main.MaxDistance = value end
})

local OtherSection = RageTab:CreateSection({ Name = "OTHER", Side = "Right" })
OtherSection:AddToggle({
    Name = "Triggerbot (Auto Fire)", Default = NeverloseConfig.Rage.Main.Triggerbot,
    Callback = function(state) NeverloseConfig.Rage.Main.Triggerbot = state end
})
OtherSection:AddToggle({
    Name = "Force Third Person View", Default = NeverloseConfig.Rage.Other.ThirdPerson,
    Callback = function(state) NeverloseConfig.Rage.Other.ThirdPerson = state end
})
OtherSection:AddSlider({
    Name = "Third Person Distance", Min = 5, Max = 30, Default = NeverloseConfig.Rage.Other.TpDistance, Decimals = 0, Suffix = " studs",
    Callback = function(value) NeverloseConfig.Rage.Other.TpDistance = value end
})




local LegitTab = Window:CreateTab({ Name = "Legit" })
local LegitMainSection = LegitTab:CreateSection({ Name = "AIMBOT CONTROL", Side = "Left" })
LegitMainSection:AddToggle({ Name = "Legit Aim Enabled", Default = false, Callback = function() end })
LegitMainSection:AddSlider({ Name = "Smoothing Factor", Min = 1, Max = 30, Default = 10, Decimals = 0, Callback = function() end })




local VisualsTab = Window:CreateTab({ Name = "Visuals" })
local EspSection = VisualsTab:CreateSection({ Name = "PLAYER ESP", Side = "Left" })
EspSection:AddToggle({
    Name = "Show Enemy Players Master", Default = NeverloseConfig.Visuals.ESP.Players,
    Callback = function(state) NeverloseConfig.Visuals.ESP.Players = state end
})
EspSection:AddToggle({
    Name = "Bounding Boxes (2D Box)", Default = NeverloseConfig.Visuals.ESP.Boxes,
    Callback = function(state) NeverloseConfig.Visuals.ESP.Boxes = state end
})
EspSection:AddToggle({
    Name = "Bone Skeleton (Joints Connect)", Default = NeverloseConfig.Visuals.ESP.Skeletons,
    Callback = function(state) NeverloseConfig.Visuals.ESP.Skeletons = state end
})
EspSection:AddToggle({
    Name = "Show Player Names Text", Default = NeverloseConfig.Visuals.ESP.Names,
    Callback = function(state) NeverloseConfig.Visuals.ESP.Names = state end
})
EspSection:AddToggle({
    Name = "Show Dynamic HealthBar", Default = NeverloseConfig.Visuals.ESP.HealthBar,
    Callback = function(state) NeverloseConfig.Visuals.ESP.HealthBar = state end
})

local WorldSection = VisualsTab:CreateSection({ Name = "RENDER SETTINGS", Side = "Right" })
WorldSection:AddToggle({
    Name = "Wall-Hack Thermal Chams", Default = NeverloseConfig.Visuals.ESP.Chams,
    Callback = function(state) NeverloseConfig.Visuals.ESP.Chams = state end
})
WorldSection:AddToggle({
    Name = "Draw Field-of-View Circle", Default = NeverloseConfig.Visuals.ESP.FovVisible,
    Callback = function(state) NeverloseConfig.Visuals.ESP.FovVisible = state end
})
WorldSection:AddSlider({
    Name = "ESP Line Thickness", Min = 1, Max = 5, Default = NeverloseConfig.Visuals.ESP.EspThickness, Decimals = 0, Suffix = " px",
    Callback = function(value) NeverloseConfig.Visuals.ESP.EspThickness = value end
})
WorldSection:AddSlider({
    Name = "ESP Global Opacity", Min = 0.1, Max = 1, Default = NeverloseConfig.Visuals.ESP.EspTransparency, Decimals = 1, Suffix = "",
    Callback = function(value) NeverloseConfig.Visuals.ESP.EspTransparency = value end
})




local InventoryTab = Window:CreateTab({ Name = "Inventory" })
local SkinSection = InventoryTab:CreateSection({ Name = "SKIN CHANGER", Side = "Left" })
SkinSection:AddToggle({ Name = "Inventory Override", Default = false, Callback = function() end })




local MiscTab = Window:CreateTab({ Name = "Miscellaneous" })
local MoveSection = MiscTab:CreateSection({ Name = "MOVEMENT ENGINE", Side = "Left" })
MoveSection:AddToggle({ Name = "Auto BunnyHop", Default = false, Callback = function() end })
MoveSection:AddToggle({ Name = "Auto Strafe", Default = false, Callback = function() end })

local NetSection = MiscTab:CreateSection({ Name = "NETWORK PERFORMANCE", Side = "Right" })
NetSection:AddToggle({ Name = "Cloudflare HKG Nodes Optimization", Default = false, Callback = function() end })
NetSection:AddToggle({ Name = "Latency Fast-Route Reduction", Default = false, Callback = function() end })


Players.PlayerAdded:Connect(createDrawingObjects)
Players.PlayerRemoving:Connect(removeDrawingObjects)
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then createDrawingObjects(p) end end

print("[CCONTOP GLOBAL LOG]: Mono Interceptor Engine coupled with Neverlose UI seamlessly.")




local ToggleKey = Enum.KeyCode.Insert

local UI_Toggle_Connection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessedEvent)
    
    if gameProcessedEvent then return end
    
    if input.KeyCode == ToggleKey then
        
        local RootGui = game:GetService("CoreGui"):FindFirstChild("KuduUi_Root") 
            or (game:GetService("Players").LocalPlayer and game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") and game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("KuduUi_Root"))
            
        if RootGui then
            
            local MainFrame = RootGui:FindFirstChild("MainFrame")
            local RegWindow = RootGui:FindFirstChild("RegistrationPanel")
            
            
            if getgenv().CurrentNeverloseConfig and getgenv().CurrentNeverloseConfig.GlobalEnabled then
                if MainFrame then
                    MainFrame.Visible = not MainFrame.Visible
                end
            else
                if RegWindow then
                    RegWindow.Visible = not RegWindow.Visible
                end
            end
        end
    end
end)




return
