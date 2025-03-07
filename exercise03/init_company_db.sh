#!/bin/bash
set -e

# Variables
POSTGRES_USER="tremend"
POSTGRES_PASSWORD="securepassword"
POSTGRES_DB="company_db"
PS_CEE_USER="ps_cee"
PS_CEE_PASSWORD="adminpassword"
SQL_SCRIPT="/populatedb.sql"    # Ensure this file is copied into the container
DUMP_FILE="/dumpfile.sql"
LOG_FILE="/query_results.log"
DB_HOST=${DB_HOST:-localhost}   # Defaults to localhost unless overridden

echo "Waiting for PostgreSQL to start..."
attempt=1
max_attempts=5
until pg_isready -h "$DB_HOST" -U "$POSTGRES_USER" > /dev/null 2>&1 || [ $attempt -gt $max_attempts ]; do
    echo "Attempt $attempt/$max_attempts: PostgreSQL not ready, waiting..."
    sleep 2
    attempt=$((attempt+1))
done

if ! pg_isready -h "$DB_HOST" -U "$POSTGRES_USER" > /dev/null 2>&1; then
    echo "PostgreSQL is still not ready. Exiting."
    exit 1
fi

echo "PostgreSQL is ready."

echo "=== Dropping existing tables if they exist ==="
psql -h "$DB_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<EOF
DROP TABLE IF EXISTS salaries CASCADE;
DROP TABLE IF EXISTS employees CASCADE;
DROP TABLE IF EXISTS departments CASCADE;
EOF

echo "=== Importing dataset with foreign key checks disabled ==="
if [ -f "$SQL_SCRIPT" ]; then
  psql -h "$DB_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<EOF
SET session_replication_role = replica;
\i $SQL_SCRIPT
SET session_replication_role = DEFAULT;
EOF
else
  echo "SQL script $SQL_SCRIPT not found. Exiting."
  exit 1
fi

echo "=== Cleaning up inconsistent salary rows ==="
psql -h "$DB_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DELETE FROM salaries WHERE NOT EXISTS (SELECT 1 FROM employees WHERE employees.employee_id = salaries.employee_id);"

echo "=== Creating second admin user: $PS_CEE_USER ==="
psql -h "$DB_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$PS_CEE_USER') THEN CREATE ROLE $PS_CEE_USER WITH LOGIN PASSWORD '$PS_CEE_PASSWORD' SUPERUSER; END IF; END \$\$;"

echo "Logging query results to $LOG_FILE"
echo "=== Query Results ===" > "$LOG_FILE"

echo "=== Running query: Total number of employees ==="
psql -h "$DB_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT COUNT(*) AS total_employees FROM employees;" >> "$LOG_FILE"

read -p "Enter department name: " dept_name
echo "=== Running query: Employees in department '$dept_name' ===" >> "$LOG_FILE"
psql -h "$DB_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT first_name, last_name FROM employees WHERE department_id = (SELECT department_id FROM departments WHERE department_name = '$dept_name');" >> "$LOG_FILE"

echo "=== Running query: Highest and lowest salaries per department ==="
psql -h "$DB_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT d.department_name, MAX(s.salary) AS highest_salary, MIN(s.salary) AS lowest_salary FROM salaries s JOIN employees e ON s.employee_id = e.employee_id JOIN departments d ON e.department_id = d.department_id GROUP BY d.department_name;" >> "$LOG_FILE"

echo "=== Dumping the database to a file ==="
pg_dump -h "$DB_HOST" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$DUMP_FILE"

echo "All tasks completed. Query results saved in $LOG_FILE and database dump in $DUMP_FILE."
