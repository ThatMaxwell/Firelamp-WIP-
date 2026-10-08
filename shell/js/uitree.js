// The live UI tree. Instead of screenshots, the AI reads this: every window, button and
// field with its role, label and exact bounds.
//
// On the real system the same tree is published over AT-SPI2 (every control here also
// sets Accessible.name / role), so native apps show up too. Inside the shell we walk
// the Qt Quick item tree directly: any item with an `aiName` is something the AI can see.
.pragma library

function visibleIn(item, root) {
    if (!item.visible || item.opacity < 0.05 || item.width < 2 || item.height < 2) return false;
    var p = item.mapToItem(root, 0, 0);
    return !(p.x + item.width < 0 || p.y + item.height < 0 || p.x > root.width || p.y > root.height);
}

function appOf(item) {
    for (var p = item; p; p = p.parent) if (p.aiApp !== undefined && p.aiApp !== "") return { app: p.aiApp, z: p.z || 0, win: p };
    return { app: "system", z: 0, win: null };
}

/** Flat list of every element the AI can perceive right now. */
function nodes(root) {
    var out = [];
    (function walk(it) {
        var kids = it.children;
        for (var i = 0; i < kids.length; i++) {
            var c = kids[i];
            if (!c.visible || c.aiHidden === true) continue;
            if (c.aiName !== undefined && c.aiName !== "" && visibleIn(c, root)) {
                var p = c.mapToItem(root, 0, 0), a = appOf(c);
                out.push({ item: c, role: c.aiRole || "item", name: c.aiName, app: a.app, z: a.z,
                           bounds: { x: Math.round(p.x), y: Math.round(p.y), w: Math.round(c.width), h: Math.round(c.height) } });
            }
            walk(c);
        }
    })(root);
    return out;
}

function norm(s) { return String(s || "").toLowerCase().replace(/[^a-z0-9 ]/g, " ").replace(/\s+/g, " ").trim(); }

/**
 * Pick the element that best matches a target description. This is the "reflex" a fast
 * decision model (Jev) makes on the real system; here it is a small scorer over the tree.
 */
function find(root, q) {
    var want = norm(q.name), best = null, bestScore = 0, list = nodes(root);
    for (var i = 0; i < list.length; i++) {
        var n = list[i];
        if (q.app && n.app !== q.app) continue;
        if (q.role && n.role !== q.role) continue;
        var have = norm(n.name), s = 0;
        if (have === want) s = 100;
        else if (have.indexOf(want) === 0) s = 70;
        else if (have.indexOf(want) >= 0) s = 50;
        else {
            var words = want.split(" "), hits = 0;
            for (var w = 0; w < words.length; w++) if (have.indexOf(words[w]) >= 0) hits++;
            s = hits ? 30 * hits / words.length : 0;
        }
        if (!s) continue;
        s += n.z / 1e5; // prefer what is on top
        if (s > bestScore) { bestScore = s; best = n; }
    }
    return best;
}

/** Nested by app, for the terminal's `tree` command. */
function snapshot(root) {
    var list = nodes(root), byApp = {}, order = [];
    for (var i = 0; i < list.length; i++) {
        var n = list[i];
        if (!byApp[n.app]) { byApp[n.app] = []; order.push(n.app); }
        byApp[n.app].push(n);
    }
    return order.map(function (a) { return { name: a, children: byApp[a] }; });
}
