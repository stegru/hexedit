part of hexedit.panels;


/**
 * Displays numeric data based on the selection of the grid.
 */
class NumericDataPanel extends DataPanel {
    NumericDataPanel(String selector) : super(selector);

    List<DataItem> getItems() {
        List<DataItem> items = new List<DataItem>();

        for (DataType dataType in DataType.all) {
            if (dataType.category == DataCategory.INTEGERS || dataType.category == DataCategory.FLOATS) {
                items.add(new DataItem(dataType: dataType));
            }
        }

        return items;
    }
}