# rk.tuning: Advanced Hyperparameter Tuning and ML Workflows for RKWard

![Version](https://img.shields.io/badge/Version-0.0.1-blue.svg)
[![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
![RKWard](https://img.shields.io/badge/Platform-RKWard-green)
[![R Linter](https://github.com/AlfCano/rk.tuning/actions/workflows/lintr.yml/badge.svg)](https://github.com/AlfCano/rk.tuning/actions/workflows/lintr.yml)
![AI Gemini](https://img.shields.io/badge/AI-Gemini-4285F4?logo=googlegemini&logoColor=white)

**A Zero-Code GUI Wrapper for the `tidymodels` Ecosystem bringing Advanced Machine Learning to RKWard**

`rk.tuning` bridges the gap between state-of-the-art machine learning engineering and practical Business Analytics. Designed with modern data science workflows in mind, this plugin provides a point-and-click interface to build strict, leak-proof predictive pipelines. Implement feature engineering, cross-validation, grid search tuning, and final model evaluation—all without writing a single line of R code.

Inspired by the philosophy of *Business Analytics: Communicating with Numbers* (Jaggia et al.), this tool ensures your models are statistically rigorous while keeping the outputs visual, interpretable, and business-ready.

---

## 🌟 Key Features

*   **Zero-Code Cross-Validation:** Easily set up K-Fold, Bootstrap, or Train/Test splits using `rsample` to ensure your model's accuracy is robust and not just a result of overfitting.
*   **Feature Engineering Pipelines:** Build `recipes` visually. Handle missing data (Mean, Mode, KNN imputation), scale variables, create dummy variables (One-Hot Encoding), and handle class imbalance (Downsampling, SMOTE via `themis`).
*   **Hyperparameter Grid Search:** Auto-generate tuning grids for high-performance algorithms: Random Forest (`ranger`), Gradient Boosting (`xgboost`), and Support Vector Machines (`kernlab`).
*   **Automated Workflows:** The plugin automatically binds your recipe and model spec, tests dozens of combinations, selects the absolute best parameters, and trains the final production-ready model for you.
*   **Beautiful `ggplot2` Output:** Automatically plots the hyperparameter grid search results, with full customization over titles, axes, and HTML pixel dimensions.
*   **Multilingual Ready:** Fully prepared for translation into English, Spanish, French, German, and Portuguese (Brazil).

---

## What's New in Version 0.0.1

*   **Initial Release:** Introduces a comprehensive, 4-step Machine Learning pipeline under RKWard's `Analysis > Predictive Analytics > Advanced Tuning (tidymodels)` menu.
*   **Modular Architecture:** Each step saves a specific object (Resample, Recipe, Spec) to your workspace, allowing you to mix and match strategies.
*   **Native GUI Integration:** Implements flawless HTML plot injection and safe saving mechanisms using RKWard's core graphical devices (`rk.graph.on`).

---

## ⚙️ Prerequisites

You must have [RKWard](https://rkward.kde.org/) installed along with the following R packages. The plugin will automatically attempt to load them when required:

```R
install.packages(c("tidymodels", "rsample", "recipes", "parsnip", "tune", "workflows", "yardstick", "ggplot2", "ranger", "xgboost", "kernlab", "themis"))
```

---

## 🚀 Installation

You can install this plugin directly from GitHub using `remotes` or `devtools` inside your RKWard console:

```R
# Install the plugin
library("remotes")
install_github("AlfCano/rk.tuning")
```

Once installed, restart RKWard to ensure the new menu entries and translations appear correctly.

---

## 🛠️ Usage Workflow (The 4 Modules)

This plugin breaks down the complex `tidymodels` framework into 4 digestible, logical steps:

### 1. Resample Data (Validation Strategy)
Define how you want to test your model's robustness. Create a 10-Fold Cross-Validation object (e.g., `cv_folds`) to ensure your model trains and tests on different slices of data, preventing overfitting.

### 2. Build Recipe (Feature Engineering)
Define your Target (Y) and Predictors (X). Add preprocessing steps sequentially: impute missing values, normalize numerical data, and balance classes. Save this pipeline as `rec_obj`.

### 3. Model Spec (Algorithms & Tuning)
Choose your algorithm (e.g., Random Forest). Check the boxes for the parameters you want the computer to test blindly (e.g., tune `mtry` and `min_n`), and define the grid size. Save as `model_spec`.

### 4. Execute & Finalize Model
The magic happens here. Drag and drop your original data, your `cv_folds`, your `rec_obj`, and your `model_spec`. Hit **Submit**. The plugin will search for the best combination, plot the results, and output a `final_model` ready for production.

---

## 📊 Real-World Case Study: Automated Optimization

Let's test our tuning pipeline using a classic dataset to see how it automatically finds the best configuration without human bias.

### Step 1: Resampling
1. Go to **Analysis > Predictive Analytics > Advanced Tuning > 1. Resample**.
2. Select `iris` as your dataset.
3. Choose **K-Fold Cross-Validation** (10 folds). Save as `cv_folds`. Hit **Submit**.

### Step 2: The Recipe
1. Go to **2. Build Recipe**.
2. Training Dataset: `iris`. Target Variable: `Species`.
3. Check the box to **Normalize** all numeric predictors (crucial for good ML performance). Save as `rec_obj`. Hit **Submit**.

### Step 3: The Model Spec
1. Go to **3. Model Spec**.
2. Algorithm: **Random Forest (ranger)**. Mode: **Classification**.
3. Check the boxes to tune `mtry` (Randomly Selected Predictors) and `min_n` (Minimal Node Size). Set Grid Size to 10. Save as `model_spec`. Hit **Submit**.

### Step 4: The Execution
1. Go to **4. Execute & Finalize Model**.
2. Insert `iris`, `cv_folds`, `rec_obj`, and `model_spec` into their respective slots.
3. Under **Plot Options**, title the plot "Random Forest Optimization". 
4. Hit **Submit**.

---

## 🗣️ Communicating with Numbers (Translating Output to Business)

True to the Jaggia philosophy, we don't hand management a report full of code. We use the tables and charts generated by RKWard to speak in terms of optimization and operational readiness.

Here is how you "pitch" the clean HTML reports RKWard just gave you:

**1. Interpreting the Hyperparameter Grid Plot:**
Look at the generated scatterplot showing the different combinations tested by the algorithm.
> *"To ensure we don't overfit our model to past data, we ran a blind simulation of 10 different configurations using a 10-Fold Cross-Validation strategy. The visual grid shows that our algorithm peaks in accuracy when we restrict the tree to evaluating only **2 random variables at a time** (`mtry=2`), and stopping the tree branching at groups of **35** (`min_n=35`)."*

**2. Interpreting the Accuracy & Brier Score:**
Look at the *Top 5 Hyperparameter Combinations* and the *Workflow [trained]* summary.
> *"By systematically tuning these parameters, our winning model achieved a verified **Accuracy of 97%** on unseen data. Furthermore, our Out-Of-Bag Brier Score is extremely low (0.034), meaning that when the algorithm predicts a category, it does so with immense statistical confidence, rarely guessing."*

**3. The Production Pipeline (The Recipe):**
> *"Most importantly, we didn't just train a mathematical algorithm; we built a **Production Workflow**. If we feed new, raw customer data into this system tomorrow, the model automatically knows how to normalize and prepare the data before predicting. It is 100% ready for deployment."*

---

## 🌍 Internationalization (i18n)

The graphical interface automatically adapts to your RKWard language settings. Currently supported languages:
*   🇺🇸 English (Default)
*   🇪🇸 Spanish (Español)
*   🇫🇷 French (Français)
*   🇩🇪 German (Deutsch)
*   🇧🇷 Portuguese (Português do Brasil)

---

## 📝 License and Author

**Author:** Alfonso Cano ([@AlfCano](https://github.com/AlfCano))  
**Email:** alfonso.cano@correo.buap.mx  
*   **Assisted by:** Gemini, a large language model from Google.
*   **License:** GPL (>= 3)

This project is licensed under the **GPL (>= 3)** License.
