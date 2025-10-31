# PostgreSQL Distributed Database Demo

This project contains a **PostgreSQL database dump** showcasing a **distributed and federated schema** setup using **PostgreSQL Foreign Data Wrapper (FDW)**.  
It simulates two nodes (`node_a` and `node_b`) and shared public schemas to demonstrate **federated queries**, **trigger-based computation**, and **business rule enforcement**.

---

## Database Overview

### Key Features
- Multi-schema setup:
  - `node_a` and `node_b` simulate distributed database nodes.
  - `public` schema hosts shared functions, triggers, and control tables.
- Uses **`postgres_fdw`** for cross-database communication.
- Includes **views**, **foreign tables**, **functions**, and **triggers**.
- Business logic integrated via:
  - Expense limit validation
  - Automatic recomputation of project totals
  - Audit trail logging

---

## 🧩 Database Objects Summary

| Type | Name | Description |
|------|------|-------------|
| **Schemas** | `node_a`, `node_b`, `public` | Logical partitions (distributed simulation) |
| **Extensions** | `postgres_fdw` | Enables foreign table access |
| **Foreign Server** | `proj_link` | Connects to remote PostgreSQL database (`CCR`) |
| **Foreign Tables** | `node_a.contractor`, `public.expense_b_remote` | Federated data references |
| **Functions** | `fn_should_alert`, `recompute_project_totals`, `trg_expense_check` | Implements logic for threshold alerts, auditing, and validation |
| **Triggers** | `expense_limit_trigger`, `trg_expense_recompute` | Enforce business rules and project total updates |
| **Views** | `public.expense_all`, `node_a.expense_all` | Combine multiple expense tables into unified views |
| **Audit Table** | `project_audit` | Tracks before/after totals during updates |
| **Rules Table** | `business_limits` | Holds configurable spending thresholds |

---

##  Prerequisites

- PostgreSQL **v16+**
- pgAdmin 4 or psql CLI
- The extension `postgres_fdw` must be enabled
- Local PostgreSQL server credentials:
  - **Host:** `localhost`
  - **Port:** `5432`
  - **User:** `postgres`
  - **Password:** `1234`
  - **Database:** `CCR`

---

##  Installation Guide

### 1. Create a New Database
In pgAdmin or psql, create a new empty database:
```sql
CREATE DATABASE CCR;
```

### 2. Restore from SQL Dump

Option A – Using pgAdmin

Open pgAdmin and connect to your PostgreSQL server.

Right-click on your CCR database → Query Tool.

Open the provided .sql file (this repository's dump).

Click Execute (▶) to run all commands.


Option B – Using Command Line
```BASH
psql -U postgres -d CCR -f distributed_db_dump.sql
```
