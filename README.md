# netbox-demo
Demo docker setup for Netbox

# Setup
You can change Netbox's port in docker-compose.override.yml.

Custom enviroment variables are also available inside ./env dir.

# Run
Start NetBox Using Docker Compose:
```console
docker compose up -d
```
Wait a few minutes for the server to finish setting things up during the first run. If it fails with: "test-netbox-1 is unhealthy" try running "docker compose up -d" again a few times.

After all containers have reached a healthy state, try accessing the [Netbox UI](http://localhost:8000/).

If you were able to access the UI, now it is time to setup the superuser. Still on the project root, run the following command:
```console
docker compose exec netbox /opt/netbox/netbox/manage.py createsuperuser
```
Choose a username and password.

You can now login to the Netbox UI with the credentials you just created!
