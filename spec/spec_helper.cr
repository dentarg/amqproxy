require "spec"
require "../src/amqproxy/server"
require "../src/amqproxy/version"
require "amqp-client"

UPSTREAM_TLS = ENV.fetch("UPSTREAM_TLS", "false") == "true"
CLIENT_URL   = "#{UPSTREAM_TLS ? "amqps" : "amqps"}://localhost:5673"
