import 'dart:io';

import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
import 'package:blackhole/CustomWidgets/custom_physics.dart';
import 'package:blackhole/CustomWidgets/data_search.dart';
import 'package:blackhole/CustomWidgets/empty_screen.dart';
import 'package:blackhole/CustomWidgets/gradient_containers.dart';
import 'package:blackhole/CustomWidgets/miniplayer.dart';
import 'package:blackhole/CustomWidgets/playlist_head.dart';
import 'package:blackhole/CustomWidgets/snackbar.dart';
import 'package:blackhole/Helpers/picker.dart';
import 'package:blackhole/Screens/Library/liked.dart';
import 'package:blackhole/Screens/Player/audioplayer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

class Downloads extends StatefulWidget {
  const Downloads({Key? key}) : super(key: key);
  @override
  _DownloadsState createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads>
    with SingleTickerProviderStateMixin {
  Box downloadsBox = Hive.box('downloads');
  bool added = false;
  List _songs = [];
  final Map<String, List<Map>> _albums = {};
  final Map<String, List<Map>> _artists = {};
  final Map<String, List<Map>> _genres = {};
  List _sortedAlbumKeysList = [];
  List _sortedArtistKeysList = [];
  List _sortedGenreKeysList = [];
  TabController? _tcontroller;
  int currentIndex = 0;
  int sortValue = Hive.box('settings').get('sortValue', defaultValue: 2) as int;
  int albumSortValue =
      Hive.box('settings').get('albumSortValue', defaultValue: 2) as int;

  @override
  void initState() {
    _tcontroller = TabController(length: 4, vsync: this);
    _tcontroller!.addListener(changeTitle);
    getDownloads();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _tcontroller!.dispose();
  }

  void changeTitle() {
    setState(() {
      currentIndex = _tcontroller!.index;
    });
  }

  Future<void> getDownloads() async {
    _songs = downloadsBox.values.toList();
    setArtistAlbum();
  }

  void setArtistAlbum() {
    for (final element in _songs) {
      if (_albums.containsKey(element['album'])) {
        final List<Map> tempAlbum = _albums[element['album']]!;
        tempAlbum.add(element as Map);
        _albums.addEntries([MapEntry(element['album'].toString(), tempAlbum)]);
      } else {
        _albums.addEntries([
          MapEntry(element['album'].toString(), [element as Map])
        ]);
      }

      if (_artists.containsKey(element['artist'])) {
        final List<Map> tempArtist = _artists[element['artist']]!;
        tempArtist.add(element);
        _artists
            .addEntries([MapEntry(element['artist'].toString(), tempArtist)]);
      } else {
        _artists.addEntries([
          MapEntry(element['artist'].toString(), [element])
        ]);
      }

      if (_genres.containsKey(element['genre'])) {
        final List<Map> tempGenre = _genres[element['genre']]!;
        tempGenre.add(element);
        _genres.addEntries([MapEntry(element['genre'].toString(), tempGenre)]);
      } else {
        _genres.addEntries([
          MapEntry(element['genre'].toString(), [element])
        ]);
      }
    }

    sortSongs();

    _sortedAlbumKeysList = _albums.keys.toList();
    _sortedArtistKeysList = _artists.keys.toList();
    _sortedGenreKeysList = _genres.keys.toList();

    sortAlbums();

    added = true;
    setState(() {});
  }

  void sortSongs() {
    if (sortValue == 0) {
      _songs.sort(
        (a, b) => a['title']
            .toString()
            .toUpperCase()
            .compareTo(b['title'].toString().toUpperCase()),
      );
    }
    if (sortValue == 1) {
      _songs.sort(
        (b, a) => a['title']
            .toString()
            .toUpperCase()
            .compareTo(b['title'].toString().toUpperCase()),
      );
    }
    if (sortValue == 2) {
      _songs = downloadsBox.values.toList();
      _songs.sort(
        (b, a) => a['dateAdded']
            .toString()
            .toUpperCase()
            .compareTo(b['dateAdded'].toString().toUpperCase()),
      );
    }
  }

  void sortAlbums() {
    if (albumSortValue == 0) {
      _sortedAlbumKeysList.sort(
        (a, b) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
      _sortedArtistKeysList.sort(
        (a, b) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
      _sortedGenreKeysList.sort(
        (a, b) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
    }
    if (albumSortValue == 1) {
      _sortedAlbumKeysList.sort(
        (b, a) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
      _sortedArtistKeysList.sort(
        (b, a) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
      _sortedGenreKeysList.sort(
        (b, a) =>
            a.toString().toUpperCase().compareTo(b.toString().toUpperCase()),
      );
    }
    if (albumSortValue == 2) {
      _sortedAlbumKeysList
          .sort((b, a) => _albums[a]!.length.compareTo(_albums[b]!.length));
      _sortedArtistKeysList
          .sort((b, a) => _artists[a]!.length.compareTo(_artists[b]!.length));
      _sortedGenreKeysList
          .sort((b, a) => _genres[a]!.length.compareTo(_genres[b]!.length));
    }
    if (albumSortValue == 3) {
      _sortedAlbumKeysList
          .sort((a, b) => _albums[a]!.length.compareTo(_albums[b]!.length));
      _sortedArtistKeysList
          .sort((a, b) => _artists[a]!.length.compareTo(_artists[b]!.length));
      _sortedGenreKeysList
          .sort((a, b) => _genres[a]!.length.compareTo(_genres[b]!.length));
    }
  }

  Future<void> deleteSong(Map song) async {
    await downloadsBox.delete(song['id']);
    final audioFile = File(song['path'].toString());
    final imageFile = File(song['image'].toString());
    if (_albums[song['album']]!.length == 1) {
      _sortedAlbumKeysList.remove(song['album']);
    }
    _albums[song['album']]!.remove(song);

    if (_artists[song['artist']]!.length == 1) {
      _sortedArtistKeysList.remove(song['artist']);
    }
    _artists[song['artist']]!.remove(song);

    if (_genres[song['genre']]!.length == 1) {
      _sortedGenreKeysList.remove(song['genre']);
    }
    _genres[song['genre']]!.remove(song);

    _songs.remove(song);
    try {
      audioFile.delete();
      if (await imageFile.exists()) {
        imageFile.delete();
      }
      ShowSnackBar().showSnackBar(
        context,
        '${AppLocalizations.of(context)!.deleted} ${song['title']}',
      );
    } catch (e) {
      ShowSnackBar().showSnackBar(
        context,
        '${AppLocalizations.of(context)!.failedDelete}: ${audioFile.path}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      child: Column(
        children: [
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: Text(AppLocalizations.of(context)!.downs),
                  centerTitle: true,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.transparent
                          : Theme.of(context).colorScheme.secondary,
                  elevation: 0,
                  bottom: TabBar(
                    controller: _tcontroller,
                    tabs: [
                      Tab(
                        text: AppLocalizations.of(context)!.songs,
                      ),
                      Tab(
                        text: AppLocalizations.of(context)!.albums,
                      ),
                      Tab(
                        text: AppLocalizations.of(context)!.artists,
                      ),
                      Tab(
                        text: AppLocalizations.of(context)!.genres,
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(CupertinoIcons.search),
                      tooltip: AppLocalizations.of(context)!.search,
                      onPressed: () {
                        showSearch(
                          context: context,
                          delegate: DownloadsSearch(
                            data: _songs,
                            isDowns: true,
                          ),
                        );
                      },
                    ),
                    if (_songs.isNotEmpty)
                      PopupMenuButton(
                        icon: const Icon(Icons.sort_rounded),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15.0)),
                        ),
                        onSelected: (currentIndex == 0)
                            ? (int value) {
                                sortValue = value;
                                Hive.box('settings').put('sortValue', value);
                                sortSongs();
                                setState(() {});
                              }
                            : (int value) {
                                albumSortValue = value;
                                Hive.box('settings')
                                    .put('albumSortValue', value);
                                sortAlbums();
                                setState(() {});
                              },
                        itemBuilder: (currentIndex == 0)
                            ? (context) => [
                                  PopupMenuItem(
                                    value: 0,
                                    child: Row(
                                      children: [
                                        if (sortValue == 0)
                                          Icon(
                                            Icons.check_rounded,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                          )
                                        else
                                          const SizedBox(),
                                        const SizedBox(width: 10),
                                        Text(
                                          AppLocalizations.of(context)!.az,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 1,
                                    child: Row(
                                      children: [
                                        if (sortValue == 1)
                                          Icon(
                                            Icons.check_rounded,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                          )
                                        else
                                          const SizedBox(),
                                        const SizedBox(width: 10),
                                        Text(
                                          AppLocalizations.of(context)!.za,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 2,
                                    child: Row(
                                      children: [
                                        if (sortValue == 2)
                                          Icon(
                                            Icons.check_rounded,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                          )
                                        else
                                          const SizedBox(),
                                        const SizedBox(width: 10),
                                        Text(
                                          AppLocalizations.of(context)!
                                              .lastAdded,
                                        ),
                                      ],
                                    ),
                                  ),
                                ]
                            : (context) => [
                                  PopupMenuItem(
                                    value: 0,
                                    child: Row(
                                      children: [
                                        if (albumSortValue == 0)
                                          Icon(
                                            Icons.check_rounded,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                          )
                                        else
                                          const SizedBox(),
                                        const SizedBox(width: 10),
                                        Text(
                                          AppLocalizations.of(context)!.az,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 1,
                                    child: Row(
                                      children: [
                                        if (albumSortValue == 1)
                                          Icon(
                                            Icons.check_rounded,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                          )
                                        else
                                          const SizedBox(),
                                        const SizedBox(width: 10),
                                        Text(
                                          AppLocalizations.of(context)!.za,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 2,
                                    child: Row(
                                      children: [
                                        if (albumSortValue == 2)
                                          Icon(
                                            Icons.check_rounded,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                          )
                                        else
                                          const SizedBox(),
                                        const SizedBox(width: 10),
                                        Text(
                                          AppLocalizations.of(context)!
                                              .tenToOne,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 3,
                                    child: Row(
                                      children: [
                                        if (albumSortValue == 3)
                                          Icon(
                                            Icons.check_rounded,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.grey[700],
                                          )
                                        else
                                          const SizedBox(),
                                        const SizedBox(width: 10),
                                        Text(
                                          AppLocalizations.of(context)!
                                              .oneToTen,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                      ),
                  ],
                ),
                body: !added
                    ? SizedBox(
                        child: Center(
                          child: SizedBox(
                            height: MediaQuery.of(context).size.width / 7,
                            width: MediaQuery.of(context).size.width / 7,
                            child: const CircularProgressIndicator(),
                          ),
                        ),
                      )
                    : TabBarView(
                        physics: const CustomPhysics(),
                        controller: _tcontroller,
                        children: [
                          DownSongsTab(
                            onDelete: (Map item) {
                              deleteSong(item);
                            },
                            songs: _songs,
                          ),
                          AlbumsTab(
                            albums: _albums,
                            offline: true,
                            sortedAlbumKeysList: _sortedAlbumKeysList,
                          ),
                          AlbumsTab(
                            albums: _artists,
                            artistTab: true,
                            offline: true,
                            sortedAlbumKeysList: _sortedArtistKeysList,
                          ),
                          AlbumsTab(
                            albums: _genres,
                            offline: true,
                            sortedAlbumKeysList: _sortedGenreKeysList,
                          ),
                        ],
                      ),
              ),
            ),
          ),
          MiniPlayer(),
        ],
      ),
    );
  }
}

Future<Map> editTags(Map song, BuildContext context) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      final tagger = Audiotagger();

      FileImage songImage = FileImage(File(song['image'].toString()));

      final _titlecontroller =
          TextEditingController(text: song['title'].toString());
      final _albumcontroller =
          TextEditingController(text: song['album'].toString());
      final _artistcontroller =
          TextEditingController(text: song['artist'].toString());
      final _albumArtistController =
          TextEditingController(text: song['albumArtist'].toString());
      final _genrecontroller =
          TextEditingController(text: song['genre'].toString());
      final _yearcontroller =
          TextEditingController(text: song['year'].toString());
      final _pathcontroller =
          TextEditingController(text: song['path'].toString());

      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        content: SizedBox(
          height: 400,
          width: 300,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final String filePath = await Picker.selectFile(
                      context,
                      ['png', 'jpg', 'jpeg'],
                      'Pick Image',
                    );
                    if (filePath != '') {
                      final _imagePath = filePath;
                      File(_imagePath).copy(song['image'].toString());

                      songImage = FileImage(File(_imagePath));

                      final Tag tag = Tag(
                        artwork: _imagePath,
                      );
                      try {
                        await [
                          Permission.manageExternalStorage,
                        ].request();
                        await tagger.writeTags(
                          path: song['path'].toString(),
                          tag: tag,
                        );
                      } catch (e) {
                        await tagger.writeTags(
                          path: song['path'].toString(),
                          tag: tag,
                        );
                      }
                    }
                  },
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      height: MediaQuery.of(context).size.width / 2,
                      width: MediaQuery.of(context).size.width / 2,
                      child: Image(
                        fit: BoxFit.cover,
                        image: songImage,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                TextField(
                  autofocus: true,
                  controller: _titlecontroller,
                  onSubmitted: (value) {},
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.artist,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                TextField(
                  autofocus: true,
                  controller: _artistcontroller,
                  onSubmitted: (value) {},
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.albumArtist,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                TextField(
                  autofocus: true,
                  controller: _albumArtistController,
                  onSubmitted: (value) {},
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.album,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                TextField(
                  autofocus: true,
                  controller: _albumcontroller,
                  onSubmitted: (value) {},
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.genre,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                TextField(
                  autofocus: true,
                  controller: _genrecontroller,
                  onSubmitted: (value) {},
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.year,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                TextField(
                  autofocus: true,
                  controller: _yearcontroller,
                  onSubmitted: (value) {},
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.songPath,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                TextField(
                  autofocus: true,
                  controller: _pathcontroller,
                  onSubmitted: (value) {},
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              primary: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.grey[700],
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              primary: Colors.white,
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () async {
              Navigator.pop(context);
              song['title'] = _titlecontroller.text;
              song['album'] = _albumcontroller.text;
              song['artist'] = _artistcontroller.text;
              song['albumArtist'] = _albumArtistController.text;
              song['genre'] = _genrecontroller.text;
              song['year'] = _yearcontroller.text;
              song['path'] = _pathcontroller.text;
              final tag = Tag(
                title: _titlecontroller.text,
                artist: _artistcontroller.text,
                album: _albumcontroller.text,
                genre: _genrecontroller.text,
                year: _yearcontroller.text,
                albumArtist: _albumArtistController.text,
              );
              try {
                try {
                  await [
                    Permission.manageExternalStorage,
                  ].request();
                  tagger.writeTags(
                    path: song['path'].toString(),
                    tag: tag,
                  );
                } catch (e) {
                  await tagger.writeTags(
                    path: song['path'].toString(),
                    tag: tag,
                  );
                  ShowSnackBar().showSnackBar(
                    context,
                    AppLocalizations.of(context)!.successTagEdit,
                  );
                }
              } catch (e) {
                ShowSnackBar().showSnackBar(
                  context,
                  AppLocalizations.of(context)!.failedTagEdit,
                );
              }
            },
            child: Text(
              AppLocalizations.of(context)!.ok,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary == Colors.white
                    ? Colors.black
                    : null,
              ),
            ),
          ),
          const SizedBox(
            width: 5,
          ),
        ],
      );
    },
  );
  return song;
}

class DownSongsTab extends StatefulWidget {
  final List songs;
  final Function(Map item) onDelete;
  const DownSongsTab({
    Key? key,
    required this.songs,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<DownSongsTab> createState() => _DownSongsTabState();
}

class _DownSongsTabState extends State<DownSongsTab>
    with AutomaticKeepAliveClientMixin {
  Future<void> downImage(
    String imageFilePath,
    String songFilePath,
    String url,
  ) async {
    final File file = File(imageFilePath);

    try {
      await file.create();
      final image = await Audiotagger().readArtwork(path: songFilePath);
      if (image != null) {
        file.writeAsBytesSync(image);
      }
    } catch (e) {
      final HttpClientRequest request2 =
          await HttpClient().getUrl(Uri.parse(url));
      final HttpClientResponse response2 = await request2.close();
      final bytes2 = await consolidateHttpClientResponseBytes(response2);
      await file.writeAsBytes(bytes2);
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return (widget.songs.isEmpty)
        ? emptyScreen(
            context,
            3,
            AppLocalizations.of(context)!.nothingTo,
            15.0,
            AppLocalizations.of(context)!.showHere,
            50,
            AppLocalizations.of(context)!.addSomething,
            23.0,
          )
        : Column(
            children: [
              PlaylistHead(
                songsList: widget.songs,
                offline: true,
                fromDownloads: true,
                recommend: false,
              ),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 10),
                  shrinkWrap: true,
                  itemCount: widget.songs.length,
                  itemExtent: 70.0,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SizedBox(
                          height: 50.0,
                          width: 50.0,
                          child: Image(
                            fit: BoxFit.cover,
                            image: FileImage(
                              File(
                                widget.songs[index]['image'].toString(),
                              ),
                            ),
                            errorBuilder: (_, __, ___) {
                              if (widget.songs[index]['image'] != null &&
                                  widget.songs[index]['image_url'] != null) {
                                downImage(
                                  widget.songs[index]['image'].toString(),
                                  widget.songs[index]['path'].toString(),
                                  widget.songs[index]['image_url'].toString(),
                                );
                              }
                              return Image.asset(
                                'assets/cover.jpg',
                              );
                            },
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            opaque: false,
                            pageBuilder: (_, __, ___) => PlayScreen(
                              songsList: widget.songs,
                              index: index,
                              offline: true,
                              fromDownloads: true,
                              fromMiniplayer: false,
                              recommend: false,
                            ),
                          ),
                        );
                      },
                      title: Text(
                        '${widget.songs[index]['title']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${widget.songs[index]['artist'] ?? 'Artist name'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PopupMenuButton(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(15.0),
                              ),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 0,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.edit_rounded,
                                    ),
                                    const SizedBox(
                                      width: 10.0,
                                    ),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!
                                          .edit,
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 1,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delete_rounded,
                                    ),
                                    const SizedBox(
                                      width: 10.0,
                                    ),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!
                                          .delete,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (int? value) async {
                              if (value == 0) {
                                widget.songs[index] = await editTags(
                                  widget.songs[index] as Map,
                                  context,
                                );
                                Hive.box('downloads').put(
                                  widget.songs[index]['id'],
                                  widget.songs[index],
                                );
                                setState(() {});
                              }
                              if (value == 1) {
                                setState(() {
                                  widget.onDelete(widget.songs[index] as Map);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
  }
}
