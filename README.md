# Construction Management System (CMS) – PostgreSQL

> **README.md**

## Overview
This project implements a **Construction Management System (CMS)** using **PostgreSQL**. It manages construction projects, contractors, materials, equipment, expenses, and payments, and enforces business rules such as **project budget control** using triggers and functions.

This README **updates and supersedes** earlier MySQL/MariaDB-oriented documentation by aligning it with the current **PostgreSQL SQL dump (`CAT.sql`)**.

---

## Database Information
- **Database Name:** `construction_management` (recommended)
- **DBMS:** PostgreSQL 16+
- **SQL Dump File:** `CAT.sql`
- **Encoding:** UTF-8

---

## Core Features
- Project and contractor management
- Material and equipment tracking per project
- Expense recording with **automatic budget validation**
- Contractor payments management
- Referential integrity via foreign keys
- Advanced objects: **functions, triggers, views**

---

## Schema Overview
### Main Tables
- `contractor`
- `project`
- `material`
- `equipment`
- `expense`
- `payment`

### Relationships
- One contractor → many projects
- One project → many materials, equipment records, expenses, and payments

---

## Advanced Database Objects

### Trigger Function: `check_project_budget()`
Prevents inserting an expense when the total expenses exceed the project budget.

- Executes **BEFORE INSERT** on `expense`
- Calculates cumulative expenses per project
- Raises an exception if the budget limit is exceeded

### Trigger
```sql
CREATE TRIGGER check_project_budget
BEFORE INSERT ON expense
FOR EACH ROW
EXECUTE FUNCTION check_project_budget();
```

### View: `total_payment`
Summarizes total project budgets by contractor.

```sql
SELECT contractorid, SUM(budget) AS total_budget
FROM project
GROUP BY contractorid;
```

---

## Installation & Setup (PostgreSQL)

1. Create the database:
```sql
CREATE DATABASE construction_management;
```

2. Connect to the database:
```sql
\c construction_management
```

3. Import the SQL dump:
```bash
psql -U postgres -d construction_management -f CAT.sql
```

4. Verify objects:
```sql
\dt
\df
\dv
```

---

## Sample Data
The dump includes sample records for contractors, projects, materials, and expenses to allow immediate testing of queries, triggers, and views.

---

## Usage Examples
- Add projects and assign contractors
- Insert expenses (budget is validated automatically)
- Query contractor-level budget summaries via `total_payment`

---

## Notes on Previous Documentation
If you have an older README referencing **MySQL/MariaDB** (phpMyAdmin, `cms.sql`, etc.), consider this document the **authoritative and updated reference** for the PostgreSQL implementation.

---

 


---


