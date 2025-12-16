-- Purpose: Create users table.
-- We need to keep users data somewhere. 

CREATE TABLE "users" (
  "id" uuid PRIMARY KEY,
  "first_name" varchar(50),
  "last_name" varchar(50),
  "email" varchar(50),
  "phone_number" varchar(50),
  "created_at" timestamp,
  "updated_at" timestamp,
  "is_deleted" bool
);
