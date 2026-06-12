-- [[ 1. Global Configuration Settings ]]
local esp_settings = {
    enabled = true,          -- Master toggle for ESP system
    box_visible = true,      -- 2D Bounding Box visibility
    name_visible = true,     -- Player name label visibility
    hp_visible = true,       -- Dynamic health bar visibility
    esp_thickness = 1,       -- Thickness of lines (1 - 5)
    esp_transparency = 0.8,  -- Global rendering opacity (0.1 - 1.0)
    
    skeleton_visible = true, -- Bone joint overlay toggle
    chams_enabled = true,    -- Occluded character thermal highlight
    chams_fill_color = Color3.fromRGB(255, 0, 0), -- Internal chams fill color
    chams_fill_trans = 0.5,  -- Internal chams transparency
    
    silent_aim = true,       -- Silent aim directional hijack toggle
    team_check = true,       -- Ignore faction allies / teammates
    aim_fov = 150,           -- Field of View locking radius (10 - 500)
    fov_visible = true,      -- Physical rendering of FOV verification circle
    aim_part = "Head",       -- Targeted bone part ("Head" or "HumanoidRootPart")
    max_distance = 1000,     -- Maximum culling threshold (100 - 3000)
    
    triggerbot = false,      -- Automated trigger mechanics
    thirdperson = false,     -- Forced third-person camera override
    tp_distance = 10,        -- Camera arm offset distance
    toggle_key = Enum.KeyCode.Insert -- Keybind to switch menu visibility
}

-- [[ 2. Core Services and Direct Localizations ]]
local Players = game:GetService("Players")
local lplr = Players.LocalPlayer
local workspace = game:GetService("Workspace")
local camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

-- Fast Method Localizations
local worldToViewportPoint = camera.worldToViewportPoint
local ViewportPointToRay = camera.ViewportPointToRay
local pairs, table_insert, table_find, math_clamp, math_floor, os_clock = pairs, table.insert, table.find, math.clamp, math.floor, os_clock
local Vector2_new, Vector3_new, Color3_fromRGB, Color3_fromHSV = Vector2.new, Vector3.new, Color3.fromRGB, Color3.fromHSV

local player_drawings = {} 
local ClosestTargetPart = nil -- Atomic storage for aim calculations

local HeadOff = Vector3_new(0, 0.5, 0)
local LegOff = Vector3_new(0, 3, 0)

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

-- Clear legacy workspace entities
if CoreGui:FindFirstChild("ImGui_Dark_Menu_Premium") then CoreGui:FindFirstChild("ImGui_Dark_Menu_Premium"):Destroy() end
if getgenv()._fov_circle_instance then 
    pcall(function() getgenv()._fov_circle_instance:Remove() end) 
end

-- [[ 3. FOV Calculation & Vector Graphics Circle ]]
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
            local viewportSize = camera.ViewportSize
            fov_circle.Position = Vector2_new(viewportSize.X / 2, viewportSize.Y / 2)
        end
    end
end)

-- [[ 4. Performance Oriented Algorithmic Solvers ]]
local function isEnemy(player)
    if not esp_settings.team_check then return true end
    return player.Team ~= lplr.Team
end

-- Asynchronous low-frequency thread for target acquisition to eliminate framerate drops
task.spawn(function()
    while task.wait(0.04) do -- Loops 25 times per second to minimize CPU scheduling pressure
        if not esp_settings.enabled or not esp_settings.silent_aim then 
            ClosestTargetPart = nil
            continue 
        end

        local Closest, Distance = nil, esp_settings.aim_fov
        local viewportSize = camera.ViewportSize
        local centerScreen = Vector2_new(viewportSize.X / 2, viewportSize.Y / 2)
        local myCharacter = lplr.Character
        local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
        if not myRoot then ClosestTargetPart = nil; continue end

        for player, cache in pairs(player_drawings) do
            if not isEnemy(player) then continue end
            
            -- Utilizing cached instances to prevent expensive FindFirstChild polling
            local character = cache.character
            local targetPart = character and cache[esp_settings.aim_part]
            local humanoid = cache.humanoid

            if targetPart and humanoid and humanoid.Health > 0 then
                if (myRoot.Position - targetPart.Position).Magnitude > esp_settings.max_distance then continue end
                
                local pos, isVisible = worldToViewportPoint(camera, targetPart.Position)
                if isVisible then
                    local screenDist = (centerScreen - Vector2_new(pos.X, pos.Y)).Magnitude
                    if screenDist < Distance then 
                        Closest = targetPart
                        Distance = screenDist 
                    end
                end
            end
        end
        ClosestTargetPart = Closest
    end
end)

-- Automated verification trigger mechanics
RunService.PostSimulation:Connect(function()
    if esp_settings.enabled and esp_settings.triggerbot then
        local viewportSize = camera.ViewportSize
        local unitRay = ViewportPointToRay(camera, viewportSize.X / 2, viewportSize.Y / 2)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {lplr.Character}
        local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * esp_settings.max_distance, raycastParams)
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
                        VirtualUser:Button1Up(Vector2.new(0, 0))
                    end
                end
            end
        end
    end
end)

-- Camera system controller overrides
RunService.RenderStepped:Connect(function()
    if esp_settings.thirdperson and lplr.Character then
        lplr.CameraMode = Enum.CameraMode.Classic
        lplr.CameraMaxZoomDistance = esp_settings.tp_distance
        lplr.CameraMinZoomDistance = esp_settings.tp_distance
    end
end)

-- ====== 🎨 ImGui Theme Layer ======
local ui = Instance.new("ScreenGui")
ui.Name = "ImGui_Dark_Menu_Premium"; ui.ResetOnSpawn = false; ui.Parent = CoreGui

local main = Instance.new("Frame")
main.Name = "MainWindow"; main.Parent = ui; main.BackgroundColor3 = Color3_fromRGB(15, 15, 15) 
main.BorderSizePixel = 1; main.BorderColor3 = Color3_fromRGB(60, 60, 70) 
main.Position = UDim2.new(0, 120, 0, 120); main.Size = UDim2.new(0, 310, 0, 500) 
main.Active = true; main.Draggable = true 

local topBar = Instance.new("Frame")
topBar.Parent = main; topBar.BackgroundColor3 = Color3_fromRGB(30, 40, 60); topBar.BorderSizePixel = 0; topBar.Size = UDim2.new(1, 0, 0, 24)

local triangle = Instance.new("TextLabel")
triangle.Text = "▼"; triangle.TextColor3 = Color3_fromRGB(240, 240, 240); triangle.TextSize = 12; triangle.Font = Enum.Font.SourceSansBold
triangle.BackgroundTransparency = 1; triangle.Position = UDim2.new(0, 5, 0, 0); triangle.Size = UDim2.new(0, 15, 1, 0); triangle.Parent = topBar

local title = Instance.new("TextLabel")
title.Text = "ccontop"; title.TextColor3 = Color3_fromRGB(240, 240, 240); title.TextSize = 13; title.Font = Enum.Font.Code
title.TextXAlignment = Enum.TextXAlignment.Left; title.BackgroundTransparency = 1; title.Position = UDim2.new(0, 22, 0, 0); title.Size = UDim2.new(1, -80, 1, 0); title.Parent = topBar

local fpsDisplay = Instance.new("TextLabel")
fpsDisplay.Size = UDim2.new(0, 50, 1, 0); fpsDisplay.Position = UDim2.new(1, -55, 0, 0); fpsDisplay.Font = Enum.Font.Code
fpsDisplay.Text = "60.0 FPS"; fpsDisplay.TextColor3 = Color3_fromRGB(0, 180, 100); fpsDisplay.TextSize = 12; fpsDisplay.TextXAlignment = Enum.TextXAlignment.Right; fpsDisplay.BackgroundTransparency = 1; fpsDisplay.Parent = topBar

local resizeGrip = Instance.new("TextButton")
resizeGrip.Name = "ResizeGrip"; resizeGrip.Size = UDim2.new(0, 14, 0, 14); resizeGrip.Position = UDim2.new(1, -14, 1, -14); resizeGrip.BackgroundTransparency = 1
resizeGrip.Text = "◢"; resizeGrip.Font = Enum.Font.SourceSansBold; resizeGrip.TextSize = 14; resizeGrip.TextColor3 = Color3_fromRGB(80, 80, 90); resizeGrip.ZIndex = 5; resizeGrip.Parent = main

local containerList = Instance.new("ScrollingFrame")
containerList.Size = UDim2.new(1, -8, 1, -32); containerList.Position = UDim2.new(0, 4, 0, 28)
containerList.BackgroundColor3 = Color3_fromRGB(20, 20, 20); containerList.BorderColor3 = Color3_fromRGB(40, 40, 45)
containerList.ScrollBarThickness = 4; containerList.ScrollBarImageColor3 = Color3_fromRGB(50, 50, 60)
containerList.CanvasSize = UDim2.new(0, 0, 0, 650); containerList.Parent = main
local layout = Instance.new("UIListLayout", containerList); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 4)

local isResizing = false
local startMousePos, startSize

resizeGrip.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = true
        startMousePos = Vector2_new(input.Position.X, input.Position.Y)
        startSize = main.AbsoluteSize
        main.Draggable = false 
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local currentMousePos = Vector2_new(input.Position.X, input.Position.Y)
        local delta = currentMousePos - startMousePos
        main.Size = UDim2.new(0, math_clamp(startSize.X + delta.X, 260, 800), 0, math_clamp(startSize.Y + delta.Y, 300, 1000))
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isResizing = false; main.Draggable = true 
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if not gpe and input.KeyCode == esp_settings.toggle_key then main.Visible = not main.Visible end
end)

local lastFpsUpdateTime, frameCount = 0, 0
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1; local currentTime = os_clock()
    if currentTime - lastFpsUpdateTime >= 0.5 then
        local currentFps = math_floor(frameCount / (currentTime - lastFpsUpdateTime))
        fpsDisplay.Text = tostring(currentFps) .. ".0 FPS"
        fpsDisplay.TextColor3 = currentFps < 45 and Color3_fromRGB(220, 80, 80) or Color3_fromRGB(0, 180, 100)
        frameCount, lastFpsUpdateTime = 0, currentTime
    end
end)

-- Core UI Element Factory Methods
local function createImGuiLabel(text)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 20); row.BackgroundTransparency = 1; row.Parent = containerList
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, -12, 1, 0); label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.Code; label.Text = text; label.TextColor3 = Color3_fromRGB(0, 170, 255) 
    label.TextSize = 12; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = row
end

local function createImGuiCheckbox(text, default_state, callback)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 24); row.BackgroundTransparency = 1; row.Parent = containerList
    local box = Instance.new("TextButton"); box.Size = UDim2.new(0, 14, 0, 14); box.Position = UDim2.new(0, 8, 0.5, -7)
    box.BackgroundColor3 = default_state and Color3_fromRGB(35, 90, 150) or Color3_fromRGB(40, 40, 45)
    box.BorderColor3 = Color3_fromRGB(70, 70, 80); box.BorderSizePixel = 1; box.AutoButtonColor = false
    box.Text = default_state and "X" or ""; box.Font = Enum.Font.Code; box.TextColor3 = Color3_fromRGB(255, 255, 255); box.TextSize = 12; box.Parent = row
    local label = Instance.new("TextButton"); label.Size = UDim2.new(1, -35, 1, 0); label.Position = UDim2.new(0, 28, 0, 0)
    label.BackgroundTransparency = 1; label.AutoButtonColor = false; label.Font = Enum.Font.Code; label.Text = text
    label.TextColor3 = Color3_fromRGB(220, 220, 220); label.TextSize = 12; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = row
    local state = default_state
    local function toggle()
        state = not state; callback(state)
        box.BackgroundColor3 = state and Color3_fromRGB(35, 90, 150) or Color3_fromRGB(40, 40, 45)
        box.Text = state and "X" or ""
    end
    box.MouseButton1Click:Connect(toggle); label.MouseButton1Click:Connect(toggle)
end

local function createImGuiSlider(text, min, max, default_value, is_float, callback)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 24); row.BackgroundTransparency = 1; row.Parent = containerList
    local trackBtn = Instance.new("TextButton"); trackBtn.Size = UDim2.new(0, 120, 0, 18); trackBtn.Position = UDim2.new(0, 8, 0.5, -9)
    trackBtn.BackgroundColor3 = Color3_fromRGB(40, 45, 50); trackBtn.BorderColor3 = Color3_fromRGB(65, 65, 75); trackBtn.BorderSizePixel = 1; trackBtn.AutoButtonColor = false; trackBtn.Text = ""; trackBtn.Parent = row
    local fill = Instance.new("Frame"); fill.Size = UDim2.new((default_value - min) / (max - min), 0, 1, 0); fill.BackgroundColor3 = Color3_fromRGB(35, 80, 135); fill.BorderSizePixel = 0; fill.Parent = trackBtn
    local valLabel = Instance.new("TextLabel"); valLabel.Size = UDim2.new(1, 0, 1, 0); valLabel.BackgroundTransparency = 1; valLabel.Font = Enum.Font.Code
    valLabel.Text = string.format(is_float and "%.2f" or "%d", default_value); valLabel.TextColor3 = Color3_fromRGB(255, 255, 255); valLabel.TextSize = 11; valLabel.ZIndex = 3; valLabel.Parent = trackBtn
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, -140, 1, 0); label.Position = UDim2.new(0, 136, 0, 0); label.BackgroundTransparency = 1; label.Font = Enum.Font.Code
    label.Text = text; label.TextColor3 = Color3_fromRGB(210, 210, 210); label.TextSize = 12; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = row
    local dragging = false
    local function updateValue(input)
        local percentage = math_clamp((input.Position.X - trackBtn.AbsolutePosition.X) / trackBtn.AbsoluteSize.X, 0, 1)
        local rawVal = min + (max - min) * percentage
        local finalVal = is_float and tonumber(string.format("%.2f", rawVal)) or math_floor(rawVal)
        fill.Size = UDim2.new(percentage, 0, 1, 0); valLabel.Text = string.format(is_float and "%.2f" or "%d", finalVal); callback(finalVal)
    end
    trackBtn.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; updateValue(input) end end)
    UserInputService.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then updateValue(input) end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
end

local function createImGuiSelector(text, options, default_opt, callback)
    local row = Instance.new("Frame"); row.Size = UDim2.new(1, 0, 0, 24); row.BackgroundTransparency = 1; row.Parent = containerList
    local btn = Instance.new("TextButton"); btn.Size = UDim2.new(0, 120, 0, 18); btn.Position = UDim2.new(0, 8, 0.5, -9)
    btn.BackgroundColor3 = Color3_fromRGB(45, 45, 50); btn.BorderColor3 = Color3_fromRGB(65, 65, 75); btn.BorderSizePixel = 1; btn.AutoButtonColor = false; btn.Font = Enum.Font.Code
    local current_idx = table_find(options, default_opt) or 1; btn.Text = tostring(options[current_idx]); btn.TextColor3 = Color3_fromRGB(240, 240, 240); btn.TextSize = 12; btn.Parent = row
    local label = Instance.new("TextLabel"); label.Size = UDim2.new(1, -140, 1, 0); label.Position = UDim2.new(0, 136, 0, 0); label.BackgroundTransparency = 1; label.Font = Enum.Font.Code
    label.Text = text; label.TextColor3 = Color3_fromRGB(210, 210, 210); label.TextSize = 12; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = row
    btn.MouseButton1Click:Connect(function() current_idx = current_idx % #options + 1; local chosen = options[current_idx]; callback(chosen); btn.Text = tostring(chosen) end)
end

-- Initialize Layout Mapping Hierarchy
createImGuiLabel("[ Visuals - Core Overlay Engine ]")
createImGuiCheckbox("Master ESP Switch", esp_settings.enabled, function(v) esp_settings.enabled = v end)
createImGuiCheckbox("Render 2D Bounding Boxes", esp_settings.box_visible, function(v) esp_settings.box_visible = v end)
createImGuiCheckbox("Render Player Identifiers", esp_settings.name_visible, function(v) esp_settings.name_visible = v end)
createImGuiCheckbox("Render Dynamic Health Bars", esp_settings.hp_visible, function(v) esp_settings.hp_visible = v end)
createImGuiCheckbox("Render Structural Skeletons", esp_settings.skeleton_visible, function(v) esp_settings.skeleton_visible = v end)
createImGuiCheckbox("Render Occluded Chams Glow", esp_settings.chams_enabled, function(v) esp_settings.chams_enabled = v end)
createImGuiSlider("Overlay Vector Thickness", 1, 5, esp_settings.esp_thickness, false, function(v) esp_settings.esp_thickness = v end)
createImGuiSlider("Global Overlay Transparency", 0.1, 1, esp_settings.esp_transparency, true, function(v) esp_settings.esp_transparency = v end)

createImGuiLabel("[ Target - Physics Solution ]")
createImGuiCheckbox("Silent Aim Kinematics", esp_settings.silent_aim, function(v) esp_settings.silent_aim = v end)
createImGuiCheckbox("Asynchronous Triggerbot", esp_settings.triggerbot, function(v) esp_settings.triggerbot = v end)
createImGuiCheckbox("Filter Team Alignment", esp_settings.team_check, function(v) esp_settings.team_check = v end)
createImGuiCheckbox("Display Verification Circle", esp_settings.fov_visible, function(v) esp_settings.fov_visible = v end)
createImGuiSlider("Verification Circle Radius", 30, 500, esp_settings.aim_fov, false, function(v) esp_settings.aim_fov = v end)
createImGuiSlider("Max Acquisition Cutoff", 100, 3000, esp_settings.max_distance, false, function(v) esp_settings.max_distance = v end)
createImGuiSelector("Target Bone Component", {"Head", "HumanoidRootPart"}, esp_settings.aim_part, function(v) esp_settings.aim_part = v end)

createImGuiLabel("[ Mechanics - Engine Displacements ]")
createImGuiCheckbox("Enforce Third Person Camera", esp_settings.thirdperson, function(v) esp_settings.thirdperson = v end)
createImGuiSlider("Third Person Arm Distance", 5, 30, esp_settings.tp_distance, false, function(v) esp_settings.tp_distance = v end)

local closeWrapper = Instance.new("Frame"); closeWrapper.Size = UDim2.new(1, 0, 0, 30); closeWrapper.BackgroundTransparency = 1; closeWrapper.Parent = containerList
local closeBtn = Instance.new("TextButton"); closeBtn.Size = UDim2.new(0, 120, 0, 20); closeBtn.Position = UDim2.new(0, 8, 0, 4); closeBtn.BackgroundColor3 = Color3_fromRGB(130, 40, 40) 
closeBtn.BorderColor3 = Color3_fromRGB(160, 50, 50); closeBtn.BorderSizePixel = 1; closeBtn.Font = Enum.Font.Code; closeBtn.Text = "Safe Execution Unload"
closeBtn.TextColor3 = Color3_fromRGB(255, 255, 255); closeBtn.TextSize = 12; closeBtn.Parent = closeWrapper

local scriptUnloaded = false

-- ====== 🎨 Unified High-Level Rendering Frame Loop ======
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

    -- Reset preexisting chams structures to negate memory expansion
    clearChams(character)

    cache.character = character
    cache.humanoid = character:WaitForChild("Humanoid", 5)
    cache.Head = character:WaitForChild("Head", 5)
    cache.HumanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
    cache.UpperTorso = character:FindFirstChild("UpperTorso")
    cache.Torso = character:FindFirstChild("Torso")
    
    -- Map R15/R6 bones inside static memory blocks to prevent run-time indexing lag
    if cache.humanoid then
        local isR15 = cache.humanoid.RigType == Enum.HumanoidRigType.R15
        local currentBones = SkeletonConnections[isR15 and "R15" or "R6"]
        for _, conn in pairs(currentBones) do
            cache[conn[1]] = character:FindFirstChild(conn[1])
            cache[conn[2]] = character:FindFirstChild(conn[2])
        end
    end

    -- Construct persistent global highlight components
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
        box = box, hpbar = hpbar, name = name, bones = bones,
        last_thickness = -1, last_transparency = -1,
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

closeBtn.MouseButton1Click:Connect(function() 
    scriptUnloaded = true; ui:Destroy() 
    if fov_circle then fov_circle:Remove() end 
    for player, _ in pairs(player_drawings) do removeDrawingObjects(player) end
end)

Players.PlayerAdded:Connect(createDrawingObjects)
Players.PlayerRemoving:Connect(removeDrawingObjects)
for _, p in pairs(Players:GetPlayers()) do if p ~= lplr then createDrawingObjects(p) end end

-- ⚡ Structural Graphics Render-Loop Drive Execution
RunService.RenderStepped:Connect(function()
    if scriptUnloaded then return end

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
            -- 1. Linear frustum distance verification
            if myRoot and (myRoot.Position - root.Position).Magnitude > esp_settings.max_distance then
                cache.box.Visible = false; cache.hpbar.Visible = false; cache.name.Visible = false
                for i = 1, #cache.bones do cache.bones[i].Visible = false end
                if cache.chamsInstance then cache.chamsInstance.Enabled = false end
                continue
            end

            -- 2. Chams pipeline logic runtime
            if esp_settings.chams_enabled then
                local chams = cache.chamsInstance
                if not chams or chams.Parent ~= character then
                    clearChams(character)
                    chams = Instance.new("Highlight"); chams.Name = "ImGuiChams"; chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; chams.Parent = character
                    cache.chamsInstance = chams
                end
                chams.Enabled = true
                chams.FillColor = esp_settings.chams_fill_color
                chams.FillTransparency = esp_settings.chams_fill_trans
                chams.OutlineColor = player.TeamColor.Color
            else
                if cache.chamsInstance then cache.chamsInstance.Enabled = false end
            end

            -- 3. World space to vector coordinate screen calculations
            local rootPos, onScreen = worldToViewportPoint(camera, root.Position)
            if onScreen then
                -- State verification caching (prevents redundant register allocation overhead)
                if cache.last_thickness ~= thickness or cache.last_transparency ~= trans then
                    cache.box.Thickness = thickness; cache.box.Transparency = trans
                    cache.hpbar.Thickness = thickness + 0.5; cache.hpbar.Transparency = trans
                    cache.name.Transparency = trans
                    for i = 1, #cache.bones do cache.bones[i].Thickness = thickness; cache.bones[i].Transparency = trans end
                    cache.last_thickness, cache.last_transparency = thickness, trans
                end

                -- Joint skeletal connection iteration loops
                if esp_settings.skeleton_visible then
                    local boneType = humanoid.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
                    local connections = SkeletonConnections[boneType]
                    for idx = 1, #connections do
                        local connection = connections[idx]
                        local partA = cache[connection[1]]
                        local partB = cache[connection[2]]
                        local lineObj = cache.bones[idx]
                        if partA and partB and lineObj then
                            local posA, screenA = worldToViewportPoint(camera, partA.Position)
                            local posB, screenB = worldToViewportPoint(camera, partB.Position)
                            if screenA and screenB then
                                lineObj.From = Vector2_new(posA.X, posA.Y); lineObj.To = Vector2_new(posB.X, posB.Y)
                                lineObj.Color = player.TeamColor.Color; lineObj.Visible = true
                            else lineObj.Visible = false end
                        end
                    end
                    for idx = #connections + 1, 15 do cache.bones[idx].Visible = false end
                else
                    for i = 1, #cache.bones do cache.bones[i].Visible = false end
                end

                -- Structural layout math matrices for bounding entities
                local headPos = worldToViewportPoint(camera, head.Position + HeadOff)
                local legPos = worldToViewportPoint(camera, root.Position - LegOff)
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
        -- Default concealment sequence for non-renderable objects
        cache.box.Visible = false; cache.hpbar.Visible = false; cache.name.Visible = false
        for i = 1, #cache.bones do cache.bones[i].Visible = false end
        if cache.chamsInstance then cache.chamsInstance.Enabled = false end
    end
end)

-- ====== 🔒 Metamethod Intersection Core Engine ======
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    
    -- Filter validation chain: targeting workspace raycast processes exclusively
    if self == workspace and Method == "Raycast" and esp_settings.silent_aim and esp_settings.enabled then
        local HitPart = ClosestTargetPart 
        
        -- Target integrity diagnostics sequence
        if HitPart and HitPart:IsA("BasePart") and HitPart.Parent then
            local targetChar = HitPart.Parent
            local humanoid = targetChar:FindFirstChildOfClass("Humanoid")
            
            if humanoid and humanoid.Health > 0 then
                local RayOrigin = Arguments[1]
                
                -- Frustum position origin tracking bounds checks (filters irrelevant engine trace updates)
                local myChar = lplr.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                
                if RayOrigin and ( (myRoot and (RayOrigin - myRoot.Position).Magnitude < 15) or (camera and (RayOrigin - camera.CFrame.Position).Magnitude < 15) ) then
                    
                    local NewDirection = HitPart.Position - RayOrigin
                    if NewDirection.Magnitude > 0.01 then
                        -- Override direction data registry with current tracking vectors
                        Arguments[2] = NewDirection
                        
                        -- Update native RaycastParams tables to avoid local model collision triggers
                        if Arguments[3] and Arguments[3]:IsA("RaycastParams") then
                            local params = Arguments[3]
                            local filter = params.FilterDescendantsInstances or {}
                            if not table.find(filter, myChar) then
                                table.insert(filter, myChar)
                                params.FilterDescendantsInstances = filter
                            end
                        end
                        
                        -- Bypass engine registers with current positional alterations
                        return oldNamecall(self, unpack(Arguments))
                    end
                end
            end
        end
    end
    
    -- Forward unmodified engine namecalls back to native routines without filtering artifacts
    return oldNamecall(self, ...)
end)