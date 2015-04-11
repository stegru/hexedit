part of hexedit.panels;


/**
 * Displays textual data based on the selection of the grid.
 */
class TextDataPanel extends DataPanel {
    TextDataPanel(String selector) : super(selector);

    List<DataItem> getItems() {
        List<DataItem> items = new List<DataItem>();

        for (DataType dataType in DataType.all) {
            if (dataType.category == DataCategory.TEXT) {
                items.add(new DataItem(dataType: dataType));
            }
        }

        return items;
    }
}