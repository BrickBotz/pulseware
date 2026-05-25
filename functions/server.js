export async function onRequest(context) {
  const cookie = context.request.headers.get("Cookie") || "";

  if (!cookie.includes("pulse_admin=loggedin")) {
    return new Response(`
      <!DOCTYPE html>
      <html>
      <head><title>Access Denied</title></head>
      <body style="background:#080808;color:#f0f0f0;font-family:monospace;padding:80px">
        <h1>Access Denied</h1>
        <p style="color:#777">Contact the developer for more information.</p>
      </body>
      </html>
    `, { headers:{ "Content-Type":"text/html" }});
  }

  return new Response(`
<!DOCTYPE html>
<html>
<head>
<title>pulse.xd server</title>
<style>
body{background:#080808;color:#f0f0f0;font-family:monospace;padding:60px}
.box{border:1px solid #1e1e1e;padding:35px;max-width:700px}
input,textarea,button{width:100%;padding:14px;margin-top:12px;background:#111;color:white;border:1px solid #333}
textarea{height:150px}
button{background:white;color:#080808;cursor:pointer}
</style>
</head>
<body>
<div class="box">
<h1>Admin Server</h1>
<p>Create announcement</p>
<input id="title" placeholder="Announcement title">
<textarea id="desc" placeholder="Announcement description"></textarea>
<input id="duration" placeholder="Duration in seconds, example: 60">
<button onclick="send()">Send Announcement</button>
<button onclick="remove()">Remove All Announcements</button>
<p id="msg"></p>
</div>

<script>
async function send(){
  const res = await fetch("/api/announcements", {
    method:"POST",
    headers:{ "Content-Type":"application/json" },
    body: JSON.stringify({
      title: title.value,
      description: desc.value,
      duration: Number(duration.value || 0)
    })
  });
  msg.textContent = res.ok ? "Announcement sent." : "Failed.";
}

async function remove(){
  const res = await fetch("/api/announcements", { method:"DELETE" });
  msg.textContent = res.ok ? "Announcements removed." : "Failed.";
}
</script>
</body>
</html>
`, { headers:{ "Content-Type":"text/html" }});
}
