#!/usr/bin/env python3
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  #
# original code https://gist.github.com/Surendrajat/ff3876fd2166dd86fb71180f4e9342d7
# weather using python
import requests
import json
import os
from datetime import datetime

# weather icons (UNCHANGED)
weather_icons = {
    "sunnyDay": "󰖙",
    "clearNight": "󰖔",
    "cloudyFoggyDay": "",
    "cloudyFoggyNight": "",
    "rainyDay": "",
    "rainyNight": "",
    "snowyIcyDay": "",
    "snowyIcyNight": "",
    "severe": "",
    "default": "",
}

# --------------------------------------------------
# Get current location based on IP
# --------------------------------------------------
def get_location():
    data = requests.get("https://ipinfo.io/json", timeout=5).json()
    lat, lon = data["loc"].split(",")
    return float(lat), float(lon)

latitude, longitude = get_location()

# --------------------------------------------------
# Open-Meteo API
# --------------------------------------------------
url = (
    "https://api.open-meteo.com/v1/forecast"
    f"?latitude={latitude}&longitude={longitude}"
    "&current_weather=true"
    "&daily=temperature_2m_max,temperature_2m_min"
    "&hourly=relativehumidity_2m,visibility,precipitation_probability"
    "&timezone=auto"
)

data = requests.get(url, timeout=10).json()

current = data["current_weather"]
daily = data["daily"]
hourly = data["hourly"]

# --------------------------------------------------
# Weather code → icon mapping (USES ALL ICONS)
# --------------------------------------------------
def get_icon(weathercode, is_day):
    if weathercode == 0:
        return weather_icons["sunnyDay"] if is_day else weather_icons["clearNight"]

    if weathercode in (1, 2, 3, 45, 48):
        return weather_icons["cloudyFoggyDay"] if is_day else weather_icons["cloudyFoggyNight"]

    if weathercode in (51, 53, 55, 61, 63, 65, 80, 81, 82):
        return weather_icons["rainyDay"] if is_day else weather_icons["rainyNight"]

    if weathercode in (71, 73, 75, 77, 85, 86):
        return weather_icons["snowyIcyDay"] if is_day else weather_icons["snowyIcyNight"]

    if weathercode in (95, 96, 99):
        return weather_icons["severe"]

    return weather_icons["default"]

# --------------------------------------------------
# Extract values
# --------------------------------------------------
temp = f"{int(current['temperature'])}°C"
wind_speed = f"{int(current['windspeed'])} km/h"
status_code = str(current["weathercode"])
is_day = current["is_day"] == 1
icon = get_icon(current["weathercode"], is_day)

status_map = {
    0: "Clear",
    1: "Mainly Clear",
    2: "Partly Cloudy",
    3: "Overcast",
    45: "Fog",
    48: "Fog",
    51: "Light Drizzle",
    53: "Drizzle",
    55: "Heavy Drizzle",
    61: "Rain",
    63: "Rain",
    65: "Heavy Rain",
    71: "Snow",
    73: "Snow",
    75: "Heavy Snow",
    77: "Snow Grains",
    80: "Rain Showers",
    81: "Rain Showers",
    82: "Heavy Showers",
    95: "Thunderstorm",
    96: "Thunderstorm",
    99: "Thunderstorm",
}

status = status_map.get(current["weathercode"], "Unknown")
status = f"{status[:16]}.." if len(status) > 17 else status

# feels-like approximation
temp_feel_text = f"Feels like {temp}"

# min / max
temp_min = f"{int(daily['temperature_2m_min'][0])}°C"
temp_max = f"{int(daily['temperature_2m_max'][0])}°C"
temp_min_max = f"  {temp_min}\t\t  {temp_max}"

# humidity / visibility / rain
humidity = f"{hourly['relativehumidity_2m'][0]}%"
humidity_text = f"  {humidity}"

visibility = f"{hourly['visibility'][0] / 1000:.1f} km"
visibility_text = f"  {visibility}"

rain_chance = f"{hourly['precipitation_probability'][0]}%"
prediction = f"\n\n (hourly) {rain_chance}"

wind_text = f"  {wind_speed}"

air_quality_index = "N/A"

# --------------------------------------------------
# Tooltip (UNCHANGED STYLE)
# --------------------------------------------------
tooltip_text = str.format(
    "\t\t{}\t\t\n{}\n{}\n{}\n\n{}\n{}\n{}{}",
    f'<span size="xx-large">{temp}</span>',
    f"<big> {icon}</big>",
    f"<b>{status}</b>",
    f"<small>{temp_feel_text}</small>",
    f"<b>{temp_min_max}</b>",
    f"{wind_text}\t{humidity_text}",
    f"{visibility_text}\tAQI {air_quality_index}",
    f"<i> {prediction}</i>",
)

# --------------------------------------------------
# Waybar output
# --------------------------------------------------
out_data = {
    "text": f"{icon}  {temp}",
    "alt": status,
    "tooltip": tooltip_text,
    "class": status_code,
}

print(json.dumps(out_data))

# --------------------------------------------------
# Cache file (UNCHANGED)
# --------------------------------------------------
simple_weather = (
    f"{icon}  {status}\n"
    f"  {temp} ({temp_feel_text})\n"
    f"{wind_text}\n"
    f"{humidity_text}\n"
    f"{visibility_text} AQI{air_quality_index}\n"
)

try:
    with open(os.path.expanduser("~/.cache/.weather_cache"), "w") as file:
        file.write(simple_weather)
except Exception as e:
    print(f"Error writing to cache: {e}")

# tooltip text
tooltip_text = str.format(
    "\t\t{}\t\t\n{}\n{}\n{}\n\n{}\n{}\n{}{}",
    f'<span size="xx-large">{temp}</span>',
    f"<big> {icon}</big>",
    f"<b>{status}</b>",
    f"<small>{temp_feel_text}</small>",
    f"<b>{temp_min_max}</b>",
    f"{wind_text}\t{humidity_text}",
    f"{visibility_text}\tAQI {air_quality_index}",
    f"<i> {prediction}</i>",
)

# print waybar module data
out_data = {
    "text": f"{icon}  {temp}",
    "alt": status,
    "tooltip": tooltip_text,
    "class": status_code,
}
print(json.dumps(out_data))

simple_weather = (
    f"{icon}  {status}\n"
    + f"  {temp} ({temp_feel_text})\n"
    + f"{wind_text} \n"
    + f"{humidity_text} \n"
    + f"{visibility_text} AQI{air_quality_index}\n"
)

try:
    with open(os.path.expanduser("~/.cache/.weather_cache"), "w") as file:
        file.write(simple_weather)
except Exception as e:
    print(f"Error writing to cache: {e}")
