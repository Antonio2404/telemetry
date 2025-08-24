
-- function to round values to 2 decimal of precision
local function round(num, decimals)
  local mult = 10^(decimals or 0)
  return math.floor(num * mult + 0.5) / mult
end

---- Screen setup
-- top left pixel coordinates
local min_x, min_y = 0, 0 
-- bottom right pixel coordinates
local max_x, max_y = 128, 63 
-- set to create a header, the grid will adjust automatically but not its content
local header_height = 0  
-- set the grid left and right coordinates; leave space left and right for batt and rssi
local grid_limit_left, grid_limit_right = 20, 108 
-- calculated grid dimensions
local grid_width = round((max_x - (max_x - grid_limit_right) - grid_limit_left), 0)
local grid_height = round(max_y - min_y - header_height)
local grid_middle = round((grid_width / 2) + grid_limit_left, 0)
local cell_height = round(grid_height / 3, 0)

-- Batt
local max_batt = 4.2
local min_batt = 3.3
local total_max_bat = 0
local total_min_bat = 5
local total_max_curr = 0

-- RSSI
local max_rssi = 90
local min_rssi = 45

-- SWITCHES
local SW_FMODE = 'sa'
local SW_ARM = 'sf'
local SW_LED = 'sc'

-- DATA SOURCES
local DS_VFAS = 'VFAS'        
local DS_AMP = 'Curr'        
local DS_CELL = 'Cell'        
local DS_CELL_MIN = 'Cell-'   
local DS_RSSI = 'RSSI'        
local DS_RSSI_MIN = 'RSSI-'   

-- Empty init function
local function init_func()
end

local function drawGrid(lines, cols)
  -- Grid limiter lines
  ---- Table Limits
  lcd.drawLine(grid_limit_left, min_y, grid_limit_right, min_y, SOLID, FORCE)
  lcd.drawLine(grid_limit_left, min_y, grid_limit_left, max_y, SOLID, FORCE)
  lcd.drawLine(grid_limit_right, min_y, grid_limit_right, max_y, SOLID, FORCE)
  lcd.drawLine(grid_limit_left, max_y, grid_limit_right, max_y, SOLID, FORCE)
  ---- Header
  lcd.drawLine(grid_limit_left, min_y + header_height, grid_limit_right, min_y + header_height, SOLID, FORCE)
  ---- Grid
  ------ Top
  lcd.drawLine(grid_middle, min_y + header_height, grid_middle, max_y, SOLID, FORCE)
  ------ Hrznt Line 1
  lcd.drawLine(grid_limit_left, cell_height + header_height - 2, grid_limit_right, cell_height + header_height -2, SOLID, FORCE)
  lcd.drawLine(grid_limit_left, cell_height * 2 + header_height - 1, grid_limit_right, cell_height * 2 + header_height - 1, SOLID, FORCE)
end

-- Draw the battery indicator
local function drawBatt()
  local batt = getValue(DS_VFAS)
  local cell = getValue(DS_CELL)
  local curr = getValue(DS_AMP)
  local data_min_batt = getValue(DS_CELL_MIN)

  -- Handle invalid telemetry values
  if batt == nil or batt == 0 then batt = 0 end
  if cell == nil or cell == 0 then cell = 0 end
  if curr == nil then curr = 0 end
  if data_min_batt == nil then data_min_batt = 0 end

  -- Update maximum battery voltage
  if total_max_bat < batt and batt > 0 then
    if batt < 10 then
      total_max_bat = round(batt, 2)
    else
      total_max_bat = round(batt, 1)
    end 
  end
  
  -- Calculate cell count
  local cell_count = 0
  if batt > 0 and cell > 0 then
    cell_count = math.floor(batt / cell + 0.5) -- Round to nearest integer
  end
  
  -- Validate cell count and calculate cell voltage
  if cell_count >= 1 and cell_count <= 6 then
    cell = batt / cell_count
  else
    cell = 0
    cell_count = 0
  end
  
  -- Update maximum current
  if total_max_curr < curr then
     total_max_curr = round(curr, 1)
  end
  
  -- Update minimum cell voltage
  if data_min_batt > 0 then   
    if total_min_bat > data_min_batt then
      total_min_bat = round(data_min_batt, 2)
    end
  end
    
  -- Calculate the size of the level
  local total_steps = 30 
  local range = max_batt - min_batt
  local step_size = range/total_steps
  local current_level = math.floor(total_steps - ((cell - min_batt) / step_size))
  
  if current_level > 30 then current_level = 30 end
  if current_level < 0 then current_level = 0 end
  
  -- Draw graphic battery level
  lcd.drawFilledRectangle(6, 2, 8, 4, SOLID)
  lcd.drawFilledRectangle(3, 5, 14, 32, SOLID)
  lcd.drawFilledRectangle(4, 6, 12, current_level, ERASE)
    
  -- Values
  lcd.drawText(2, 39, round(cell, 2), SMLSIZE)
  if batt < 10 then
    lcd.drawText(2, 48, round(batt, 2), SMLSIZE)
  else
    lcd.drawText(2, 48, round(batt, 1), SMLSIZE)
  end
  
  lcd.drawText(1, 57, "Vbat", INVERS + SMLSIZE)
  
  -- Display cell count and statistics
  lcd.drawText(grid_limit_left + 4, min_y + header_height + cell_height * 2 + 3, cell_count .. "S", DBLSIZE)
  lcd.drawText(grid_limit_left + 27, min_y + header_height + cell_height * 2 + 3, round(total_min_bat, 2), SMLSIZE)
  lcd.drawText(grid_limit_left + 27, min_y + header_height + cell_height * 2 + 3 + 9, round(total_max_curr, 1), SMLSIZE)
end

local function drawRSSI()
  local rssi = getValue(DS_RSSI)
  
  -- Handle invalid RSSI values
  if rssi == nil then rssi = 0 end
  
  local CLAMPrssi = rssi
  if rssi < 45 then
    CLAMPrssi = 45
  elseif rssi > 90 then
    CLAMPrssi = 90
  end
    
  local total_steps = 30
  local range = max_rssi - min_rssi
  local step_size = range/total_steps
  local current_level = math.floor(total_steps - ((CLAMPrssi - min_rssi) / step_size))

  -- Draw graphic RSSI level
  lcd.drawFilledRectangle(111, 4, 14, 32, SOLID)
  lcd.drawFilledRectangle(112, 5, 12, current_level, ERASE)

  -- Display current RSSI value
  if rssi >= 100 then
    lcd.drawText(111, 42, round(rssi, 0), SMLSIZE)
  else
    lcd.drawText(110, 38, round(rssi, 0), DBLSIZE)
  end
  
  lcd.drawText(109, 57, "rssi", INVERS + SMLSIZE)
end

-- Top Left cell -- Flight mode
local function cell_1()
  local x1 = grid_limit_left + 1
  local y1 = min_y + header_height - 2

  -- FMODE
  local f_mode = "UNKN"
  local fm = getValue(SW_FMODE)
  
  if fm < -1000 then
    f_mode = "ANGL"
  elseif fm > 1000 then
    f_mode = "ACRO"
  else
    f_mode = "HRZN"
  end
  
  lcd.drawText(x1 + 4, y1 + 6, f_mode, MIDSIZE)
end

-- Middle left cell -- Switch statuses (enabled, disabled)
local function cell_2()
  local x1 = grid_limit_left + 1
  local y1 = min_y + header_height + cell_height - 1

  local armed = getValue(SW_ARM)    -- arm
  local ledmode = getValue(SW_LED)  -- ledmode
 
  -- Handle switch values
  if armed == nil then armed = 0 end
  if ledmode == nil then ledmode = 0 end
  if failsafe == nil then failsafe = 0 end
  if bbox == nil then bbox = 0 end
  if beepr == nil then beepr = 0 end

  if failsafe < 0 then
    -- Normal operation (not failsafe)
    if armed < 10 then
      lcd.drawText(x1 + 3, y1 + 2, "Arm", SMLSIZE)
    else
      lcd.drawText(x1 + 3, y1 + 2, "Arm", INVERS + SMLSIZE)
    end

    if ledmode < -10 then
      lcd.drawText(x1 + 25, y1 + 2, "Air", SMLSIZE)
    else
      lcd.drawText(x1 + 25, y1 + 2, "Air", INVERS + SMLSIZE)
    end
    
    if bbox < -10 then
      lcd.drawText(x1 + 3, y1 + 12, "Bbx", SMLSIZE)
    else
      lcd.drawText(x1 + 3, y1 + 12, "Bbx", INVERS + SMLSIZE)
    end

    if beepr < 10 then
      lcd.drawText(x1 + 25, y1 + 12, "Bpr", SMLSIZE)
    else
      lcd.drawText(x1 + 25, y1 + 12, "Bpr", INVERS + SMLSIZE)
    end
  else
    -- Failsafe active
    lcd.drawFilledRectangle(x1, y1, (grid_limit_right - grid_limit_left) / 2, cell_height, DEFAULT)
    lcd.drawText(x1 + 2, y1 + 2, "FailSafe", SMLSIZE + INVERS + BLINK)
  end
end

-- Top Right cell -- Current time
local function cell_4() 
  local x1 = grid_middle + 1
  local y1 = min_y + header_height + 1

  local datenow = getDateTime()
  lcd.drawText(x1 + 4, y1 + 6, string.format("%02d:%02d:%02d", datenow.hour, datenow.min, datenow.sec), SMLSIZE)
end

-- Center right cell -- Timer1
local function cell_5() 
  local x1 = grid_middle + 1
  local y1 = min_y + header_height + cell_height + 1

  lcd.drawText(x1, y1, "T1", INVERS)

  -- Show timer
  local timer = model.getTimer(0)
  if timer then
    local s = timer.value
    local time = string.format("%02d:%02d", math.floor(s/60), s%60)
    lcd.drawText(x1 + 4, y1 + 10, time, SMLSIZE)
  end
end

-- Bottom right cell -- Timer2
local function cell_6() 
  local x1 = grid_middle + 1
  local y1 = min_y + header_height + cell_height * 2 + 1

  lcd.drawText(x1, y1, "T2", INVERS)
  
  -- Show timer
  local timer = model.getTimer(1)
  if timer then
    local s = timer.value
    local time = string.format("%02d:%02d", math.floor(s/60), s%60)
    lcd.drawText(x1 + 4, y1 + 10, time, SMLSIZE)
  end
end

-- Execute
local function run(event)
  lcd.clear()
  drawGrid()
  cell_1()
  cell_2()
  cell_4()
  cell_5()
  cell_6()
  drawBatt()
  drawRSSI()
end

return {run = run, init = init_func}