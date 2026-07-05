resource "google_pubsub_topic" "order_events" {
  name = "order-events"
}

resource "google_pubsub_subscription" "order_events_sub" {
  name  = "order-events-sub"
  topic = google_pubsub_topic.order_events.name

  ack_deadline_seconds = 20
}