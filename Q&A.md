# Q&A

---

## Load Balancers

### How does load balancing contribute to fault tolerance? What about high availability?

These two concepts are related but not the same thing, so worth separating them a bit.

**Fault tolerance** is basically the system's ability to keep running even when something breaks. Load balancers help here because they distribute traffic across multiple backend instances. If one instance crashes or becomes unhealthy, the load balancer stops sending traffic to it and routes requests to the remaining healthy instances. The user (hopefully) never notices. So the system tolerates the fault without going down.

**High availability** is more about ensuring the system is accessible as close to 100% of the time as possible. Load balancers contribute to this by removing single points of failure — instead of one server handling everything (and taking everything down with it if it fails), you've got a pool of servers. On top of that, a global load balancer specifically can route around regional outages by sending traffic to a different region entirely. That's a pretty big deal for availability.

So: load balancing contributes to fault tolerance by rerouting traffic away from broken things, and it contributes to high availability by making sure there's always somewhere healthy to send traffic.

---

### Do global load balancers decrease latency for end users? Why or why not?

Yes, they do — and it's mainly because of how they handle where traffic enters the Google network.

With a global load balancer, user requests hit Google's network at the nearest **Point of Presence (POP)**, which is typically pretty close to the user geographically. Once the request is on Google's backbone network, it travels to the backend over Google's private infrastructure, which is way faster and more reliable than the public internet.

Without a global load balancer, a user in Tokyo might have their request travel all the way across the public internet to a backend in Iowa before getting a response. That's a lot of hops and a lot of variability. With the global LB, their traffic hits a Google POP in Asia and then travels over Google's internal network to the backend — much less latency.

There's also the fact that a global LB can route to the *nearest healthy backend*, so if you have backends in multiple regions, users in Asia might hit an Asia region rather than always being sent to the US. That obviously cuts down round-trip time.

---

### What are LB health checks for? Do we always need them? Is a LB different from a reverse proxy?

**Health checks** are how the load balancer figures out which backends are actually capable of handling traffic. The LB periodically pings each backend instance (usually on a specific port or path like `/health`), and if an instance stops responding or returns an error, the LB marks it unhealthy and stops sending it traffic. Once it recovers, it gets added back. Without health checks, the LB would happily send requests to a crashed instance, and those requests would just fail.

Do we always need them? Technically you *can* skip them in some setups, but you really shouldn't. Without health checks, you have no automatic way to remove broken instances from rotation. So in any production setup, yes — they're basically required. The only scenario where you might skip them is something super simple or internal where you're okay with manual intervention if something breaks.

**Is a LB different from a reverse proxy?**

Kind of, but they're closely related. A reverse proxy sits in front of your servers and forwards client requests to the appropriate backend — it's working on behalf of the server, not the client. Load balancers do this too, but the primary focus of a load balancer is distributing traffic across *multiple* backends. 

In practice, most load balancers function as reverse proxies. GCP's HTTPS load balancer definitely does — it terminates TLS, inspects the request, and forwards it. The terms overlap a lot. The distinction is mostly conceptual: a reverse proxy is the broader concept, load balancing is a specific function that reverse proxies often provide.

---

### What are LB routing rules and URL maps for? Give an example or two.

URL maps and routing rules are how you tell the load balancer where to send traffic based on the content of the request — specifically the URL path or the hostname.

Without them, all traffic goes to one backend. With them, you can do much more intelligent routing.

**Example 1 — Path-based routing:**
Say you have a single domain `myapp.com` but your app has a separate backend for the API and a different one for serving static content. You could set up rules like:
- `/api/*` → send to the API backend service
- `/static/*` → send to a Cloud Storage bucket or CDN backend
- Everything else → send to your main web app backend

This is super common when you're running microservices. Each service can have its own backend but share a single IP and domain.

**Example 2 — Host-based routing:**
You could route based on the subdomain. So:
- `admin.myapp.com` → sends traffic to the admin backend
- `www.myapp.com` → sends to the public-facing app

This lets you keep everything behind one load balancer instead of spinning up separate LBs for every service, which would get expensive and complicated fast.

---

### Explain what an anycast IP address is used for in the context of a global load balancer.

An anycast IP is a single IP address that's advertised from multiple locations simultaneously. When a user sends traffic to that IP, the internet's routing infrastructure automatically directs the request to the *closest* location that's advertising it — not a specific server, just the nearest one geographically.

In the context of GCP's global load balancer, Google advertises the load balancer's IP from POPs all around the world. So when a user in London types your URL, DNS resolves to the same IP that a user in Sydney would get — but London traffic gets routed to a nearby POP in Europe, and Sydney traffic hits a POP in Asia-Pacific. They both used the same IP, but arrived at different network entry points.

This is important because it means the load balancer is effectively "everywhere" at once. Users always enter Google's network at the nearest point, which reduces latency and avoids unnecessary traversal of the public internet. It also helps with failover — if one POP goes down, traffic naturally starts routing to the next nearest one because that location stops advertising the IP.

---

## Cloud Armor

### What does Cloud Armor offer?

Cloud Armor is GCP's security service for protecting applications from attacks at the edge of the network — basically before bad traffic even reaches your actual infrastructure. It sits in front of your global load balancer and gives you the ability to:

- Block or allow traffic based on IP addresses or IP ranges
- Set up security policies with rules to detect and block common web attacks (SQL injection, XSS, etc.) using pre-built or custom rule sets
- Rate limit requests to prevent any one source from overwhelming your service
- Use adaptive protection to automatically detect and respond to DDoS-style attack patterns
- Integrate reCAPTCHA for bot detection

---

### Why is it used in the first place?

The internet is full of automated bots, scrapers, and attackers constantly scanning for vulnerabilities. Without something in front of your application, all of that traffic hits your servers directly. That's a problem for a few reasons — it wastes resources, can cause outages if the traffic volume is high enough, and can expose your app to application-layer exploits that your backend might not handle well.

Cloud Armor puts a filter in front of everything. It can drop malicious requests before they ever reach your backend, which means your actual application doesn't have to deal with that garbage. It's especially useful because it operates at Google's edge — so even massive volumetric attacks get absorbed before they even touch your VPC.

---

### What layer in the OSI model does it operate at? Why is this important and how is it different from VPC firewall rules?

Cloud Armor operates at **Layer 7** — the application layer. This means it can inspect the actual *content* of HTTP/HTTPS requests. It can look at headers, query strings, request bodies, URLs, and cookies to make decisions. That's what allows it to detect things like SQL injection attempts or cross-site scripting — it's reading what's inside the request, not just where it came from.

VPC firewall rules, on the other hand, operate at **Layer 3/4** — the network and transport layers. They make decisions based on things like IP addresses, ports, and protocols. They can say "block all traffic to port 22 from this IP range" but they have no idea what's inside the packets. They can't detect an HTTP request that looks like a SQL injection because they don't look that deep.

This distinction matters a lot because application-layer attacks can look totally legitimate from a network perspective — they use normal ports (80, 443), come from real IP addresses, and use valid protocols. Layer 3/4 firewalls are blind to them. Cloud Armor fills that gap.

---

### What are rate-based rules for?

Rate-based rules let you limit how many requests a single IP address (or a group of IPs) can make within a given time window. If they exceed the threshold, Cloud Armor can block them, redirect them, or send them to a reCAPTCHA challenge.

The main use case is preventing abuse — things like brute-force login attempts, scraping, or layer 7 DDoS attacks where an attacker sends a massive volume of requests from distributed sources. Even if each individual request looks legitimate, the sheer volume causes problems.

For example: you might say no single IP should make more than 100 requests per minute to your login endpoint. Someone trying to brute-force passwords would hit that limit fast and get blocked automatically, without you having to do anything manually.

---

### What is reCAPTCHA and how does it relate to Cloud Armor?

reCAPTCHA is Google's service for distinguishing humans from bots. You've definitely seen it — the "I'm not a robot" checkboxes, or the image challenges where you pick all the traffic lights. It works by analyzing user behavior and signals to determine whether a request is likely from a real human or an automated script.

Cloud Armor integrates with reCAPTCHA Enterprise so that instead of just blocking suspicious traffic outright, you can redirect it to a challenge page. If the user passes (proves they're human), they get through. If they fail or don't engage, they get blocked.

This is useful because sometimes you don't want to hard-block traffic that *might* be legitimate. Rate-based rules can catch bots, but they can also accidentally block real users who happen to be on a shared IP or are just clicking fast. Sending them to a reCAPTCHA challenge is a softer way to filter — legitimate humans pass, bots don't.

---

## Cloud CDN

### What are POPs used for?

POP stands for Point of Presence, and they're basically Google's distributed caching locations spread around the world. When a user requests content, the CDN serves it from the POP closest to them rather than going all the way back to your origin server.

The main benefit is speed — instead of a user in Brazil having to wait for a round trip to a server in the US, they get the response from a Google POP in South America that already has a cached copy. Dramatically lower latency.

---

### What kind of files are served with Cloud CDN?

Cloud CDN is best suited for **static content** — stuff that doesn't change per user and doesn't need to be generated on the fly. Classic examples:

- Images (JPGs, PNGs, SVGs, WebP)
- JavaScript and CSS files
- Videos and audio files
- Fonts
- PDFs and other downloadable documents
- HTML pages that are mostly static

Dynamic content (things that are personalized per user, pulled from a database in real time, etc.) typically can't be effectively cached because the response is different every time. You *can* set up CDN rules for dynamic content in some cases, but it's not the primary use case.

---

### What services can be used with Cloud CDN for the source of content (the origin)?

Cloud CDN can pull content from several different origin types:

- **Compute Engine backends** (VM instance groups — the most common for web apps)
- **Cloud Storage buckets** (great for static assets, no servers needed)
- **Cloud Run services** (serverless containers)
- **App Engine** applications
- **External backends** (servers hosted outside GCP — Cloud CDN can use an internet NEG to point at an external origin)
- **GKE** (via load balancer backends)

So basically anything that sits behind a GCP load balancer can potentially use Cloud CDN as a caching layer in front of it.

---

### Does Cloud CDN help protect against any types of malicious actors or cyberattacks?

Somewhat, but it's not really a security tool. The main benefit from a security standpoint is that caching reduces the volume of requests that actually hit your origin server. If 90% of requests are served from cache, your origin is only seeing 10% of the traffic — so even if someone is trying to overwhelm you with requests, most of them hit the CDN layer and get absorbed before reaching your infrastructure.

That said, Cloud CDN on its own doesn't do any threat analysis or filtering. It's not going to detect malicious payloads or block attackers. That's what Cloud Armor is for. They're often used together — Cloud CDN in front for caching and performance, Cloud Armor for security policy enforcement.

So: CDN provides *some* incidental protection from volumetric attacks just by absorbing traffic, but it's not a substitute for actual security tooling.

---

### Should an enterprise always use Cloud CDN? Why or why not?

Not always — it depends on what the application is actually doing.

Cloud CDN makes a lot of sense if:
- You have a high volume of users in different geographic locations
- A significant portion of your content is static and can be cached
- You want to reduce load on your origin servers and lower egress costs over time

It doesn't really make sense if:
- Your application is mostly dynamic — personalized data, real-time queries, frequently changing content. Caching won't help much and might actually cause problems if stale data gets served.
- Your user base is highly localized (everyone is in one city). The latency benefits of CDN are most noticeable across large geographic distances.
- You're running something internal-only where external CDN serving doesn't apply

There's also cost to consider. CDN adds some overhead, and for low-traffic applications the benefit might not outweigh the complexity and additional cost. It's a tool that should be used when the workload fits it, not something you slap on everything by default.

---

### What is TTL and how does it control content "freshness"?

TTL stands for **Time to Live** — it's how long a cached copy of a piece of content is considered valid before the CDN needs to go check the origin for a fresh version.

When Cloud CDN caches a file, it stores it at the POP with a timer. If a request comes in and the TTL hasn't expired, the CDN serves the cached version without touching your origin. Fast, cheap. When the TTL expires, the next request triggers a check against the origin — if the content hasn't changed, the cache is refreshed with the same data (and the TTL resets). If it has changed, the CDN fetches and stores the new version.

TTL is usually set through HTTP cache-control headers on the origin response (like `Cache-Control: max-age=3600` for a one-hour TTL), or you can configure default TTLs in Cloud CDN directly.

**Freshness** is basically the question of whether the cached copy is still accurate. Short TTLs (seconds to minutes) mean content is very fresh but you're hitting the origin more often. Long TTLs (hours or days) mean better cache performance but potentially stale content if the source file changes. You tune this based on how often your content actually changes — something like your company logo probably has a TTL of days or weeks, while a news feed might have a TTL of 30 seconds.
