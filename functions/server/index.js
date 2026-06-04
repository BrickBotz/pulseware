export async function onRequestGet(context) {
  return new Response("Access Denied", {
    status: 403,
    headers: {
      "Content-Type": "text/plain"
    }
  });
}
