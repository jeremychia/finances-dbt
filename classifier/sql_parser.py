import logging
import re
import sqlglot
from sqlglot.expressions import Column

logger = logging.getLogger(__name__)


def extract_description_columns(sql_text: str) -> list[str]:
    """
    Extract column names that feed into the `description` alias from a dbt staging SQL file.

    Handles three patterns:
    - Pass-through: `description` (no transformation)
    - Single alias: `some_col as description`
    - Multi-column concat: `concat(col1, col2, col3, ...) as description`

    Returns a list of source column names (lowercased). Raises ValueError if extraction fails.
    """
    logger.debug("Extracting description columns from SQL")
    # Strip Jinja template expressions by replacing with a stub table name
    sql_clean = re.sub(r"\{\{[^}]*\}\}", "source_table", sql_text)

    try:
        parsed = sqlglot.parse_one(sql_clean, dialect="bigquery")
    except Exception as e:
        logger.error(f"Failed to parse SQL: {e}")
        raise ValueError(f"Failed to parse SQL: {e}")

    # Use the top-level SELECT (the outermost/final query)
    if not isinstance(parsed, sqlglot.exp.Select):
        raise ValueError("No top-level SELECT statement found in SQL")
    select_stmt = parsed

    # Find the alias/expression for `description`
    description_expr = None
    for expr in select_stmt.expressions:
        # Check if the alias is "description"
        if (
            hasattr(expr, "alias")
            and expr.alias
            and expr.alias.lower() == "description"
        ):
            description_expr = expr.this
            break
        # Also check bare column named `description` (pass-through case)
        elif (
            isinstance(expr, sqlglot.exp.Column) and expr.name.lower() == "description"
        ):
            description_expr = expr
            break

    # If not found and final SELECT is just *, look in the last CTE
    if description_expr is None and len(select_stmt.expressions) == 1:
        if isinstance(select_stmt.expressions[0], sqlglot.exp.Star):
            # Get the table being selected from
            from_clause = select_stmt.args.get("from_")
            if from_clause:
                table_name = (
                    from_clause.this.name.lower()
                    if hasattr(from_clause.this, "name")
                    else None
                )
                # Look for a CTE with this name
                if table_name and select_stmt.ctes:
                    for cte in select_stmt.ctes:
                        if cte.alias.lower() == table_name:
                            # Look for `description` in this CTE
                            for cte_expr in cte.this.expressions:
                                # Check for aliased description
                                if (
                                    hasattr(cte_expr, "alias")
                                    and cte_expr.alias
                                    and cte_expr.alias.lower() == "description"
                                ):
                                    description_expr = cte_expr.this
                                    break
                                # Check for bare column named description
                                elif (
                                    isinstance(cte_expr, Column)
                                    and cte_expr.name.lower() == "description"
                                ):
                                    description_expr = cte_expr
                                    break

    if description_expr is None:
        raise ValueError("No 'description' column or alias found in SELECT")

    # Extract all column names from the expression
    columns = set()
    for col_node in description_expr.find_all(Column):
        col_name = col_node.name.lower()
        # Skip if it's a known function name or special token (basic filter)
        if col_name not in ("", "null", "true", "false"):
            columns.add(col_name)

    # If the expression is just a bare column name (e.g., "description" from a CTE),
    # try to trace it back through the CTEs to find the actual source columns
    if len(columns) == 1 and isinstance(description_expr, Column):
        bare_col_name = next(iter(columns)).lower()
        # Look for this column in the CTEs
        if select_stmt.ctes:
            for cte in select_stmt.ctes:
                # Check if this CTE defines the column we're looking for
                for cte_expr in cte.this.expressions:
                    cte_alias = None
                    cte_col_expr = None

                    if hasattr(cte_expr, "alias") and cte_expr.alias:
                        cte_alias = cte_expr.alias.lower()
                        cte_col_expr = cte_expr.this
                    elif isinstance(cte_expr, Column):
                        cte_alias = cte_expr.name.lower()
                        cte_col_expr = cte_expr

                    # If this CTE defines our column, extract sources from it
                    if cte_alias == bare_col_name:
                        columns = set()
                        if cte_col_expr:
                            for col_node in cte_col_expr.find_all(Column):
                                col_name = col_node.name.lower()
                                if col_name not in ("", "null", "true", "false"):
                                    columns.add(col_name)
                        # If we found columns in the CTE expression, use them
                        if columns:
                            logger.debug(
                                f"Traced '{bare_col_name}' through CTE to source columns: {sorted(list(columns))}"
                            )
                            return sorted(list(columns))
                        # If CTE just passes through the column, continue looking
                        break

    if not columns:
        logger.error("No source columns found in description expression")
        raise ValueError("No source columns found in description expression")

    logger.debug(f"Found description columns: {sorted(list(columns))}")
    return sorted(list(columns))


def get_description_expression(sql_text: str) -> str:
    """
    Extract the SQL expression that computes `description` from a staging SQL file.

    Returns the expression as a string (e.g., "trim(concat(...))")
    Raises ValueError if extraction fails.
    """
    # Strip Jinja template expressions
    sql_clean = re.sub(r"\{\{[^}]*\}\}", "source_table", sql_text)

    try:
        parsed = sqlglot.parse_one(sql_clean, dialect="bigquery")
    except Exception as e:
        raise ValueError(f"Failed to parse SQL: {e}")

    # Use the top-level SELECT (the outermost/final query)
    if not isinstance(parsed, sqlglot.exp.Select):
        raise ValueError("No top-level SELECT statement found in SQL")
    select_stmt = parsed

    # Find the description expression
    for expr in select_stmt.expressions:
        if (
            hasattr(expr, "alias")
            and expr.alias
            and expr.alias.lower() == "description"
        ):
            # Return the expression as SQL
            return expr.this.sql(dialect="bigquery")
        elif (
            isinstance(expr, sqlglot.exp.Column) and expr.name.lower() == "description"
        ):
            # This is a bare column reference; try to resolve it through CTEs
            try:
                return _resolve_column_through_ctes(select_stmt.ctes, "description")
            except ValueError:
                # If we can't resolve, return the bare column name
                return expr.sql(dialect="bigquery")

    # If not found and final SELECT is just *, look in the last CTE
    if len(select_stmt.expressions) == 1:
        if isinstance(select_stmt.expressions[0], sqlglot.exp.Star):
            # Get the table being selected from
            from_clause = select_stmt.args.get("from_")
            if from_clause:
                table_name = (
                    from_clause.this.name.lower()
                    if hasattr(from_clause.this, "name")
                    else None
                )
                # Look for a CTE with this name
                if table_name and select_stmt.ctes:
                    for cte in select_stmt.ctes:
                        if cte.alias.lower() == table_name:
                            # Look for `description` in this CTE
                            for cte_expr in cte.this.expressions:
                                # Check for aliased description
                                if (
                                    hasattr(cte_expr, "alias")
                                    and cte_expr.alias
                                    and cte_expr.alias.lower() == "description"
                                ):
                                    expr_sql = cte_expr.this.sql(dialect="bigquery")
                                    # If the expression is just a column name, try to resolve it further
                                    if _is_bare_column_name(expr_sql, cte_expr.this):
                                        col_name = expr_sql.lower()
                                        # Recursively resolve through CTEs
                                        try:
                                            return _resolve_column_through_ctes(
                                                select_stmt.ctes, col_name
                                            )
                                        except ValueError:
                                            # If we can't resolve further, return what we have
                                            return expr_sql
                                    return expr_sql
                                # Check for bare column named description
                                elif (
                                    isinstance(cte_expr, Column)
                                    and cte_expr.name.lower() == "description"
                                ):
                                    # This is a bare column reference; try to resolve it
                                    try:
                                        return _resolve_column_through_ctes(
                                            select_stmt.ctes, "description"
                                        )
                                    except ValueError:
                                        return cte_expr.sql(dialect="bigquery")

    raise ValueError("No 'description' column or alias found in SELECT")


def _is_bare_column_name(expr_sql: str, expr_node) -> bool:
    """Check if an expression is just a bare column name."""
    return isinstance(expr_node, Column)


def _resolve_column_through_ctes(ctes, col_name: str) -> str:
    """Resolve a column name through CTEs to find its actual definition."""
    for cte in ctes:
        for cte_expr in cte.this.expressions:
            cte_alias = None
            cte_col_expr = None

            if hasattr(cte_expr, "alias") and cte_expr.alias:
                cte_alias = cte_expr.alias.lower()
                cte_col_expr = cte_expr.this
            elif isinstance(cte_expr, Column):
                cte_alias = cte_expr.name.lower()
                cte_col_expr = cte_expr

            if cte_alias == col_name:
                # Found the column definition
                expr_sql = (
                    cte_col_expr.sql(dialect="bigquery")
                    if cte_col_expr
                    else cte_expr.sql(dialect="bigquery")
                )
                # If this is also a bare column, try to resolve further
                if cte_col_expr and isinstance(cte_col_expr, Column):
                    try:
                        return _resolve_column_through_ctes(
                            ctes, cte_col_expr.name.lower()
                        )
                    except ValueError:
                        return expr_sql
                return expr_sql

    raise ValueError(f"Column '{col_name}' not found in any CTE")


def evaluate_description_expression(sql_text: str, row_data: dict) -> str:
    """
    Evaluate the description expression using values from a row of data.

    Args:
        sql_text: The staging SQL file content
        row_data: Dictionary with column names as keys and values from the sheet

    Returns the computed description string (same as the staging model would compute)
    """
    # Get the description expression
    expr_sql = get_description_expression(sql_text)

    # Normalize column names to lowercase for matching
    row_data_lower = {k.lower(): v for k, v in row_data.items()}

    try:
        result = _simple_sql_eval(expr_sql, row_data_lower)
        return str(result) if result else ""
    except Exception:
        # Fallback: if evaluation fails, try to manually handle common patterns
        return _manual_expression_eval(expr_sql, row_data_lower)


def _simple_sql_eval(expr: str, context: dict) -> str:
    """Simple evaluation of common SQL functions."""
    # Create a normalized lookup for column values
    # Normalize both spaces and underscores to handle "Payment reference" vs "payment_reference"
    context_normalized = {}
    for k, v in context.items():
        # Normalize: lowercase, replace spaces with underscores
        normalized_key = k.lower().replace(" ", "_")
        context_normalized[normalized_key] = v

    # Replace column references with actual values
    for col_name_normalized, col_value in context_normalized.items():
        col_value_str = str(col_value) if col_value is not None else ""
        # Replace column name with quoted value (case-insensitive regex)
        # Match with either spaces or underscores: "payment_reference" or "payment reference"
        pattern = col_name_normalized.replace("_", "[_ ]")
        pattern = rf"\b{pattern}\b"
        expr = re.sub(pattern, f"'{col_value_str}'", expr, flags=re.IGNORECASE)

    # Handle CAST: CAST(...  AS STRING) -> just the inner part
    expr = re.sub(
        r"CAST\s*\(\s*('[^']*')\s*AS\s+STRING\s*\)", r"\1", expr, flags=re.IGNORECASE
    )

    # Handle COALESCE: coalesce('val1', 'val2') -> first non-empty, repeatedly
    max_iterations = 10
    while max_iterations > 0:
        new_expr = re.sub(
            r"COALESCE\s*\(\s*'([^']*)'\s*,\s*'([^']*)'\s*\)",
            lambda m: f"'{m.group(1) if m.group(1) else m.group(2)}'",
            expr,
            flags=re.IGNORECASE,
        )
        if new_expr == expr:
            break
        expr = new_expr
        max_iterations -= 1

    # Handle CONCAT: concat('a', 'b', 'c') -> 'abc', repeatedly
    max_iterations = 10
    while max_iterations > 0:
        new_expr = re.sub(
            r"CONCAT\s*\(\s*('[^']*'(?:\s*,\s*'[^']*')*)\s*\)",
            lambda m: "'" + "".join(re.findall(r"'([^']*)'", m.group(1))) + "'",
            expr,
            flags=re.IGNORECASE,
        )
        if new_expr == expr:
            break
        expr = new_expr
        max_iterations -= 1

    # Handle TRIM: trim('  value  ') -> 'value'
    expr = re.sub(
        r"TRIM\s*\(\s*('[^']*')\s*\)",
        lambda m: f"'{m.group(1)[1:-1].strip()}'",
        expr,
        flags=re.IGNORECASE,
    )

    # Extract final quoted value
    match = re.search(r"'([^']*)'", expr)
    return match.group(1) if match else ""


def _manual_expression_eval(expr: str, context: dict) -> str:
    """Fallback manual evaluation for SQL expressions."""
    try:
        # Very simple case: just column name
        expr_clean = expr.strip().lower()
        if expr_clean in context:
            return str(context[expr_clean]) if context[expr_clean] is not None else ""

        # Try simple evaluation
        result = _simple_sql_eval(expr, context)
        return result if result else ""
    except Exception:
        return ""
