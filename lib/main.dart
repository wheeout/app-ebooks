import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:vocsy_epub_viewer/epub_viewer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Book {
  final int id;
  final String title;
  final String author;
  final String coverUrl;
  final String downloadUrl;
  bool isFavorite;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.downloadUrl,
    this.isFavorite = false,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      title: json['title'],
      author: json['author'],
      coverUrl: json['cover_url'],
      downloadUrl: json['download_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'cover_url': coverUrl,
      'download_url': downloadUrl,
      'is_favorite': isFavorite,
    };
  }
}

class BookModel extends ChangeNotifier {
  List<Book> _books = [];

  List<Book> get books => _books;

  Future<void> fetchBooks() async {
    final url = 'https://escribo.com/books.json';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        _books = data.map((json) => Book.fromJson(json)).toList();

        notifyListeners();
      } else {
        throw Exception('Falha ao baixar a lista de livros');
      }
    } catch (e) {}
  }

  Future<void> downloadBook(Book book) async {
    final fileName = '${book.id}.epub';
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';
    final fileExists = await File(filePath).exists();

    if (!fileExists) {
      final response = await http.get(Uri.parse(book.downloadUrl));

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        notifyListeners();
      } else {
        throw Exception('Falha ao baixar o livro');
      }
    }
  }

  void toggleFavorite(Book book) {
    book.isFavorite = !book.isFavorite;

    if (book.isFavorite) {
      _books.remove(book);
      _books.insert(0, book);
    }

    notifyListeners();
  }
}

class BookApp extends StatelessWidget {
  final bookModel = BookModel();

  BookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplicativo de eBooks',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChangeNotifierProvider(
        create: (context) => bookModel,
        child: BookHome(bookModel: bookModel),
      ),
    );
  }
}

class BookHome extends StatefulWidget {
  final BookModel bookModel;

  const BookHome({Key? key, required this.bookModel}) : super(key: key);

  @override
  _BookHomeState createState() {
    return _BookHomeState();
  }
}

class BookReader extends StatelessWidget {
  final Book book;

  const BookReader({Key? key, required this.book}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return FutureBuilder(
      future: _getFilePath(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final filePath = snapshot.data as String;

          return InkWell(
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              final lastLocationJson =
                  prefs.getString('${book.id}_lastLocation');

              final lastLocation = lastLocationJson != null
                  ? EpubLocator.fromJson(jsonDecode(lastLocationJson))
                  : null;

              VocsyEpub.open(filePath, lastLocation: lastLocation);

              VocsyEpub.locatorStream.listen((locator) {
                prefs.setString('${book.id}_lastLocation', locator);
              });
            },
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Future<String> _getFilePath() async {
    final fileName = '${book.id}.epub';
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';
    return filePath;
  }
}

class _BookHomeState extends State<BookHome> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    if (widget.bookModel.books.isEmpty) {
      widget.bookModel.fetchBooks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aplicativo de eBooks'),
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<BookModel>(
      builder: (context, bookModel, child) {
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemCount: bookModel.books.length,
          itemBuilder: (context, index) {
            final book = bookModel.books[index];

            if (_selectedIndex == 1) {
              if (!book.isFavorite) {
                return SizedBox.shrink();
              }
            }

            return InkWell(
              onTap: () async {
                await bookModel.downloadBook(book);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookReader(book: book),
                  ),
                );
              },
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.network(
                    book.coverUrl,
                    fit: BoxFit.cover,
                  ),
                  IconButton(
                    icon: Icon(
                      book.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: book.isFavorite ? Colors.red : null,
                    ),
                    onPressed: () {
                      bookModel.toggleFavorite(book);
                    },
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      alignment: Alignment.bottomLeft,
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.8)
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            book.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

void main() => runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => BookModel()),
        ],
        child: BookApp(),
      ),
    );
