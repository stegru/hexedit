part of hexedit;

class Dialog extends Component<DivElement> {

    bool created = false;


    /// Ultimate parent of the dialog, will be the shader for modals.
    DivElement container;
    /// The whole dialog.
    DivElement dialog;
    /// The title.
    DivElement title;
    /// Button container.
    DivElement footer;

    /// What the dialog content used to belong to (and will be re-appended to upon closure).
    Element originalParent = null;

    String dialogClass = null;

    List<Element> buttons = [];
    Element defaultButton = null;

    Completer completer;

    static Dialog active = null;

    bool canDismiss = true;


    String get titleText => this.element.dataset["title"];

    set titleText(String value) {
        if (value == null) {
            value = "";
        }
        this.element.dataset["title"] = value;
        if (this.created) {
            this.title.dataset["title"] = value;
        }
    }

    bool get visible {
        return this.dialog.style.visibility != 'hidden';

    }

    void set visible(bool value) {
        this.dialog.style.visibility = value ? 'visible' : 'hidden';
    }

    /**
     * Display a yes/no pop-up (or ok/cancel if [okCancel] is true).
     */
    static Future<bool> confirm(String text, {String title: "", bool okCancel: false}) {
        Completer<bool> completer = new Completer<bool>();

        Dialog.prompt(text, okCancel ? ["*ok|OK", "cancel|Cancel"] : ["*yes|Yes", "no|No"], title: title).then((String value) {
            completer.complete(value == "yes" || value == "ok");
        });

        return completer.future;
    }

    /**
     * Displays a popup containing [prompt], with the specified [buttons].
     * [buttons] is an array of strings in the form of "id|text" (or just "text"). The return value of the future
     * is the id (or index) of the button clicked. null if the pop-up was closed without using a button.
     */
    static Future<String> prompt(String text, List<String> buttons, {String title: "", String dialogClass: null}) {
        DivElement content = new DivElement();
        content.text = text;

        Dialog dlg = new Dialog(content, dialogClass);
        dlg.titleText = title;

        RegExp re = new RegExp(r"[^a-z0-9_-]+");
        for (String button in buttons) {
            bool isDefault = (button[0] == "*");
            if (isDefault) {
                button = button.substring(1);
            }

            List<String> s = button.split("|");
            String text, id, cls;
            if (s.length > 1) {
                text = s[1];
                id = s[0];
                cls = "button-${id}";
            } else {
                text = button;
                id = "";
                cls = null;
            }

            dlg.addButton(text, id: id, classes: cls == null ? null : [cls], isDefault: isDefault);
        }

        return dlg.show();
    }

    /**
     * Create a new [Dialog], using [dialog] as the content.
     */
    Dialog(DivElement dialog, [String dialogClass = null]) {
        this.element = dialog;
        this.originalParent = this.element.parent;
        this.titleText = this.element.dataset["title"];
        this.dialogClass = dialogClass;
    }

    /**
     * Create and wraps the dialog around the content.
     */
    void create() {

        if (!this.created) {
            /*
                <div class="dialog-behind modal">
                    <div class="dialog">
                        <div class="dialog-title"></div>
                        <div class="dialog-content"></div>
                        <div class="dialog-footer"></div>
                    </div>
                </div>
             */
            this.container = new DivElement();
            this.container.classes.addAll(["dialog-shade", "modal", "showing"]);

            this.container.onClick.listen((MouseEvent e) {
                if (e.target == this.container) {
                    this.dismiss(null);
                    e.stopPropagation();
                    e.stopImmediatePropagation();
                }
            });

            this.dialog = new DivElement();
            this.dialog.classes.add("dialog");
            if (this.dialogClass != null) {
                this.dialog.classes.add(this.dialogClass);
            }

            this.title = new DivElement();
            this.title.classes.add("dialog-title");
            this.title.dataset = this.element.dataset;

            this.footer = new DivElement();
            this.footer.classes.add("dialog-footer");
            this.buttons.forEach((button) => this.footer.append(button));

            this.element.classes.add("dialog-content");

            this.element.remove();
            this.container.append(this.dialog);
            this.dialog
                ..append(this.title)
                ..append(this.element)
                ..append(this.footer);

            document.body.append(this.container);

            this.created = true;
        }
    }

    /**
     * Shows the dialog.
     */
    Future<String> show() {
        this.create();

        new Timer(new Duration(milliseconds: 1), () {
            this.container.classes.add("show");
            this.container.classes.remove("showing");
        });

        Dialog.active = this;

        if (this.defaultButton == null && this.buttons != null && this.buttons.isNotEmpty) {
            this.defaultButton = this.buttons.first;
        }
        if (this.defaultButton != null) {
            this.defaultButton.dataset["default"] = "1";
            this.defaultButton.focus();
        }



        this.completer = new Completer<String>();
        return this.completer.future;
    }

    void destroy() {

        if (Dialog.active == this) {
            bool couldDismiss = this.canDismiss;
            this.canDismiss = false;
            this.dismiss();
            this.canDismiss = couldDismiss;
        }

        this.element.remove();

        if (this.originalParent != null) {
            this.originalParent.append(this.element);
        }

        this.container.remove();
        this.container = this.dialog = this.title = this.footer = null;
    }

    /**
     * Dismiss the dialog.
     */
    void dismiss([String returnValue = null]) {

        if (!this.canDismiss) {
            return;
        }

        this.container.classes.add("hide");
        this.container.classes.remove("show");
        this.container.onTransitionEnd.listen((Event e) {
            this.container.classes.removeAll(["show", "hide", "showing"]);
        });

        //this.shade.classes.remove("show");
        Dialog.active = null;

        this.completer.complete(returnValue);

        this.destroy();
    }

    void buttonClicked(MouseEvent e) {
        Element b = e.currentTarget as Element;
        this.dismiss(b.dataset["id"]);
        e.stopPropagation();
    }

    void addButton(String text, {String id: "", List<String> classes: null, bool isDefault: false}) {
        Element button = new ButtonElement();

        if (classes != null) {
            button.classes.addAll(classes);
        }

        button.classes.add("button");

        if (id == null || id == "") {
            id = this.buttons.length.toString();
            if (classes == null) {
                classes = [ text.toLowerCase().replaceAll(new RegExp("[^a-z0-9_-]+"), "") ];
            }
        } else {
            if (classes == null) {
                classes = [ id.toLowerCase().replaceAll(new RegExp("[^a-z0-9_-]+"), "") ];
            }
        }

        button.dataset["id"] = id;

        button.appendHtml("<span>${text}</span>");
        button.onClick.listen(this.buttonClicked);

        if (isDefault) {
            this.defaultButton = button;
        }

        this.buttons.add(button);
    }

}