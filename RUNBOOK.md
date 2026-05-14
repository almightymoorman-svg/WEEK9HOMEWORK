# Runbook: External Application Global Load Balancer (ClickOps)

This runbook walks through configuring a fully functional external application global HTTPS load balancer in GCP using the console. The backend is a Managed Instance Group (MIG). By the end, you should have a working LB with health checks that distributes traffic across your MIG instances.

---

## Prerequisites

- GCP project with billing enabled and sufficient IAM permissions (at minimum: Compute Admin, Load Balancer Admin)
- A running **Managed Instance Group** (MIG) already created with:
  - An instance template that runs a web server (e.g., Apache or Nginx on port 80)
  - At least 1 instance running (2+ recommended to actually see load balancing in action)
  - A target tag applied to instances (e.g., `http-server`) — you'll need this for firewall rules
- Firewall rule allowing traffic on port **80** from the Google health check IP ranges:
  - `130.211.0.0/22` and `35.191.0.0/16`
  - This rule should target the same tag as your MIG instances
- An SSL certificate (managed or self-signed) if you want HTTPS end-to-end. For testing, GCP-managed certs work fine — just note they require a real domain and DNS propagation.
- DNS access if using GCP-managed SSL certs (you'll need to point a domain at the LB IP after creation)

---

## Step 1: Start the Load Balancer Creation

1. Navigate to **Network Services → Load Balancing** in the GCP console
2. Click **Create Load Balancer**
3. Under "Application Load Balancer (HTTP/HTTPS)", click **Start configuration**
4. Select:
   - **From Internet to my VMs or serverless services** (external)
   - **Global** — this is key; don't pick regional here
5. Click **Continue**

---

## Step 2: Configure the Backend Service

This is where you wire the MIG in.

1. Click **Backend configuration**
2. Click **Create a backend service**
3. Fill out:
   - **Name**: something descriptive, e.g., `web-backend-service`
   - **Backend type**: Instance group
   - **Protocol**: HTTP (traffic from LB to backend is HTTP; TLS terminates at the LB)
   - **Named port**: `http` (make sure your MIG has a named port mapping for this — if not, go back and set it)
4. Under **Backends**, click **Add backend**:
   - Select your MIG from the dropdown
   - **Port numbers**: 80
   - **Balancing mode**: Rate or Utilization — for most web workloads, **Rate (requests per second)** is fine; Utilization is CPU-based
   - Leave max RPS or utilization at default for now unless you have specific scaling targets
5. **Health check** — click **Create a health check**:
   - **Name**: e.g., `web-health-check`
   - **Protocol**: HTTP
   - **Port**: 80
   - **Request path**: `/` (or whatever path your app returns a 200 on — a dedicated `/health` endpoint is better practice)
   - **Check interval**: 10 seconds
   - **Timeout**: 5 seconds
   - **Healthy threshold**: 2 (needs 2 consecutive successes to be marked healthy)
   - **Unhealthy threshold**: 3 (3 consecutive failures to be marked unhealthy)
   - Click **Save and continue**
6. **Cloud CDN**: Enable if desired (optional for this runbook)
7. Click **Create**

> **Key setting note**: The named port (`http:80`) must be configured on the MIG, not just the instance template. If you skip this, the backend service won't know how to reach instances and health checks will fail. Set it under the MIG's "Port mapping" configuration.

---

## Step 3: Configure the Frontend (Host and Path Rules / URL Map)

1. Click **Host and path rules** (URL map configuration)
2. The default rule sends all traffic to the backend service you just created — this is fine for basic setups
3. If you need path-based routing (e.g., `/api/*` to a different backend), add rules here:
   - Click **Add host and path rule**
   - Set the host and path pattern
   - Select the target backend service
4. For a basic single-backend setup, leave the default rule as-is and move on

---

## Step 4: Configure the Frontend (IP and Port)

1. Click **Frontend configuration**
2. Click **Add Frontend IP and Port**
3. Configure:
   - **Name**: e.g., `web-lb-frontend`
   - **Protocol**: HTTPS (recommended) or HTTP for testing
   - **IP version**: IPv4
   - **IP address**: Click **Create IP address** → give it a name → **Reserve**. This gives you the anycast IP.
   - **Port**: 443 for HTTPS, 80 for HTTP
   - **Certificate**: Select or create an SSL cert if using HTTPS
     - For GCP-managed: select "Create a new certificate", enter your domain, leave Google-managed selected
     - Note: managed certs won't provision until DNS resolves to the LB IP, so there's a delay here
4. If you want to support both HTTP and HTTPS: add a second frontend on port 80 and optionally add a redirect rule (HTTP → HTTPS)
5. Click **Done**

---

## Step 5: Review and Create

1. Click **Review and finalize** — check that:
   - Backend service shows your MIG and health check
   - Frontend shows the reserved IP and correct port/protocol
   - URL map default rule points to your backend
2. Click **Create**

---

## Step 6: Verify

Allow 3–5 minutes for the LB to fully provision.

1. Go to **Load Balancing** and click your new LB
2. Check **Backend services** — instances should show a green checkmark once health checks pass
   - If health checks are failing, verify the firewall rule for GCP health check ranges is in place (see Prerequisites)
3. Grab the IP from the frontend and test in a browser or with curl:
   ```bash
   curl -v http://<LB_IP>/
   ```
4. If using HTTPS with a managed cert, wait for cert provisioning (can take 10–30 min after DNS propagates) and test:
   ```bash
   curl -v https://yourdomain.com/
   ```

---

## Key Settings Explained

| Setting | Value | Why |
|---|---|---|
| Backend protocol | HTTP | TLS terminates at the LB; internal traffic stays HTTP. Simpler, and backend instances don't need certs |
| Health check path | `/` | Works for basic setups. Use a dedicated health endpoint in prod so a broken page doesn't look healthy |
| Balancing mode | Rate (RPS) | More predictable for web traffic than CPU utilization; doesn't depend on instance load |
| Health check interval | 10s / timeout 5s | Balances detection speed vs. flapping. Shorter intervals detect failures faster but generate more check traffic |
| Anycast IP | Reserved static IP | Required for global LB — this is what Google advertises from all POPs. Don't use ephemeral; it'll change |
| Named port | `http:80` | Required for the backend service to know how to reach the MIG instances. Easy to miss |

---

## Common Issues

- **Health checks failing**: Almost always a missing firewall rule. Make sure `130.211.0.0/22` and `35.191.0.0/16` can reach port 80 on your instances via the target tag.
- **Certificate not provisioning**: DNS for your domain hasn't resolved to the LB IP yet. Check with `dig yourdomain.com` and compare to the LB's frontend IP.
- **502 errors**: Backend is getting traffic but returning errors. Check that your web server is actually running on the instances — SSH in and test locally.
- **Named port error**: Backend service can't find the port. Go to the MIG, click Edit, and verify the port name mapping is set.
