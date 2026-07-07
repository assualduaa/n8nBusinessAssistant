# How to Run the AI Salon Business Assistant (Explained Simply)

This guide walks you through everything, from zero, assuming you're starting fresh. Follow the
steps in order — don't skip ahead.

---

## What you're building

A chat box where you type questions like "How many appointments happened today?" and a robot
(powered by Google's Gemini AI) looks up the real answer in a database and tells you in plain
English.

Three things work together:
1. **Docker** — a program that runs other programs (like n8n and a database) in neat little boxes
   called "containers," so you don't have to install anything messy directly on your computer.
2. **n8n** — the tool where we build the actual chatbot workflow (the brain's wiring diagram).
3. **MySQL** — the database that stores all the salon's appointments, staff, customers, and sales.

---

## Step 1: Install Docker Desktop

Docker Desktop is the app that lets your computer run containers.

1. Go to https://www.docker.com/products/docker-desktop/ and download it for Windows.
2. Install it like any normal program (keep clicking Next).
3. Open Docker Desktop once. Leave it running in the background — everything else needs it.

You'll know it worked if you see the little whale icon in your system tray, and opening Docker
Desktop shows "Containers" and "Images" on the left without errors.

---

## Step 2: Get the project files ready

You should already have a folder here:
```
C:\Users\user\Documents\Claude\Projects\n8n Workflow Setup
```
Inside it, check that these files exist:
- `docker-compose.yml` — tells Docker what containers to create (n8n + MySQL)
- `.env.example` — a template for your passwords
- `salon-assistant\mysql_init.sql` — the file that fills the database with sample data
- `salon-assistant\DESIGN.md` — the full technical design (for reference)
- `salon-assistant\HOW_TO_RUN.md` — this file

### Create your real `.env` file

`.env.example` is just a template — Docker won't read it directly. Make a copy named `.env` in
the same folder, and open it in Notepad. It should look like this (feel free to change the
passwords to anything you like, just remember them):

```
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=changeme
TZ=UTC
MYSQL_ROOT_PASSWORD=changeme_root
MYSQL_USER=salon_app
MYSQL_PASSWORD=changeme_app
```

Save it as `.env` (not `.env.txt` — in Notepad's Save dialog, choose "All Files" as the type so
it doesn't sneak a `.txt` on the end).

---

## Step 3: Start Docker containers

1. Open Command Prompt (search "cmd" in the Start menu).
2. Move into your project folder:
   ```
   cd "C:\Users\user\Documents\Claude\Projects\n8n Workflow Setup"
   ```
3. Start everything:
   ```
   docker compose up -d
   ```
   (`-d` means "run in the background, give me my terminal back")
4. Check both containers are running:
   ```
   docker ps
   ```
   You should see two rows: one named `n8n`, one named `salon-mysql`.

**Wait about 30 seconds** the very first time — MySQL needs a moment to set itself up and load
the sample data from `mysql_init.sql`.

If you ever need to stop everything: `docker compose down`. To start again later: `docker
compose up -d` (your data stays saved in between, unless you also add `-v` to the down command,
which wipes it).

---

## Step 4: Open n8n in your browser

Go to: http://localhost:5678

Log in with the `N8N_BASIC_AUTH_USER` / `N8N_BASIC_AUTH_PASSWORD` you set in your `.env` file.

---

## Step 5: Get a free Gemini API key

This is the "brain" — Google's AI that reads your question and figures out what to do.

1. Go to https://aistudio.google.com/apikey
2. Sign in with a Google account.
3. Click **Create API key** — if asked, create a new project (any name is fine, e.g. "salon
   assistant").
4. Copy the key it gives you (long string of letters/numbers). Keep this safe — treat it like a
   password.

---

## Step 6: Build the workflow in n8n

In n8n, click **+ New workflow**. Add these pieces one at a time:

### 6.1 — Chat Trigger
Search "chat" in the node panel, add **Chat Trigger**. This is the entry point — it gives you a
little chat box to type questions into.

### 6.2 — Preprocess Input (optional but recommended)
Add a **Set** node after Chat Trigger. This just tidies up the question text before it goes to
the AI (trims extra spaces, tags the conversation with a session ID). Not strictly required —
you can skip this and connect Chat Trigger straight to the AI Agent if you want the simplest
possible version.

### 6.3 — AI Agent
Search "AI Agent", add it, connect it after your previous node. This is the decision-maker: it
reads the question, decides whether it needs to look something up, and writes the final answer.

Click into it and paste this into the **System Message** field (Options → System Message):

```
SYSTEM:
You are the AI Business Assistant for a salon chain. You answer manager questions about appointments, revenue, employees, customers, and products by querying a MySQL database.

DATABASE SCHEMA:
- branches(branch_id, name, city)
- employees(employee_id, name, branch_id, role, hire_date)
- customers(customer_id, name, phone, join_date, branch_id)
- services(service_id, name, price, duration_minutes)
- products(product_id, name, category, price)
- appointments(appointment_id, customer_id, employee_id, branch_id, service_id, appointment_date, appointment_time, status['Completed'|'Cancelled'|'No-show'|'Booked'], amount)
- product_sales(sale_id, appointment_id, customer_id, employee_id, branch_id, product_id, sale_date, quantity, amount)
- vw_transactions(transaction_id, type['appointment'|'product_sale'], customer_id, employee_id, branch_id, item_id, transaction_date, amount) -- use this view for any revenue/sales question, it already combines completed appointments + product sales.

RULES:
- Use the SQL tool for any question requiring real data. Never invent numbers.
- Only ever generate SELECT statements. Never write INSERT, UPDATE, DELETE, DROP, ALTER, TRUNCATE, or GRANT statements under any circumstances.
- Use vw_transactions for revenue/sales aggregation questions; use appointments directly only for questions about appointment counts/status, not revenue.
- "Today"/"yesterday"/"this month"/"last week" are relative to the database's current date -- use MySQL date functions (CURDATE(), DATE_SUB(CURDATE(), INTERVAL n DAY), DATE_FORMAT(col,'%Y-%m'), etc.), never hardcode a date.
- This database runs in MySQL's default ONLY_FULL_GROUP_BY mode: every non-aggregated column in the SELECT list must also appear in GROUP BY (e.g. GROUP BY e.employee_id, e.name).
- If a query returns no rows, say so plainly instead of guessing.
- If the question is ambiguous, state the assumption you're using in your answer.
- If the question is unrelated to the salon's business data, politely say you can only answer questions about salon appointments, revenue, employees, customers, and products.
- Keep answers concise: lead with the direct answer, then one short supporting sentence if useful.

OUTPUT FORMAT:
Plain natural-language sentence(s) for the chat user. No markdown tables, no JSON.
```

Do **not** paste the whole DESIGN.md document here — just this block, nothing else. A bloated
system message burns through your free API quota much faster.

### 6.4 — Google Gemini Chat Model
Under the AI Agent, click the small **+** next to "Chat Model". Search "Gemini", add **Google
Gemini Chat Model**. Create a new credential, paste in your API key from Step 5. For the model
name, try `models/gemini-2.5-flash` (if you get quota errors, try `models/gemini-1.5-flash`
instead — free-tier limits vary by model).

### 6.5 — Window Buffer Memory
Under the AI Agent, click **+** next to "Memory". Search "Window Buffer Memory", add it. This
lets the assistant remember the last few messages in a conversation (e.g. "what about last
month?" after asking about this month).

### 6.6 — MySQL Tool (the important one)
Under the AI Agent, click **+** next to "Tool". Search "mysql", add **MySQL Tool**. Set it up:

- **Credential**: create new —
  - Host: `salon-mysql`
  - Port: `3306`
  - Database: `salon`
  - User: `salon_app`
  - Password: (whatever you put for `MYSQL_PASSWORD` in your `.env`)
- **Operation**: change from the default to **Execute SQL**
- **Query**: click into the box, delete whatever's there, and type:
  ```
  {{ $fromAI("query", "A single SELECT-only SQL statement to run against the salon schema. Never use INSERT, UPDATE, DELETE, DROP, ALTER, TRUNCATE, or GRANT.", "string") }}
  ```

### 6.7 (Optional) Validate Answer / Fallback
You can add an **IF** node after the Agent that checks the output isn't empty, with a **Set**
node on the "false" branch saying "Sorry, I couldn't find an answer to that." This is a safety
net, not required to get things working.

---

## Step 7: Save and activate

Click **Save** (top right), then toggle the workflow to **Active**.

---

## Step 8: Test it

Click **Chat** (usually a button at the bottom of the canvas) and type:

```
Which employee generated the highest sales?
```

You should get a real, specific answer (a name and a number), not an error. If something goes
wrong, check:
- Are both Docker containers running? (`docker ps`)
- Did you wait ~30 seconds after first starting Docker for MySQL to finish setting up?
- Is the MySQL Tool's host exactly `salon-mysql` (no typos, no spaces)?
- Is the system message just the short block above, not the whole design document?
- Getting a "429 / quota" error? Wait a minute — free-tier Gemini allows a limited number of
  requests per minute.

---

## Good questions to try once it's working

- How many appointments happened today?
- Which employee generated the highest sales?
- Which branch earned the most revenue this month?
- How many new customers joined last week?
- Which product sells the most?
- Show yesterday's revenue.
- Average appointment value.
- Top 5 customers.
- Lowest performing employee.
- Sales by branch.

That's it — you now have a working AI business assistant, built and explained from scratch.
