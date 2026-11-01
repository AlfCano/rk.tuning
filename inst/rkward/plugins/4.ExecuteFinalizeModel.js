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
	echo("require(tidymodels)\n");	echo("require(tune)\n");	echo("require(workflows)\n");	echo("require(yardstick)\n");	echo("require(ggplot2)\n");	echo("require(ranger)\n");	echo("require(xgboost)\n");	echo("require(kernlab)\n");
}

function calculate(is_preview){
	// read in variables from dialog


	// the R code to be evaluated

    var data = getValue('exec_data');
    var res = getValue('exec_res');
    var rec = getValue('exec_rec');
    var mod = getValue('exec_mod');
    var metric = getValue('exec_metric');

    echo('# Step 4: Hyperparameter Tuning and Finalization\n');

    // Juntar Receta y Modelo en un Workflow
    echo('wf <- workflows::workflow() %>%\n');
    echo('  workflows::add_recipe(' + rec + ') %>%\n');
    echo('  workflows::add_model(' + mod + ')\n\n');

    echo('cat("Tuning hyperparameters... This may take some time depending on your data and grid size.\\n")\n');

    // Mágia: El tamaño de la grilla lo guardamos dinámicamente como <mod>_grid_size en el Módulo 3
    echo('tune_res <- tune::tune_grid(\n');
    echo('  wf,\n');
    echo('  resamples = ' + res + ',\n');
    echo('  grid = ' + mod + '_grid_size,\n');
    echo('  metrics = yardstick::metric_set(yardstick::' + metric + ')\n');
    echo(')\n\n');

    // Seleccionar la mejor combinación, finalizar la receta, y entrenar el modelo final
     echo('best_params <- tune::select_best(tune_res, metric = "' + metric + '")\n');

    echo('final_wf <- tune::finalize_workflow(wf, best_params)\n');

    // Regla de Oro 13 (Hardcode inicial de saveobj)
     echo('final_model <- fit(final_wf, data = ' + data + ')\n\n');

    // --- NUEVO: Construcción de la gráfica con títulos personalizados ---
    var main_tit = cleanStr(getValue('exec_plot_main'));
    var x_tit = cleanStr(getValue('exec_plot_xlab'));
    var y_tit = cleanStr(getValue('exec_plot_ylab'));

    var title_str = (main_tit !== '') ? main_tit : 'Hyperparameter Tuning Results';

    echo('p <- ggplot2::autoplot(tune_res) + ggplot2::theme_minimal() + \n');
    echo('     ggplot2::labs(title = "' + title_str + '"');

    if (x_tit !== '') { echo(', x = "' + x_tit + '"'); }
    if (y_tit !== '') { echo(', y = "' + y_tit + '"'); }

    echo(')\n');
  
}

function printout(is_preview){
	// printout the results
	new Header(i18n("4. Execute & Finalize Model results")).print();

    var w = getValue('exec_plot_w');
    var h = getValue('exec_plot_h');
    var res = getValue('exec_plot_res');
    var metric = getValue('exec_metric');

    if (typeof is_preview === 'undefined' || !is_preview) {
        echo('rk.header("4. Model Execution and Tuning Results", level = 2)\n');

        // Imprimir gráfica del tuning
        echo('rk.graph.on(width = ' + w + ', height = ' + h + ', res = ' + res + ')\n');
        echo('try({ print(p) }, silent=TRUE)\n');
        echo('rk.graph.off()\n\n');

        // Imprimir resultados en tablas HTML
        echo('rk.header("Top 5 Hyperparameter Combinations", level = 3)\n');
        echo('rk.print(as.data.frame(tune::show_best(tune_res, metric = "' + metric + '")))\n');

        echo('rk.header("Best Selected Parameters", level = 3)\n');
        echo('rk.print(as.data.frame(best_params))\n');

        // NUEVO: Mensajes de confirmación y guardado del gráfico
        if (getValue('exec_save.active') || getValue('exec_save_plot.active')) {
            echo('rk.print("<hr>")\n');
        }

        if (getValue('exec_save.active')) {
            echo('rk.print(paste0("<b>Final trained model saved as: </b><code>", "' + getValue('exec_save') + '", "</code><br>"))\n');
        }

        if (getValue('exec_save_plot.active')) {
            // SOLUCIÓN (Regla de Oro 13): Usamos exactamente el string del 'initial' (tuning_plot)
            echo('tuning_plot <- p\n');
            echo('rk.print(paste0("<b>Plot object (ggplot2) saved as: </b><code>", "' + getValue('exec_save_plot') + '", "</code>"))\n');
        }
    }
  
	//// save result object
	// read in saveobject variables
	var execSave = getValue("exec_save");
	var execSaveActive = getValue("exec_save.active");
	var execSaveParent = getValue("exec_save.parent");	var execSavePlot = getValue("exec_save_plot");
	var execSavePlotActive = getValue("exec_save_plot.active");
	var execSavePlotParent = getValue("exec_save_plot.parent");
	// assign object to chosen environment
	if(execSaveActive) {
		echo(".GlobalEnv$" + execSave + " <- final_model\n");
	}
	if(execSavePlotActive) {
		echo(".GlobalEnv$" + execSavePlot + " <- tuning_plot\n");
	}

}

