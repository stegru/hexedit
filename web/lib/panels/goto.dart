part of hexedit.panels;


/**
 * Displays textual data based on the selection of the grid.
 */
class GotoPanel extends Panel {
    GotoPanel(String selector) : super(selector);

    bool isBottomPanel = true;
    TextInputElement offsetText;
    SelectElement whenceDropdown;
    CheckboxInputElement extendCheckbox;

    void create() {
        this.expanded = false;
        super.create();

        this.offsetText = this.$('#goto-offset');
        this.whenceDropdown = this.$('#goto-whence');
        this.extendCheckbox = this.$('#goto-extend');
    }

    void addEventHandlers() {
        super.addEventHandlers();

        this.onToggle.add((Panel p) {
            if (p.expanded) {
                this.offsetText.focus();
            }
        });
    }

    void focus() {
        if (this.expanded) {
            this.offsetText.focus();
        } else {
            this.expand(true);
        }
    }

    void submit() {
        int number = int.parse(this.offsetText.value, radix: 10, onError: (String s) => null);

        if (number == null) {
            return;
        }

        int offset = 0;

        switch (this.whenceDropdown.value) {
            case "start":
                offset = number.abs();
                break;
            case "offset":
                offset = this.grid.selection.offset;
                break;
            case "end":
                offset = this.hexEdit.data.length - number.abs();
                break;
        }

        offset = offset.clamp(0, this.hexEdit.data.length);

        if (this.extendCheckbox.checked) {
            if (this.grid.selection.length > 0) {
                int start, end;
                if (offset < this.grid.selection.offset) {
                     end = this.grid.selection.offset + this.grid.selection.length;
                } else {
                    start = this.grid.selection.offset;
                    end = offset;
                }
            } else {
                this.grid.selection.set(this.grid.cursorOffset, offset);
            }
        } else {
            this.grid.selection.set(offset);
        }
    }

    void update() {

    }
}
