# HNG PostgreSQL Data Cleaning Project

This project contains SQL scripts used to inspect and clean the `HNG` PostgreSQL database.

## Files

- `hng_database_cleaning.sql` - Main documented cleaning script.
- `01_clean_hng.sql` - Working cleaning script created during the cleaning process.
- `TRAIN.sql` - Simple query for Lagos customers.
- `tradezone_database.sql` - Database dump/source SQL file.

## Cleaning Covered

- Created backup tables before updates.
- Standardized customer and seller city names.
- Standardized state and account status values.
- Cleaned customer emails by trimming, lowercasing, and converting blanks to `NULL`.
- Standardized product categories.
- Recalculated order item and order totals where reliable source data exists.
- Created review views for unresolved data quality issues.

## Review Views

```sql
SELECT *
FROM data_quality_issues;
```

```sql
SELECT *
FROM duplicate_customer_email_inspection;
```

## Notes

Missing product prices were not guessed. They remain flagged in `data_quality_issues` so revenue analysis can exclude incomplete records.
