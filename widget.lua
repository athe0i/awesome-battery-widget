local awful = require("awful")
local naughty = require("naughty")
local wibox = require("wibox")
local gears = require("gears")



local function getCommandOutput(command)
    local pipe = io.popen(command)
    local result = ''

    for line in pipe:lines() do
       result = result .. line
    end

    return result:gsub("^%s+", "") 
end

local function getIconPath(iconName)
    return string.format('/usr/share/icons/mate/scalable/status/%s.svg', iconName)
end

local function getBatteryMetric(metricName)
    local bashCommand = "upower -i $(upower -e | grep BAT) | grep --color=never -E \"" .. metricName .. "\"|xargs|cut -d':' -f2"

    return getCommandOutput(bashCommand)
end

local function getBatteryInfo()
    local batteryState = getBatteryMetric('state')
    local timeString = ''

    if batteryState == 'charging' then 
        timeString = getBatteryMetric('time to full')
    else
        timestring = getBatteryMetric('time to empty')
    end

    return string.format("Remains: %s\nPrecentage: %s", timeString, getBatteryMetric('percentage')) 
end


-- print(getBatteryInfo())
-- print(getIconPath(getBatteryMetric('icon-name')))
local notification
local function showBatteryNotification()
    notification = naughty.notify({
        text = getBatteryInfo(),
        title = "Battery Status",
        width = 200,
        timeout = 5, hover_timeout = 0.5,
    })
end


local function showBatteryWarning()
    naughty.notify{
        icon = getIconPath('battery-caution-symbolic'),
        icon_size=100,
        text = "Huston, we have a problem",
        title = "Battery is dying",
        timeout = 5, hover_timeout = 0.5,
        position = "top_right",
        bg = "#F06060",
        fg = "#EEE9EF",
        width = 300,
    }
end

local batteryWidget = wibox.widget {
    {
        id = "icon",
        widget = wibox.widget.imagebox,
        resize = false
    },
    layout = wibox.container.margin(_, 0, 0, 3)
}
batteryWidget.icon:set_image(getIconPath(getBatteryMetric('icon-name')))

gears.timer({
    timeout   = 60,
    autostart = true,
    callback  = function()
        batteryWidget.icon:set_image(getIconPath(getBatteryMetric('icon-name')))

	local percentagestr = getBatteryMetric('percentage')
	
	if percentagestr:gub('%%') < 10 then showBatteryWarning() end 
    end
})

batteryWidget:connect_signal('mouse::enter', function () showBatteryNotification() end)
batteryWidget:connect_signal('mouse::leave', function () naughty.destroy(notification) end)

return batteryWidget
