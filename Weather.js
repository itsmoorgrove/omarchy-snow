.pragma library

function location(raw) {
    if (typeof raw !== 'string' || raw.length > 8192) return null
    try {
        var p = JSON.parse(raw)
        if (!p || typeof p.name !== 'string' || !p.name.trim() || p.name.length > 160) return null
        if (typeof p.latitude !== 'number' || typeof p.longitude !== 'number') return null
        if (!isFinite(p.latitude) || !isFinite(p.longitude) || Math.abs(p.latitude) > 90 || Math.abs(p.longitude) > 180) return null
        return {name:p.name.trim(), latitude:p.latitude, longitude:p.longitude}
    } catch (_) { return null }
}

function current(raw, now) {
    if (typeof raw !== 'string' || raw.length > 16384) return null
    try {
        var p = JSON.parse(raw), c = p.current
        if (!c || typeof c.time !== 'number' || typeof c.weather_code !== 'number') return null
        if (!isFinite(c.time) || c.time > now + 900 || c.time < now - 5400) return null
        var valid = [0,1,2,3,45,48,51,53,55,56,57,61,63,65,66,67,71,73,75,77,80,81,82,85,86,95,96,99]
        if (valid.indexOf(c.weather_code) === -1) return null
        return {snow:[71,73,75,77,85,86].indexOf(c.weather_code) !== -1, time:c.time}
    } catch (_) { return null }
}
