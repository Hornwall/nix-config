#!/usr/bin/env bash
# Fetch structured weather data for the Quickshell weather service.
set -euo pipefail

data=$(curl -fsS --max-time 10 \
  'https://api.open-meteo.com/v1/forecast?latitude=59.3293&longitude=18.0686&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,precipitation,is_day&hourly=temperature_2m,weather_code,precipitation_probability,is_day&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset,uv_index_max&temperature_unit=celsius&wind_speed_unit=kmh&timezone=Europe%2FStockholm&forecast_days=7' \
  2>/dev/null)

jq -c '
  . as $root
  | ([range(0; ($root.hourly.time | length))
      | select($root.hourly.time[.] >= $root.current.time)][0] // 0) as $start
  | (if ($start + 24) < ($root.hourly.time | length)
      then ($start + 24)
      else ($root.hourly.time | length)
    end) as $stop
  | {
      location: "Stockholm",
      updated: $root.current.time,
      current: {
        temperature: ($root.current.temperature_2m | round),
        apparentTemperature: ($root.current.apparent_temperature | round),
        humidity: $root.current.relative_humidity_2m,
        weatherCode: $root.current.weather_code,
        windSpeed: ($root.current.wind_speed_10m | round),
        precipitation: $root.current.precipitation,
        isDay: ($root.current.is_day == 1)
      },
      hourly: [
        range($start; $stop; 3) as $i
        | {
            time: $root.hourly.time[$i],
            temperature: ($root.hourly.temperature_2m[$i] | round),
            weatherCode: $root.hourly.weather_code[$i],
            precipitationProbability: $root.hourly.precipitation_probability[$i],
            isDay: ($root.hourly.is_day[$i] == 1)
          }
      ],
      daily: [
        range(0; ($root.daily.time | length)) as $i
        | {
            date: $root.daily.time[$i],
            weatherCode: $root.daily.weather_code[$i],
            minimum: ($root.daily.temperature_2m_min[$i] | round),
            maximum: ($root.daily.temperature_2m_max[$i] | round),
            precipitationProbability: $root.daily.precipitation_probability_max[$i],
            sunrise: $root.daily.sunrise[$i],
            sunset: $root.daily.sunset[$i],
            uvIndex: $root.daily.uv_index_max[$i]
          }
      ]
    }
' <<<"$data"
