# The Golden Rules of RKWard Plugin Development (v4.3 - Expanded Edition)

*Comprehensive guidelines for `rkwarddev` (0.10-3+) based on real-world debugging, advanced architectural design, and hard-earned lessons.*

## Part I: The Core Architecture & Generation

### 1. The R Script is the Single Source of Truth
Your output is always a single R script wrapped in `local({})`.
*   **Never** manually edit the generated `.xml`, `.js`, or `.pluginmap` files.
*   If you need to change something, change the generator script and regenerate.

### 2. The Hierarchy Case-Sensitivity Rule
RKWard's internal menu IDs are **case-sensitive** and predefined.
*   **Standard Menus:** `"data"`, `"analysis"`, `"plots"`, `"distributions"`.
*   **The Trap:** If you use `"Data"` (capital D), RKWard treats it as a custom menu (falling back to "Test").
*   **Correct:** `hierarchy = list("data", "My Submenu")`.

### 3. The "Ghost Plugin" Fallacy (Skeleton vs. Components)
When building multi-component plugins, you might be tempted to put everything inside the `components = list(...)` argument and leave the main `xml` and `js` arguments empty in `rk.plugin.skeleton()`.
*   **The Trap:** If you request file creation (`create = c("xml", "js")`) but leave the main arguments empty, `rkwarddev` creates a blank "ghost" plugin with broken `.js` paths, causing a QtScript engine crash on load.
*   **The Rule:** The primary interface (your "Main" component) **must** be defined directly inside `xml` and `js` in `rk.plugin.skeleton()`. Only use the `components` list for *additional* secondary tools (like Reshaping or Fast I/O).

### 4. The Anti-Overwrite Bug Protocol (The `unlink` Silver Bullet)
When repeatedly compiling a plugin during development, `rkwarddev` often throws a *"File already exists and overwrite is set to FALSE"* error, even when `overwrite = TRUE` is explicitly set in `rk.plugin.skeleton()` (due to internal sub-component bugs).
*   **The Solution:** Always place an `unlink("your.plugin.name", recursive = TRUE)` command immediately before the `rk.plugin.skeleton()` call. Erasing the old directory prevents all internal file conflicts.

---

## Part II: Internationalization (i18n)

### 5. The `po_id` Generation Logic
RKWard determines the "text domain" (translation ID) based on the **Plugin Map Name**, stripping spaces and appending `_rkward`.
*   Name: `"data.table GUI"` -> ID: `datatableGUI_rkward`

### 6. The Binary File Naming Convention & Manual Strategy
The compiled translation file (`.mo`) must match the `po_id` exactly.
*   **Format:** `rkward__[po_id].mo`
*   **Failure Mode:** If automatic extraction (`rk.updatePluginMessages`) fails, manually create the `.po` files, compile with Poedit, and place the `.mo` files in `inst/rkward/po/[lang]/LC_MESSAGES/`.

---

## Part III: Robust JavaScript Generation & R Backend

### 7. The Quote Escaping Strategy (Backslash Hell)
Use **Single Quotes** in JS to wrap R code strings, and properly escape internal double quotes (`\\"`).

### 8. Variable Name Safety (Backticks)
Never assume a user's variable name is safe. Use a `parseVar()` JS helper to strip RKWard's `[[` formatting, and always wrap the raw variable names in backticks (`` ` ``) in the generated R code.

### 9. The Backend Overwrite Contract
When the user selects "Overwrite" in an RKWard file save dialog, RKWard *only* suppresses the GUI warning. It does **not** force the R backend to overwrite.
*   **The Trap:** Functions like `tinytable::save_tt` or `ipumsr::set_ipums_api_key` will still fail with a "File already exists" error in the R console.
*   **The Rule:** Your generated JS code must explicitly inject `overwrite = TRUE` into the R function call when writing files or modifying system files (`.Renviron`).

### 10. Preview Logic Stability (`is_preview`)
Previews run continuously. You must prevent the plugin from saving files to disk or printing duplicate headers during a preview.
*   **The Rule:** Wrap all permanent actions (like saving files or exporting headers) in this strict JS condition:

```{javascript}
    if (typeof is_preview === 'undefined' || !is_preview) { // Permanent actions }
```

---

## Part IV: UI, Layout, & Logic

### 11. The Boolean Logic Conversion Rule (UI Signals)
You cannot connect a `Radio` button or `Dropdown` string value directly to a frame's `visible` or `enabled` property.
*   **The Trap:** `rk.XML.connect(governor = "my_radio.string", set = "visible")` will fail silently or throw XML parsing errors.
*   **The Rule:** You **must** convert the string state into a Boolean signal using `rk.XML.convert()`, and then connect that signal to the UI element.
    ```R
    # 1. Convert string to Boolean
    cond_true <- rk.XML.convert(sources = list(my_radio), mode = c(equals = "option_a"), id.name = "cond_a")
    # 2. Apply logic
    logic <- rk.XML.logic(cond_true, rk.XML.connect(governor = cond_true, client = my_frame, set = "visible"))
    ```

### 12. The Global Varselector Paradigm
When using an `rk.XML.tabbook` with multiple tabs requiring variable inputs, **do not** place the `varselector` inside one of the tabs.
*   **The UX Trap:** Users cannot drag and drop variables into slots located on Tab 2 if the selector is hidden on Tab 1.
*   **The Solution:** Wrap the entire dialog in an `rk.XML.row()`. Place the `varselector` on the left, and the `tabbook` on the right. This keeps the selector globally visible.

### 13. The `calculate` / `saveobj` Double Assignment Trap
When providing users with an `rk.XML.saveobj()` tool to export results to the Global Environment:
*   **The Rule:** RKWard handles the actual `.GlobalEnv$user_name <- result` assignment internally at the very end of the script execution.
*   **The Trap:** Do not write `echo("user_name <- result")` in your JS `printout` phase. This will execute a redundant assignment, waste memory, and cause confusing output logs. Just inform the user:
    ```javascript
    echo('rk.print("<b>Saved as: </b><code>" + getValue("my_save_ui") + "</code>")');
    ```
*   **The Hardcoding Rule:** The R object generated in the `calculate` JS block *must* use the exact hardcoded string defined in the `initial` argument of `rk.XML.saveobj`.

---

## Part V: Performance & Memory Management

### 14. The "Silent Killer" of Memory (`ggplot2` Environments)
`ggplot2` captures the entire local plugin environment (`local({})`) when rendering.
*   **The Cure:** Always execute `p$plot_env <- emptyenv()` and clear large intermediate dataframes (`rm()`, `gc()`) before exposing the plot object to prevent `.RData` workspace bloat.

## Part VI: Advanced Rendering (HTML & Widgets)

### 15. The HTML Preview & Injection Protocol
RKWard expects static graphics for previews. To output interactive HTML (like `tinytable` or `DT` widgets), you must bypass the standard device.
*   **Force Output Mode:** `<preview mode="output" />`
*   **The `srcdoc` Injection:** Save the widget as a temporary HTML file in R, read it as a raw string, inject it into a Bootstrap-formatted `<iframe>` using the `srcdoc` attribute (escaping single quotes), and print it directly via `cat(..., file = rk.get.output.html.file(), append = TRUE)`.
