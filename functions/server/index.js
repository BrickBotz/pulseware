export async function onRequestGet(context) {
  const cookie = context.request.headers.get("Cookie") || "";

  const isAdmin =
    cookie.includes("admin=true") ||
    cookie.includes("admin=1");

  if (!isAdmin) {
    return new Response("Access Denied", {
      status: 403,
      headers: {
        "Content-Type": "text/plain"
      }
    });
  }

  const html = `<!DOCTYPE html>
<html>
<head>
  <title>Satire Server Panel</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      background: #080808;
      color: white;
      font-family: Arial, sans-serif;
      padding: 40px;
    }
    .box {
      max-width: 900px;
      margin: auto;
      border: 1px solid #333;
      padding: 25px;
      border-radius: 12px;
      background: #111;
    }
    a {
      color: white;
    }
  </style>
</head>
<body>
  <div class="box">
    <h1>Satire Server Panel</h1>
    <p>You are logged in as admin.</p>

    <h3>Available Routes</h3>
    <p><a href="/server/script?game=106525922058591">Test Game Script</a></p>
    <p><a href="/api/games">View Games API</a></p>
    <p><a href="/api/hubhandler">View Hubhandler</a></p>
  </div>
</body>
</html>`;

  return new Response(html, {
    status: 200,
    headers: {
      "Content-Type": "text/html"
    }
  });
}
