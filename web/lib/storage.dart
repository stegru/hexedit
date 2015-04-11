part of hexedit;

/** Handles the loading and saving of files. */
class Storage {
    static final Storage _instance = new Storage._();

    FileUploadInputElement fileInput;

    factory Storage() {
        return _instance;
    }

    Storage._() {
    }

    void openFileDialog(HexEdit hexEdit) {
    }
}

