# 📌 Livestock Growth Modeling

## 📝 Objective
This project compares the growth performance of **Holstein Friesian purebred** and **F1 crossbred (Holstein Friesian × Sokoto Gudali) cattle** by fitting three **non-linear growth models** using **R**:

- **Brody**
- **Von Bertalanffy**
- **Richards**

Key model parameters estimated:

| Parameter | Description |
|-----------|-------------|
| **A** | Asymptotic weight (maximum attainable weight) |
| **B** | Proportion of asymptotic weight gained after birth (initial growth) |
| **k** | Maturity rate (rate at which the animal approaches its asymptotic weight) |

---
## ⚙️ Tasks

1. **Data Loading & Inspection**  
   - Load cattle dataset from an **Excel file**  
   - Inspect dataset structure  
   - Summarize key statistics  
2. **Data Cleaning & Quality Checks**  
   - Handle missing values, duplicates, and outliers (age & weight variables)  
3. **Growth Model Definition**  
   - Define three **non-linear growth models**: Brody, von Bertalanffy, and Logistic functions  
4. **Model Fitting**  
   - Use **nonlinear least squares (nlsLM)** to fit each model separately for different cattle breed groups  
5. **Parameter Estimation**  
   - Extract key model parameters (**A, B, k**) for each breed & model type  
6. **Model Evaluation**  
   - Compare models using **AIC, BIC, and R²** for goodness of fit  
7. **Convergence Check**  
   - Verify model convergence & track iteration counts  
8. **Visualization**  
   - Generate **growth curves** to compare model predictions vs. observed weight data  

---
## 📊 Statistical Interpretation of the Results

### 🔹 **1. Parameter Estimates Interpretation**

#### **Comparison of Growth Parameters Between Hybrid and Purebred Cattle**

| Model              | Breed     | A (Mature Weight) | B (Scaling) | k (Maturation Rate) |
|--------------------|----------|------------------|------------|--------------------|
| **Brody**         | **Hybrid**   | 🔼 730.56 (Higher) | 1.003      | 🔽 0.0228 (Slower maturity) |
|                   | **Purebred** | 🔽 352.17 (Lower)  | 1.084      | 🔼 0.0737 (Faster maturity) |
| **Von Bertalanffy** | **Hybrid**   | 🔼 618.85 (Higher) | 1.078      | 🔽 0.0306 (Slower maturity) |
|                   | **Purebred** | 🔽 337.39 (Lower)  | 1.320      | 🔼 0.0896 (Faster maturity) |
| **Logistic (Richards)** | **Hybrid**   | 348.42           | 🔼 6.879 (Higher) | 🔽 0.1573 (Slower maturity) |
|                   | **Purebred** | 305.93           | 🔽 5.014 (Lower)  | 🔼 0.1776 (Faster maturity) |

**🔑 Key Insight:**  
- **Hybrid cattle** take longer to reach full size but **ultimately grow larger**  
- **Purebred cattle** mature more quickly but reach **a smaller maximum weight**  

---

### 🔹 **2. Model Performance Comparison (Goodness of Fit)**

#### **Residual Sum of Squares (RSS)**  

| Model              | Hybrid RSS | Purebred RSS |
|--------------------|-----------|-------------|
| **Brody**         | 4348      | 5957        |
| **Von Bertalanffy** | 4324      | 5817        |
| **Logistic (Richards)** | 🔽 3722 (Lowest) | 🔽 5018 (Lowest) |

- Measures difference between **observed vs. predicted weights** (lower = better model fit)  
- Best **RSS values:**
  - **Hybrid Cattle:** Lowest RSS in **Logistic model (3722)**  
  - **Purebred Cattle:** Lowest RSS in **Logistic model (5018)**  
  
✅ **Best Fit:** The **Logistic model** outperforms Brody & Von Bertalanffy models for both breeds.

---

### 🔹 **3. Model Fit Statistics (AIC, BIC, R²)**

#### **R² (Coefficient of Determination)**  

Model              | Hybrid R² | Purebred R² |
|--------------------|----------|------------|
| **Brody**         | 0.9743   | 0.9545     |
| **Von Bertalanffy** | 0.9745   | 0.9556     |
| **Logistic (Richards)** | 🔼 0.9780 (Highest) | 🔼 0.9617 (Highest) |

- Higher **R²** = better model fit  
- **Logistic model** has the highest **R²**, meaning it best explains growth variation  
- **Hybrid cattle data fits better** (higher **R²**) than purebred cattle data  

#### **AIC (Akaike Information Criterion) & BIC (Bayesian Information Criterion)**  

Model              | Hybrid AIC | Hybrid BIC | Purebred AIC | Purebred BIC |
|--------------------|-----------|-----------|-------------|-------------|
| **Brody**         | 295.96    | 302.51    | 328.48      | 335.34      |
| **Von Bertalanffy** | 295.75    | 302.30    | 327.50      | 334.36      |
| **Logistic (Richards)** | 🔽 290.05 (Lowest) | 🔽 296.60 (Lowest) | 🔽 321.45 (Lowest) | 🔽 328.30 (Lowest) |

- Lower **AIC/BIC** = better model selection  
- **Logistic model** has the **lowest AIC & BIC**, confirming best overall performance  
- Hybrid cattle have a **slightly better fit** (lower AIC/BIC) than purebred cattle  

---

### 🔹 **4. Statistical Significance of Parameters**

Model              | Breed     | A (p-value) | B (p-value) | k (p-value) |
|--------------------|----------|------------|------------|------------|
| **Brody**         | **Hybrid**   | ✅ 0.008 (Significant)  | ✅ <0.001 (Significant)  | ⚠️ 0.050 (Marginal)  |
|                   | **Purebred** | ✅ <0.001 (Significant) | ✅ <0.001 (Significant) | ✅ <0.001 (Significant) |
| **Von Bertalanffy** | **Hybrid**   | ✅ 0.016 (Significant)  | ✅ <0.001 (Significant)  | ❌ 0.149 (Not significant) |
|                   | **Purebred** | ✅ <0.001 (Significant) | ✅ <0.001 (Significant) | ✅ <0.001 (Significant) |
| **Logistic**      | **Hybrid**   | ✅ <0.001 (Significant) | ✅ <0.001 (Significant) | ✅ <0.001 (Significant) |
|                   | **Purebred** | ✅ <0.001 (Significant) | ✅ <0.001 (Significant) | ✅ <0.001 (Significant) |

- **p-values (Pr > |t|)** indicate significance of parameters:  
  - **p < 0.05** → Statistically significant (important in explaining growth)  
  - **p > 0.05** → Not statistically significant  

✅ **Most parameters are significant (p < 0.05)**, confirming their role in growth modeling  
❌ Exception: **Maturity rate (k) in Von Bertalanffy model for Hybrid Cattle** (p = 0.149) is **not significant**, suggesting it may not accurately describe growth.

---

## 🎯 Key Takeaways & Practical Implications

### ✅ **Which Growth Model is Best?**
- **The Logistic model (Richards) is the best fit** (lowest RSS, highest R², lowest AIC/BIC)
- Growth follows a **sigmoidal pattern**: 
  1. **Slow initial phase**
  2. **Rapid growth phase**
  3. **Maturity leveling off**

### ✅ **Which Breed Has Better Growth Performance?**
- **Hybrid cattle (Holstein Friesian × Sokoto Gudali)** 
  - **Higher mature weight (A)** in all models
  - **Slower maturation (k)** but ultimately **larger**
- **Purebred cattle (Holstein Friesian)**
  - **Faster initial growth (higher k)**
  - **Lower final weight (A)**

### ✅ **Recommendations for Cattle Farming**
📌 **For early market sale:** Choose **Purebred Holstein Friesian** (faster weight gain).  
📌 **For long-term farming/dairy production:** Choose **Hybrid cattle (F1 crossbred)** (larger mature size).  
📌 **For future growth predictions:** Use the **Logistic model**.

---

### 🔗 **Project Repository**
💾 [Project Report](#) _(https://github.com/Ormolt/r/blob/main/nls_cattle_growth_model.html)_

🚀 **Developed & Maintained By:** _Yusuf Omotosho_  
📧 **Contact:** _yusufomotoso@outlook.com_  

---
