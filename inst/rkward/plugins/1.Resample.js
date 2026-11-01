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
	echo("require(tidymodels)\n");	echo("require(rsample)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var data = getValue('res_data');
    var strata = parseVar(getValue('res_strata'));
    var type = getValue('res_type');
    var seed_chk = getValue('res_seed_chk');
    var seed_val = getValue('res_seed_val');

    echo('# Step 1: Validation Strategy via rsample\n');

    if (seed_chk === 'TRUE') {
        echo('set.seed(' + seed_val + ')\n');
    }

    var strata_arg = (strata !== '') ? ', strata = ' + strata : '';

    if (type === 'vfold') {
        var v = getValue('res_v');
        var r = getValue('res_repeats');
        var rep_arg = (r > 1) ? ', repeats = ' + r : '';
        // REGLA 13: El nombre DEBE ser cv_folds (el initial del saveobj)
        echo('cv_folds <- rsample::vfold_cv(' + data + ', v = ' + v + rep_arg + strata_arg + ')\n');

    } else if (type === 'boot') {
        var times = getValue('res_times');
        echo('cv_folds <- rsample::bootstraps(' + data + ', times = ' + times + strata_arg + ')\n');

    } else if (type === 'split') {
        var prop = getValue('res_prop');
        echo('cv_folds <- rsample::initial_split(' + data + ', prop = ' + prop + strata_arg + ')\n');
    }
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("1. Resample results")).print();

    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header("1. Resampling Strategy (tidymodels)")\n');

        // 1. Capturamos la salida
        echo('res_out <- paste(capture.output(print(cv_folds)), collapse = "\\n")\n');

        // 2. Escapamos los signos < > para que el HTML no se confunda
        echo('res_out <- gsub("<", "&lt;", res_out)\n');
        echo('res_out <- gsub(">", "&gt;", res_out)\n');

        // 3. Imprimimos el bloque de texto puro y seguro
        echo('cat(paste0("<pre>", res_out, "</pre>\\n"), file = rk.get.output.html.file(), append = TRUE)\n');

        if (getValue('res_save.active')) {
            echo('rk.print("<hr>")\n');
            echo('rk.print(paste0("<b>Resample object successfully saved as: </b><code>", "' + getValue('res_save') + '", "</code>"))\n');
        }
    }
  
	//// save result object
	// read in saveobject variables
	var resSave = getValue("res_save");
	var resSaveActive = getValue("res_save.active");
	var resSaveParent = getValue("res_save.parent");
	// assign object to chosen environment
	if(resSaveActive) {
		echo(".GlobalEnv$" + resSave + " <- cv_folds\n");
	}

}

