"use strict";

/**
 * Event-driven function: validates a new todo title and returns an audit payload.
 * Trigger: HTTP POST from OpenFaaS gateway (optional webhook from backend on todo create).
 */
module.exports = async (event, context) => {
  let body = {};
  try {
    body = event.body ? JSON.parse(event.body) : {};
  } catch {
    return context.status(400).json({ error: "Invalid JSON body" });
  }

  const title = (body.title || "").trim();
  if (!title) {
    return context.status(400).json({
      error: "title is required",
      event: "todo-notify-rejected",
    });
  }

  if (title.length > 255) {
    return context.status(400).json({
      error: "title exceeds 255 characters",
      event: "todo-notify-rejected",
    });
  }

  return context.status(200).json({
    event: "todo-notify-accepted",
    message: `Todo "${title}" queued for async processing`,
    title,
    timestamp: new Date().toISOString(),
    handler: "todo-notify",
  });
};
