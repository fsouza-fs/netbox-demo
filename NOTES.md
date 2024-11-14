
# NetBox Deployment and R&D Notes

---

## 1. Deployment and Setup Options

### On-Premises Deployment Options

1. **Bare Metal**:
   - Deploying NetBox directly on a physical server provides full control over resources, optimized performance, and is ideal for environments where Docker or Kubernetes isn't preferred. It can be tightly integrated with existing on-prem services and offers high reliability for critical infrastructure setups. However, it requires manual management of dependencies and updates.

2. **Docker**:
   - Using Docker offers a streamlined setup with containerized isolation, simplifying dependency management and deployment. Docker Compose allows quick installation and version control, making it an excellent option for small to medium environments or testing. Docker is flexible, efficient, and easily adaptable to changing requirements.

3. **Kubernetes (K8s)**:
   - Kubernetes is suited for larger-scale, production-grade deployments where scalability, load balancing, and high availability are priorities. Deploying NetBox on Kubernetes provides fault tolerance, automated scaling, and seamless updates, making it optimal for environments with high uptime requirements and complex infrastructure.

### Best Choice:
- For small to medium setups or testing: **Docker** is ideal.
- For high-demand production environments requiring scalability: **Kubernetes** is the preferred choice.
- For resource-sensitive or minimal dependency environments: **Bare Metal** is optimal.

---

## 2. Deployment and Functionality R&D Notes

### Deployment and Setup

   - **Environment**: Deployed locally on a Docker environment using `docker-compose`, making it easy to spin up NetBox along with its required services (PostgreSQL and Redis).
   - **Docker Compose Configuration**: 
     - Configured essential services in `docker-compose.yml`, including:
       - **NetBox Application**: Main container running NetBox.
       - **PostgreSQL**: Database container storing NetBox’s data.
       - **Redis**: Used by NetBox for caching and job queues.
     - Customized Netbox port in `docker-compose.override.yml`
     - Added multiple env files in `./env` for sensitive information like `POSTGRES_PASSWORD` and `SECRET_KEY`.
     - Added 2 extra variables in `netbox.env` `no_proxy=localhost` and `ALLOWED_HOSTS=netbox.domain.net localhost`. These were needed to fix an issue with the health check not reaching the server. see: (https://github.com/netbox-community/netbox/discussions/11362).

   - **Initial Setup**:
     - `docker compose up -d` command failed the first time after a couple of minutes with unhealthy status, due the long database setup process. Running it again a couple of times got rid of the error.
     - Accessed NetBox at `http://localhost:8000` after starting the Docker Compose setup.
     - Created an admin account via the `createsuperuser` command.

### Functionality Testing and Features

   - **Core Modules and Features**:
     - **IP Address Management (IPAM)**: Tested IP range creation, subnet allocation, and tracking of IP addresses. The hierarchical structure allows for efficient IP management.
     - **Data Center Infrastructure Management (DCIM)**: Set up racks, devices, and connectivity. Verified device placement within racks and connection mapping between devices.
     - **Inventory Management**: Experimented with adding devices and components, assigning roles (e.g., switches, routers, servers), and managing their configuration details.
     - **Virtualization Support**: Explored options for managing virtual machines (VMs) and clusters, simulating network infrastructure in both physical and virtual environments.

   - **Customization**:
     - Created custom fields for specific use cases, such as tracking unique identifiers, warranty expiry, or assigned departments.
     - Configured tags and custom scripts to enhance NetBox’s functionality for specific scenarios.
     - Explored automation options using Webhooks and API calls.

### Integration and Automation

   - **API and Webhooks**:
     - **REST API**: Tested NetBox’s API endpoints for CRUD operations on devices, IPs, VLANs, and more. The API is well-documented and allows for extensive integration with other systems.
     - **Webhooks**: Configured Webhooks to trigger specific actions (e.g., updating inventory records or synchronizing data) upon certain events in NetBox.

   - **Automation Potential**:
     - Integrated with **Ansible** for automated configuration management, allowing inventory data from NetBox to be used in playbooks.
     - Potential integration with network monitoring and automation tools, such as NAPALM or Netmiko, to keep configurations in sync.

### User Experience and Interface

   - **UI and Navigation**:
     - Clean and user-friendly interface with a clear structure for network elements (e.g., Sites, Racks, Devices).
     - Good organization of DCIM and IPAM data, making it easy to navigate between data centers, racks, and devices.
     - **Search and Filtering**: Strong filtering and search capabilities for locating devices, IPs, and other resources quickly.

   - **Performance**:
     - Local deployment runs smoothly for a small-scale setup, with reasonable response times for typical tasks (e.g., adding devices, querying IPs).
     - Redis cache improves performance, particularly for frequently accessed data.

### Known Challenges and Limitations

   - **Data Import**:
     - Bulk data import is available but has limitations. CSV import requires formatting data correctly and can be challenging for large, complex datasets.
     - CSV templates are helpful, but data mapping requires attention to avoid errors.

   - **Scaling Considerations**:
     - Local deployment works for testing and small-scale environments, but high-scale environments may require more robust infrastructure (e.g., multiple database nodes, load balancing).
     - Docker Compose setup is primarily for development/testing and may need adaptation for production (e.g., using Kubernetes for better scaling and resilience).

   - **Documentation**:
     - NetBox’s documentation is comprehensive but could be more detailed in certain areas (e.g., advanced customizations and integration examples).
     - Additional community resources (e.g., forums, GitHub discussions) are helpful for troubleshooting specific issues.

### Future Experimentation and Enhancements

   - **Advanced Customizations**:
     - Explore creating advanced custom fields and scripts tailored to specific infrastructure needs.
     - Investigate using plugins for extending NetBox’s functionality and introducing new modules (e.g., advanced logging, reporting tools).

   - **Enhanced Automation**:
     - Integrate with CI/CD pipelines to keep infrastructure data in sync with deployed configurations.
     - Automate IP allocation and VLAN provisioning based on predefined rules.

   - **Monitoring Integration**:
     - Test integration with monitoring solutions (e.g., Prometheus, Grafana) to pull data from NetBox, allowing for real-time network visibility.
     - Evaluate webhook integration for automated alerting and network status updates.

---

### Summary

   - NetBox is a powerful tool for IPAM and DCIM, with extensive customization options and API support.
   - Deployment with Docker Compose offers a fast setup process, though it’s more suited for testing and development than production at large scales.
   - Future improvements could focus on automation, integration with CI/CD workflows, and enhanced monitoring to maximize the value of NetBox in managing network infrastructure.

---
