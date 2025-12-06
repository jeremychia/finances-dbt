# Personal Finance Data Pipeline

A comprehensive dbt (data build tool) project designed to manage, transform, and analyze personal financial data across multiple currencies, countries, and financial institutions. This project creates a unified data warehouse for tracking expenses, investments, and balances with proper foreign exchange handling and categorization.

## 🎯 Project Purpose

This dbt project consolidates financial data from various sources to provide:
- **Multi-currency financial tracking** with automatic SGD conversion
- **Investment portfolio monitoring** with gain/loss calculations
- **Expense categorization** and analysis across different spending patterns
- **Balance tracking** across bank accounts, credit cards, and investment platforms
- **Time-series analysis** with proper date dimensions

## 🏗️ Architecture Overview

The project follows a layered data architecture:

```
Sources → Staging → Facts/Dimensions → Marts
```

### Data Sources
- **Bank Transactions**: Multiple accounts across Singapore, Germany, France, Hong Kong, UK, and US
- **Investment Data**: Portfolio balances from various investment platforms
- **Foreign Exchange**: EUR and other currency exchange rates
- **Categories**: Manual categorization of transactions

### Key Features
- **Multi-currency support**: Primary focus on SGD with EUR, USD, HKD conversions
- **Temporal tracking**: Daily snapshots with historical analysis
- **Investment analytics**: Market value vs. cost basis with P&L calculations  
- **Flexible categorization**: Hierarchical expense categories (category → category2 → category3)

## 📊 Data Model Structure

### Staging Layer (`models/staging/`)
Raw data transformation and standardization:
- **Bank staging**: Normalizes transaction data from 20+ bank/card sources
- **Investment staging**: Processes portfolio data from multiple investment platforms
- **FX staging**: Standardizes exchange rate data

### Facts Layer (`models/facts/`)
Core business events and metrics:
- `fact_bank_transactions`: All normalized bank transactions
- `fact_invm_balances_line_items`: Investment portfolio positions
- `fact_sgd_exchange_rates_long`: Daily FX rates in long format

### Dimensions Layer (`models/dimensions/`)
Reference data and categorization:
- `dim_categories`: Hierarchical expense categorization
- `dim_dates`: Date dimension with Singapore timezone

### Marts Layer (`models/marts/`)
Business-ready analytics tables:
- `mart_transactions`: Unified transaction view with SGD conversion
- `mart_sgd_balances`: Consolidated balance view (cash + investments)
- `mart_sgd_bank_transactions`: Bank transactions with category enrichment
- `mart_sgd_invm_balances`: Investment balances with P&L calculations

## 💰 Supported Financial Institutions

### Singapore
- **Banks**: DBS, UOB, OCBC, HSBC
- **Credit Cards**: Citi, Standard Chartered, UOB, HSBC
- **Digital**: Revolut, Wise

### International
- **Germany**: N26, AMEX (Payback, Rose Gold, Miles & More)
- **France**: HSBC France
- **Hong Kong**: Hang Seng Bank
- **UK/US**: Wise multi-currency accounts

### Investment Platforms
- Local SGD investments
- USD-denominated investments
- HKD/USD hybrid investments
- CDP (Central Depository) accounts
- FundingSocieties P2P lending

## 🌍 Currency Handling

The project handles multi-currency scenarios with:
- **Base currency**: Singapore Dollar (SGD) as the primary reporting currency
- **FX conversion**: Automated daily exchange rate application
- **FX gain/loss tracking**: Separate calculation of currency vs. investment gains
- **Timezone**: Asia/Singapore for consistent date handling

## 📈 Key Metrics & Analytics

### Transaction Analysis
- Spending by category with hierarchical breakdowns
- Fixed vs. variable expense classification
- Monthly/quarterly spending trends
- Cross-currency transaction analysis

### Investment Tracking
- Portfolio value vs. cost basis
- Investment gain/loss by currency
- FX gain/loss separate from investment performance
- Redemption tracking for realized gains

### Balance Monitoring
- Daily balance snapshots across all accounts
- Asset allocation across cash, credit, and investments
- Net worth calculation in SGD equivalent

## 🔧 Technical Implementation

### dbt Packages Used
- `dbt-utils`: For union operations and utility macros
- `dbt-date`: Singapore timezone handling and date operations
- `dbt-external-tables`: For external data source management

### Materialization Strategy
- **Staging models**: Views for flexibility and cost optimization
- **Facts/Marts**: Tables for performance on analytical queries
- **Documentation**: Comprehensive model and column documentation

### Data Quality
- Unique constraints on dimension keys
- Date validation and parsing
- Currency code standardization
- Category mapping validation

## 🚀 Getting Started

1. **Prerequisites**: dbt Core with BigQuery adapter
2. **Configuration**: Set up `profiles.yml` for your data warehouse
3. **Dependencies**: Run `dbt deps` to install required packages
4. **Seeds**: Load category mapping with `dbt seed`
5. **Build**: Execute full pipeline with `dbt build`

## 📝 Usage Examples

```sql
-- Monthly spending by category
select
    format_date('%Y-%m', local_date) as month, category2, sum(sgd_amount) as total_sgd
from mart_sgd_bank_transactions
where category3 = 'Expense'
group by 1, 2
order by 1 desc, 3 desc
;

-- Investment performance summary
select
    source,
    max(sgd_market) as current_value_sgd,
    max(sgd_invm_gain_loss) as investment_gain_loss,
    max(sgd_fx_gain_loss) as fx_gain_loss
from mart_sgd_invm_balances
where is_latest_date = true
group by 1
;

-- Net worth tracking
select local_date, sum(sgd_balance) as total_net_worth_sgd
from mart_sgd_balances
group by 1
order by 1
;

```

This project provides a robust foundation for personal financial analysis with the flexibility to accommodate complex multi-currency scenarios and diverse financial institution integrations.
