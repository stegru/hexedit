part of hexedit.panels;


/**
 * Displays textual data based on the selection of the grid.
 */
class FindPanel extends Panel {
    FindPanel(String selector) : super(selector);

    bool isBottomPanel = true;


    void create() {
        this.expanded = false;

        super.create();
    }


    void addEventHandlers() {
        super.addEventHandlers();
    }

    void update() {

    }
}
