export async function onRequestGet(context) {
  const cookie = context.request.headers.get("Cookie") || "";

  if (!cookie.includes("pulse_admin=loggedin")) {
    return new Response("Access Denied", {
      status: 403,
      headers: {
        "Content-Type": "text/plain"
      }
    });
  }

  return new Response(`<!DOCTYPE html>
<html>
<head>
  <title>Pulse Server</title>
</head>
<body style="background:#080808;color:white;font-family:Arial;padding:40px">
  <h1>Pulse Server Panel</h1>
  <p>You are logged in.</p>
</body>
</html>`, {
    status: 200,
    headers: {
      "Content-Type": "text/html"
    }
  });
}
