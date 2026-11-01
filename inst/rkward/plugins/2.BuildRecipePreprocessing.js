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
	echo("require(tidymodels)\n");	echo("require(recipes)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var data = getValue('rec_data');
    var target = parseVar(getValue('rec_target'));
    var preds_raw = getValue('rec_preds');

    echo('# Step 2: Feature Engineering via recipes\n');

    // Build formula
    var preds_str = '.';
    if (preds_raw !== '') {
        var preds_arr = preds_raw.split('\n').map(parseVar).filter(Boolean);
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
        echo(' %>%\n  recipes::step_impute_mean(recipes::all_numeric_predictors()) %>%\n  recipes::step_impute_mode(recipes::all_nominal_predictors())');
    } else if (impute === 'knn') {
        echo(' %>%\n  recipes::step_impute_knn(recipes::all_predictors())');
    }

    if (getValue('rec_dummy') === 'TRUE') {
        echo(' %>%\n  recipes::step_dummy(recipes::all_nominal_predictors())');
    }

    if (getValue('rec_norm') === 'TRUE') {
        echo(' %>%\n  recipes::step_normalize(recipes::all_numeric_predictors())');
    }

    var imb = getValue('rec_imb');
    if (imb === 'down') {
        echo(' %>%\n  themis::step_downsample(`' + target + '`)');
    } else if (imb === 'smote') {
        echo(' %>%\n  themis::step_smote(`' + target + '`)');
    }

    echo('\n\n');
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("2. Build Recipe (Preprocessing) results")).print();

    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header("2. Feature Engineering Recipe (tidymodels)", level = 2)\n');

        // SOLUCIÓN: Envolvemos las funciones en as.data.frame() para destruir el tibble antes de imprimir
        echo('rk.header("Variables and Roles", level = 3)\n');
        echo('rk.print(as.data.frame(summary(rec_obj)))\n');

        echo('rk.header("Preprocessing Steps Applied", level = 3)\n');
        echo('rk.print(as.data.frame(recipes::tidy(rec_obj)))\n');

        if (getValue('rec_save.active')) {
            echo('rk.print("<hr>")\n');
            echo('rk.print(paste0("<b>Recipe object successfully saved as: </b><code>", "' + getValue('rec_save') + '", "</code>"))\n');
        }
    }
  
	//// save result object
	// read in saveobject variables
	var recSave = getValue("rec_save");
	var recSaveActive = getValue("rec_save.active");
	var recSaveParent = getValue("rec_save.parent");
	// assign object to chosen environment
	if(recSaveActive) {
		echo(".GlobalEnv$" + recSave + " <- rec_obj\n");
	}

}

