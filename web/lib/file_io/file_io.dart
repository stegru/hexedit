library hexedit.file_io;

import "dart:html";
import 'dart:async';

import '../hexedit.dart';

part 'file_provider.dart';
part 'browser_file.dart';

class FileIO {

    Element dialogElement;
    Element listElement;
    bool populated = false;
    Dialog dialog = null;

    Completer<FileInfo> completer = null;
    List<FileProvider> providers = [];

    static FileIO _instance = new FileIO._();

    FileIO._() {
    }

    static void init(Element dialog, Element list) {

        _instance.dialogElement = dialog;
        _instance.listElement = list;
    }

    static Future<FileInfo> open() {
        return _instance.show();
    }

    bool populate() {

        if (!this.populated) {
            this.providers = FileProvider.getProviders();

            if (this.providers.length < 2) {
                return false;
            }

            for (FileProvider provider in this.providers) {
                SpanElement item = new SpanElement();
                item.dataset["id"] = provider.id;
                item.dataset["name"] = provider.name;
                item.classes.addAll(["file-provider-item", provider.id]);

                SpanElement label = new SpanElement();
                label.text = provider.name;
                label.dataset = item.dataset;
                item.append(label);

                item.onClick.listen((MouseEvent e) {
                    provider.openFile().then((FileInfo fi) {
                        this.dialog.dismiss("success");
                        this.completer.complete(fi);
                    });
                });

                this.listElement.append(item);
            }
            this.populated = true;
        }

        return true;
    }

    Future<FileInfo> show() {
        if (!this.populate()) {
            if (this.providers.length > 0) {
                return this.providers.first.openFile();
            }

            return new Future<FileInfo>.error("No providers");
        }

        this.dialog = new Dialog(this.dialogElement);
        this.completer = new Completer<FileInfo>();


        this.dialog
            ..addButton("Close")
            ..create();


        this.dialog.show().then((value) {
            if (value == null && !this.completer.isCompleted) {
                this.completer.complete(null);
            }
        });

        return this.completer.future;
    }
}