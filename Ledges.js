.pragma library

function cut(spans, left, right) {
    var result = []
    for (var i = 0; i < spans.length; i++) {
        var a = spans[i][0], b = spans[i][1]
        if (right <= a || left >= b) result.push([a, b])
        else {
            if (left > a) result.push([a, left])
            if (right < b) result.push([right, b])
        }
    }
    return result
}

function visibleLedges(clients, monitor, width, height) {
    if (!monitor || !Array.isArray(clients) || !(width > 0 && height > 0)) return []
    var active = monitor.activeWorkspace ? monitor.activeWorkspace.id : null
    var special = monitor.specialWorkspace ? monitor.specialWorkspace.id : 0
    var ox = Number(monitor.x) || 0, oy = Number(monitor.y) || 0
    var rectangles = []
    clients.slice(0, 256).forEach(function(c) {
        if (!c || c.hidden || c.mapped === false || !c.workspace) return
        if (c.workspace.id !== active && !(special && c.workspace.id === special) && !c.pinned) return
        if (!Array.isArray(c.at) || !Array.isArray(c.size)) return
        var x = Number(c.at[0]) - ox, y = Number(c.at[1]) - oy
        var w = Number(c.size[0]), h = Number(c.size[1])
        if (![x, y, w, h].every(isFinite) || w < 20 || h < 20) return
        if (x >= width || y >= height || x + w <= 0 || y + h <= 0) return
        rectangles.push({x:x, y:y, width:w, height:h, id:String(c.address || '').slice(0, 32),
            floating:!!c.floating, fullscreen:!!c.fullscreen, special:c.workspace.id === special,
            focus: isFinite(c.focusHistoryID) && c.focusHistoryID >= 0 ? c.focusHistoryID : 9999})
    })
    rectangles.sort(function(a, b) {
        return Number(b.special) - Number(a.special) || Number(b.fullscreen) - Number(a.fullscreen)
            || Number(b.floating) - Number(a.floating) || a.focus - b.focus
    })
    var result = [], above = []
    rectangles.forEach(function(r) {
        if (!r.fullscreen) {
            var seed = 0
            for (var n = 0; n < r.id.length; n++) seed = (seed * 31 + r.id.charCodeAt(n)) % 997
            function add(y, left, right, kind) {
                if (y < 8 || y > height || right <= left) return
                var spans = [[Math.max(0, left), Math.min(width, right)]]
                above.forEach(function(o) {
                    if (o.y <= y + 2 && o.y + o.height >= y - 7)
                        spans = cut(spans, o.x - 3, o.x + o.width + 3)
                })
                spans.forEach(function(s) {
                    if (s[1] - s[0] > 5) result.push({x:s[0], y:y, width:s[1]-s[0], kind:kind,
                        key:r.id + ':' + kind + ':' + left, seed:seed})
                })
            }
            add(r.y + 1, r.x + 9, r.x + r.width - 9, 'top')
            var corner = Math.min(80, r.width * 0.15)
            add(r.y + r.height - 1, r.x + 8, r.x + corner, 'corner')
            add(r.y + r.height - 1, r.x + r.width - corner, r.x + r.width - 8, 'corner')
        }
        above.push(r)
    })
    return result
}

function paintBank(ctx, edge, amount) {
    if (!(amount > 0) || edge.width <= 0) return
    var max = edge.kind === 'floor' ? 9 : edge.kind === 'corner' ? 4.5 : 3.5
    var depth = max * Math.sqrt(amount)
    var step = edge.kind === 'floor' ? 12 : 6
    ctx.beginPath()
    ctx.moveTo(edge.x, edge.y)
    for (var dx = 0; dx <= edge.width; dx += step) {
        var fraction = dx / edge.width
        var taper = Math.pow(Math.max(0, Math.sin(Math.PI * fraction)), 0.4)
        var wave = 0.66 + 0.17 * Math.sin((edge.x + dx) * 0.041 + edge.seed)
            + 0.12 * Math.sin((edge.x + dx) * 0.113 + edge.seed * 0.7)
        ctx.lineTo(edge.x + dx, edge.y - depth * wave * taper)
    }
    ctx.lineTo(edge.x + edge.width, edge.y)
    ctx.closePath()
    var gradient = ctx.createLinearGradient(0, edge.y - depth, 0, edge.y + 1)
    gradient.addColorStop(0, '#f5fbff')
    gradient.addColorStop(0.6, '#e4f0f6')
    gradient.addColorStop(1, '#b2cbd9')
    ctx.fillStyle = gradient
    ctx.globalAlpha = Math.min(0.92, amount * 5)
    ctx.fill()
    ctx.globalAlpha = 1
}
