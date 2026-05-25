export async function onRequestPost(context) {
  const { username, password } = await context.request.json();

  if (username === "--1.3>" && password === "0.F7s--1") {
    return new Response("OK", {
      headers: {
        "Set-Cookie": "pulse_admin=loggedin; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=86400"
      }
    });
  }

  return new Response("Invalid", { status: 401 });
}
