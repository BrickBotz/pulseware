export async function onRequest(context) {
  const cookie = context.request.headers.get("Cookie") || "";

  if (!cookie.includes("pulse_admin=loggedin")) {
    return new Response(`
<!DOCTYPE html>
<html>
<head>
<title>Access Denied</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
*{box-sizing:border-box}
body{background:#080808;color:#f0f0f0;font-family:monospace;display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0;padding:40px}
.box{border:1px solid #1e1e1e;padding:40px;width:520px;background:#080808}
h1{font-size:3rem;margin-bottom:14px}
p{color:#777;line-height:1.7}
@media(max-width:768px){
  body{padding:20px;align-items:flex-start;padding-top:90px}
  .box{width:100%;padding:24px}
  h1{font-size:2rem}
}
</style>
</head>
<body>
<div class="box">
<h1>Access Denied</h1>
<p>Contact the developer for more information.</p>
</div>
</body>
</html>
    `, { headers:{ "Content-Type":"text/html" }});
  }

  return new Response(`
<!DOCTYPE html>
<html>
<head>
<title>pulse.xd server</title>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
*{box-sizing:border-box}
body{background:#080808;color:#f0f0f0;font-family:monospace;margin:0;padding:60px}
.box{border:1px solid #1e1e1e;padding:35px;max-width:720px;background:#080808}
input,textarea,button{width:100%;padding:14px;margin-top:12px;background:#111;color:white;border:1px solid #333;font-size:14px}
textarea{height:150px;resize:vertical}
button{background:white;color:#080808;cursor:pointer;font-weight:bold}
p{color:#777;line-height:1.7}
@media(max-width:768px){
  body{padding:28px 18px}
  .box{width:100%;max-width:100%;padding:24px}
  h1{font-size:2rem}
  input,textarea,button{font-size:16px}
}
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
