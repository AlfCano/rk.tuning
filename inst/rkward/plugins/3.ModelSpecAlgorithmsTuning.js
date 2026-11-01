// this code was generated using the rkwarddev package.
// perhaps don't make changes here, but in the rkwarddev script instead!

// define variables globally
    function cleanStr(val) {
        if(!val) return '';
        return val.replace(/'/g, "\\'").replace(/"/g, '\\"');
    }

    function parseVar(fullPath) {
        if (!fullPath) return '';
        var raw_col = '';
        if (fullPath.indexOf('[[') > -1) {
            var parts = fullPath.split('[[');
            var inner = parts[1].replace(']]', '');
            raw_col = inner.replace(/["']/g, '');
        } else if (fullPath.indexOf('$') > -1) {
            raw_col = fullPath.split('$')[1];
        } else {
            raw_col = fullPath;
        }
        return raw_col;
    }
  



function preprocess(is_preview){
	// add requirements etc. here
	echo("require(tidymodels)\n");	echo("require(parsnip)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var alg = getValue('alg_type');
    var mode = getValue('alg_mode');

    echo('# Step 3: Model Specification and Tuning Grid\n');

    var args = [];
    if (alg === 'rf') {
        var mtry = (getValue('rf_mtry_chk') === 'TRUE') ? 'tune()' : getValue('rf_mtry_val');
        var trees = (getValue('rf_trees_chk') === 'TRUE') ? 'tune()' : getValue('rf_trees_val');
        var minn = (getValue('rf_minn_chk') === 'TRUE') ? 'tune()' : getValue('rf_minn_val');

        echo('model_spec <- parsnip::rand_forest(mtry = ' + mtry + ', trees = ' + trees + ', min_n = ' + minn + ') %>%\n');
        echo('  parsnip::set_engine("ranger") %>%\n');
        echo('  parsnip::set_mode("' + mode + '")\n');

    } else if (alg === 'xgb') {
        var x_trees = (getValue('xgb_trees_chk') === 'TRUE') ? 'tune()' : getValue('xgb_trees_val');
        var x_depth = (getValue('xgb_depth_chk') === 'TRUE') ? 'tune()' : getValue('xgb_depth_val');
        var x_lr = (getValue('xgb_lr_chk') === 'TRUE') ? 'tune()' : getValue('xgb_lr_val');

        echo('model_spec <- parsnip::boost_tree(trees = ' + x_trees + ', tree_depth = ' + x_depth + ', learn_rate = ' + x_lr + ') %>%\n');
        echo('  parsnip::set_engine("xgboost") %>%\n');
        echo('  parsnip::set_mode("' + mode + '")\n');

    } else if (alg === 'svm') {
        var s_cost = (getValue('svm_cost_chk') === 'TRUE') ? 'tune()' : getValue('svm_cost_val');
        var s_sigma = (getValue('svm_sigma_chk') === 'TRUE') ? 'tune()' : getValue('svm_sigma_val');

        echo('model_spec <- parsnip::svm_rbf(cost = ' + s_cost + ', rbf_sigma = ' + s_sigma + ') %>%\n');
        echo('  parsnip::set_engine("kernlab") %>%\n');
        echo('  parsnip::set_mode("' + mode + '")\n');
    }

    // Save grid size as a separate object so Module 4 can read it
    echo('model_grid_size <- ' + getValue('alg_grid_size') + '\n\n');
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("3. Model Spec (Algorithms & Tuning) results")).print();

    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header("3. Model Specification (tidymodels)", level = 2)\n');

        // Anti-HTML Escaping for clean console output
        echo('alg_out <- paste(capture.output(print(model_spec)), collapse = "\\n")\n');
        echo('alg_out <- gsub("<", "&lt;", alg_out)\n');
        echo('alg_out <- gsub(">", "&gt;", alg_out)\n');
        echo('cat(paste0("<pre>", alg_out, "</pre>\\n"), file = rk.get.output.html.file(), append = TRUE)\n');

        if (getValue('alg_save.active')) {
            echo('rk.print("<hr>")\n');
            var save_name = getValue('alg_save');

            // RKWard maneja 'model_spec' mágicamente al final (Regla 13),
            // pero nosotros debemos mandar el grid_size al GlobalEnv manualmente:
            echo('.GlobalEnv$' + save_name + '_grid_size <- model_grid_size\n');

            echo('rk.print(paste0("<b>Model spec saved as: </b><code>", "' + save_name + '", "</code><br>"))\n');
            echo('rk.print(paste0("<b>Grid size parameter saved as: </b><code>", "' + save_name + '_grid_size", "</code>"))\n');
        }
    }
  
	//// save result object
	// read in saveobject variables
	var algSave = getValue("alg_save");
	var algSaveActive = getValue("alg_save.active");
	var algSaveParent = getValue("alg_save.parent");
	// assign object to chosen environment
	if(algSaveActive) {
		echo(".GlobalEnv$" + algSave + " <- model_spec\n");
	}

}

