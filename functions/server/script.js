export async function onRequestGet(context) {
  const url = new URL(context.request.url);
  const gameId = url.searchParams.get("game");

  if (!gameId) {
    return new Response("UNSUPPORTED", {
      headers: { "Content-Type": "text/plain" }
    });
  }

  const scriptUrl =
    `https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/games/${gameId}.lua`;

  const res = await fetch(scriptUrl);

  if (!res.ok) {
    return new Response("UNSUPPORTED", {
      headers: { "Content-Type": "text/plain" }
    });
  }

  const code = await res.text();

  return new Response(code, {
    headers: {
      "Content-Type": "text/plain",
      "Cache-Control": "no-store"
    }
  });
}
