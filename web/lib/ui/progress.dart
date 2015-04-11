part of hexedit;


class ProgressBar extends Component<DivElement> {

    DivElement bar;

    ProgressBar(DivElement progressElement) {
        this.element = progressElement;
    }

    double _max = 1.0;
    double _value = 0.0;

    double get max => this._max;
    void set max(double value) {
        this._max = value;
        this.update();
    }

    double get value => this._value;
    void set value(double newValue) {
        this._value = newValue;
        this.update();
    }

    void update() {
        this.bar.style.width = "${(this._value / this._max) * 100}%";
    }

    void create() {

        this.element.classes.add("progress");

        if (this.bar == null) {
            this.bar = this.$(".progress-bar");
            if (this.bar == null) {
                this.bar = new DivElement();
                this.element.append(this.bar);
            }
        }

        this.bar.classes.add("progress-bar");
        this.update();
    }
}

class ProgressDialog extends Dialog {

    ProgressBar progress;

    ProgressDialog(DivElement dialog, [String dialogClass = null]) : super(dialog, dialogClass) {
    }

    void create() {
        super.create();
        this.progress = new ProgressBar(this.dialog.querySelector(".progress"));
        this.progress.create();
    }

    void dismiss([String returnValue = null]) {
        this.canDismiss = true;
        super.dismiss(returnValue);
    }

}