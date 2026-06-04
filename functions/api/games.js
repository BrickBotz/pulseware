const GAMES = {
  "106525922058591": "106525922058591.lua"
};

function isAdmin(request) {
  const cookie = request.headers.get("Cookie") || "";
  return cookie.includes("pulse_admin=loggedin");
}

export async function onRequestGet(context) {
  if (!isAdmin(context.request)) {
    return new Response("Access Denied", { status: 403 });
  }

  const games = Object.keys(GAMES).map(gameId => ({
    gameId,
    name: GAMES[gameId]
  }));

  return new Response(JSON.stringify(games), {
    headers: { "Content-Type": "application/json" }
  });
}
