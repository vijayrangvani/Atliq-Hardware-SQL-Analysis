# Business Questions - Atliq Hardware SQL Analysis 🛠️💻

This document outlines the key business questions addressed in the **Atliq Hardware SQL Analysis** project. Each question is answered using specific SQL queries provided in the main SQL file.

---

### 1. **Which markets does "Atliq Exclusive" operate in within the APAC region?**

- **Objective**: Identify all the markets where "Atliq Exclusive" operates its business in the APAC region.
- **SQL Query**:

    ```sql
    SELECT DISTINCT market 
    FROM dim_customer
    WHERE customer = 'Atliq Exclusive' 
      AND region = 'APAC';
    ```

---

### 2. **What is the percentage increase in unique products in 2021 vs. 2020?**

- **Objective**: Calculate the percentage growth in unique products sold in 2021 compared to 2020.
- **SQL Query**:

    ```sql
    WITH dist_prod AS (
      SELECT 
          fiscal_year,
          COUNT(DISTINCT product_code) AS product_cnt
      FROM fact_sales_monthly
      WHERE fiscal_year IN (2020, 2021)
      GROUP BY fiscal_year
    )
    SELECT 
      dp_2020.product_cnt AS unique_products_2020,
      dp_2021.product_cnt AS unique_products_2021,
      ROUND(100 * (dp_2021.product_cnt - dp_2020.product_cnt) / dp_2020.product_cnt, 2) AS percentage_chg
    FROM dist_prod dp_2020
    JOIN dist_prod dp_2021
      ON dp_2020.fiscal_year = 2020 AND dp_2021.fiscal_year = 2021;
    ```

---

### 3. **Report unique product counts by segment, sorted by count.**

- **Objective**: List unique product counts per segment, sorted in descending order of product counts.
- **SQL Query**:

    ```sql
    SELECT segment, COUNT(DISTINCT product_code) AS product_count
    FROM dim_product
    GROUP BY segment
    ORDER BY product_count DESC;
    ```

---

### 4. **Which segment had the most increase in unique products in 2021 vs. 2020?**

- **Objective**: Identify the segment that saw the largest increase in unique products sold between 2020 and 2021.
- **SQL Query**:

    ```sql
    WITH unique_products AS (
      SELECT 
          p.segment,
          s.fiscal_year,
          COUNT(DISTINCT p.product_code) AS product_count
      FROM dim_product p
      JOIN fact_sales_monthly s
        ON p.product_code = s.product_code
      WHERE s.fiscal_year IN (2020, 2021)
      GROUP BY p.segment, s.fiscal_year
    )
    SELECT 
      up_2020.segment,
      up_2020.product_count AS product_count_2020,
      up_2021.product_count AS product_count_2021,
      (up_2021.product_count - up_2020.product_count) AS difference
    FROM unique_products up_2020
    JOIN unique_products up_2021
      ON up_2020.segment = up_2021.segment
    WHERE up_2020.fiscal_year = 2020 AND up_2021.fiscal_year = 2021
    ORDER BY difference DESC;
    ```

---

### 5. **Products with the highest and lowest manufacturing costs.**

- **Objective**: Find the products with the highest and lowest manufacturing costs.
- **SQL Query**:

    ```sql
    WITH temp AS (
      SELECT 
          p.product_code,
          m.manufacturing_cost,
          DENSE_RANK() OVER (ORDER BY manufacturing_cost DESC) AS top_rank,
          DENSE_RANK() OVER (ORDER BY manufacturing_cost ASC) AS bottom_rank
      FROM dim_product p
      JOIN fact_manufacturing_cost m
        ON p.product_code = m.product_code
    )
    SELECT product_code, manufacturing_cost
    FROM temp
    WHERE top_rank = 1 OR bottom_rank = 1
    ORDER BY top_rank;
    ```

---

This concludes the list of business questions and their respective SQL queries for the Atliq Hardware SQL Analysis project.
