--hi guy this script will help you to win
-- [[ 1. 全局可自定义配置核心架构表 ]]
local esp_settings = {
    enabled = true,          -- 透视总开关
    box_visible = true,      -- 2D方框显示
    name_visible = true,     -- 玩家名称显示
    hp_visible = true,       -- 动态血条显示
    esp_thickness = 1,       -- 线条粗细 (1 - 5)
    esp_transparency = 0.8,  -- 渲染全局透明度 (0.1 - 1.0)
    
    skeleton_visible = true, -- 骨骼透视开关
    chams_enabled = true,    -- 墙后发光热成像透视
    chams_fill_color = Color3.fromRGB(255, 0, 0), -- 内部填充色
    chams_fill_trans = 0.5,  -- 填充透明度
    
    silent_aim = true,       -- 静默自瞄开关
    hit_chance = 100,        -- 子弹追踪概率控制百分比 (10 - 100) -> 新增功能
    team_check = true,       -- 过滤队友/阵营检查开关
    aim_fov = 150,           -- 自瞄范围半径 (10 - 500)
    fov_visible = true,      -- FOV物理渲染圈可见性
    aim_part = "Head",       -- 锁敌部位 ("Head" 或 "HumanoidRootPart")
    max_distance = 1000,     -- 最大裁剪距离 (100 - 3000)
    
    triggerbot = false,      -- 自动扳机
    thirdperson = false,     -- 强制第三人称视角
    tp_distance = 10,        -- 第三人称镜头拉伸距离
    toggle_key = Enum.KeyCode.Insert -- 一键隐藏/呼出菜单快捷键
}

-- [[ 2. IMGUI 动画UI框架内核引擎段 ]]
local ImGuiAnimated = {}
ImGuiAnimated.__index = ImGuiAnimated

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")
local Camera = workspace.CurrentCamera
local VirtualUser = game:GetService("VirtualUser")
local lplr = Players.LocalPlayer
local Mouse = lplr:GetMouse()

local IM_THEME = {
    WindowBG = Color3.fromRGB(21, 22, 23),       -- 经典暗灰底
    HeaderBG = Color3.fromRGB(39, 73, 114),      -- 工业顶栏深蓝
    HeaderHover = Color3.fromRGB(49, 93, 144),   -- 顶栏渐变悬停蓝
    WidgetBG = Color3.fromRGB(33, 54, 79),       -- 激活态/拖拽条亮蓝
    WidgetIdle = Color3.fromRGB(26, 36, 46),     -- 未激活控件暗沉底色
    WidgetHover = Color3.fromRGB(43, 72, 104),    -- 控件悬停底色
    Border = Color3.fromRGB(55, 60, 65),         -- 细部像素隔离框线
    Selection = Color3.fromRGB(60, 131, 217),    -- 拖拽条内部数字下面的高亮蓝色选块
    TextMain = Color3.fromRGB(255, 255, 255),    -- 纯白代码文字
    TextLabel = Color3.fromRGB(180, 180, 180),   -- 右侧说明灰字
    Font = Enum.Font.RobotoMono,                 -- 严格等宽位图流字体
    FontSize = 13,
    ItemSpacing = 4,
    DragInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    WidgetInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    CloseInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
}

local function ApplyEngineStyles(instance: GuiObject, radiusPixel: number): UIStroke
    instance.BorderSizePixel = 0
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = IM_THEME.Border
    stroke.Transparency = 0.1
    stroke.Parent = instance
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radiusPixel)
    corner.Parent = instance
    return stroke
end

-- ====== 🎬 【新增功能一：CCONTOP 注入动画视效引擎】 ======
local function PlayCoreInjectionIntro()
    local IntroGui = Instance.new("ScreenGui")
    IntroGui.Name = "CCONTOP_Splash_Network"
    IntroGui.ResetOnSpawn = false
    IntroGui.IgnoreGuiInset = true
    IntroGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local success, _ = pcall(function() IntroGui.Parent = CoreGui:FindFirstChild("RobloxGui") or CoreGui end)
    if not success then IntroGui.Parent = lplr:WaitForChild("PlayerGui") end
    
    local Backdrop = Instance.new("Frame")
    Backdrop.Size = UDim2.new(1, 0, 1, 0)
    Backdrop.BackgroundColor3 = Color3.fromRGB(10, 11, 13)
    Backdrop.BackgroundTransparency = 1
    Backdrop.Parent = IntroGui
    
    local AccentLine = Instance.new("Frame")
    AccentLine.Size = UDim2.new(0, 0, 0, 2)
    AccentLine.Position = UDim2.new(0.5, 0, 0.5, 30)
    AccentLine.BackgroundColor3 = IM_THEME.Selection
    AccentLine.BorderSizePixel = 0
    AccentLine.Parent = Backdrop
    
    local TerminalText = Instance.new("TextLabel")
    TerminalText.Size = UDim2.new(1, 0, 0, 40)
    TerminalText.Position = UDim2.new(0, 0, 0.5, -20)
    TerminalText.BackgroundTransparency = 1
    TerminalText.Text = ""
    TerminalText.TextColor3 = IM_THEME.TextMain
    TerminalText.Font = Enum.Font.RobotoMono
    TerminalText.TextSize = 26
    TerminalText.TextTransparency = 1
    TerminalText.Parent = Backdrop
    
    -- 1. 淡入暗流底色背景
    TweenService:Create(Backdrop, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {BackgroundTransparency = 0.15}):Play()
    task.wait(0.4)
    
    -- 2. 扫描线延展动画
    TerminalText.TextTransparency = 0
    TweenService:Create(AccentLine, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, 360, 0, 2), Position = UDim2.new(0.5, -180, 0.5, 30)}):Play()
    
    -- 3. CCONTOP FOR CHEAT 高速打字机矩阵流输出
    local rawLog = "CCONTOP FOR CHEAT"
    for length = 1, #rawLog do
        TerminalText.Text = string.sub(rawLog, 1, length) .. "_"
        local frequencySound = math.random() * 0.02 + 0.03
        task.wait(frequencySound)
    end
    TerminalText.Text = rawLog
    
    -- 闪烁等待增强黑客质感
    for blink = 1, 3 do
        AccentLine.Visible = false; task.wait(0.12)
        AccentLine.Visible = true; task.wait(0.12)
    end
    task.wait(0.4)
    
    -- 4. 整体原子级渐隐销毁
    TweenService:Create(TerminalText, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {TextTransparency = 1}):Play()
    TweenService:Create(AccentLine, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 0, 0, 2), Position = UDim2.new(0.5, 0, 0.5, 30)}):Play()
    local outro = TweenService:Create(Backdrop, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
    outro:Play()
    outro.Completed:Wait()
    
    IntroGui:Destroy()
end

function ImGuiAnimated.new()
    local self = setmetatable({}, ImGuiAnimated)
    if CoreGui:FindFirstChild("ImGui_Animated_Matrix") then 
        CoreGui:FindFirstChild("ImGui_Animated_Matrix"):Destroy() 
    end
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ImGui_Animated_Matrix"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local success, _ = pcall(function() screenGui.Parent = CoreGui:FindFirstChild("RobloxGui") or CoreGui end)
    if not success then screenGui.Parent = lplr:WaitForChild("PlayerGui") end
    self.ScreenGui = screenGui
    return self
end

function ImGuiAnimated:CreateWindow(titleText: string, size: UDim2, pos: UDim2): (Frame, ScrollingFrame)
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainWindow"
    MainFrame.Size = size
    MainFrame.Position = pos
    MainFrame.BackgroundColor3 = IM_THEME.WindowBG
    ApplyEngineStyles(MainFrame, 4)
    MainFrame.Active = true
    MainFrame.Parent = self.ScreenGui
    
    local Header = Instance.new("Frame")
    Header.Name = "HeaderBar"
    Header.Size = UDim2.new(1, 0, 0, 24)
    Header.BackgroundColor3 = IM_THEME.HeaderBG
    Header.Parent = MainFrame
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 4)
    HeaderCorner.Parent = Header
    local BottomMask = Instance.new("Frame")
    BottomMask.Size = UDim2.new(1, 0, 0, 4)
    BottomMask.Position = UDim2.new(0, 0, 1, -4)
    BottomMask.BackgroundColor3 = IM_THEME.HeaderBG
    BottomMask.BorderSizePixel = 0
    BottomMask.Parent = Header
    
    local ArrowBtn = Instance.new("TextButton")
    ArrowBtn.Size = UDim2.new(0, 22, 1, 0)
    ArrowBtn.Position = UDim2.new(0, 4, 0, 0)
    ArrowBtn.BackgroundTransparency = 1
    ArrowBtn.Text = "▼"
    ArrowBtn.TextColor3 = IM_THEME.TextMain
    ArrowBtn.Font = Enum.Font.SourceSansBold
    ArrowBtn.TextSize = 11
    ArrowBtn.Parent = Header
    
    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -110, 1, 0)
    TitleLabel.Position = UDim2.new(0, 26, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = titleText
    TitleLabel.TextColor3 = IM_THEME.TextMain
    TitleLabel.Font = IM_THEME.Font
    TitleLabel.TextSize = IM_THEME.FontSize
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Header

    local FpsLabel = Instance.new("TextLabel")
    FpsLabel.Size = UDim2.new(0, 55, 1, 0)
    FpsLabel.Position = UDim2.new(1, -80, 0, 0)
    FpsLabel.BackgroundTransparency = 1
    FpsLabel.Text = "60.0 FPS"
    FpsLabel.TextColor3 = Color3.fromRGB(0, 180, 100)
    FpsLabel.Font = IM_THEME.Font
    FpsLabel.TextSize = 11
    FpsLabel.TextXAlignment = Enum.TextXAlignment.Right
    FpsLabel.Parent = Header
    
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 22, 1, 0)
    CloseBtn.Position = UDim2.new(1, -24, 0, 0)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = IM_THEME.TextMain
    CloseBtn.Font = Enum.Font.SourceSans
    CloseBtn.TextSize = 18
    CloseBtn.Parent = Header
    
    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Name = "Container"
    ContentFrame.Size = UDim2.new(1, -8, 1, -32)
    ContentFrame.Position = UDim2.new(0, 4, 0, 28)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ScrollBarThickness = 3
    ContentFrame.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 70)
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentFrame.Parent = MainFrame
    
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0, IM_THEME.ItemSpacing)
    ListLayout.Parent = ContentFrame
    
    ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ContentFrame.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 6)
    end)
    
    self:_attachAnimatedDrag(Header, MainFrame)
    
    Header.MouseEnter:Connect(function()
        TweenService:Create(Header, IM_THEME.WidgetInfo, {BackgroundColor3 = IM_THEME.HeaderHover}):Play()
        TweenService:Create(BottomMask, IM_THEME.WidgetInfo, {BackgroundColor3 = IM_THEME.HeaderHover}):Play()
    end)
    Header.MouseLeave:Connect(function()
        TweenService:Create(Header, IM_THEME.WidgetInfo, {BackgroundColor3 = IM_THEME.HeaderBG}):Play()
        TweenService:Create(BottomMask, IM_THEME.WidgetInfo, {BackgroundColor3 = IM_THEME.HeaderBG}):Play()
    end)
    
    local collapsed = false
    ArrowBtn.MouseButton1Click:Connect(function()
        collapsed = not collapsed
        if collapsed then
            ArrowBtn.Text = "▶"
            TweenService:Create(MainFrame, IM_THEME.DragInfo, {Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 24)}):Play()
            ContentFrame.Visible = false
        else
            ArrowBtn.Text = "▼"
            TweenService:Create(MainFrame, IM_THEME.DragInfo, {Size = size}):Play()
            ContentFrame.Visible = true
        end
    end)
    
    task.spawn(function()
        local lastTime, frames = os.clock(), 0
        while MainFrame and MainFrame.Parent do
            frames = frames + 1
            local now = os.clock()
            if now - lastTime >= 0.5 then
                local fps = math.floor(frames / (now - lastTime))
                FpsLabel.Text = tostring(fps) .. ".0 FPS"
                FpsLabel.TextColor3 = fps < 45 and Color3.fromRGB(220, 80, 80) or Color3.fromRGB(0, 180, 100)
                frames, lastTime = 0, now
            end
            RunService.RenderStepped:Wait()
        end
    end)

    return MainFrame, ContentFrame
end

function ImGuiAnimated:CreateSectionLabel(parent: ScrollingFrame, text: string)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 20)
    Row.BackgroundTransparency = 1
    Row.Parent = parent
    local Label = Instance.new("TextLabel")
    local padding = parent.ScrollBarThickness + 4
    Label.Size = UDim2.new(1, -padding, 1, 0)
    Label.Position = UDim2.new(0, 4, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Color3.fromRGB(0, 170, 255)
    Label.Font = IM_THEME.Font
    Label.TextSize = IM_THEME.FontSize
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Row
end

function ImGuiAnimated:CreateCheckbox(parent: ScrollingFrame, text: string, default: boolean, callback: (boolean) -> ())
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 22)
    Row.BackgroundTransparency = 1
    Row.Parent = parent
    
    local Box = Instance.new("TextButton")
    Box.Size = UDim2.new(0, 14, 0, 14)
    Box.Position = UDim2.new(0, 4, 0.5, -7)
    Box.BackgroundColor3 = default and IM_THEME.WidgetBG or IM_THEME.WidgetIdle
    Box.Text = default and "✓" or ""
    Box.TextColor3 = IM_THEME.TextMain
    Box.Font = Enum.Font.Code
    Box.TextSize = 12
    Box.AutoButtonColor = false
    ApplyEngineStyles(Box, 2)
    Box.Parent = Row
    
    local Label = Instance.new("TextButton")
    local padding = parent.ScrollBarThickness + 26
    Label.Size = UDim2.new(1, -padding, 1, 0)
    Label.Position = UDim2.new(0, 24, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = IM_THEME.TextMain
    Label.Font = IM_THEME.Font
    Label.TextSize = IM_THEME.FontSize
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.AutoButtonColor = false
    Label.Parent = Row
    
    local state = default
    local function click()
        state = not state
        callback(state)
        TweenService:Create(Box, IM_THEME.WidgetInfo, {BackgroundColor3 = state and IM_THEME.WidgetBG or IM_THEME.WidgetIdle}):Play()
        Box.Text = state and "✓" or ""
    end
    Box.MouseButton1Click:Connect(click)
    Label.MouseButton1Click:Connect(click)
    
    local function hover(isHovering)
        TweenService:Create(Label, IM_THEME.WidgetInfo, {TextColor3 = isHovering and Color3.fromRGB(255, 255, 255) or IM_THEME.TextMain}):Play()
        if not state then
            TweenService:Create(Box, IM_THEME.WidgetInfo, {BackgroundColor3 = isHovering and IM_THEME.WidgetHover or IM_THEME.WidgetIdle}):Play()
        end
    end
    Box.MouseEnter:Connect(function() hover(true) end)
    Box.MouseLeave:Connect(function() hover(false) end)
    Label.MouseEnter:Connect(function() hover(true) end)
    Label.MouseLeave:Connect(function() hover(false) end)
end

function ImGuiAnimated:CreateSlider(parent: ScrollingFrame, text: string, min: number, max: number, default: number, isFloat: boolean, callback: (number) -> ())
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 22)
    Row.BackgroundTransparency = 1
    Row.Parent = parent
    
    local Track = Instance.new("TextButton")
    Track.Size = UDim2.new(0, 115, 0, 16)
    Track.Position = UDim2.new(0, 4, 0.5, -8)
    Track.BackgroundColor3 = IM_THEME.WidgetIdle
    Track.Text = ""
    Track.AutoButtonColor = false
    ApplyEngineStyles(Track, 2)
    Track.Parent = Row
    
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = IM_THEME.WidgetBG
    Fill.BorderSizePixel = 0
    Fill.Parent = Track
    
    local ValLabel = Instance.new("TextLabel")
    ValLabel.Size = UDim2.new(1, 0, 1, 0)
    ValLabel.BackgroundTransparency = 1
    ValLabel.Text = string.format(isFloat and "%.2f" or "%d", default)
    ValLabel.TextColor3 = IM_THEME.TextMain
    ValLabel.Font = IM_THEME.Font
    ValLabel.TextSize = 11
    ValLabel.ZIndex = 3
    ValLabel.Parent = Track
    
    local Label = Instance.new("TextLabel")
    local padding = parent.ScrollBarThickness + 130
    Label.Size = UDim2.new(1, -padding, 1, 0)
    Label.Position = UDim2.new(0, 126, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = IM_THEME.TextLabel
    Label.Font = IM_THEME.Font
    Label.TextSize = IM_THEME.FontSize
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Row
    
    local dragging = false
    local function update(input)
        local ratio = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local raw = min + (max - min) * ratio
        local final = isFloat and tonumber(string.format("%.2f", raw)) or math.floor(raw)
        TweenService:Create(Fill, IM_THEME.WidgetInfo, {Size = UDim2.new(ratio, 0, 1, 0)}):Play()
        ValLabel.Text = string.format(isFloat and "%.2f" or "%d", final)
        callback(final)
    end
    
    Track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

function ImGuiAnimated:CreateSelector(parent: ScrollingFrame, text: string, options: table, default: string, callback: (string) -> ())
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 22)
    Row.BackgroundTransparency = 1
    Row.Parent = parent
    
    local Btn = Instance.new("TextButton")
    local currentIdx = table.find(options, default) or 1
    Btn.Size = UDim2.new(0, 115, 0, 16)
    Btn.Position = UDim2.new(0, 4, 0.5, -8)
    Btn.BackgroundColor3 = IM_THEME.WidgetIdle
    Btn.Text = tostring(options[currentIdx])
    Btn.TextColor3 = IM_THEME.TextMain
    Btn.Font = IM_THEME.Font
    Btn.TextSize = 11
    Btn.AutoButtonColor = false
    ApplyEngineStyles(Btn, 2)
    Btn.Parent = Row
    
    local Label = Instance.new("TextLabel")
    local padding = parent.ScrollBarThickness + 130
    Label.Size = UDim2.new(1, -padding, 1, 0)
    Label.Position = UDim2.new(0, 126, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = IM_THEME.TextLabel
    Label.Font = IM_THEME.Font
    Label.TextSize = IM_THEME.FontSize
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Row
    
    Btn.MouseEnter:Connect(function() TweenService:Create(Btn, IM_THEME.WidgetInfo, {BackgroundColor3 = IM_THEME.WidgetHover}):Play() end)
    Btn.MouseLeave:Connect(function() TweenService:Create(Btn, IM_THEME.WidgetInfo, {BackgroundColor3 = IM_THEME.WidgetIdle}):Play() end)
    
    Btn.MouseButton1Click:Connect(function()
        currentIdx = currentIdx % #options + 1
        local choice = options[currentIdx]
        Btn.Text = tostring(choice)
        callback(choice)
    end)
end

function ImGuiAnimated:CreateDestructButton(parent: ScrollingFrame, text: string, callback: () -> ())
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 26)
    Row.BackgroundTransparency = 1
    Row.Parent = parent
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -12, 0, 20)
    Btn.Position = UDim2.new(0, 4, 0, 3)
    Btn.BackgroundColor3 = Color3.fromRGB(130, 40, 40)
    Btn.Text = text
    Btn.TextColor3 = IM_THEME.TextMain
    Btn.Font = IM_THEME.Font
    Btn.TextSize = IM_THEME.FontSize
    Btn.AutoButtonColor = false
    local stroke = ApplyEngineStyles(Btn, 2)
    stroke.Color = Color3.fromRGB(160, 50, 50)
    Btn.Parent = Row
    
    Btn.MouseEnter:Connect(function() TweenService:Create(Btn, IM_THEME.WidgetInfo, {BackgroundColor3 = Color3.fromRGB(160, 50, 50)}):Play() end)
    Btn.MouseLeave:Connect(function() TweenService:Create(Btn, IM_THEME.WidgetInfo, {BackgroundColor3 = Color3.fromRGB(130, 40, 40)}):Play() end)
    Btn.MouseButton1Click:Connect(callback)
end

function ImGuiAnimated:_attachAnimatedDrag(trigger: GuiObject, windowFrame: Frame)
    local active = false
    local token: InputObject?
    local pivot: Vector3?
    local basePos: UDim2?
    trigger.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = true; pivot = input.Position; basePos = windowFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then active = false end end)
        end
    end)
    trigger.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then token = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == token and active then
            local offset = input.Position - (pivot :: Vector3)
            TweenService:Create(windowFrame, IM_THEME.DragInfo, {
                Position = UDim2.new((basePos :: UDim2).X.Scale, (basePos :: UDim2).X.Offset + offset.X, (basePos :: UDim2).Y.Scale, (basePos :: UDim2).Y.Offset + offset.Y)
            }):Play()
        end
    end)
end

-- [[ 3. 高频缓存、基础核心物理函数缓存段 ]]
local WorldToScreenPoint = Camera.WorldToScreenPoint
local GetPlayers = Players.GetPlayers
local FindFirstChild = game.FindFirstChild
local pairs, table_insert, table_find, math_clamp, math_floor, os_clock = pairs, table.insert, table.find, math.clamp, math.floor, os_clock
local Vector2_new, Vector3_new, Color3_fromRGB, Color3_fromHSV = Vector2.new, Vector3.new, Color3.fromRGB, Color3.fromHSV

local player_drawings = {}
local HeadOff = Vector3_new(0, 0.5, 0)
local LegOff = Vector3_new(0, 3, 0)

-- 全局内部高频标记变量
local internal_raycast = false
local is_intercepting = false

-- 随机数种子初始化
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

if getgenv()._fov_circle_instance then pcall(function() getgenv()._fov_circle_instance:Remove() end) end

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 32
fov_circle.Radius = esp_settings.aim_fov
fov_circle.Filled = false
fov_circle.Transparency = 0.5
fov_circle.Color = Color3_fromRGB(30, 90, 160)
getgenv()._fov_circle_instance = fov_circle

RunService.RenderStepped:Connect(function()
    if fov_circle then
        local is_visible = esp_settings.fov_visible and esp_settings.silent_aim and esp_settings.enabled
        fov_circle.Visible = is_visible
        if is_visible then
            fov_circle.Radius = esp_settings.aim_fov
            local viewportSize = Camera.ViewportSize
            fov_circle.Position = Vector2_new(viewportSize.X / 2, viewportSize.Y / 2)
        end
    end
end)

local function isEnemy(player)
    if not esp_settings.team_check then return true end
    return player.Team ~= lplr.Team
end

local function GetOnScreenPosition(V3)
    local Position, IsVisible = WorldToScreenPoint(Camera, V3)
    return Vector2_new(Position.X, Position.Y), IsVisible
end

local function GetDirection(Origin, Position)
    return (Position - Origin).Unit * (Origin - Position).Magnitude
end

local function GetMousePosition()
    return Vector2_new(Mouse.X, Mouse.Y)
end

local function GetClosestPlayer()
    if not esp_settings.enabled or not esp_settings.silent_aim then return nil end
    
    local Closest, Distance = nil, esp_settings.aim_fov
    local MousePos = GetMousePosition()
    local myChar = lplr.Character
    local myRoot = myChar and FindFirstChild(myChar, "HumanoidRootPart")
    
    for _, Player in next, GetPlayers(Players) do
        if Player ~= lplr and isEnemy(Player) then
            local Character = Player.Character
            local TargetPart = Character and FindFirstChild(Character, esp_settings.aim_part)
            local Humanoid = Character and FindFirstChild(Character, "Humanoid")
            
            if TargetPart and (Humanoid and Humanoid.Health > 0) then
                if myRoot and (myRoot.Position - TargetPart.Position).Magnitude > esp_settings.max_distance then 
                    continue 
                end
                
                local ScreenPos, IsVisible = GetOnScreenPosition(TargetPart.Position)
                if IsVisible then
                    local _Distance = (MousePos - ScreenPos).Magnitude
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

-- 自动扳机循环
RunService.PostSimulation:Connect(function()
    if esp_settings.enabled and esp_settings.triggerbot then
        local viewportSize = Camera.ViewportSize
        local unitRay = Camera:ViewportPointToRay(viewportSize.X / 2, viewportSize.Y / 2)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {lplr.Character}
        
        internal_raycast = true
        local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * esp_settings.max_distance, raycastParams)
        internal_raycast = false
        
        if result and result.Instance then
            local model = result.Instance:FindFirstAncestorOfClass("Model")
            if model then
                local player = Players:GetPlayerFromCharacter(model)
                if player and player ~= lplr and isEnemy(player) then
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

-- 第三人称视角
RunService.RenderStepped:Connect(function()
    if esp_settings.thirdperson and lplr.Character then
        lplr.CameraMode = Enum.CameraMode.Classic
        lplr.CameraMaxZoomDistance = esp_settings.tp_distance
        lplr.CameraMinZoomDistance = esp_settings.tp_distance
    end
end)

-- ====== 🎨 【渲染及外部透视缓存管理段】 ======
local function clearChams(character)
    if character then
        local oldChams = character:FindFirstChild("ImGuiChams")
        if oldChams then pcall(function() oldChams:Destroy() end) end
    end
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
    cache.UpperTorso = character:FindFirstChild("UpperTorso")
    cache.Torso = character:FindFirstChild("Torso")
    if cache.humanoid then
        local isR15 = cache.humanoid.RigType == Enum.HumanoidRigType.R15
        local currentBones = SkeletonConnections[isR15 and "R15" or "R6"]
        for _, conn in pairs(currentBones) do
            cache[conn[1]] = character:FindFirstChild(conn[1])
            cache[conn[2]] = character:FindFirstChild(conn[2])
        end
    end
    if esp_settings.chams_enabled and isEnemy(player) then
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
    player_drawings[player] = {
        box = box, hpbar = hpbar, name = name, bones = bones, last_thickness = -1, last_transparency = -1,
        character = nil, humanoid = nil, Head = nil, HumanoidRootPart = nil, chamsInstance = nil
    }
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

-- 高速缓存渲染线框
RunService.RenderStepped:Connect(function()
    if getgenv()._scriptUnloaded then return end
    local myChar = lplr.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local thickness = esp_settings.esp_thickness
    local trans = esp_settings.esp_transparency
    local espEnabled = esp_settings.enabled

    for player, cache in pairs(player_drawings) do
        local character = cache.character
        local root = cache.HumanoidRootPart
        local head = cache.Head
        local humanoid = cache.humanoid

        if espEnabled and isEnemy(player) and character and root and head and humanoid and humanoid.Health > 0 then
            local inRange = true
            if myRoot and (myRoot.Position - root.Position).Magnitude > esp_settings.max_distance then
                inRange = false
            end
            
            if esp_settings.chams_enabled then
                local chams = cache.chamsInstance
                if not chams or chams.Parent ~= character then
                    clearChams(character)
                    chams = Instance.new("Highlight")
                    chams.Name = "ImGuiChams"
                    chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    chams.Parent = character
                    cache.chamsInstance = chams
                end
                if inRange then
                    chams.Enabled = true
                    chams.FillColor = esp_settings.chams_fill_color
                    chams.FillTransparency = esp_settings.chams_fill_trans
                    chams.OutlineColor = player.TeamColor.Color
                else
                    chams.Enabled = false
                end
            else
                if cache.chamsInstance then cache.chamsInstance.Enabled = false end
            end

            if not inRange then
                cache.box.Visible = false; cache.hpbar.Visible = false; cache.name.Visible = false
                for i = 1, #cache.bones do cache.bones[i].Visible = false end
                continue
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
                
                if esp_settings.skeleton_visible then
                    local boneType = humanoid.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
                    local connections = SkeletonConnections[boneType]
                    
                    local viewportCoordsCache = {}
                    for _, conn in pairs(connections) do
                        local p1, p2 = conn[1], conn[2]
                        if not viewportCoordsCache[p1] then
                            local part = cache[p1]
                            if part then
                                local pPos, sOk = Camera:WorldToViewportPoint(part.Position)
                                viewportCoordsCache[p1] = {Pos = pPos, OnScreen = sOk}
                            end
                        end
                        if not viewportCoordsCache[p2] then
                            local part = cache[p2]
                            if part then
                                local pPos, sOk = Camera:WorldToViewportPoint(part.Position)
                                viewportCoordsCache[p2] = {Pos = pPos, OnScreen = sOk}
                            end
                        end
                    end
                    
                    for idx = 1, #connections do
                        local connection = connections[idx]
                        local coordA = viewportCoordsCache[connection[1]]
                        local coordB = viewportCoordsCache[connection[2]]
                        local lineObj = cache.bones[idx]
                        
                        if coordA and coordB and coordA.OnScreen and coordB.OnScreen and lineObj then
                            lineObj.From = Vector2_new(coordA.Pos.X, coordA.Pos.Y)
                            lineObj.To = Vector2_new(coordB.Pos.X, coordB.Pos.Y)
                            lineObj.Color = player.TeamColor.Color
                            lineObj.Visible = true
                        else
                            if lineObj then lineObj.Visible = false end
                        end
                    end
                    for idx = #connections + 1, 15 do cache.bones[idx].Visible = false end
                else
                    for i = 1, #cache.bones do cache.bones[i].Visible = false end
                end

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
                cache.box.Visible = esp_settings.box_visible
                cache.hpbar.Visible = esp_settings.hp_visible
                cache.name.Visible = esp_settings.name_visible
                continue
            end
        end
        cache.box.Visible = false; cache.hpbar.Visible = false; cache.name.Visible = false
        for i = 1, #cache.bones do cache.bones[i].Visible = false end
        if cache.chamsInstance then cache.chamsInstance.Enabled = false end
    end
end)

-- ====== 🔒 【内核底层 HookMetamethod 变换（新增：二分控制随机追踪率）】 ======
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}

    if is_intercepting or internal_raycast then
        return oldNamecall(...)
    end

    if Arguments[1] == workspace and Method == "Raycast" then
        if typeof(Arguments[#Arguments]) ~= "RaycastParams" then
            return oldNamecall(...)
        end

        -- ====== 【新增功能二：随机化子弹追踪拦截门禁判定】 ======
        if esp_settings.hit_chance < 100 then
            local rolledPercentage = math.random(1, 100)
            if rolledPercentage > esp_settings.hit_chance then
                return oldNamecall(...) -- 概率不通过，放行原生弹道，实现高质伪装
            end
        end

        is_intercepting = true
        local HitPart = GetClosestPlayer()
        is_intercepting = false

        if HitPart then
            Arguments[3] = GetDirection(Arguments[2], HitPart.Position)
            return oldNamecall(unpack(Arguments))
        end
    end

    return oldNamecall(...)
end)

-- [[ 4. 挂载初始化、控件装配与同步控制绑定 ]]
getgenv()._scriptUnloaded = false

-- 执行开头异步阻塞动画
task.spawn(function()
    PlayCoreInjectionIntro()
end)

-- 延迟 2 秒（动画加载期）后实例化主窗体，达成无缝衔接
task.wait(2.0)

local UIInstance = ImGuiAnimated.new()
local UIWindow, StreamContainer = UIInstance:CreateWindow("ccontop for CHEATV1.0", UDim2.new(0, 335, 0, 500), UDim2.new(0, 120, 0, 120))

UIInstance:CreateSectionLabel(StreamContainer, "[ 绘制 ]")
UIInstance:CreateCheckbox(StreamContainer, "启用全局透", esp_settings.enabled, function(v) esp_settings.enabled = v end)
UIInstance:CreateCheckbox(StreamContainer, "显示 2D 方框几何形", esp_settings.box_visible, function(v) esp_settings.box_visible = v end)
UIInstance:CreateCheckbox(StreamContainer, "显示 玩家名称标识", esp_settings.name_visible, function(v) esp_settings.name_visible = v end)
UIInstance:CreateCheckbox(StreamContainer, "显示 玩家动态血条", esp_settings.hp_visible, function(v) esp_settings.hp_visible = v end)
UIInstance:CreateCheckbox(StreamContainer, "显示 玩家高级关节骨骼", esp_settings.skeleton_visible, function(v) esp_settings.skeleton_visible = v end)
UIInstance:CreateCheckbox(StreamContainer, "显示 墙后发光热成像", esp_settings.chams_enabled, function(v) esp_settings.chams_enabled = v end)
UIInstance:CreateSlider(StreamContainer, "全息透视线条粗细", 1, 5, esp_settings.esp_thickness, false, function(v) esp_settings.esp_thickness = v end)
UIInstance:CreateSlider(StreamContainer, "全息透视全局透明", 0.1, 1, esp_settings.esp_transparency, true, function(v) esp_settings.esp_transparency = v end)

UIInstance:CreateSectionLabel(StreamContainer, "[ 锁敌-暴力 or safe ]")
UIInstance:CreateCheckbox(StreamContainer, "开启 静默子弹追踪", esp_settings.silent_aim, function(v) esp_settings.silent_aim = v end)
-- 新增追踪概率控制滑块
UIInstance:CreateSlider(StreamContainer, "子弹追踪生效概率 (%)", 10, 100, esp_settings.hit_chance, false, function(v) esp_settings.hit_chance = v end)
UIInstance:CreateCheckbox(StreamContainer, "开启 级自动扳机", esp_settings.triggerbot, function(v) esp_settings.triggerbot = v end)
UIInstance:CreateCheckbox(StreamContainer, "开启 过滤同阵营队友", esp_settings.team_check, function(v) esp_settings.team_check = v end)
UIInstance:CreateCheckbox(StreamContainer, "显示 中心自瞄范围圈", esp_settings.fov_visible, function(v) esp_settings.fov_visible = v end)
UIInstance:CreateSlider(StreamContainer, "自瞄瞄准范围半径", 30, 500, esp_settings.aim_fov, false, function(v) esp_settings.aim_fov = v end)
UIInstance:CreateSlider(StreamContainer, "全局最大锁敌距离", 100, 3000, esp_settings.max_distance, false, function(v) esp_settings.max_distance = v end)
UIInstance:CreateSelector(StreamContainer, "指定自瞄锁敌部位", {"Head", "HumanoidRootPart"}, esp_settings.aim_part, function(v) esp_settings.aim_part = v end)

UIInstance:CreateSectionLabel(StreamContainer, "[ 机制机制 ]")
UIInstance:CreateCheckbox(StreamContainer, "强制 锁定第三人称", esp_settings.thirdperson, function(v) esp_settings.thirdperson = v end)
UIInstance:CreateSlider(StreamContainer, "第三人称镜头距离", 5, 30, esp_settings.tp_distance, false, function(v) esp_settings.tp_distance = v end)

UIInstance:CreateDestructButton(StreamContainer, "清理退出", function()
    getgenv()._scriptUnloaded = true
    if fov_circle then pcall(function() fov_circle:Remove() end) end
    for player, _ in pairs(player_drawings) do removeDrawingObjects(player) end
    local fadeTween = TweenService:Create(UIWindow, IM_THEME.CloseInfo, {Size = UDim2.new(0, UIWindow.Size.X.Offset, 0, 0), BackgroundTransparency = 1})
    fadeTween:Play()
    for _, obj in ipairs(UIWindow:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then TweenService:Create(obj, IM_THEME.CloseInfo, {TextTransparency = 1}):Play()
        elseif obj:IsA("Frame") then TweenService:Create(obj, IM_THEME.CloseInfo, {BackgroundTransparency = 1}):Play() end
    end
    fadeTween.Completed:Wait()
    UIInstance.ScreenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == esp_settings.toggle_key then
        UIWindow.Visible = not UIWindow.Visible
    end
end)

Players.PlayerAdded:Connect(createDrawingObjects)
Players.PlayerRemoving:Connect(removeDrawingObjects)
for _, p in pairs(Players:GetPlayers()) do if p ~= lplr then createDrawingObjects(p) end end

print("[Engine Suite]: ccontop core suite v2.5.0 finalized and deployed.")
return ImGuiAnimated
