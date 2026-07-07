
# 🤖 AI Business Assistant

A chat-based AI agent — built in **n8n** — that answers natural-language business questions by translating them into SQL, querying a live database, and explaining the result in plain language. Built for any business that tracks appointments/orders, staff, customers, and products or services: salons, clinics, gyms, restaurants, retail stores, repair shops, and more.

```
User → Chat Trigger → AI Agent (Gemini) → SQL Tool → real data → AI explains → User
```

---

## 🎯 Aim

Give any business owner or manager a single chat box where they can ask plain-English questions like *"Which staff member generated the highest sales?"* or *"What was yesterday's revenue?"* and get a real, data-backed answer — no dashboards, no SQL knowledge required, and no hallucinated numbers.

The workflow pattern is domain-agnostic. Point it at your own database schema and it works for any business built around the same shape of data: locations/branches, staff, customers, services or products, and transactions.

---
<img width="1918" height="862" alt="image" src="https://github.com/user-attachments/assets/64f4fe6c-574d-4f95-8d81-28499d7b91d2" />
<img width="1896" height="760" alt="image" src="https://github.com/user-attachments/assets/ecacb441-6a0a-4b5d-a574-2fc3039c764e" />

## ✨ Features

- Natural-language → SQL → natural-language answer loop, powered by an n8n **AI Agent**
- Read-only **SQL Tool** integration — the agent can only `SELECT`, never mutate data
- Conversation memory (last 10 messages) for follow-up questions like *"what about last month?"*
- Handles relative dates ("today", "yesterday", "this month") correctly against the live DB clock
- Graceful handling of ambiguous questions, empty results, and out-of-scope queries
- Fully containerized — n8n + MySQL run together via Docker Compose
- Schema-driven design — swap the seed data/schema to adapt to any business type

---

## 🧠 How It Works

| Stage | n8n Node | Purpose |
|---|---|---|
| Trigger | Chat Trigger | Built-in web chat UI, entry point |
| Preprocessing | Set | Trims input, tags session ID |
| LLM Reasoning | AI Agent | Decides whether the question needs data |
| Chat Model | Google Gemini Chat Model | LLM backing the agent (free tier) |
| Memory | Window Buffer Memory | Keeps last 10 messages of context |
| Tool Execution | MySQL Tool | Runs agent-generated, read-only SQL |
| Validation | IF node | Guards against empty/error output |
| Output | Chat Trigger response | Returns final answer to the user |

The included reference schema covers `branches`, `employees`, `customers`, `services`, `products`, `appointments`, and `product_sales`, plus a `vw_transactions` view that unions completed appointments and product sales for revenue queries. This maps cleanly onto most service/retail businesses — rename the tables and you have the same pattern for a clinic (`patients`, `visits`), a gym (`members`, `sessions`), or a restaurant (`orders`, `menu_items`).

---

## 🛠️ Tech Stack

- **[n8n](https://n8n.io/)** — self-hosted workflow/agent orchestration
- **Google Gemini** — LLM (free tier via Google AI Studio)
- **MySQL 8** — business data store, seeded with sample data
- **Docker / Docker Compose** — containerized local environment

---

## 📁 Project Structure

```
n8n Workflow Setup/
├── docker-compose.yml          # n8n + MySQL container definitions
├── .env.example                # Template for environment variables
├── README.md
└── business-assistant/         # reference implementation + docs
    ├── DESIGN.md                # Architecture, schema, system prompt, edge cases
    ├── HOW_TO_RUN.md             # Step-by-step setup guide (zero to running)
    ├── TEST_PLAN.md              # Verified test questions + expected answers
    ├── mysql_init.sql            # Reference schema + seed data (swap for your own)
    └── workflow.json             # Exported n8n workflow
```

> Note: the `business-assistant` folder in this repo is currently populated with a service-business example dataset (appointments/staff/customers). Replace `mysql_init.sql` with your own schema to adapt this to a different type of business — the workflow and agent logic don't need to change, only the schema description in the system prompt.

---

## ✅ Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- A free [Google Gemini API key](https://aistudio.google.com/apikey)

---

## 🚀 Getting Started

1. **Clone this repo**
   ```bash
   git clone <your-repo-url>
   cd "n8n Workflow Setup"
   ```

2. **Configure environment variables**
   ```bash
   cp .env.example .env
   ```
   Edit `.env` and set your own credentials:
   ```
   N8N_BASIC_AUTH_USER=admin
   N8N_BASIC_AUTH_PASSWORD=changeme
   TZ=UTC
   MYSQL_ROOT_PASSWORD=changeme_root
   MYSQL_USER=salon_app
   MYSQL_PASSWORD=changeme_app
   ```

3. **Start the containers**
   ```bash
   docker compose up -d
   docker ps   # confirm "n8n" and the MySQL container are both running
   ```
   First boot takes ~30 seconds while MySQL seeds itself from `mysql_init.sql`.

4. **Open n8n**
   Go to [http://localhost:5678](http://localhost:5678) and log in with your `.env` credentials.

5. **Build/import the workflow**
   Import the workflow JSON, or follow the manual walkthrough in `HOW_TO_RUN.md`, which covers:
   - Adding the Chat Trigger, AI Agent, Gemini Chat Model, Memory, and MySQL Tool nodes
   - Pasting the system prompt (edit the schema section to match your own tables)
   - Wiring the MySQL Tool credential (`host`, `port: 3306`, `db`)

6. **Activate and test**
   Click **Chat** in the n8n canvas and ask:
   ```
   Which staff member generated the highest sales?
   ```

---

## 💬 Example Questions

- How many appointments/orders happened today?
- Which staff member generated the highest sales?
- Which location earned the most revenue this month?
- How many new customers joined last week?
- Top 5 customers
- Sales by location

---

## 🔄 Adapting to a Different Business

This project is a template, not a fixed vertical solution. To point it at a different business:

1. Replace the schema in `mysql_init.sql` with your own tables (keep a similar shape: entities, transactions, a revenue/aggregation view if useful).
2. Update the `DATABASE SCHEMA` block in the AI Agent's system prompt to describe your new tables.
3. Update the example questions to match your domain.
4. Re-seed the database (`docker compose down -v && docker compose up -d`) and retest.

The trigger, agent logic, memory, tool wiring, and validation layer stay the same regardless of business type.

---

## 🔒 Security

- The SQL Tool should use a **read-only** database user in production:
  ```sql
  GRANT SELECT ON <your_database>.* TO 'readonly_user'@'%';
  ```
- `.env` is gitignored — never commit real credentials
- The system prompt explicitly forbids non-`SELECT` SQL as a first layer of defense; the read-only DB user is the real guardrail
- All external inputs (chat messages) are treated as untrusted and cannot alter data, only query it

---

## 📚 Documentation

| Doc | Contents |
|---|---|
| `DESIGN.md` | Full architecture, schema, system prompt, edge-case handling, failure strategy |
| `HOW_TO_RUN.md` | Beginner-friendly, step-by-step setup guide |
| `TEST_PLAN.md` | Accuracy test questions with verified expected answers |
| `mysql_init.sql` | Reference schema + seed data |
| `workflow.json` | Exported n8n workflow for direct import |

---

## 🗺️ Roadmap

- [ ] Caching layer for repeated same-day questions
- [ ] Role-based access (front-line staff vs. owner) for location-level revenue data
- [ ] Scheduled daily summary posted to Slack via n8n Schedule Trigger
- [ ] Pluggable schema configs for common business types (retail, clinic, gym, restaurant)

---


---

## 🙋 Support

For setup issues, check the troubleshooting notes at the bottom of `HOW_TO_RUN.md` (containers running? DB host correct? Gemini quota hit?).
