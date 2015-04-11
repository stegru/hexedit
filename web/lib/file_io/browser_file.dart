part of hexedit.file_io;

class BrowserFileProvider extends FileProvider {

    FileUploadInputElement fileInput;

    BrowserFileProvider() : super() {
        this.id = "browser";
        this.name = "Local file system";
    }

    Future<FileInfo> openFile() {
        Completer completer = new Completer<FileInfo>();

        if (this.fileInput != null) {
            this.fileInput.remove();
            this.fileInput = null;
        }

        if (this.fileInput == null) {
            this.fileInput = new FileUploadInputElement();

            this.fileInput.onChange.listen((Event e) {

                if (this.fileInput.files.length > 0) {
                    FileInfo fileInfo = new FileInfo();

                    fileInfo.file = this.fileInput.files.first;
                    fileInfo.name = fileInfo.file.name;
                    fileInfo.path = fileInfo.file.relativePath;

                    completer.complete(fileInfo);

                }
            });

            this.fileInput.onAbort.listen((Event e){
//                this.fileInput.remove();
//                this.fileInput = null;
            });

            document.body.append(this.fileInput);
        }

        this.fileInput.click();

        return completer.future;
    }

    void saveFile(FileInfo file) {

    }

}