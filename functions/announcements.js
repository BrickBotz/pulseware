export async function onRequestGet(context) {
  const data = await context.env.ANNOUNCEMENTS.get("items");
  return Response.json(JSON.parse(data || "[]"));
}

export async function onRequestPost(context) {
  const cookie = context.request.headers.get("Cookie") || "";
  if (!cookie.includes("pulse_admin=loggedin")) {
    return new Response("Access Denied", { status: 403 });
  }

  const body = await context.request.json();
  const items = JSON.parse(await context.env.ANNOUNCEMENTS.get("items") || "[]");

  const announcement = {
    title: body.title,
    description: body.description,
    expiresAt: body.duration ? Date.now() + body.duration * 1000 : null
  };

  items.push(announcement);
  await context.env.ANNOUNCEMENTS.put("items", JSON.stringify(items));

  return new Response("OK");
}

export async function onRequestDelete(context) {
  const cookie = context.request.headers.get("Cookie") || "";
  if (!cookie.includes("pulse_admin=loggedin")) {
    return new Response("Access Denied", { status: 403 });
  }

  await context.env.ANNOUNCEMENTS.put("items", "[]");
  return new Response("OK");
}
