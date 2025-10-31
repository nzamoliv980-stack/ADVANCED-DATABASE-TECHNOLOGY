# 🏗️ Construction Management System (CMS) Database

## 📋 Overview
This SQL dump file represents a **Construction Management System (CMS)** database built with **MariaDB / MySQL**.  
It is designed to manage construction projects, contractors, materials, equipment, expenses, and payments efficiently.  

The database includes foreign key relationships, data validation through triggers, and a view for project payment summaries.

---

## 🧱 Database Information
- **Database Name:** `cms`  
- **SQL Dump Source:** phpMyAdmin 5.2.1  
- **Server Version:** 10.4.28-MariaDB  
- **PHP Version:** 8.2.4  
- **Character Set:** `utf8mb4`  

---

## ⚙️ How to Import the Database

1. **Open phpMyAdmin** or connect to your MySQL/MariaDB server.
2. **Create a new database** named `cms`:
   ```sql
   CREATE DATABASE cms;
   USE cms;
## Import the SQL dump file:

In phpMyAdmin: click Import → Choose File → Upload the SQL dump.

Or via terminal:

```bash
mysql -u root -p cms < cms.sql
```

The system will automatically create:

- All required tables,
- Insert sample data,
- Define foreign keys,
- And create the check_project_budget trigger.
