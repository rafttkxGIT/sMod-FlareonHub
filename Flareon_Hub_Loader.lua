--[[
    Flareon Hub - ML Loader
    Orange flame aesthetic | Restyled from Silence
]]

local LoaderSystem = {}
LoaderSystem.__index = LoaderSystem

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

local function Create(className, properties, parent)
    local instance = Instance.new(className)

    for property, value in pairs(properties) do
        instance[property] = value
    end

    if parent then
        instance.Parent = parent
    end

    return instance
end



function LoaderSystem:CreateLoader(Config)
    local Title = "Flareon Hub"
    local Description = Config.Description or "Choose your script..."
    local MainScriptURL = Config.MainScriptURL or "https://raw.githubusercontent.com/rafttkxGIT/sMod-FlareonHub/refs/heads/main/main.lua"
    local FastFarmingURL = Config.FastFarmingURL or "https://raw.githubusercontent.com/rafttkxGIT/sMod-FlareonHub/refs/heads/main/fast.lua"
    
    -- Flareon blue colors (right side sun)
    local FlameBlue = Color3.fromRGB(100, 200, 255)
    local BrightBlue = Color3.fromRGB(150, 220, 255)
    local DarkBlue = Color3.fromRGB(50, 150, 220)
    local AccentBlue = Color3.fromRGB(120, 210, 255)
    local NeonBlue = Color3.fromRGB(180, 240, 255)
    local DeepBlue = Color3.fromRGB(70, 180, 240)

    local LoaderGui = Create("ScreenGui", {
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Name = "LoaderGui"
    }, RunService:IsStudio() and Player.PlayerGui or 
       (gethui and gethui() or game:GetService("CoreGui")))

    local BlurBackground = Create("Frame", {
        BackgroundColor3 = Color3.fromRGB(50, 150, 200),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Name = "BlurBackground"
    }, LoaderGui)

    local BackgroundGradient = Create("UIGradient", {
        Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0.0, Color3.fromRGB(100, 200, 255)),
            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(80, 180, 240)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(60, 150, 220)),
            ColorSequenceKeypoint.new(1.0, Color3.fromRGB(20, 80, 150))
        },
        Rotation = 45
    }, BlurBackground)

    local bgGradientTween = TweenService:Create(
        BackgroundGradient,
        TweenInfo.new(8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Rotation = 225}
    )
    bgGradientTween:Play()

    for i = 1, 25 do
        local particleSize = math.random(1, 6)
        local particle = Create("Frame", {
            BackgroundColor3 = i <= 15 and FlameBlue or (i <= 20 and NeonBlue or BrightBlue),
            BackgroundTransparency = math.random(70, 90) / 100,
            BorderSizePixel = 0,
            Size = UDim2.new(0, particleSize, 0, particleSize),
            Position = UDim2.new(math.random(0, 100) / 100, 0, math.random(0, 100) / 100, 0),
            Name = "Particle" .. i
        }, BlurBackground)

        Create("UICorner", {CornerRadius = UDim.new(1, 0)}, particle)

        if i <= 10 then
            local particleGlow = Create("Frame", {
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(1, 4, 1, 4),
                BackgroundColor3 = particle.BackgroundColor3,
                BackgroundTransparency = 0.9,
                BorderSizePixel = 0,
                ZIndex = particle.ZIndex - 1
            }, particle)
            Create("UICorner", {CornerRadius = UDim.new(1, 0)}, particleGlow)

            local glowTween = TweenService:Create(
                particleGlow,
                TweenInfo.new(math.random(2, 4), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
                {BackgroundTransparency = 0.95, Size = UDim2.new(1, 8, 1, 8)}
            )
            glowTween:Play()
        end

        local floatSpeed = math.random(8, 30)
        local floatTween = TweenService:Create(
            particle,
            TweenInfo.new(floatSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {
                Position = UDim2.new(math.random(0, 100) / 100, 0, math.random(0, 100) / 100, 0),
                BackgroundTransparency = math.random(40, 95) / 100,
                Rotation = math.random(-180, 180)
            }
        )
        floatTween:Play()
    end

    local LoaderContainer = Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 340, 0, 280),
        Name = "LoaderContainer"
    }, BlurBackground)

    Create("UICorner", {CornerRadius = UDim.new(0, 18)}, LoaderContainer)

    local BorderStroke = Create("UIStroke", {
        Color = FlameBlue,
        Thickness = 2.5,
        Transparency = 0.2,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    }, LoaderContainer)

    for i = 1, 3 do
        local glowSize = 8 + (i * 4)
        local GlowFrame = Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, glowSize, 1, glowSize),
            BackgroundColor3 = i == 1 and FlameBlue or (i == 2 and NeonBlue or BrightBlue),
            BackgroundTransparency = 0.8 + (i * 0.05),
            BorderSizePixel = 0,
            ZIndex = LoaderContainer.ZIndex - i
        }, BlurBackground)

        Create("UICorner", {CornerRadius = UDim.new(0, 22 + (i * 2))}, GlowFrame)

        local glowTween = TweenService:Create(
            GlowFrame,
            TweenInfo.new(2 + i, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {
                BackgroundTransparency = 0.95,
                Size = UDim2.new(1, glowSize + 8, 1, glowSize + 8)
            }
        )
        glowTween:Play()
    end

    local FooterFrame = Create("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 1, -35),
    Size = UDim2.new(1, 0, 0, 35),
    ZIndex = 1000,
    Name = "FooterFrame"
}, LoaderContainer)

local FooterLine = Create("Frame", {
    BackgroundColor3 = FlameBlue,
    BackgroundTransparency = 0.6,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 20, 0, 0),
    Size = UDim2.new(1, -40, 0, 1),
    ZIndex = 1001,
    Name = "FooterLine"
}, FooterFrame)

local FooterText = Create("TextLabel", {
    Font = Enum.Font.FredokaOne,
    Text = "Made with  ❄️  by Flareon",
    TextColor3 = Color3.fromRGB(100, 200, 255),
    TextSize = 15,
    TextTransparency = 0,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 8),
    Size = UDim2.new(1, 0, 0, 20),
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 1002,
    Name = "FooterText"
}, FooterFrame)

local FooterGlow = Create("TextLabel", {
    Font = Enum.Font.FredokaOne,
    Text = "(M)Made by Flareon",
    TextColor3 = Color3.fromRGB(150, 220, 255),
    TextTransparency = 0.85,
    TextSize = 15,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 1, 0, 9),
    Size = UDim2.new(1, 0, 0, 20),
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 1001,
    Name = "FooterGlow"
}, FooterFrame)

    local CloseButton = Create("TextButton", {
        Font = Enum.Font.GothamBold,
        Text = "×",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 22,
        BackgroundColor3 = FlameBlue,
        BackgroundTransparency = 0.3,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 40, 0, 40),
        Position = UDim2.new(1, -45, 0, 5),
        Name = "CloseButton",
        ZIndex = 1005
    }, LoaderContainer)

    Create("UICorner", {CornerRadius = UDim.new(0, 8)}, CloseButton)

    CloseButton.MouseEnter:Connect(function()
        TweenService:Create(CloseButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 0.1,
            TextSize = 26
        }):Play()
    end)

    CloseButton.MouseLeave:Connect(function()
        TweenService:Create(CloseButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 0.3,
            TextSize = 22
        }):Play()
    end)

    local TitleLabel = Create("TextLabel", {
        Font = Enum.Font.FredokaOne,
        Text = Title,
        TextColor3 = Color3.fromRGB(150, 220, 255),
        TextSize = 32,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 20),
        Size = UDim2.new(1, -40, 0, 40),
        TextXAlignment = Enum.TextXAlignment.Center,
        Name = "TitleLabel",
        ZIndex = 1003
    }, LoaderContainer)

    local TitleShadow = Create("TextLabel", {
        Font = Enum.Font.FredokaOne,
        Text = Title,
        TextColor3 = Color3.fromRGB(70, 180, 240),
        TextSize = 32,
        TextTransparency = 0.6,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 22, 0, 22),
        Size = UDim2.new(1, -40, 0, 40),
        TextXAlignment = Enum.TextXAlignment.Center,
        Name = "TitleShadow",
        ZIndex = 1002
    }, LoaderContainer)

    local function animateTitle()
        while true do
            for i = 1, 5 do
                TitleLabel.TextSize = 32 - (i * 0.5)
                TitleShadow.TextSize = 32 - (i * 0.5)
                TweenService:Create(TitleLabel, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextSize = 32}):Play()
                TweenService:Create(TitleShadow, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextSize = 32}):Play()

                TweenService:Create(TitleLabel, TweenInfo.new(0.04, Enum.EasingStyle.Quad), {TextTransparency = 0.5}):Play()
                TweenService:Create(TitleLabel, TweenInfo.new(0.04, Enum.EasingStyle.Quad), {TextTransparency = 0}):Play()

                wait(0.05)
            end

            wait(1)
        end
    end

    spawn(animateTitle)

    for i = 1, 20 do
        local sparkleType = i <= 8 and 1 or (i <= 14 and 2 or 3)
        local sparkleSize = sparkleType == 1 and 2 or (sparkleType == 2 and 3 or 1)
        local sparkleColor = sparkleType == 1 and Color3.fromRGB(255, 255, 255) or 
                            (sparkleType == 2 and NeonBlue or BrightBlue)

        local sparkle = Create("Frame", {
            BackgroundColor3 = sparkleColor,
            BackgroundTransparency = 0.6,
            BorderSizePixel = 0,
            Size = UDim2.new(0, sparkleSize, 0, sparkleSize),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, math.random(-120, 120), 0, 35 + math.random(-30, 30)),
            ZIndex = TitleLabel.ZIndex + 1,
            Name = "Sparkle" .. i
        }, LoaderContainer)

        if sparkleType == 3 then
            Create("UICorner", {CornerRadius = UDim.new(0, 1)}, sparkle) 
        else
            Create("UICorner", {CornerRadius = UDim.new(1, 0)}, sparkle) 
        end

        local sparkleSpeed = math.random(10, 40) / 10
        local sparkleTween = TweenService:Create(
            sparkle,
            TweenInfo.new(sparkleSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            {
                BackgroundTransparency = 0.2,
                Size = UDim2.new(0, sparkleSize + 2, 0, sparkleSize + 2),
                Position = UDim2.new(0.5, math.random(-140, 140), 0, 35 + math.random(-35, 35)),
                Rotation = math.random(-360, 360)
            }
        )
        sparkleTween:Play()
    end

    local DescLabel = Create("TextLabel", {
        Font = Enum.Font.FredokaOne,
        Text = Description,
        TextColor3 = Color3.fromRGB(100, 200, 255),
        TextSize = 15,
        TextWrapped = true,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 75),
        Size = UDim2.new(1, -40, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Center,
        Name = "DescLabel"
    }, LoaderContainer)

    local DescGlow = Create("TextLabel", {
        Font = Enum.Font.FredokaOne,
        Text = Description,
        TextColor3 = Color3.fromRGB(180, 230, 255),
        TextTransparency = 0.8,
        TextSize = 15,
        TextWrapped = true,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 21, 0, 76),
        Size = UDim2.new(1, -40, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = DescLabel.ZIndex - 1,
        Name = "DescGlow"
    }, LoaderContainer)

    local ButtonsFrame = Create("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 20, 0, 120),
        Size = UDim2.new(1, -40, 0, 120),
        Name = "ButtonsFrame"
    }, LoaderContainer)

    local function createEnhancedButton(properties, parent)
        local button = Create("TextButton", properties, parent)
        Create("UICorner", {CornerRadius = UDim.new(0, 10)}, button)

        local buttonGlow = Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 4, 1, 4),
            BackgroundColor3 = properties.BackgroundColor3,
            BackgroundTransparency = 0.9,
            BorderSizePixel = 0,
            ZIndex = button.ZIndex - 1
        }, button)
        Create("UICorner", {CornerRadius = UDim.new(0, 12)}, buttonGlow)

        return button, buttonGlow
    end

    local MainScriptButton, MainScriptGlow = createEnhancedButton({
        Font = Enum.Font.FredokaOne,
        Text = "Main Script (All Features)",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        BackgroundColor3 = BrightBlue,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 50),
        Name = "MainScriptButton"
    }, ButtonsFrame)

    local FastFarmingButton, FastFarmingGlow = createEnhancedButton({
        Font = Enum.Font.FredokaOne,
        Text = "Fast Farming (Rep Pets only!)",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 14,
        BackgroundColor3 = DarkBlue,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0, 60),
        Size = UDim2.new(1, 0, 0, 50),
        Name = "FastFarmingButton"
    }, ButtonsFrame)

    local function addEnhancedHoverEffect(button, buttonGlow, hoverColor, originalColor)
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundColor3 = hoverColor,
                Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, button.Size.Y.Scale, button.Size.Y.Offset + 3),
                TextSize = button.TextSize + 1
            }):Play()
            TweenService:Create(buttonGlow, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundTransparency = 0.7,
                Size = UDim2.new(1, 8, 1, 8)
            }):Play()
        end)

        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundColor3 = originalColor,
                Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset, button.Size.Y.Scale, button.Size.Y.Offset - 3),
                TextSize = button.TextSize - 1
            }):Play()
            TweenService:Create(buttonGlow, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                BackgroundTransparency = 0.9,
                Size = UDim2.new(1, 4, 1, 4)
            }):Play()
        end)
    end

    addEnhancedHoverEffect(MainScriptButton, MainScriptGlow, Color3.fromRGB(180, 240, 255), BrightBlue)
    addEnhancedHoverEffect(FastFarmingButton, FastFarmingGlow, Color3.fromRGB(100, 210, 255), DarkBlue)

    MainScriptButton.Activated:Connect(function()
        script = Instance.new("LocalScript")
        script.Name = "FlareonRuntime"
        LoaderGui:Destroy()
        loadstring(game:HttpGet(MainScriptURL))()
    end)

    FastFarmingButton.Activated:Connect(function()
        script = Instance.new("LocalScript")
        script.Name = "FlareonRuntime"
        LoaderGui:Destroy()
        loadstring(game:HttpGet(FastFarmingURL))()
    end)

    CloseButton.Activated:Connect(function()
        TweenService:Create(LoaderContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0), 
            BackgroundTransparency = 1,
            Rotation = 180
        }):Play()
        TweenService:Create(BlurBackground, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
        wait(0.6)
        LoaderGui:Destroy()
    end)

    LoaderContainer.Size = UDim2.new(0, 0, 0, 0)
    LoaderContainer.BackgroundTransparency = 1
    LoaderContainer.Rotation = -180

    TweenService:Create(LoaderContainer, TweenInfo.new(1.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 340, 0, 280),
        BackgroundTransparency = 0,
        Rotation = 0
    }):Play()

    local elements = {TitleLabel, DescLabel, ButtonsFrame}
    for i, element in pairs(elements) do
        element.Position = element.Position + UDim2.new(0, 0, 0, 50)
        element.Rotation = math.random(-45, 45)

        TweenService:Create(element, TweenInfo.new(0.8 + (i * 0.1), Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = element.Position - UDim2.new(0, 0, 0, 50),
            Rotation = 0
        }):Play()
    end

    return LoaderGui
end

LoaderSystem:CreateLoader({
    Description = "Choose your script to execute"
})

return LoaderSystem
