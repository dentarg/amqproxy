# AMQProxy

An intelligent AMQP proxy with AMQP connection and channel pooling/reusing. Allows e.g. PHP clients to keep long lived connections to upstream servers, increasing publishing speed with a magnitude or more.

In the AMQP protocol, if you open a connection the client and the server has to exchange 7 TCP packages. If you then want to publish a message you have to open a channel which requires 2 more, and then to do the publish you need at least one more, and then to gracefully close the connection you need 4 more packages. In total 15 TCP packages, or 18 if you use AMQPS (TLS). For clients that can't for whatever reason keep long-lived connections to the server this has a considerable latency impact.

This proxy server, if run on the same machine as the client can save all that latency. When a connection is made to the proxy the proxy opens a connection to the upstream server, using the credentials the client provided. AMQP traffic is then forwarded between the client and the server but when the client disconnects the proxy intercepts the Channel Close command and instead keeps it open on the upstream server (if deemed safe). Next time a client connects (with the same credentials) the connection to the upstream server is reused so no TCP packages for opening and negotiating the AMQP connection or opening and waiting for the channel to be opened has to be made.

Only "safe" channels are reused, that is channels where only Basic Publish or Basic Get (with no_ack) has occurred. Any channels who has subscribed to a queue will be closed when the client disconnects. However, the connection to the upstream AMQP server are always kept open and can be reused.

In our benchmarks publishing one message per connection to a server (using TLS) with a round-trip latency of 50ms, takes on avarage 0.01s using the proxy and 0.50s without. You can read more about the proxy here [Maintaining long-lived connections with AMQProxy](https://www.cloudamqp.com/blog/2019-05-29-maintaining-long-lived-connections-with-AMQProxy.html)


## Installation

Debian/Ubuntu:

```sh
wget -qO- https://packagecloud.io/cloudamqp/amqproxy/gpgkey | sudo apt-key add -
echo "deb https://packagecloud.io/cloudamqp/amqproxy/ubuntu/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/amqproxy.list

sudo apt update
sudo apt install amqproxy
```

Docker/Podman:

Docker images are published at [Docker Hub](https://hub.docker.com/r/cloudamqp/amqproxy). Fetch and run the latest version with:

`docker run --rm -it -p 5673:5673 cloudamqp/amqproxy amqp://SERVER:5672`

Then from your AMQP client connect to localhost:5673, it will resuse connections made to the upstream. The AMQP_URL should only include protocol, hostname and port (only if non default, 5672 for AMQP and 5671 for AMQPS). Any username, password or vhost will be ignored, and it's up to the client to provide them.

## Installation (from source)

[Install Crystal](https://crystal-lang.org/install/)

```
shards build --release --production
cp bin/amqproxy /usr/bin
cp extras/amqproxy.service /etc/systemd/system/
systemctl enable amqproxy
systemctl start amqproxy
```

You probably want to modify `/etc/systemd/system/amqproxy.service` and configure another upstream host.
