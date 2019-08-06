# Docker/Nginx/ModSecurity

## Overvoew

This is a simple proof of concept I put together a while ago to see how difficult it would be to roll my own web application firewall within a container.

It's barely customised and wouldn't be used in production in it current state.

Building can take some time as you'll be compiling nginx, modsecurity, and the modsecurity-nginx module.

## Testing

A docker-compose file is included which launches a basic WordPress setup with the nginx container with modsecurity as a proxy to it.

Unless something has changed since 2018; it's unlikely that you'll be able to log in to WordPress with the default rule set.
