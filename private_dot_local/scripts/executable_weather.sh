API_KEY=$(<~/.weatherapikey)
curl -s "http://api.weatherapi.com/v1/current.json?key=$API_KEY&q=auto:ip&aqi=no" | jq -r '(.current.feelslike_c | tostring) + "°C"'
