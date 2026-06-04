// server.js — Satire Hub Backend
// npm install express express-session

const express = require("express");
const session = require("express-session");
const fs      = require("fs");
const path    = require("path");

const app  = express();
const PORT = process.env.PORT || 3000;

// ════════════════════════════════
//   CONFIG — change these
// ════════════════════════════════
const ADMIN_USER = process.env.ADMIN_USER || "pulse.xd";
const ADMIN_PASS = process.env.ADMIN_PASS || "pulse.on.top//";
const SESSION_SECRET = process.env.SESSION_SECRET || "dc2e24f9b16ff3a389dad6bce37652235d51c882967383158d52d113f0763057";

const GAMES_DIR  = path.join(__dirname, "games");
const PUBLIC_DIR = path.join(__dirname, "public");
const DATA_DIR   = path.join(__dirname, "data");

// ensure data dir exists
if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });

// ════════════════════════════════
//   MIDDLEWARE
// ════════════════════════════════
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(session({
    secret: SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    cookie: { maxAge: 1000 * 60 * 60 * 24 * 7 } // 7 days
}));

// serve public folder (your existing site pages)
app.use(express.static(PUBLIC_DIR));

// ════════════════════════════════
//   AUTH ROUTES
// ════════════════════════════════
app.post("/api/login", (req, res) => {
    const { username, password } = req.body;
    if (username === ADMIN_USER && password === ADMIN_PASS) {
        req.session.admin = true;
        return res.json({ ok: true });
    }
    return res.status(401).json({ error: "Invalid credentials" });
});

app.get("/api/logout", (req, res) => {
    req.session.destroy();
    res.redirect("/");
});

app.get("/api/me", (req, res) => {
    res.json({ admin: req.session.admin === true });
});

// ════════════════════════════════
//   ANNOUNCEMENTS API
//   (kept from your existing site)
// ════════════════════════════════
const ANNOUNCEMENTS_PATH = path.join(DATA_DIR, "announcements.json");
if (!fs.existsSync(ANNOUNCEMENTS_PATH)) {
    fs.writeFileSync(ANNOUNCEMENTS_PATH, JSON.stringify([]));
}

app.get("/api/announcements", (req, res) => {
    const data = JSON.parse(fs.readFileSync(ANNOUNCEMENTS_PATH, "utf8"));
    res.json(data);
});

app.post("/api/announcements", (req, res) => {
    if (!req.session.admin) return res.status(403).send("Access Denied");
    const { title, description, expiresAt } = req.body;
    const data = JSON.parse(fs.readFileSync(ANNOUNCEMENTS_PATH, "utf8"));
    data.push({ title, description, expiresAt: expiresAt || null, id: Date.now() });
    fs.writeFileSync(ANNOUNCEMENTS_PATH, JSON.stringify(data, null, 2));
    res.json({ ok: true });
});

app.delete("/api/announcements/:id", (req, res) => {
    if (!req.session.admin) return res.status(403).send("Access Denied");
    let data = JSON.parse(fs.readFileSync(ANNOUNCEMENTS_PATH, "utf8"));
    data = data.filter(a => String(a.id) !== req.params.id);
    fs.writeFileSync(ANNOUNCEMENTS_PATH, JSON.stringify(data, null, 2));
    res.json({ ok: true });
});

// ════════════════════════════════
//   SCRIPT ENDPOINT
//   GET /server/script?game=PLACEID
//
//   executor  → always gets raw lua
//   admin     → sees editor UI
//   normal    → Access Denied
// ════════════════════════════════
app.get("/server/script", (req, res) => {
    const ua       = (req.headers["user-agent"] || "").toLowerCase();
    const isAdmin  = req.session.admin === true;
    const gameId   = req.query.game || "";

    // detect executor: no mozilla OR known executor UAs
    const isBrowser = ua.includes("mozilla") && !ua.includes("synapse") && !ua.includes("krnl") && !ua.includes("fluxus") && !ua.includes("hydrogen") && !ua.includes("wave") && !ua.includes("delta") && !ua.includes("curl") && !ua.includes("python");

    const isExecutor = !isBrowser;

    if (isExecutor) {
        // serve game script raw to executor
        return serveGameScript(res, gameId);
    }

    if (isAdmin) {
        // admin browser sees editor
        return res.sendFile(path.join(__dirname, "scripts", "script-editor.html"));
    }

    // normal browser
    res.setHeader("Content-Type", "text/plain");
    return res.status(403).send("Access Denied");
});

function serveGameScript(res, gameId) {
    res.setHeader("Content-Type", "text/plain");

    if (!gameId) {
        return res.send("UNSUPPORTED");
    }

    // check for game-specific script file
    const gamePath = path.join(GAMES_DIR, `${gameId}.lua`);

    if (fs.existsSync(gamePath)) {
        // inject the hubhandler as the wrapper
        const hubHandler  = fs.readFileSync(path.join(GAMES_DIR, "hubhandler.lua"), "utf8");
        return res.send(hubHandler);
    }

    // game not supported
    return res.send("UNSUPPORTED");
}

// ════════════════════════════════
//   GAME SCRIPT FILE API
//   admin can view/edit game scripts
// ════════════════════════════════
app.get("/api/games", (req, res) => {
    if (!req.session.admin) return res.status(403).send("Access Denied");
    const files = fs.readdirSync(GAMES_DIR)
        .filter(f => f.endsWith(".lua") && f !== "hubhandler.lua")
        .map(f => ({ name: f, gameId: f.replace(".lua","") }));
    res.json(files);
});

app.get("/api/games/:gameId", (req, res) => {
    if (!req.session.admin) return res.status(403).send("Access Denied");
    const filePath = path.join(GAMES_DIR, `${req.params.gameId}.lua`);
    if (!fs.existsSync(filePath)) return res.status(404).json({ error: "Not found" });
    res.setHeader("Content-Type", "text/plain");
    res.send(fs.readFileSync(filePath, "utf8"));
});

app.put("/api/games/:gameId", (req, res) => {
    if (!req.session.admin) return res.status(403).send("Access Denied");
    const { content } = req.body;
    if (!content) return res.status(400).json({ error: "No content" });
    const filePath = path.join(GAMES_DIR, `${req.params.gameId}.lua`);
    fs.writeFileSync(filePath, content);
    res.json({ ok: true });
});

app.post("/api/games", (req, res) => {
    if (!req.session.admin) return res.status(403).send("Access Denied");
    const { gameId, content } = req.body;
    if (!gameId) return res.status(400).json({ error: "No gameId" });
    const filePath = path.join(GAMES_DIR, `${gameId}.lua`);
    fs.writeFileSync(filePath, content || "-- new game script\n");
    res.json({ ok: true });
});

app.delete("/api/games/:gameId", (req, res) => {
    if (!req.session.admin) return res.status(403).send("Access Denied");
    const filePath = path.join(GAMES_DIR, `${req.params.gameId}.lua`);
    if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
    res.json({ ok: true });
});

// hubhandler edit
app.get("/api/hubhandler", (req, res) => {
    if (!req.session.admin) return res.status(403).send("Access Denied");
    const content = fs.readFileSync(path.join(GAMES_DIR, "hubhandler.lua"), "utf8");
    res.setHeader("Content-Type", "text/plain");
    res.send(content);
});

app.put("/api/hubhandler", (req, res) => {
    if (!req.session.admin) return res.status(403).send("Access Denied");
    const { content } = req.body;
    fs.writeFileSync(path.join(GAMES_DIR, "hubhandler.lua"), content);
    res.json({ ok: true });
});

// ════════════════════════════════
//   SERVER ADMIN PAGE
// ════════════════════════════════
app.get("/server", (req, res) => {
    if (!req.session.admin) {
        res.setHeader("Content-Type", "text/plain");
        return res.status(403).send("Access Denied");
    }
    res.sendFile(path.join(__dirname, "scripts", "script-editor.html"));
});

// ════════════════════════════════
//   404
// ════════════════════════════════
app.use((req, res) => {
    res.status(404).sendFile(path.join(PUBLIC_DIR, "404.html"));
});

app.listen(PORT, () => {
    console.log(`Satire Hub running on port ${PORT}`);
});
