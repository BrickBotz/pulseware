const RAW_SCRIPT_URL =
  "https://raw.githubusercontent.com/BrickBotz/Pulze/refs/heads/main/Pulze";

function isAdmin(request) {
  const cookie = request.headers.get("Cookie") || "";
  return cookie.includes("pulse_admin=loggedin");
}

function isBrowser(request) {
  const ua = (request.headers.get("User-Agent") || "").toLowerCase();
  return ua.includes("mozilla");
}

export async function onRequestGet(context) {
  const request = context.request;

  // Browser visit
  if (isBrowser(request)) {
    if (!isAdmin(request)) {
      return new Response("Access Denied", {
        status: 403,
        headers: { "Content-Type": "text/plain" }
      });
    }

    const res = await fetch(RAW_SCRIPT_URL);
    const code = await res.text();

    return new Response(code, {
      status: 200,
      headers: {
        "Content-Type": "text/plain",
        "Cache-Control": "no-store"
      }
    });
  }

  // Executor visit
  const res = await fetch(RAW_SCRIPT_URL);

  if (!res.ok) {
    return new Response(`error("Pulse failed to load")`, {
      headers: { "Content-Type": "text/plain" }
    });
  }

  const code = await res.text();

  return new Response(code, {
    status: 200,
    headers: {
      "Content-Type": "text/plain",
      "Cache-Control": "no-store"
    }
  });
}
