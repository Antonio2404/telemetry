-- This code is an Adapted for Taranis QX7 display 
-- BetaFPV PAVO20
-- Crossfire protocol / CRSF

--1RSS -- Uplink - received signal strength antenna 1 (RSSI) | Уровень сигнала (антенна 1, приём) | дБ
--2RSS --  Uplink - received signal strength antenna 2 (RSSI) | Уровень сигнала (антенна 2, приём) | дБ
--RQLY --  Uplink - link quality (valid packets) | Качество связи (приём) / % годных пакетов | %
--RSNR --  Uplink - signal-to-noise ratio | Соотношение сигнал/шум (С/Ш, приём) | дБ
--ANT --  Antenna | Активная антенна | raw
--RFMD --  Uplink - update rate; 0 = 4Hz; 1 = 50Hz; 2 = 150Hz | Скорость передачи (Uplink) | raw (0=4Гц, 1=50Гц, 2=150Гц)
--TPWR --  Uplink - transmitting power | Мощность передачи (Uplink) | мВт
--TRSS --  Downlink - signal strength antenna (radio controller) | Уровень сигнала (телеметрия, приём на пульт) | дБ
--TQLY --  Downlink - link quality (valid packets) | Качество связи (телеметрия) / % годных пакетов | %
--TSNR --  Downlink - signal-to-noise ratio | Соотношение сигнал/шум (С/Ш, телеметрия) | дБ
--GPS --  GPS Coordinates | Координаты GPS | шир. + долг.
--GSpd --  GPS ground speed | Скорость над землей (GS) | км/ч
--Hdg --  Magnetic orientation / heading | Курс (магнитный) | град.
--Alt --  GPS Altitudes | Высота (по GPS) | м
--Sats --  GPS Satellites acquired | Кол-во спутников GPS | raw
--RxBt --  Battery voltage | Напряжение аккумулятора (приёмник) | В
--Curr --  Current draw | Потребляемый ток | А
--Capa --  Current consumption | Ёмкость потрачена / Разряд | мА·ч
--Bat% -- Battery remaining | Остаток заряда батареи | %
--Ptch --  FC pitch angle | Тангаж (от полётного контроллера) | град.
--Roll --  FC roll angle | Крен (от полётного контроллера) | град.
--Yaw --  FC yaw angle | Рыскание (от полётного контроллера) | град.
--FM --  Flight mode | Режим полёта | (см. ниже)

--!FS --  Failsafe mode | Режим отказа (Failsafe)
--RTH --  Return To Home mode | Режим «Возврат домой» (RTH)
--MANU --  Passthru mode | Ручной режим (MANU)
--ACRO --  ACRO mode | Акро режим (ACRO)
--STAB --  Angle mode | Стабилизированный режим (STAB/ANGLE)
--HOR --  Horizon mode | Режим «Горизонт» (HORIZON)
--AIR --  Air mode | Режим «Air» (для 3D-полёта)
--WAIT --  Wait for GPS lock | Ожидание GPS-фиксации
--**appended *** FC is not ARMED | Полётный контроллер НЕ взведён (DISARMED)

-- Функция для округления чисел с заданной точностью
-- @param num число для округления
-- @param decimals количество знаков после запятой (по умолчанию 0)
-- @return округленное число
local function round(num, decimals)
  local mult = 10^(decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

---- Настройка экрана
-- Координаты верхнего левого угла
local min_x, min_y = 0, 0
-- Координаты нижнего правого угла
local max_x, max_y = 128, 63
-- Высота заголовка (если нужен)
local header_height = 0
-- Границы сетки по горизонтали (отступы слева и справа)
local grid_limit_left, grid_limit_right = 20, 108
-- Расчет размеров сетки
local grid_width = round((max_x - (max_x - grid_limit_right) - grid_limit_left), 0)
local grid_height = round(max_y - min_y - header_height)
local grid_middle = round((grid_width / 2) + grid_limit_left, 0)
local cell_height = round(grid_height / 3, 0)

-- Настройки батареи
local max_batt = 4.2  -- Максимальное напряжение банки
local min_batt = 3.3  -- Минимальное напряжение банки
local total_max_bat = 0  -- Максимальное зарегистрированное напряжение
local total_min_bat = 5  -- Минимальное зарегистрированное напряжение банки
local total_max_curr = 0 -- Максимальный зарегистрированный ток

-- Настройки RSSI
local max_rssi = 90  -- Максимальный уровень RSSI
local min_rssi = 45  -- Минимальный уровень RSSI

-- ПЕРЕКЛЮЧАТЕЛИ (ПРОВЕРЬТЕ НАЗВАНИЯ В НАСТРОЙКАХ МОДЕЛИ РАДИО!)
local SW_FMODE = 'sa'  -- Переключатель режимов полета
local SW_ARM = 'sf'    -- Переключатель взведения (Arm)
local SW_LED = 'sc'    -- Переключатель подсветки (LED)

-- Источники данных для ELRS + Betaflight
local DS_VFAS = 'BAT%'        -- Общее напряжение батареи
local DS_AMP = 'Curr'         -- Ток потребления
local DS_CELL = 'Cell'        -- Напряжение на банке (среднее)
local DS_CELL_MIN = 'Cell-'   -- Минимальное напряжение на банке
local DS_RSSI = '1RSS'        -- Текущее значение RSSI

-- Функция инициализации (пустая)
local function init_func()
  -- Код инициализации может быть добавлен здесь при необходимости
end

-- Функция отрисовки сетки интерфейса
-- @param lines количество линий (не используется)
-- @param cols количество колонок (не используется)
local function drawGrid(lines, cols)
  -- Линии ограничения сетки
  ---- Границы таблицы
  lcd.drawLine(grid_limit_left, min_y, grid_limit_right, min_y, SOLID, FORCE)
  lcd.drawLine(grid_limit_left, min_y, grid_limit_left, max_y, SOLID, FORCE)
  lcd.drawLine(grid_limit_right, min_y, grid_limit_right, max_y, SOLID, FORCE)
  lcd.drawLine(grid_limit_left, max_y, grid_limit_right, max_y, SOLID, FORCE)
  ---- Заголовок
  lcd.drawLine(grid_limit_left, min_y + header_height, grid_limit_right, min_y + header_height, SOLID, FORCE)
  ---- Сетка
  ------ Вертикальная линия посередине
  lcd.drawLine(grid_middle, min_y + header_height, grid_middle, max_y, SOLID, FORCE)
  ------ Горизонтальные линии между ячейками
  lcd.drawLine(grid_limit_left, cell_height + header_height - 2, grid_limit_right, cell_height + header_height -2, SOLID, FORCE)
  lcd.drawLine(grid_limit_left, cell_height * 2 + header_height - 1, grid_limit_right, cell_height * 2 + header_height - 1, SOLID, FORCE)
end

-- Функция отрисовки индикатора батареи
local function drawBatt()
  local batt = getValue(DS_VFAS)      -- Общее напряжение
  local cell = getValue(DS_CELL)      -- Напряжение банки
  local curr = getValue(DS_AMP)       -- Ток потребления
  local data_min_batt = getValue(DS_CELL_MIN)  -- Минимальное напряжение банки

  -- Обработка невалидных значений телеметрии
  if batt == nil or batt == 0 then batt = 0 end
  if cell == nil or cell == 0 then cell = 0 end
  if curr == nil then curr = 0 end
  if data_min_batt == nil then data_min_batt = 0 end

  -- Обновление максимального напряжения батареи
  if total_max_bat < batt and batt > 0 then
    if batt < 10 then
      total_max_bat = round(batt, 2)
    else
      total_max_bat = round(batt, 1)
    end
  end

  -- Расчет количества банок
  local cell_count = 0
  if batt > 0 and cell > 0 then
    cell_count = math.floor(batt / cell + 0.5) -- Округление до ближайшего целого
  end

  -- Проверка валидности количества банок и расчет напряжения на банке
  if cell_count >= 1 and cell_count <= 6 then
    cell = batt / cell_count
  else
    cell = 0
    cell_count = 0
  end

  -- Обновление максимального тока
  if total_max_curr < curr then
    total_max_curr = round(curr, 1)
  end

  -- Обновление минимального напряжения банки
  if data_min_batt > 0 then
    if total_min_bat > data_min_batt then
      total_min_bat = round(data_min_batt, 2)
    end
  end

  -- Расчет уровня заполнения индикатора
  local total_steps = 30
  local range = max_batt - min_batt
  local step_size = range/total_steps
  local current_level = math.floor(total_steps - ((cell - min_batt) / step_size))

  -- Ограничение уровня в пределах 0-30
  if current_level > 30 then current_level = 30 end
  if current_level < 0 then current_level = 0 end

  -- Отрисовка графического индикатора батареи
  lcd.drawFilledRectangle(6, 2, 8, 4, SOLID)  -- Верхний контакт
  lcd.drawFilledRectangle(3, 5, 14, 32, SOLID)  -- Корпус батареи
  lcd.drawFilledRectangle(4, 6, 12, current_level, ERASE)  -- Уровень заряда

  -- Отображение значений
  lcd.drawText(2, 39, round(cell, 2), SMLSIZE)  -- Напряжение на банке
  if batt < 10 then
    lcd.drawText(2, 48, round(batt, 2), SMLSIZE)  -- Общее напряжение
  else
    lcd.drawText(2, 48, round(batt, 1), SMLSIZE)
  end

  lcd.drawText(1, 57, "Vbat", INVERS + SMLSIZE)  -- Подпись

  -- Отображение количества банок и статистики
  lcd.drawText(grid_limit_left + 4, min_y + header_height + cell_height * 2 + 3, cell_count .. "S", DBLSIZE)
  lcd.drawText(grid_limit_left + 27, min_y + header_height + cell_height * 2 + 3, round(total_min_bat, 2), SMLSIZE)  -- Min напряжение
  lcd.drawText(grid_limit_left + 27, min_y + header_height + cell_height * 2 + 3 + 9, round(total_max_curr, 1), SMLSIZE)  -- Max ток
end

-- Функция отрисовки индикатора RSSI
local function drawRSSI()
  local rssi = getValue(DS_RSSI)  -- Получение значения RSSI

  -- Обработка невалидных значений RSSI
  if rssi == nil then rssi = 0 end

  -- Ограничение значения RSSI в диапазоне 45-90
  local CLAMPrssi = rssi
  if rssi < 45 then
    CLAMPrssi = 45
  elseif rssi > 90 then
    CLAMPrssi = 90
  end

  -- Расчет уровня заполнения индикатора
  local total_steps = 30
  local range = max_rssi - min_rssi
  local step_size = range/total_steps
  local current_level = math.floor(total_steps - ((CLAMPrssi - min_rssi) / step_size))

  -- Отрисовка графического индикатора RSSI
  lcd.drawFilledRectangle(111, 4, 14, 32, SOLID)  -- Корпус индикатора
  lcd.drawFilledRectangle(112, 5, 12, current_level, ERASE)  -- Уровень сигнала

  -- Отображение текущего значения RSSI
  if rssi >= 100 then
    lcd.drawText(111, 42, round(rssi, 0), SMLSIZE)
  else
    lcd.drawText(110, 38, round(rssi, 0), DBLSIZE)
  end

  lcd.drawText(109, 57, "rssi", INVERS + SMLSIZE)  -- Подпись
end

-- Ячейка 1 (верхняя левая) - Режим полета
local function cell_1()
  local x1 = grid_limit_left + 1
  local y1 = min_y + header_height - 2

  -- Определение режима полета по переключателю
  local f_mode = "UNKN"  -- По умолчанию неизвестно
  local fm = getValue(SW_FMODE)  -- Получение значения переключателя

  if fm < -1000 then
    f_mode = "ANGL"  -- Angle mode (Стабилизация)
  elseif fm > 1000 then
    f_mode = "ACRO"  -- Acro mode (Акробатический)
  else
    f_mode = "HRZN"  -- Horizon mode (Горизонт)
  end

  -- Отображение режима полета
  lcd.drawText(x1 + 4, y1 + 6, f_mode, MIDSIZE)
end

-- Ячейка 2 (средняя левая) - Статус переключателей
local function cell_2()
  local x1 = grid_limit_left + 1
  local y1 = min_y + header_height + cell_height - 1

  local armed = getValue(SW_ARM)    -- Взведение (Arm)
  local ledmode = getValue(SW_LED)  -- Режим подсветки

  -- Обработка значений переключателей
  if armed == nil then armed = 0 end
  if ledmode == nil then ledmode = 0 end
  if failsafe == nil then failsafe = 0 end
  if bbox == nil then bbox = 0 end
  if beepr == nil then beepr = 0 end

  if failsafe < 0 then
    -- Нормальный режим (не failsafe)

    -- Переключатель Arm
    if armed < 10 then
      lcd.drawText(x1 + 3, y1 + 2, "Arm", SMLSIZE)  -- Не взведен
    else
      lcd.drawText(x1 + 3, y1 + 2, "Arm", INVERS + SMLSIZE)  -- Взведен (инверсный)
    end

    -- Переключатель Air mode
    if ledmode < -10 then
      lcd.drawText(x1 + 25, y1 + 2, "Air", SMLSIZE)  -- Выключен
    else
      lcd.drawText(x1 + 25, y1 + 2, "Air", INVERS + SMLSIZE)  -- Включен
    end

    -- Переключатель Bbx (предположительно Blackbox)
    if bbox < -10 then
      lcd.drawText(x1 + 3, y1 + 12, "Bbx", SMLSIZE)  -- Выключен
    else
      lcd.drawText(x1 + 3, y1 + 12, "Bbx", INVERS + SMLSIZE)  -- Включен
    end

    -- Переключатель Bpr (предположительно Beeper - пищалка)
    if beepr < 10 then
      lcd.drawText(x1 + 25, y1 + 12, "Bpr", SMLSIZE)  -- Выключен
    else
      lcd.drawText(x1 + 25, y1 + 12, "Bpr", INVERS + SMLSIZE)  -- Включен
    end
  else
    -- Активен режим Failsafe
    lcd.drawFilledRectangle(x1, y1, (grid_limit_right - grid_limit_left) / 2, cell_height, DEFAULT)
    lcd.drawText(x1 + 2, y1 + 2, "FailSafe", SMLSIZE + INVERS + BLINK)  -- Мигающая надпись
  end
end

-- Ячейка 4 (верхняя правая) - Текущее время
local function cell_4()
  local x1 = grid_middle + 1
  local y1 = min_y + header_height + 1

  local datenow = getDateTime()  -- Получение текущего времени
  -- Форматирование и отображение времени ЧЧ:ММ:СС
  lcd.drawText(x1 + 4, y1 + 6, string.format("%02d:%02d:%02d", datenow.hour, datenow.min, datenow.sec), SMLSIZE)
end

-- Ячейка 5 (средняя правая) - Таймер 1
local function cell_5()
  local x1 = grid_middle + 1
  local y1 = min_y + header_height + cell_height + 1

  lcd.drawText(x1, y1, "T1", INVERS)  -- Заголовок таймера

  -- Получение и отображение значения таймера
  local timer = model.getTimer(0)
  if timer then
    local s = timer.value
    local time = string.format("%02d:%02d", math.floor(s/60), s%60)  -- Формат ММ:СС
    lcd.drawText(x1 + 4, y1 + 10, time, SMLSIZE)
  end
end

-- Ячейка 6 (нижняя правая) - Таймер 2
local function cell_6()
  local x1 = grid_middle + 1
  local y1 = min_y + header_height + cell_height * 2 + 1

  lcd.drawText(x1, y1, "T2", INVERS)  -- Заголовок таймера

  -- Получение и отображение значения таймера
  local timer = model.getTimer(1)
  if timer then
    local s = timer.value
    local time = string.format("%02d:%02d", math.floor(s/60), s%60)  -- Формат ММ:СС
    lcd.drawText(x1 + 4, y1 + 10, time, SMLSIZE)
  end
end

-- Основная функция выполнения (вызывается постоянно)
-- @param event событие (не используется в этой версии)
local function run(event)
  lcd.clear()  -- Очистка экрана
  drawGrid()   -- Отрисовка сетки
  cell_1()     -- Режим полета
  cell_2()     -- Статус переключателей
  cell_4()     -- Время
  cell_5()     -- Таймер 1
  cell_6()     -- Таймер 2
  drawBatt()   -- Батарея
  drawRSSI()   -- Уровень сигнала
end

-- Возврат функций для использования системой
return {run = run, init = init_func}