export async function onRequestGet(context) {
  const cookie = context.request.headers.get("Cookie") || "";

  const isAdmin = cookie.includes("pulse_admin=loggedin");

  if (!isAdmin) {
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
<title>Satire Server Panel</title>
</head>
<body style="background:#080808;color:white;font-family:Arial">
<h1>Satire Server Panel</h1>
<p>You are logged in.</p>
</body>
</html>`, {
    headers: {
      "Content-Type": "text/html"
    }
  });
}
