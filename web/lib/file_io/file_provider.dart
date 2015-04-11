part of hexedit.file_io;


abstract class FileProvider {

    static List<FileProvider> _providers = [ new BrowserFileProvider()  ];

    static void addProvider(FileProvider provider) {
        _providers.add(provider);
    }

    static List<FileProvider> getProviders() {
        return _providers.toList(growable: false);
    }

    static FileProvider getProvider(String id) {
        return _providers.where( (p) => p.name ).first;
    }

    String name;
    String id;

    FileProvider() {

    }

    Future<FileInfo> openFile();
    void saveFile(FileInfo file);

}


class FileInfo {

    String name;
    String path;

    File file;

}
