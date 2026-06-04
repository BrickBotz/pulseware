export async function onRequestPost(context) {
  const { username, password } = await context.request.json();

  if (username === "--1.3>" && password === "0.F7s--1") {
    return new Response(JSON.stringify({ ok: true }), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Set-Cookie": "pulse_admin=loggedin; Path=/; Secure; SameSite=Lax; Max-Age=86400"
      }
    });
  }

  return new Response(JSON.stringify({ ok: false, error: "Invalid" }), {
    status: 401,
    headers: {
      "Content-Type": "application/json"
    }
  });
}
