local({
  # =========================================================================================
  # 1. Setup and Metadata
  # =========================================================================================
  require(rkwarddev)

  plugin_name <- "rk.tuning"

  about_info <- rk.XML.about(
    name = plugin_name,
    author = person(
      given = "Alfonso",
      family = "Cano",
      email = "alfonso.cano@correo.buap.mx",
      role = c("aut", "cre")
    ),
    about = list(
      desc = "Hyperparameter Tuning and Machine Learning Workflows via tidymodels",
      version = "0.0.1",
      url = "https://github.com/AlfCano/rk.tuning",
      license = "GPL (>= 3)"
    )
  )

  dependencies_node <- rk.XML.dependencies(
    dependencies = list(R.min = "4.1.0"),
    package = list(c(name = "tidymodels"), c(name = "rsample"), c(name = "themis"), c(name = "ranger"), c(name = "xgboost"), c(name = "kernlab"))
  )

  # Menu hierarchy: Analysis -> Predictive Analytics -> Tuning (tidymodels)
  h_tuning <- list("analysis", "Predictive Analytics", "Advanced Tuning (tidymodels)")

  # Global JavaScript Helper Functions
  js_helpers <- "
    function cleanStr(val) {
        if(!val) return '';
        return val.replace(/'/g, \"\\\\'\").replace(/\"/g, '\\\\\"');
    }

    function parseVar(fullPath) {
        if (!fullPath) return '';
        var raw_col = '';
        if (fullPath.indexOf('[[') > -1) {
            var parts = fullPath.split('[[');
            var inner = parts[1].replace(']]', '');
            raw_col = inner.replace(/[\"']/g, '');
        } else if (fullPath.indexOf('$') > -1) {
            raw_col = fullPath.split('$')[1];
        } else {
            raw_col = fullPath;
        }
        return raw_col;
    }
  "

  # =========================================================================================
  # 2. MODULE 1: Resample (Validation Strategy via rsample)
  # =========================================================================================

  # --- UI Elements ---
  res_vs <- rk.XML.varselector(id.name = "res_vs")
  res_data <- rk.XML.varslot("Dataset to Resample", source = "res_vs", classes = "data.frame", required = TRUE, id.name = "res_data")
  res_strata <- rk.XML.varslot("Stratification Variable (Optional but recommended to balance classes)", source = "res_vs", required = FALSE, id.name = "res_strata")

  # Resampling Methods
  res_type <- rk.XML.dropdown("Resampling Method", options = list(
    "K-Fold Cross-Validation" = list(val = "vfold", chk = TRUE),
    "Bootstrap Resampling" = list(val = "boot"),
    "Validation Split (Train/Test)" = list(val = "split")
  ), id.name = "res_type")

  # Dynamic Frames for specific method options
  # 1. K-Fold Options
  res_v <- rk.XML.spinbox("Number of Folds (v)", min = 2, max = 20, initial = 10, real = FALSE, id.name = "res_v")
  res_repeats <- rk.XML.spinbox("Repeats", min = 1, max = 20, initial = 1, real = FALSE, id.name = "res_repeats")
  frm_kfold <- rk.XML.frame(res_v, res_repeats, label = "K-Fold Options", id.name = "frm_kfold")

  # 2. Bootstrap Options
  res_times <- rk.XML.spinbox("Number of Bootstraps", min = 1, max = 500, initial = 25, real = FALSE, id.name = "res_times")
  frm_boot <- rk.XML.frame(res_times, label = "Bootstrap Options", id.name = "frm_boot")

  # 3. Validation Split Options
  res_prop <- rk.XML.spinbox("Proportion of data for Training", min = 0.1, max = 0.99, initial = 0.75, real = TRUE, id.name = "res_prop")
  frm_split <- rk.XML.frame(res_prop, label = "Validation Split Options", id.name = "frm_split")

  # Reproducibility & Output
  res_seed_chk <- rk.XML.cbox("Set Random Seed (Reproducibility)", value = "TRUE", chk = TRUE, id.name = "res_seed_chk")
  res_seed_val <- rk.XML.spinbox("Seed Value", min = 1, max = 999999, initial = 12345, real = FALSE, id.name = "res_seed_val")
  frm_seed <- rk.XML.frame(res_seed_chk, res_seed_val, label = "Reproducibility")

  res_save <- rk.XML.saveobj("Save Resample Object As:", initial = "cv_folds", chk = TRUE, id.name = "res_save")

  # --- UI Logic ---

  # SOLUCIÓN: Agregamos "string =" dentro de list() para leer el texto del menú
  cond_vfold <- rk.XML.convert(sources = list(string = res_type), mode = c(equals = "vfold"), id.name = "cond_vfold")
  cond_boot <- rk.XML.convert(sources = list(string = res_type), mode = c(equals = "boot"), id.name = "cond_boot")
  cond_split <- rk.XML.convert(sources = list(string = res_type), mode = c(equals = "split"), id.name = "cond_split")

  logic_res <- rk.XML.logic(
    # Connect dataset to varselector
    rk.XML.connect(governor = res_data, get = "available", client = res_vs, set = "root"),

    # Declarar conversiones
    cond_vfold, cond_boot, cond_split,

    # EFECTO GRAY-OUT: Habilitar/Deshabilitar frames
    rk.XML.connect(governor = cond_vfold, client = frm_kfold, set = "enabled"),
    rk.XML.connect(governor = cond_boot, client = frm_boot, set = "enabled"),
    rk.XML.connect(governor = cond_split, client = frm_split, set = "enabled"),

    # Activar la semilla solo si el checkbox está marcado
    rk.XML.connect(governor = res_seed_chk, get = "state", client = res_seed_val, set = "enabled")
  )

  # --- Dialog Layout ---
  tab_res <- rk.XML.tabbook(tabs = list(
    "Data & Method" = rk.XML.col(
      res_data,
      res_strata,
      res_type,
      rk.XML.stretch()
    ),
    "Method Options" = rk.XML.col(
      frm_kfold,
      frm_boot,
      frm_split,
      rk.XML.stretch()
    ),
    "Output" = rk.XML.col(
      frm_seed,
      rk.XML.frame(res_save, label = "Export Object to Workspace"),
      rk.XML.stretch()
    )
  ))

  dialog_res <- rk.XML.dialog(
    rk.XML.row(
      res_vs,
      rk.XML.col(tab_res)
    ),
    label = "1. Resample Data (Validation Strategy)"
  )


  # --- JavaScript Generators ---
  js_calc_res <- "
    var data = getValue('res_data');
    var strata = parseVar(getValue('res_strata'));
    var type = getValue('res_type');
    var seed_chk = getValue('res_seed_chk');
    var seed_val = getValue('res_seed_val');

    echo('# Step 1: Validation Strategy via rsample\\n');

    if (seed_chk === 'TRUE') {
        echo('set.seed(' + seed_val + ')\\n');
    }

    var strata_arg = (strata !== '') ? ', strata = ' + strata : '';

    if (type === 'vfold') {
        var v = getValue('res_v');
        var r = getValue('res_repeats');
        var rep_arg = (r > 1) ? ', repeats = ' + r : '';
        // REGLA 13: El nombre DEBE ser cv_folds (el initial del saveobj)
        echo('cv_folds <- rsample::vfold_cv(' + data + ', v = ' + v + rep_arg + strata_arg + ')\\n');

    } else if (type === 'boot') {
        var times = getValue('res_times');
        echo('cv_folds <- rsample::bootstraps(' + data + ', times = ' + times + strata_arg + ')\\n');

    } else if (type === 'split') {
        var prop = getValue('res_prop');
        echo('cv_folds <- rsample::initial_split(' + data + ', prop = ' + prop + strata_arg + ')\\n');
    }
  "

  js_print_res <- "
    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header(\"1. Resampling Strategy (tidymodels)\")\\n');

        // 1. Capturamos la salida
        echo('res_out <- paste(capture.output(print(cv_folds)), collapse = \"\\\\n\")\\n');

        // 2. Escapamos los signos < > para que el HTML no se confunda
        echo('res_out <- gsub(\"<\", \"&lt;\", res_out)\\n');
        echo('res_out <- gsub(\">\", \"&gt;\", res_out)\\n');

        // 3. Imprimimos el bloque de texto puro y seguro
        echo('cat(paste0(\"<pre>\", res_out, \"</pre>\\\\n\"), file = rk.get.output.html.file(), append = TRUE)\\n');

        if (getValue('res_save.active')) {
            echo('rk.print(\"<hr>\")\\n');
            echo('rk.print(paste0(\"<b>Resample object successfully saved as: </b><code>\", \"' + getValue('res_save') + '\", \"</code>\"))\\n');
        }
    }
  "

  # Register Component
  comp_res <- rk.plugin.component(
    "1. Resample (Validation Strategy)",
    xml = list(dialog = dialog_res, logic = logic_res),
    js = list(require = c("tidymodels", "rsample"), globals = js_helpers, calculate = js_calc_res, printout = js_print_res),
    hierarchy = h_tuning
  )

  # =========================================================================================
  # 3. MODULE 2: Recipe (Feature Engineering & Preprocessing)
  # =========================================================================================

  # --- UI Elements ---
  rec_vs <- rk.XML.varselector(id.name = "rec_vs")
  rec_data <- rk.XML.varslot("Training Dataset (Data Frame)", source = "rec_vs", classes = "data.frame", required = TRUE, id.name = "rec_data")
  rec_target <- rk.XML.varslot("Target Variable (Y)", source = "rec_vs", required = TRUE, id.name = "rec_target")

  rec_preds <- rk.XML.varslot("Predictor Variables (X) (Leave empty to use all remaining)", source = "rec_vs", multi = TRUE, required = FALSE, id.name = "rec_preds")

  # Preprocessing Steps
  rec_impute <- rk.XML.dropdown("Handling Missing Data (NAs)", options = list(
    "Do nothing (Algorithms might fail if NAs exist)" = list(val = "none", chk = TRUE),
    "Impute Mean (Numeric) / Mode (Categorical)" = list(val = "mean"),
    "Impute via K-Nearest Neighbors (KNN)" = list(val = "knn")
  ), id.name = "rec_impute")

  rec_dummy <- rk.XML.cbox("One-Hot Encoding: Convert categorical variables to dummy numeric columns", value = "TRUE", chk = TRUE, id.name = "rec_dummy")
  rec_norm <- rk.XML.cbox("Normalize: Center and Scale all numeric predictors", value = "TRUE", chk = TRUE, id.name = "rec_norm")

  rec_imb <- rk.XML.dropdown("Class Imbalance Handling (Only for Classification)", options = list(
    "Do nothing (Keep original proportions)" = list(val = "none", chk = TRUE),
    "Downsample (Reduce majority class)" = list(val = "down"),
    "SMOTE (Synthetically oversample minority class) *Requires 'themis'* " = list(val = "smote")
  ), id.name = "rec_imb")

  frm_steps <- rk.XML.frame(rec_impute, rec_dummy, rec_norm, rec_imb, label = "Data Transformations (Applied in order)")

  # Output
  rec_save <- rk.XML.saveobj("Save Recipe Object As:", initial = "rec_obj", chk = TRUE, id.name = "rec_save")

  # --- UI Logic ---
  logic_rec <- rk.XML.logic(
    rk.XML.connect(governor = rec_data, get = "available", client = rec_vs, set = "root")
  )

  # --- Dialog Layout ---
  tab_rec <- rk.XML.tabbook(tabs = list(
    "Variables (Roles)" = rk.XML.col(rec_data, rec_target, rec_preds, rk.XML.stretch()),
    "Preprocessing Steps" = rk.XML.col(frm_steps, rk.XML.stretch()),
    "Output" = rk.XML.col(rk.XML.frame(rec_save, label = "Export Object to Workspace"), rk.XML.stretch())
  ))

  dialog_rec <- rk.XML.dialog(
    rk.XML.row(rec_vs, rk.XML.col(tab_rec)),
    label = "2. Build Recipe (Feature Engineering)"
  )

  # --- JavaScript Generators ---
  js_calc_rec <- "
    var data = getValue('rec_data');
    var target = parseVar(getValue('rec_target'));
    var preds_raw = getValue('rec_preds');

    echo('# Step 2: Feature Engineering via recipes\\n');

    // Build formula
    var preds_str = '.';
    if (preds_raw !== '') {
        var preds_arr = preds_raw.split('\\n').map(parseVar).filter(Boolean);
        if (preds_arr.length > 0) {
            preds_str = preds_arr.map(function(v){ return '`' + v + '`'; }).join(' + ');
        }
    }
    var formula = '`' + target + '` ~ ' + preds_str;

    // Start Recipe
    echo('rec_obj <- recipes::recipe(' + formula + ', data = ' + data + ')');

    // Append Steps
    var impute = getValue('rec_impute');
    if (impute === 'mean') {
        echo(' %>%\\n  recipes::step_impute_mean(recipes::all_numeric_predictors()) %>%\\n  recipes::step_impute_mode(recipes::all_nominal_predictors())');
    } else if (impute === 'knn') {
        echo(' %>%\\n  recipes::step_impute_knn(recipes::all_predictors())');
    }

    if (getValue('rec_dummy') === 'TRUE') {
        echo(' %>%\\n  recipes::step_dummy(recipes::all_nominal_predictors())');
    }

    if (getValue('rec_norm') === 'TRUE') {
        echo(' %>%\\n  recipes::step_normalize(recipes::all_numeric_predictors())');
    }

    var imb = getValue('rec_imb');
    if (imb === 'down') {
        echo(' %>%\\n  themis::step_downsample(`' + target + '`)');
    } else if (imb === 'smote') {
        echo(' %>%\\n  themis::step_smote(`' + target + '`)');
    }

    echo('\\n\\n');
  "

  js_print_rec <- "
    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header(\"2. Feature Engineering Recipe (tidymodels)\", level = 2)\\n');

        // SOLUCIÓN: Envolvemos las funciones en as.data.frame() para destruir el tibble antes de imprimir
        echo('rk.header(\"Variables and Roles\", level = 3)\\n');
        echo('rk.print(as.data.frame(summary(rec_obj)))\\n');

        echo('rk.header(\"Preprocessing Steps Applied\", level = 3)\\n');
        echo('rk.print(as.data.frame(recipes::tidy(rec_obj)))\\n');

        if (getValue('rec_save.active')) {
            echo('rk.print(\"<hr>\")\\n');
            echo('rk.print(paste0(\"<b>Recipe object successfully saved as: </b><code>\", \"' + getValue('rec_save') + '\", \"</code>\"))\\n');
        }
    }
  "


  # Register Component
  comp_rec <- rk.plugin.component(
    "2. Build Recipe (Preprocessing)",
    xml = list(dialog = dialog_rec, logic = logic_rec),
    js = list(require = c("tidymodels", "recipes"), globals = js_helpers, calculate = js_calc_rec, printout = js_print_rec),
    hierarchy = h_tuning
  )

  # =========================================================================================
  # 4. MODULE 3: Model Specification & Hyperparameters (parsnip & tune)
  # =========================================================================================

  # --- UI Elements ---
  alg_type <- rk.XML.dropdown("Machine Learning Algorithm", options = list(
    "Random Forest (ranger)" = list(val = "rf", chk = TRUE),
    "XGBoost / Gradient Boosting (xgboost)" = list(val = "xgb"),
    "Support Vector Machine - Radial (kernlab)" = list(val = "svm")
  ), id.name = "alg_type")

  alg_mode <- rk.XML.radio("Task (Mode)", options = list(
    "Classification (Predict categories)" = list(val = "classification", chk = TRUE),
    "Regression (Predict numbers)" = list(val = "regression")
  ), id.name = "alg_mode")

  # 1. Random Forest Hyperparameters
  rf_mtry_chk <- rk.XML.cbox("Tune 'mtry' (Variables sampled at each split)", value = "TRUE", chk = TRUE, id.name = "rf_mtry_chk")
  rf_mtry_val <- rk.XML.spinbox("Fixed 'mtry'", min = 1, max = 100, initial = 3, real = FALSE, id.name = "rf_mtry_val")
  rf_trees_chk <- rk.XML.cbox("Tune 'trees' (Number of trees)", value = "TRUE", chk = FALSE, id.name = "rf_trees_chk")
  rf_trees_val <- rk.XML.spinbox("Fixed 'trees'", min = 1, max = 5000, initial = 500, real = FALSE, id.name = "rf_trees_val")
  rf_minn_chk <- rk.XML.cbox("Tune 'min_n' (Minimum data points in a node)", value = "TRUE", chk = TRUE, id.name = "rf_minn_chk")
  rf_minn_val <- rk.XML.spinbox("Fixed 'min_n'", min = 1, max = 100, initial = 5, real = FALSE, id.name = "rf_minn_val")

  # SOLUCIÓN: Agregamos id.name explícitos a cada rk.XML.row()
  frm_rf <- rk.XML.frame(
    rk.XML.row(rf_mtry_chk, rf_mtry_val, id.name = "row_rf_1"),
    rk.XML.row(rf_trees_chk, rf_trees_val, id.name = "row_rf_2"),
    rk.XML.row(rf_minn_chk, rf_minn_val, id.name = "row_rf_3"),
    label = "Random Forest Settings", id.name = "frm_rf"
  )

  # 2. XGBoost Hyperparameters
  xgb_trees_chk <- rk.XML.cbox("Tune 'trees' (Number of trees)", value = "TRUE", chk = TRUE, id.name = "xgb_trees_chk")
  xgb_trees_val <- rk.XML.spinbox("Fixed 'trees'", min = 1, max = 5000, initial = 500, real = FALSE, id.name = "xgb_trees_val")
  xgb_depth_chk <- rk.XML.cbox("Tune 'tree_depth' (Max depth of trees)", value = "TRUE", chk = TRUE, id.name = "xgb_depth_chk")
  xgb_depth_val <- rk.XML.spinbox("Fixed 'tree_depth'", min = 1, max = 15, initial = 6, real = FALSE, id.name = "xgb_depth_val")
  xgb_lr_chk <- rk.XML.cbox("Tune 'learn_rate' (Learning rate)", value = "TRUE", chk = TRUE, id.name = "xgb_lr_chk")
  xgb_lr_val <- rk.XML.spinbox("Fixed 'learn_rate'", min = 0.0001, max = 1, initial = 0.3, real = TRUE, id.name = "xgb_lr_val")

  frm_xgb <- rk.XML.frame(
    rk.XML.row(xgb_trees_chk, xgb_trees_val, id.name = "row_xgb_1"),
    rk.XML.row(xgb_depth_chk, xgb_depth_val, id.name = "row_xgb_2"),
    rk.XML.row(xgb_lr_chk, xgb_lr_val, id.name = "row_xgb_3"),
    label = "XGBoost Settings", id.name = "frm_xgb"
  )

  # 3. SVM Hyperparameters
  svm_cost_chk <- rk.XML.cbox("Tune 'cost' (Cost of predicting a sample within the margin)", value = "TRUE", chk = TRUE, id.name = "svm_cost_chk")
  svm_cost_val <- rk.XML.spinbox("Fixed 'cost'", min = 0.001, max = 100, initial = 1, real = TRUE, id.name = "svm_cost_val")
  svm_sigma_chk <- rk.XML.cbox("Tune 'rbf_sigma' (Precision parameter)", value = "TRUE", chk = TRUE, id.name = "svm_sigma_chk")
  svm_sigma_val <- rk.XML.spinbox("Fixed 'rbf_sigma'", min = 0.001, max = 10, initial = 0.1, real = TRUE, id.name = "svm_sigma_val")

  frm_svm <- rk.XML.frame(
    rk.XML.row(svm_cost_chk, svm_cost_val, id.name = "row_svm_1"),
    rk.XML.row(svm_sigma_chk, svm_sigma_val, id.name = "row_svm_2"),
    label = "SVM Settings", id.name = "frm_svm"
  )
  # Output Grid Settings
  alg_grid_size <- rk.XML.spinbox("Grid Size (Number of random parameter combinations to try)", min = 1, max = 100, initial = 10, real = FALSE, id.name = "alg_grid_size")
  frm_grid <- rk.XML.frame(alg_grid_size, label = "Tuning Grid Configuration")

  alg_save <- rk.XML.saveobj("Save Model Specification As:", initial = "model_spec", chk = TRUE, id.name = "alg_save")

 # --- UI Logic ---
  cond_rf <- rk.XML.convert(sources = list(string = alg_type), mode = c(equals = "rf"), id.name = "cond_rf")
  cond_xgb <- rk.XML.convert(sources = list(string = alg_type), mode = c(equals = "xgb"), id.name = "cond_xgb")
  cond_svm <- rk.XML.convert(sources = list(string = alg_type), mode = c(equals = "svm"), id.name = "cond_svm")

  logic_alg <- rk.XML.logic(
    cond_rf, cond_xgb, cond_svm,
    rk.XML.connect(governor = cond_rf, client = frm_rf, set = "enabled"),
    rk.XML.connect(governor = cond_xgb, client = frm_xgb, set = "enabled"),
    rk.XML.connect(governor = cond_svm, client = frm_svm, set = "enabled"),

    # SOLUCIÓN: Usamos 'state.not' para invertir la lógica directamente
    # Random Forest
    rk.XML.connect(governor = rf_mtry_chk, get = "state.not", client = rf_mtry_val, set = "enabled"),
    rk.XML.connect(governor = rf_trees_chk, get = "state.not", client = rf_trees_val, set = "enabled"),
    rk.XML.connect(governor = rf_minn_chk, get = "state.not", client = rf_minn_val, set = "enabled"),

    # XGBoost
    rk.XML.connect(governor = xgb_trees_chk, get = "state.not", client = xgb_trees_val, set = "enabled"),
    rk.XML.connect(governor = xgb_depth_chk, get = "state.not", client = xgb_depth_val, set = "enabled"),
    rk.XML.connect(governor = xgb_lr_chk, get = "state.not", client = xgb_lr_val, set = "enabled"),

    # SVM
    rk.XML.connect(governor = svm_cost_chk, get = "state.not", client = svm_cost_val, set = "enabled"),
    rk.XML.connect(governor = svm_sigma_chk, get = "state.not", client = svm_sigma_val, set = "enabled")
  )

  # --- Dialog Layout ---
  tab_alg <- rk.XML.tabbook(tabs = list(
    "1. Algorithm & Mode" = rk.XML.col(alg_type, alg_mode, rk.XML.stretch()),
    "2. Random Forest Settings" = rk.XML.col(frm_rf, rk.XML.stretch()),
    "3. XGBoost Settings" = rk.XML.col(frm_xgb, rk.XML.stretch()),
    "4. SVM Settings" = rk.XML.col(frm_svm, rk.XML.stretch()),
    "5. Grid & Output" = rk.XML.col(
      frm_grid,
      rk.XML.frame(alg_save, label = "Export Specification to Workspace"),
      rk.XML.stretch()
    )
  ))

  dialog_alg <- rk.XML.dialog(tab_alg, label = "3. Model Spec (Algorithms & Tuning)")


  # --- JavaScript Generators ---

  js_calc_alg <- "
    var alg = getValue('alg_type');
    var mode = getValue('alg_mode');

    echo('# Step 3: Model Specification and Tuning Grid\\n');

    var args = [];
    if (alg === 'rf') {
        var mtry = (getValue('rf_mtry_chk') === 'TRUE') ? 'tune()' : getValue('rf_mtry_val');
        var trees = (getValue('rf_trees_chk') === 'TRUE') ? 'tune()' : getValue('rf_trees_val');
        var minn = (getValue('rf_minn_chk') === 'TRUE') ? 'tune()' : getValue('rf_minn_val');

        echo('model_spec <- parsnip::rand_forest(mtry = ' + mtry + ', trees = ' + trees + ', min_n = ' + minn + ') %>%\\n');
        echo('  parsnip::set_engine(\"ranger\") %>%\\n');
        echo('  parsnip::set_mode(\"' + mode + '\")\\n');

    } else if (alg === 'xgb') {
        var x_trees = (getValue('xgb_trees_chk') === 'TRUE') ? 'tune()' : getValue('xgb_trees_val');
        var x_depth = (getValue('xgb_depth_chk') === 'TRUE') ? 'tune()' : getValue('xgb_depth_val');
        var x_lr = (getValue('xgb_lr_chk') === 'TRUE') ? 'tune()' : getValue('xgb_lr_val');

        echo('model_spec <- parsnip::boost_tree(trees = ' + x_trees + ', tree_depth = ' + x_depth + ', learn_rate = ' + x_lr + ') %>%\\n');
        echo('  parsnip::set_engine(\"xgboost\") %>%\\n');
        echo('  parsnip::set_mode(\"' + mode + '\")\\n');

    } else if (alg === 'svm') {
        var s_cost = (getValue('svm_cost_chk') === 'TRUE') ? 'tune()' : getValue('svm_cost_val');
        var s_sigma = (getValue('svm_sigma_chk') === 'TRUE') ? 'tune()' : getValue('svm_sigma_val');

        echo('model_spec <- parsnip::svm_rbf(cost = ' + s_cost + ', rbf_sigma = ' + s_sigma + ') %>%\\n');
        echo('  parsnip::set_engine(\"kernlab\") %>%\\n');
        echo('  parsnip::set_mode(\"' + mode + '\")\\n');
    }

    // Save grid size as a separate object so Module 4 can read it
    echo('model_grid_size <- ' + getValue('alg_grid_size') + '\\n\\n');
  "

  js_print_alg <- "
    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header(\"3. Model Specification (tidymodels)\", level = 2)\\n');

        // Anti-HTML Escaping for clean console output
        echo('alg_out <- paste(capture.output(print(model_spec)), collapse = \"\\\\n\")\\n');
        echo('alg_out <- gsub(\"<\", \"&lt;\", alg_out)\\n');
        echo('alg_out <- gsub(\">\", \"&gt;\", alg_out)\\n');
        echo('cat(paste0(\"<pre>\", alg_out, \"</pre>\\\\n\"), file = rk.get.output.html.file(), append = TRUE)\\n');

        if (getValue('alg_save.active')) {
            echo('rk.print(\"<hr>\")\\n');
            var save_name = getValue('alg_save');

            // RKWard maneja 'model_spec' mágicamente al final (Regla 13),
            // pero nosotros debemos mandar el grid_size al GlobalEnv manualmente:
            echo('.GlobalEnv$' + save_name + '_grid_size <- model_grid_size\\n');

            echo('rk.print(paste0(\"<b>Model spec saved as: </b><code>\", \"' + save_name + '\", \"</code><br>\"))\\n');
            echo('rk.print(paste0(\"<b>Grid size parameter saved as: </b><code>\", \"' + save_name + '_grid_size\", \"</code>\"))\\n');
        }
    }
  "

  # Register Component
  comp_alg <- rk.plugin.component(
    "3. Model Spec (Algorithms & Tuning)",
    xml = list(dialog = dialog_alg, logic = logic_alg),
    js = list(require = c("tidymodels", "parsnip"), globals = js_helpers, calculate = js_calc_alg, printout = js_print_alg),
    hierarchy = h_tuning
  )

  # =========================================================================================
  # 5. MODULE 4: Execution & Finalization (tune & workflows)
  # =========================================================================================

  # --- UI Elements ---
  exec_vs <- rk.XML.varselector(id.name = "exec_vs")

  # Cajas para arrastrar los 4 ingredientes del ecosistema (A prueba de balas)
  exec_data <- rk.XML.varslot("1. Original Training Dataset", source = "exec_vs", classes = "data.frame", required = TRUE, id.name = "exec_data")

  # 'rset' es la clase interna que usa tidymodels para los resamples (cv_folds)
  exec_res <- rk.XML.varslot("2. Resampling Object (e.g., cv_folds)", source = "exec_vs", classes = "rset", required = TRUE, id.name = "exec_res")

  # 'recipe' es la clase de las recetas
  exec_rec <- rk.XML.varslot("3. Recipe Object (e.g., rec_obj)", source = "exec_vs", classes = "recipe", required = TRUE, id.name = "exec_rec")

  # 'model_spec' es la clase de los modelos de parsnip
  exec_mod <- rk.XML.varslot("4. Model Specification (e.g., model_spec)", source = "exec_vs", classes = "model_spec", required = TRUE, id.name = "exec_mod")


  frm_inputs <- rk.XML.frame(exec_data, exec_res, exec_rec, exec_mod, label = "Input Objects (Drag and Drop)")

  exec_metric <- rk.XML.dropdown("Optimization Metric", options = list(
    "Accuracy (Classification)" = list(val = "accuracy", chk = TRUE),
    "ROC AUC (Classification)" = list(val = "roc_auc"),
    "RMSE (Regression)" = list(val = "rmse"),
    "R-Squared (Regression)" = list(val = "rsq")
  ), id.name = "exec_metric")

  frm_metric <- rk.XML.frame(exec_metric, label = "Tuning Goal")

  # Plot Options for the Tuning Results
   # --- NUEVO: Plot Customization (Títulos) ---
  exec_plot_main <- rk.XML.input("Main Title (Leave empty for default)", id.name = "exec_plot_main")
  exec_plot_xlab <- rk.XML.input("X-Axis Label (Leave empty for default)", id.name = "exec_plot_xlab")
  exec_plot_ylab <- rk.XML.input("Y-Axis Label (Leave empty for default)", id.name = "exec_plot_ylab")
  frm_exec_plot_labels <- rk.XML.frame(exec_plot_main, exec_plot_xlab, exec_plot_ylab, label = "Plot Customization")

  # Plot Options (Tamaño)
  exec_plot_w <- rk.XML.spinbox("HTML Plot Width (pixels)", min = 100, max = 5000, initial = 800, real = FALSE, id.name = "exec_plot_w")
  exec_plot_h <- rk.XML.spinbox("HTML Plot Height (pixels)", min = 100, max = 5000, initial = 600, real = FALSE, id.name = "exec_plot_h")
  exec_plot_res <- rk.XML.spinbox("Resolution (DPI)", min = 72, max = 600, initial = 120, real = FALSE, id.name = "exec_plot_res")
  frm_exec_graph <- rk.XML.frame(rk.XML.row(exec_plot_w, exec_plot_h, exec_plot_res), label = "HTML Graphics Size")

  # Exportar
  exec_save <- rk.XML.saveobj("Save Final Trained Model As:", initial = "final_model", chk = TRUE, id.name = "exec_save")
  exec_save_plot <- rk.XML.saveobj("Save Plot (ggplot2) As:", initial = "tuning_plot", chk = FALSE, id.name = "exec_save_plot")
  frm_exec_export <- rk.XML.frame(exec_save, exec_save_plot, label = "Export Objects to Workspace")

  # --- Dialog Layout (Actualizado a 3 pestañas) ---
  tab_exec <- rk.XML.tabbook(tabs = list(
    "1. Inputs & Goal" = rk.XML.col(frm_inputs, frm_metric, rk.XML.stretch()),
    "2. Plot Options" = rk.XML.col(frm_exec_plot_labels, frm_exec_graph, rk.XML.stretch()),
    "3. Output" = rk.XML.col(frm_exec_export, rk.XML.stretch())
  ))

  dialog_exec <- rk.XML.dialog(rk.XML.row(exec_vs, rk.XML.col(tab_exec)), label = "4. Execute & Finalize Model")

  # --- UI Logic ---
  logic_exec <- rk.XML.logic() # Vacío a propósito para ver el GlobalEnv completo

  # --- JavaScript Generators ---
  js_calc_exec <- "
    var data = getValue('exec_data');
    var res = getValue('exec_res');
    var rec = getValue('exec_rec');
    var mod = getValue('exec_mod');
    var metric = getValue('exec_metric');

    echo('# Step 4: Hyperparameter Tuning and Finalization\\n');

    // Juntar Receta y Modelo en un Workflow
    echo('wf <- workflows::workflow() %>%\\n');
    echo('  workflows::add_recipe(' + rec + ') %>%\\n');
    echo('  workflows::add_model(' + mod + ')\\n\\n');

    echo('cat(\"Tuning hyperparameters... This may take some time depending on your data and grid size.\\\\n\")\\n');

    // Mágia: El tamaño de la grilla lo guardamos dinámicamente como <mod>_grid_size en el Módulo 3
    echo('tune_res <- tune::tune_grid(\\n');
    echo('  wf,\\n');
    echo('  resamples = ' + res + ',\\n');
    echo('  grid = ' + mod + '_grid_size,\\n');
    echo('  metrics = yardstick::metric_set(yardstick::' + metric + ')\\n');
    echo(')\\n\\n');

    // Seleccionar la mejor combinación, finalizar la receta, y entrenar el modelo final
     echo('best_params <- tune::select_best(tune_res, metric = \"' + metric + '\")\\n');

    echo('final_wf <- tune::finalize_workflow(wf, best_params)\\n');

    // Regla de Oro 13 (Hardcode inicial de saveobj)
     echo('final_model <- fit(final_wf, data = ' + data + ')\\n\\n');

    // --- NUEVO: Construcción de la gráfica con títulos personalizados ---
    var main_tit = cleanStr(getValue('exec_plot_main'));
    var x_tit = cleanStr(getValue('exec_plot_xlab'));
    var y_tit = cleanStr(getValue('exec_plot_ylab'));

    var title_str = (main_tit !== '') ? main_tit : 'Hyperparameter Tuning Results';

    echo('p <- ggplot2::autoplot(tune_res) + ggplot2::theme_minimal() + \\n');
    echo('     ggplot2::labs(title = \"' + title_str + '\"');

    if (x_tit !== '') { echo(', x = \"' + x_tit + '\"'); }
    if (y_tit !== '') { echo(', y = \"' + y_tit + '\"'); }

    echo(')\\n');
  "

  js_print_exec <- "
    var w = getValue('exec_plot_w');
    var h = getValue('exec_plot_h');
    var res = getValue('exec_plot_res');
    var metric = getValue('exec_metric');

    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header(\"4. Model Execution and Tuning Results\", level = 2)\\n');

        // Imprimir gráfica del tuning
        echo('rk.graph.on(width = ' + w + ', height = ' + h + ', res = ' + res + ')\\n');
        echo('try({ print(p) }, silent=TRUE)\\n');
        echo('rk.graph.off()\\n\\n');

        // Imprimir resultados en tablas HTML
        echo('rk.header(\"Top 5 Hyperparameter Combinations\", level = 3)\\n');
        echo('rk.print(as.data.frame(tune::show_best(tune_res, metric = \"' + metric + '\")))\\n');

        echo('rk.header(\"Best Selected Parameters\", level = 3)\\n');
        echo('rk.print(as.data.frame(best_params))\\n');

        // NUEVO: Mensajes de confirmación y guardado del gráfico
        if (getValue('exec_save.active') || getValue('exec_save_plot.active')) {
            echo('rk.print(\"<hr>\")\\n');
        }

        if (getValue('exec_save.active')) {
            echo('rk.print(paste0(\"<b>Final trained model saved as: </b><code>\", \"' + getValue('exec_save') + '\", \"</code><br>\"))\\n');
        }

        if (getValue('exec_save_plot.active')) {
            // SOLUCIÓN (Regla de Oro 13): Usamos exactamente el string del 'initial' (tuning_plot)
            echo('tuning_plot <- p\\n');
            echo('rk.print(paste0(\"<b>Plot object (ggplot2) saved as: </b><code>\", \"' + getValue('exec_save_plot') + '\", \"</code>\"))\\n');
        }
    }
  "

  # Register Component
  comp_exec <- rk.plugin.component(
    "4. Execute & Finalize Model",
    xml = list(dialog = dialog_exec, logic = logic_exec),
    js = list(require = c("tidymodels", "tune", "workflows", "yardstick", "ggplot2", "ranger", "xgboost", "kernlab"), globals = js_helpers, calculate = js_calc_exec, printout = js_print_exec),
    hierarchy = h_tuning
  )

  # =========================================================================================
  # 6. BUILD SKELETON
  # =========================================================================================

  unlink("rk.tuning", recursive = TRUE)

  rk.plugin.skeleton(
    about = about_info,
    path = ".",
    # Only adding the main component for Module 1
    xml = list(dialog = dialog_res, logic = logic_res),
    js = list(require = c("tidymodels", "rsample"), globals = js_helpers, calculate = js_calc_res, printout = js_print_res),
    pluginmap = list(name = "1. Resample", hierarchy = h_tuning),
    dependencies = dependencies_node,
    components = list(comp_rec, comp_alg, comp_exec),
    create = c("pmap", "xml", "js", "desc", "rkh"),
    overwrite = TRUE,
    load = TRUE
  )

  cat("\nPhase 1: 'rk.tuning' generated successfully.\n")
})
