import 'package:flutter/material.dart';
import 'package:webfeed/webfeed.dart';
import 'package:http/http.dart' as http;
import 'dart:convert' show utf8;
import 'package:cached_network_image/cached_network_image.dart';

class RssHomePage extends StatefulWidget {
  RssHomePage({Key key}) : super(key: key);

  @override
  _RssHomePageState createState() => _RssHomePageState();
}

class _RssHomePageState extends State<RssHomePage> {
  RssFeed _feed;
  String rssurl = 'https://t24.com.tr/rss'; // kullanacağımız rss sitesinin urli
  GlobalKey<RefreshIndicatorState>
      _refreshKey; // yukarıdan çektiğimiz sayfanın yenilenmesi için kullanacağımız key
  static const String placeholderImg =
      'assets/rss.png'; // resimler yüklenene kadar gözükecek resim yolu

  Future<void> load() async {
    await loadFeed().then((result) async {
      if (null == result || result.toString().isEmpty) {
        return;
      }
      setState(() {
        _feed = result;
      });
    });
  }

  Future<RssFeed> loadFeed() async {
    try {
      final client = http.Client();
      final response = await client.get(rssurl);
      final responseBody = utf8.decode(response.bodyBytes);
      return RssFeed.parse(responseBody);
    } on Exception {}
    return null;
  }

  @override
  void initState() {
    super.initState();
    _refreshKey = GlobalKey<RefreshIndicatorState>();
    load();
  }

  Widget list() {
    // ekranda göreceğimiz arayüz. Arayüzde değiştirme isterseniz burayı güncellemeniz gerekiyor.
    return ListView.builder(
      padding: const EdgeInsets.only(left: 1, right: 1, top: 5),
      shrinkWrap: true,
      itemCount: _feed.items.length,
      itemBuilder: (BuildContext context, int index) {
        final item = _feed.items[index];
        return Column(
          children: [
            GestureDetector(
              // birazdan haberin üzerine tıklayınca haber ayrıntılarına gitmek için kullanacağız.
              onTap: () {
                print('yönlendirme');
              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: ListTile(
                    leading: CachedNetworkImage(
                      placeholder: (context, url) =>
                          Image.asset(placeholderImg),
                      imageUrl: item.enclosure.url,
                      alignment: Alignment.center,
                      fit: BoxFit.fill,
                    ),
                    title: Text(
                      item.title ??
                          "title gelecek", // haber ilk girildiğinde title bazen boş olabiliyor, hata almamak için bu şeklide bir kullanım tercih ettim
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  bool isFeedEmpty() {
    // rssten veri gelip gelmediğinin kontrolü
    return null == _feed || null == _feed.items;
  }

  Widget body() {
    // Gelmediyse ortada yükleniyor işareti dönüyor. Geldiyse oluşturduğumuz list() yükleniyor.
    return isFeedEmpty() // kontrol
        ? Center(child: CircleAvatar())
        : RefreshIndicator(
            key: _refreshKey,
            child: list(),
            onRefresh: () async =>
                load(), //ekranı yukarıdan çektiğimizde yeni veri geldiyse ana sayfamızın güncellenmesien yarar.
          );
  }

  @override
  Widget build(BuildContext context) {
    // standart kullanım
    return Scaffold(
      appBar: AppBar(
        title: Text('Rss Haberler'),
        centerTitle: true,
      ),
      body: body(),
    );
  }
}
