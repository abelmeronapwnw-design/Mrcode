2 -- ============================================================
--  SISTEMA DE LLAVES (VERSIÓN LOADSTRING COMPATIBLE)
-- ============================================================

-- Si ya existe una GUI, eliminarla
if _G._keyScreen then
    pcall(function() _G._keyScreen:Destroy() end)
    _G._keyScreen = nil
end

-- CONFIGURACIÓN
local GIST_RAW_URL = "https://gist.githubusercontent.com/abelmeronapwnw-design/d0801495daa4d6b52aa4f0f101d03946/raw/127c49710b1c0237da873669b63e83be1b1d7036/keys.json"
local HUB_URL = "https://raw.githubusercontent.com/abelmeronapwnw-design/Mrcode/main/ChiperPremium"

-- COLORES
local KEY_COLORS = {
    BG = Color3.fromRGB(8, 8, 15),
    PANEL = Color3.fromRGB(12, 12, 18),
    CARD = Color3.fromRGB(14, 14, 24),
    ACCENT = Color3.fromRGB(99, 102, 241),
    PURPLE = Color3.fromRGB(139, 92, 246),
    ICE = Color3.fromRGB(56, 189, 248),
    TEXT = Color3.fromRGB(235, 235, 245),
    SECONDARY = Color3.fromRGB(165, 165, 185),
    STROKE = Color3.fromRGB(30, 30, 45),
    OFF = Color3.fromRGB(22, 22, 32)
}

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer
local TS = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

-- ============================================================
--  FUNCIÓN HTTP (COMPATIBLE CON DELTA)
-- ============================================================
local function httpGet(url)
    local HttpFunc = request or http_request or (http and http.request)
    if not HttpFunc then
        warn("❌ No hay función HTTP")
        return nil
    end

    local ok, res = pcall(function()
        return HttpFunc({ Url = url, Method = "GET" })
    end)

    if not ok then
        warn("❌ Error HTTP: " .. tostring(res))
        return nil
    end

    if res and res.StatusCode == 200 then
        return res.Body
    else
        warn("❌ Status: " .. tostring(res and res.StatusCode))
        return nil
    end
end

-- ============================================================
--  FUNCIÓN DE ERROR (CON SACUDIDA)
-- ============================================================
local function showError(box, btn, label, msg)
    label.Text = msg or "❌ Clave incorrecta"
    label.TextColor3 = Color3.fromRGB(255, 70, 70)
    local origPos = UDim2.new(box.Position.X.Scale, box.Position.X.Offset, box.Position.Y.Scale, box.Position.Y.Offset)
    for i = 1, 4 do
        local offset = (i % 2 == 0) and 8 or -8
        TS:Create(box, TweenInfo.new(0.06, Enum.EasingStyle.Linear), {
            Position = UDim2.new(origPos.X.Scale, origPos.X.Offset + offset, origPos.Y.Scale, origPos.Y.Offset)
        }):Play()
        task.wait(0.06)
    end
    TS:Create(box, TweenInfo.new(0.06), {Position = origPos}):Play()
    task.wait(0.1)
    label.Text = "🔑 Ingresa tu llave"
    label.TextColor3 = KEY_COLORS.TEXT
end

-- ============================================================
--  CREAR INTERFAZ
-- ============================================================
local function createKeyGui()
    local old = CoreGui:FindFirstChild("ChiperKeyScreen")
    if old then old:Destroy() end
    if _G._keyScreen then
        pcall(function() _G._keyScreen:Destroy() end)
        _G._keyScreen = nil
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "ChiperKeyScreen"
    screen.ResetOnSpawn = false
    screen.DisplayOrder = 100
    screen.IgnoreGuiInset = true
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(screen) end
    end)
    screen.Parent = CoreGui
    _G._keyScreen = screen -- Guardar referencia global

    -- Fondo
    local backdrop = Instance.new("Frame", screen)
    backdrop.Name = "Backdrop"
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.BorderSizePixel = 0

    -- Panel principal
    local W, H = 320, 180
    local panel = Instance.new("Frame", screen)
    panel.Name = "Panel"
    panel.Size = UDim2.new(0, W, 0, H)
    panel.Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
    panel.BackgroundColor3 = KEY_COLORS.BG
    panel.BorderSizePixel = 0
    panel.ClipsDescendants = true
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 20)

    -- Borde con gradiente
    local stroke = Instance.new("UIStroke", panel)
    stroke.Color = KEY_COLORS.ACCENT
    stroke.Thickness = 1.5
    stroke.Transparency = 0.2
    local gradStroke = Instance.new("UIGradient", stroke)
    gradStroke.Color = ColorSequence.new(KEY_COLORS.ACCENT, KEY_COLORS.ICE)
    gradStroke.Rotation = 45

    -- Título
    local title = Instance.new("TextLabel", panel)
    title.Size = UDim2.new(1, -40, 0, 36)
    title.Position = UDim2.new(0, 20, 0, 18)
    title.BackgroundTransparency = 1
    title.Text = "🌐 ACCESO AL HUB"
    title.TextColor3 = KEY_COLORS.TEXT
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    local titleGrad = Instance.new("UIGradient", title)
    titleGrad.Color = ColorSequence.new(KEY_COLORS.ACCENT, KEY_COLORS.ICE)

    -- Etiqueta
    local label = Instance.new("TextLabel", panel)
    label.Size = UDim2.new(1, -40, 0, 22)
    label.Position = UDim2.new(0, 20, 0, 62)
    label.BackgroundTransparency = 1
    label.Text = "🔑 Ingresa tu llave"
    label.TextColor3 = KEY_COLORS.TEXT
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left

    -- Caja de texto
    local box = Instance.new("TextBox", panel)
    box.Size = UDim2.new(1, -40, 0, 44)
    box.Position = UDim2.new(0, 20, 0, 92)
    box.BackgroundColor3 = KEY_COLORS.CARD
    box.BorderSizePixel = 0
    box.Text = ""
    box.PlaceholderText = "Escribe la clave..."
    box.TextColor3 = KEY_COLORS.TEXT
    box.PlaceholderColor3 = KEY_COLORS.SECONDARY
    box.Font = Enum.Font.GothamBold
    box.TextSize = 18
    box.ClearTextOnFocus = true
    box.TextXAlignment = Enum.TextXAlignment.Center
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 12)
    local boxStroke = Instance.new("UIStroke", box)
    boxStroke.Color = KEY_COLORS.ACCENT
    boxStroke.Thickness = 1.5
    boxStroke.Transparency = 0.4
    local boxGrad = Instance.new("UIGradient", boxStroke)
    boxGrad.Color = ColorSequence.new(KEY_COLORS.ACCENT, KEY_COLORS.ICE)
    boxGrad.Rotation = 0

    -- Botón ENTER
    local btn = Instance.new("TextButton", panel)
    btn.Size = UDim2.new(0, 110, 0, 44)
    btn.Position = UDim2.new(1, -130, 0, 92)
    btn.BackgroundColor3 = KEY_COLORS.ACCENT
    btn.BorderSizePixel = 0
    btn.Text = "ENTER"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBlack
    btn.TextSize = 16
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
    local btnGrad = Instance.new("UIGradient", btn)
    btnGrad.Color = ColorSequence.new(KEY_COLORS.ACCENT, KEY_COLORS.PURPLE)
    btnGrad.Rotation = 35
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Color = Color3.fromRGB(255, 180, 230)
    btnStroke.Thickness = 1
    btnStroke.Transparency = 0.4

    btn.MouseEnter:Connect(function()
        TS:Create(btnStroke, TweenInfo.new(0.12), {Transparency = 0.05}):Play()
        TS:Create(btn, TweenInfo.new(0.12), {Size = UDim2.new(0, 114, 0, 46), Position = UDim2.new(1, -134, 0, 91)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(btnStroke, TweenInfo.new(0.12), {Transparency = 0.4}):Play()
        TS:Create(btn, TweenInfo.new(0.12), {Size = UDim2.new(0, 110, 0, 44), Position = UDim2.new(1, -130, 0, 92)}):Play()
    end)

    -- ============================================================
    --  VALIDACIÓN
    -- ============================================================
    local function validateKey(input)
        label.Text = "🔄 Verificando..."
        label.TextColor3 = KEY_COLORS.ICE
        task.wait(0.3)

        local content = httpGet(GIST_RAW_URL)
        if not content then
            showError(box, btn, label, "❌ Error al conectar")
            box.Text = ""
            return
        end

        local ok, keysData = pcall(function()
            return HttpService:JSONDecode(content)
        end)

        if not ok or not keysData then
            showError(box, btn, label, "❌ Error al leer llaves")
            box.Text = ""
            return
        end

        local found = false
        for _, entry in ipairs(keysData) do
            if entry.key == input then
                found = true
                break
            end
        end

        if not found then
            showError(box, btn, label, "❌ Llave incorrecta")
            box.Text = ""
            return
        end

        -- Llave válida
        print("✅ Llave válida")
        label.Text = "✅ Acceso concedido"
        label.TextColor3 = Color3.fromRGB(34, 197, 94)

        -- Cerrar GUI
        task.wait(0.5)
        TS:Create(backdrop, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1
        }):Play()
        TS:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, -W/2, 0.5, -H/2 + 20)
        }):Play()
        task.wait(0.35)
        screen:Destroy()
        _G._keyScreen = nil

        -- Cargar hub
        local hubContent = httpGet(HUB_URL)
        if hubContent then
            local fn, err = loadstring(hubContent)
            if fn then
                fn()
            else
                warn("❌ Error compilando hub: " .. tostring(err))
            end
        else
            warn("❌ Error descargando hub")
        end
    end

    local function onValidate()
        local input = box.Text:gsub("%s+", "")
        if input == "" then
            showError(box, btn, label, "⚠️ Ingresa un código")
            return
        end
        validateKey(input)
    end

    btn.Activated:Connect(onValidate)
    box.FocusLost:Connect(function(enter)
        if enter then onValidate() end
    end)

    -- Animación de entrada
    panel.BackgroundTransparency = 1
    panel.Size = UDim2.new(0, W * 0.8, 0, H * 0.8)
    panel.Position = UDim2.new(0.5, -W * 0.4, 0.5, -H * 0.4)
    TS:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0,
        Size = UDim2.new(0, W, 0, H),
        Position = UDim2.new(0.5, -W/2, 0.5, -H/2)
    }):Play()
end

-- ============================================================
--  EJECUTAR
-- ============================================================
print("🚀 Sistema de llaves iniciado (compatible con loadstring)")
createKeyGui()
