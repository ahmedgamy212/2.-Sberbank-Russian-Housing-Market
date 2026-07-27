# 🏠 Moscow Housing Market Analytics & Price Prediction

An end-to-end real estate analytics project built using the **Sberbank Russian Housing Market** dataset. This project combines **Python, SQL, Power BI, and Machine Learning** to analyze housing market trends, generate business insights, and predict property prices with high accuracy.

---

# 📌 Overview

The project demonstrates the complete data analytics lifecycle, from raw data preprocessing to interactive business dashboards and predictive modeling.

The primary objectives are to:

- Analyze the Moscow housing market
- Identify factors influencing property prices
- Build interactive Power BI dashboards
- Perform SQL-based business analytics
- Engineer meaningful real estate features
- Train a high-performance machine learning model
- Deliver actionable insights for buyers, sellers, and investors

---

# 📂 Dataset

**Source:** Sberbank Russian Housing Market (Kaggle)

The dataset contains over **30,000 residential properties** and hundreds of variables describing:

- Property characteristics
- Location
- Infrastructure
- Transportation
- Schools
- Healthcare
- Environmental indicators
- Demographics
- Macroeconomic indicators

---

# 🛠 Tech Stack

- Python
- Pandas
- NumPy
- Matplotlib
- Seaborn
- Scikit-learn
- XGBoost
- SQL Server
- Power BI
- Joblib

---

# 📊 Project Workflow

## 1. Data Cleaning

- Missing value treatment
- Duplicate removal
- Data type correction
- Outlier handling
- Feature transformation

---

## 2. Feature Engineering

Created additional analytical features including:

- Price per Square Meter
- Distance Band
- Building Era
- Amenity Class
- Market Segment
- Neighborhood Categories

---

## 3. Exploratory Data Analysis (EDA)

Performed comprehensive analysis to understand:

- Price distribution
- Property size distribution
- Location impact
- Infrastructure influence
- Correlation analysis
- Market segmentation

---

## 4. SQL Business Analytics

Developed SQL queries to answer business questions such as:

- Average property prices
- Price per square meter
- Building era comparison
- Distance band analysis
- Amenity premium
- Market segment distribution
- Mortgage rate trends

---

## 5. Power BI Dashboard

The dashboard consists of multiple analytical pages designed for business users.

### Executive Overview

- Total Properties
- Average Property Price
- Average Price per m²
- Data Quality Indicators

### Market Analysis

- Price per m² by Distance Band
- Price per m² by Building Era
- Market Segment Mix
- Amenity Class Premium

### Trend Analysis

- Monthly Price per m²
- Mortgage Rate Comparison
- Seasonal Market Trends

Interactive slicers enable dynamic market exploration.

---

# 🤖 Machine Learning

Several regression models were evaluated before selecting the final model.

### Final Model

**XGBoost Regressor**

Performance:

| Metric | Score |
|---------|--------|
| R² | **0.91** |
| RMSE | **26.3K** |

---

# 📈 Key Business Insights

- Premium neighborhoods achieve significantly higher prices per square meter.
- Luxury amenities contribute noticeable price premiums.
- Building age strongly influences property value.
- Mortgage rate fluctuations correspond with housing price changes.
- Distance from the city center remains one of the strongest pricing factors.

---

# 📷 Dashboard Preview

## Executive Dashboard

<img src="Images/dashboard1.png" width="900">

---

## Market Analysis Dashboard

<img src="Images/dashboard2.png" width="900">

---

# 📁 Project Structure

```
Moscow-Housing-Market-Analytics
│
├── Data
│
├── Notebook
│   └── Sberbank Russian Housing Market.ipynb
│
├── SQL
│   └── SQL Queries.sql
│
├── Dashboard
│   └── Moscow Housing Dashboard.pbix
│
├── Images
│   ├── dashboard1.png
│   └── dashboard2.png
│
├── Model
│   └── xgboost_model.pkl
│
└── README.md
```

---

# 🚀 Future Improvements

- Deploy the model using Streamlit
- Build an automated ETL pipeline
- Hyperparameter optimization
- API deployment
- Real-time market monitoring

---

# 👨‍💻 Author

**Ahmed Gamal**

Data Analyst | Python | SQL | Power BI | Machine Learning

---

## ⭐ If you found this project useful, consider giving it a Star!
