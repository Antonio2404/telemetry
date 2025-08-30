-- Этот код адаптирован для дисплея Taranis QX7
-- Для дрона BetaFPV PAVO20
-- Использует протокол Crossfire / CRSF

-- Список параметров телеметрии CRSF для отображения
local telemetryParams = {
    "1RSS",    -- Uplink - received signal strength antenna 1 (RSSI)
    "2RSS",    -- Uplink - received signal strength antenna 2 (RSSI) 
    "RQLY",    -- Uplink - link quality (valid packets)
    "RSNR",    -- Uplink - signal-to-noise ratio
    "ANT",     -- Antenna
    "RFMD",    -- Uplink - update rate
    "TPWR",    -- Uplink - transmitting power
    "TRSS",    -- Downlink - signal strength antenna (radio controller)
    "TQLY",    -- Downlink - link quality (valid packets)
    "TSNR",    -- Downlink - signal-to-noise ratio
    "GPS",     -- GPS Coordinates
    "GSpd",    -- GPS ground speed
    "Hdg",     -- Magnetic orientation / heading
    "Alt",     -- GPS Altitude
    "Sats",    -- GPS Satellites acquired
    "RxBt",    -- Battery voltage
    "Curr",    -- Current draw
    "Capa",    -- Current consumption
    "Bat%",    -- Battery remaining
    "Ptch",    -- FC pitch angle
    "Roll",    -- FC roll angle
    "Yaw",     -- FC yaw angle
    "FM"       -- Flight mode
}

-- Единицы измерения для каждого параметра
local units = {
    ["1RSS"] = "dB",
    ["2RSS"] = "dB",
    ["RQLY"] = "%",
    ["RSNR"] = "dB",
    ["ANT"] = "",
    ["RFMD"] = "Hz",
    ["TPWR"] = "mW",
    ["TRSS"] = "dB",
    ["TQLY"] = "%",
    ["TSNR"] = "dB",
    ["GPS"] = "",
    ["GSpd"] = "km/h",
    ["Hdg"] = "°",
    ["Alt"] = "m",
    ["Sats"] = "",
    ["RxBt"] = "V",
    ["Curr"] = "A",
    ["Capa"] = "mAh",
    ["Bat%"] = "%",
    ["Ptch"] = "°",
    ["Roll"] = "°",
    ["Yaw"] = "°",
    ["FM"] = ""
}

-- Русские названия параметров
local russianNames = {
    ["1RSS"] = "Уровень сигнала (антенна 1)",
    ["2RSS"] = "Уровень сигнала (антенна 2)",
    ["RQLY"] = "Качество связи (приём)",
    ["RSNR"] = "Соотношение сигнал/шум (приём)",
    ["ANT"] = "Активная антенна",
    ["RFMD"] = "Скорость передачи",
    ["TPWR"] = "Мощность передачи",
    ["TRSS"] = "Уровень сигнала (телеметрия)",
    ["TQLY"] = "Качество связи (телеметрия)",
    ["TSNR"] = "Соотношение сигнал/шум (телеметрия)",
    ["GPS"] = "Координаты GPS",
    ["GSpd"] = "Скорость над землей",
    ["Hdg"] = "Курс (магнитный)",
    ["Alt"] = "Высота (по GPS)",
    ["Sats"] = "Кол-во спутников GPS",
    ["RxBt"] = "Напряжение аккумулятора",
    ["Curr"] = "Потребляемый ток",
    ["Capa"] = "Ёмкость потрачена",
    ["Bat%"] = "Остаток заряда батареи",
    ["Ptch"] = "Тангаж",
    ["Roll"] = "Крен",
    ["Yaw"] = "Рыскание",
    ["FM"] = "Режим полёта"
}

-- Функция для получения значения телеметрии
local function getTelemetryValue(param)
    local value = getValue(param)
    if value == nil then
        return "N/A"
    end

    -- Специальная обработка для некоторых параметров
    if param == "RFMD" then
        -- Преобразование числового значения в частоту
        if value == 0 then return "4" end
        if value == 1 then return "50" end
        if value == 2 then return "150" end
        return tostring(value)
    elseif param == "FM" then
        -- Преобразование кодов режимов полета в читаемый вид
        local fmCodes = {
            ["!FS"] = "Failsafe",
            ["RTH"] = "Return To Home",
            ["MANU"] = "Manual",
            ["ACRO"] = "Acro",
            ["STAB"] = "Stabilize",
            ["HOR"] = "Horizon",
            ["AIR"] = "Air Mode",
            ["WAIT"] = "Waiting GPS"
        }
        return fmCodes[tostring(value)] or tostring(value)
    elseif param == "GPS" then
        -- Обработка GPS координат
        local lat = getValue("GPS-Lat")
        local lon = getValue("GPS-Lon")
        if lat and lon then
            return string.format("%.6f, %.6f", lat, lon)
        else
            return "No GPS"
        end
    end

    return tostring(value)
end

-- Функция для отображения всех параметров телеметрии
local function displayAllTelemetry()
    local y_pos = 5
    local line_height = 8

    lcd.drawText(5, 2, "CRSF TELEMETRY VALUES", DBLSIZE)

    for i, param in ipairs(telemetryParams) do
        local value = getTelemetryValue(param)
        local unit = units[param] or ""
        local name = russianNames[param] or param

        -- Форматирование строки: Параметр - Значение Единица
        local displayText = string.format("%s - %s %s", param, value, unit)

        -- Отображение на экране
        lcd.drawText(5, y_pos, displayText, SMLSIZE)

        y_pos = y_pos + line_height

        -- Если экран заполнен, выходим из цикла
        if y_pos > 60 then
            lcd.drawText(5, y_pos, "...and more", SMLSIZE)
            break
        end
    end
end

-- Функция для отображения по группам (постранично)
local function displayTelemetryGroups()
    local groups = {
        {"1RSS", "2RSS", "RQLY", "RSNR", "ANT", "RFMD", "TPWR"},
        {"TRSS", "TQLY", "TSNR", "GPS", "GSpd", "Hdg", "Alt", "Sats"},
        {"RxBt", "Curr", "Capa", "Bat%", "Ptch", "Roll", "Yaw", "FM"}
    }

    local y_pos = 5
    lcd.drawText(5, 2, "CRSF TELEMETRY GROUP " .. currentGroup, DBLSIZE)

    for i, param in ipairs(groups[currentGroup]) do
        local value = getTelemetryValue(param)
        local unit = units[param] or ""

        local displayText = string.format("%s - %s %s", param, value, unit)
        lcd.drawText(5, y_pos, displayText, SMLSIZE)

        y_pos = y_pos + 8
    end
end

-- Переменные для управления отображением
local currentView = 1  -- 1: все параметры, 2: по группам
local currentGroup = 1  -- текущая группа параметров
local lastSwitchTime = 0

-- Основная функция выполнения
local function run(event)
    lcd.clear()

    -- Обработка событий переключения
    if event == EVT_ROT_RIGHT or event == EVT_ROT_LEFT then
        if currentView == 2 then
            if event == EVT_ROT_RIGHT then
                currentGroup = (currentGroup % 3) + 1
            else
                currentGroup = ((currentGroup - 2) % 3) + 1
            end
            lastSwitchTime = getTime()
        end
    end

    -- Отображение в зависимости от текущего режима
    if currentView == 1 then
        displayAllTelemetry()
    else
        displayTelemetryGroups()
    end

    -- Отображение подсказки
    lcd.drawText(5, 57, "Rotate to switch", SMLSIZE)
end

-- Функция инициализации
local function init()
    currentGroup = 1
    currentView = 1
    lastSwitchTime = getTime()
end

return {run = run, init = init}