export async function onRequestGet(context) {
  const cookie = context.request.headers.get("Cookie") || "";

  if (!cookie.includes("pulse_admin=loggedin")) {
    return new Response("Access Denied", {
      status: 403,
      headers: { "Content-Type": "text/plain" }
    });
  }

  return new Response(`<!DOCTYPE html>
<html>
<head>
  <title>Pulse Server Panel</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body{background:#080808;color:white;font-family:Arial;padding:30px}
    .box{max-width:1000px;margin:auto;background:#111;border:1px solid #333;border-radius:12px;padding:25px}
    input,textarea,button{width:100%;padding:12px;margin-top:10px;background:#0b0b0b;color:white;border:1px solid #333;border-radius:8px}
    button{cursor:pointer;background:white;color:black;font-weight:bold}
    textarea{height:300px;font-family:monospace}
    .row{display:flex;gap:10px}
    .row>*{flex:1}
    .game{padding:10px;border:1px solid #333;margin-top:8px;border-radius:8px;cursor:pointer}
  </style>
</head>
<body>
  <div class="box">
    <h1>Pulse Server Panel</h1>

    <h2>Games</h2>
    <div id="games">Loading...</div>

    <h2>Editor</h2>
    <input id="gameId" placeholder="Game PlaceId">
    <textarea id="content" placeholder="Lua script content"></textarea>

    <div class="row">
      <button onclick="saveGame()">Save Game Script</button>
      <button onclick="createGame()">Create New Game</button>
      <button onclick="deleteGame()">Delete Game</button>
    </div>

    <h2>Hubhandler</h2>
    <button onclick="loadHub()">Load Hubhandler</button>
    <button onclick="saveHub()">Save Hubhandler</button>
  </div>

<script>
async function loadGames(){
  const res = await fetch('/api/games');
  const text = await res.text();

  if(!res.ok){
    document.getElementById('games').innerText = text;
    return;
  }

  const games = JSON.parse(text);
  const box = document.getElementById('games');
  box.innerHTML = '';

  games.forEach(g => {
    const div = document.createElement('div');
    div.className = 'game';
    div.innerText = g.name;
    div.onclick = () => loadGame(g.gameId);
    box.appendChild(div);
  });
}

async function loadGame(gameId){
  const res = await fetch('/api/games/' + gameId);
  const text = await res.text();

  document.getElementById('gameId').value = gameId;
  document.getElementById('content').value = text;
}

async function saveGame(){
  const gameId = document.getElementById('gameId').value.trim();
  const content = document.getElementById('content').value;

  const res = await fetch('/api/games/' + gameId, {
    method:'PUT',
    headers:{'Content-Type':'application/json'},
    body:JSON.stringify({content})
  });

  alert(await res.text());
  loadGames();
}

async function createGame(){
  const gameId = document.getElementById('gameId').value.trim();
  const content = document.getElementById('content').value || '-- new game script';

  const res = await fetch('/api/games', {
    method:'POST',
    headers:{'Content-Type':'application/json'},
    body:JSON.stringify({gameId, content})
  });

  alert(await res.text());
  loadGames();
}

async function deleteGame(){
  const gameId = document.getElementById('gameId').value.trim();
  if(!confirm('Delete ' + gameId + '?')) return;

  const res = await fetch('/api/games/' + gameId, {
    method:'DELETE'
  });

  alert(await res.text());
  loadGames();
}

async function loadHub(){
  const res = await fetch('/api/hubhandler');
  const text = await res.text();

  document.getElementById('gameId').value = 'hubhandler';
  document.getElementById('content').value = text;
}

async function saveHub(){
  const content = document.getElementById('content').value;

  const res = await fetch('/api/hubhandler', {
    method:'PUT',
    headers:{'Content-Type':'application/json'},
    body:JSON.stringify({content})
  });

  alert(await res.text());
}

loadGames();
</script>
</body>
</html>`, {
    status: 200,
    headers: { "Content-Type": "text/html" }
  });
}
