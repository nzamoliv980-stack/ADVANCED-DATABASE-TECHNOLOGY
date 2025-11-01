# ADVANCED-DATABASE-TECHNOLOGY
# CMS Database (PostgreSQL)

This repository contains a **PostgreSQL database dump** for a Construction Management System (CMS).  
The database stores information about projects, contractors, payments, expenses, equipment, and materials.  
It is designed to help track project budgets, manage resources, and monitor contractor activity.

---

##  Database Overview

**Database name:** `CMS`  
**PostgreSQL version:** 16.10  
**Encoding:** UTF8

### Main Entities

| Table | Description |
|:------|:-------------|
| `contractor` | Stores contractor details such as name, contact info, and experience. |
| `project` | Contains information about construction projects, including budget, location, and timeline. |
| `expense` | Tracks all expenses for each project with validation against the project budget. |
| `payment` | Records payments made to contractors for specific projects. |
| `equipment` | Manages equipment allocated to projects, their costs, and status. |
| `material` | Keeps track of materials, suppliers, costs, and quantities per project. |

---

## ⚙️ Functional Logic

### 1. **Trigger Function**
#### `check_project_budget()`
Ensures total expenses for a project do not exceed its allocated budget.
```sql
CREATE FUNCTION public.check_project_budget() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  total_expenses NUMERIC(10,2);
  project_budget NUMERIC(10,2);
BEGIN
  SELECT COALESCE(SUM(amount), 0)
  INTO total_expenses
  FROM expense
  WHERE projectid = NEW.projectid;

  SELECT budget
  INTO project_budget
  FROM project
  WHERE projectid = NEW.projectid;

  IF (total_expenses + NEW.amount) > project_budget THEN
    RAISE EXCEPTION 'Error: Total expenses exceed the project budget.';
  END IF;
  RETURN NEW;
END;
$$;
