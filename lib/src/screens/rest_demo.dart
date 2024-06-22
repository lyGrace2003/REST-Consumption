import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:state_change_demo/src/models/post.model.dart';
import 'package:state_change_demo/src/models/user.model.dart';

//add and delete post works

class RestDemoScreen extends StatefulWidget {
  const RestDemoScreen({super.key});

  @override
  State<RestDemoScreen> createState() => _RestDemoScreenState();
}

class _RestDemoScreenState extends State<RestDemoScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<PostController>(context, listen: false).getPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Posts"),
        leading: IconButton(
            onPressed: () {
              Provider.of<PostController>(context, listen: false).getPosts();
            },
            icon: const Icon(Icons.refresh)),
        actions: [
          IconButton(
              onPressed: () {
                showNewPostFunction(context);
              },
              icon: const Icon(Icons.add))
        ],
      ),
      body: SafeArea(
        child: Consumer<PostController>(
          builder: (context, controller, child) {
            if (controller.error != null) {
              return Center(
                child: Text(controller.error.toString()),
              );
            }

            if (!controller.working) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (Post post in controller.postList)
                      PostCard(
                        post: post,
                        onDelete: () {
                          controller.deletePost(post.id);
                        },
                      ),
                  ],
                ),
              );
            }
            return const Center(
              child: SpinKitChasingDots(
                size: 54,
                color: Colors.black87,
              ),
            );
          },
        ),
      ),
    );
  }

  void showNewPostFunction(BuildContext context) {
    AddPostDialog.show(context,
        controller: Provider.of<PostController>(context, listen: false));
  }
}

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onDelete;

  const PostCard({Key? key, required this.post, required this.onDelete})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => PostDetailsScreen(post: post),
        ));
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            IconButton(onPressed: onDelete, icon: const Icon(Icons.delete))
          ],
          // children: [
          //   Expanded(
          //     child: Column(
          //       crossAxisAlignment: CrossAxisAlignment.start,
          //       children: [
          //         Text(post.title,
          //             style: const TextStyle(
          //                 fontSize: 16, fontWeight: FontWeight.bold)),
          //         const SizedBox(height: 8),
          //         Text(
          //             post.body.length > 100
          //                 ? '${post.body.substring(0, 97)}...'
          //                 : post.body,
          //             maxLines: 2,
          //             overflow: TextOverflow.ellipsis),
          //       ],
          //     ),
          //   ),
          //   Column(
          //     children: [
          //       IconButton(
          //         onPressed: onDelete,
          //         icon: const Icon(
          //           Icons.delete,
          //           size: 18,
          //         ),
          //       ),
          //     ],
          //   ),
          // ],
        ),
      ),
    );
  }
}

class AddPostDialog extends StatefulWidget {
  static show(BuildContext context, {required PostController controller}) =>
      showDialog(
          context: context, builder: (dContext) => AddPostDialog(controller));
  const AddPostDialog(this.controller, {super.key});

  final PostController controller;

  @override
  State<AddPostDialog> createState() => _AddPostDialogState();
}

class _AddPostDialogState extends State<AddPostDialog> {
  late TextEditingController bodyC, titleC;

  @override
  void initState() {
    super.initState();
    bodyC = TextEditingController();
    titleC = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: const Text("Add new post"),
      actions: [
        ElevatedButton(
          onPressed: () async {
            await widget.controller.makePost(
                title: titleC.text.trim(), body: bodyC.text.trim(), userId: 1);
            Navigator.of(context).pop();
          },
          child: const Text("Add"),
        )
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Title"),
          TextFormField(
            controller: titleC,
          ),
          const Text("Content"),
          TextFormField(
            controller: bodyC,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    bodyC.dispose();
    titleC.dispose();
    super.dispose();
  }
}

//added update, and delete post
class PostController with ChangeNotifier {
  Map<String, dynamic> posts = {};
  bool working = true;
  Object? error;

  List<Post> get postList =>
      posts.values.whereType<Post>().toList().reversed.toList();

  clear() {
    error = null;
    posts = {};
    notifyListeners();
  }

  Future<Post> makePost(
      {required String title,
      required String body,
      required int userId}) async {
    try {
      working = true;
      if (error != null) error = null;

      http.Response res = await HttpService.post(
          url: "https://jsonplaceholder.typicode.com/posts",
          body: {"title": title, "body": body, "userId": userId});

      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("${res.statusCode} | ${res.body}");
      }

      Map<String, dynamic> result = jsonDecode(res.body);

      Post output = Post.fromJson(result);
      posts[output.id.toString()] = output;
      working = false;
      notifyListeners();
      return output;
    } catch (e, st) {
      print(e);
      print(st);
      error = e;
      working = false;
      notifyListeners();
      return Post.empty;
    }
  }

  Future<void> getPosts() async {
    try {
      working = true;
      clear();
      List result = [];
      http.Response res = await HttpService.get(
          url: "https://jsonplaceholder.typicode.com/posts");
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("${res.statusCode} | ${res.body}");
      }
      result = jsonDecode(res.body);

      List<Post> tmpPost = result.map((e) => Post.fromJson(e)).toList();
      posts = {for (Post p in tmpPost) "${p.id}": p};
      working = false;
      notifyListeners();
    } catch (e, st) {
      print(e);
      print(st);
      error = e;
      working = false;
      notifyListeners();
    }
  }

  Future<Post?> updatePost({required int id, required String title, required String body, required int userId}) async {
    try {
      working = true;
      if (error != null) error = null;
      http.Response res = await HttpService.put(
        url: "https://jsonplaceholder.typicode.com/posts/$id",
        body: {"id": id, "title": title, "body": body, "userId": userId},
      );
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("${res.statusCode} | ${res.body}");
      }

      Map<String, dynamic> result = jsonDecode(res.body);

      Post output = Post.fromJson(result);
      posts[output.id.toString()] = output;
      working = false;
      notifyListeners();
      return output;
    } catch (e, st) {
      error = e;
      working = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> deletePost(int id) async {
    try {
      working = true;
      if (error != null) error = null;
      http.Response res = await HttpService.delete(
          url: "https://jsonplaceholder.typicode.com/posts/$id");
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("${res.statusCode} | ${res.body}");
      }
      posts.remove("$id");
      working = false;
      notifyListeners();
    } catch (e, st) {
      print(e);
      print(st);
      error = e;
      working = false;
      notifyListeners();
    }
  }
}

class UserController with ChangeNotifier {
  Map<String, dynamic> users = {};
  bool working = true;
  Object? error;

  List<User> get userList => users.values.whereType<User>().toList();

  getUsers() async {
    try {
      working = true;
      List result = [];
      http.Response res = await HttpService.get(
          url: "https://jsonplaceholder.typicode.com/users");
      if (res.statusCode != 200 && res.statusCode != 201) {
        throw Exception("${res.statusCode} | ${res.body}");
      }
      result = jsonDecode(res.body);

      List<User> tmpUser = result.map((e) => User.fromJson(e)).toList();
      users = {for (User u in tmpUser) "${u.id}": u};
      working = false;
      notifyListeners();
    } catch (e, st) {
      print(e);
      print(st);
      error = e;
      working = false;
      notifyListeners();
    }
  }

  clear() {
    users = {};
    notifyListeners();
  }
}

//added put and delete service
class HttpService {
  static Future<http.Response> get(
      {required String url, Map<String, dynamic>? headers}) async {
    Uri uri = Uri.parse(url);
    return http.get(uri, headers: {
      'Content-Type': 'application/json',
      if (headers != null) ...headers
    });
  }

  static Future<http.Response> post(
      {required String url,
      required Map<dynamic, dynamic> body,
      Map<String, dynamic>? headers}) async {
    Uri uri = Uri.parse(url);
    return http.post(uri, body: jsonEncode(body), headers: {
      'Content-Type': 'application/json',
      if (headers != null) ...headers
    });
  }

  static Future<http.Response> put(
      {required String url,
      required Map<dynamic, dynamic> body,
      Map<String, dynamic>? headers}) async {
    Uri uri = Uri.parse(url);
    return http.put(uri, body: jsonEncode(body), headers: {
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    });
  }

  static Future<http.Response> delete(
      {required String url, Map<String, dynamic>? headers}) async {
    Uri uri = Uri.parse(url);
    return http.delete(uri, headers: {
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    });
  }
}

class PostDetailsScreen extends StatefulWidget {
  final Post post;

  const PostDetailsScreen({required this.post, Key? key}) : super(key: key);

  @override
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  late Post _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_post.title),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => showEditPostFunction(context, _post),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Text(_post.body),
        ),
      ),
    );
  }

  showEditPostFunction(BuildContext context, Post post) async {
    final updatedPost = await EditPostDialog.show(
      context,
      post: post,
      controller: Provider.of<PostController>(context, listen: false),
    );
    if (updatedPost != null) {
      setState(() {
        _post = updatedPost;
      });
    }
  }
}


class EditPostDialog extends StatefulWidget {
  static Future<Post?> show(BuildContext context, {required Post post, required PostController controller}) =>
      showDialog(
        context: context,
        builder: (dContext) => EditPostDialog(post, controller),
      );

  const EditPostDialog(this.post, this.controller, {super.key});

  final Post post;
  final PostController controller;

  @override
  State<EditPostDialog> createState() => _EditPostDialogState();
}

class _EditPostDialogState extends State<EditPostDialog> {
  late TextEditingController bodyC, titleC;

  @override
  void initState() {
    super.initState();
    bodyC = TextEditingController(text: widget.post.body);
    titleC = TextEditingController(text: widget.post.title);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: const Text("Edit Post"),
      actions: [
        ElevatedButton(
          onPressed: () async {
            final updatedPost = await widget.controller.updatePost(
              id: widget.post.id,
              title: titleC.text.trim(),
              body: bodyC.text.trim(),
              userId: widget.post.userId,
            );
            Navigator.of(context).pop(updatedPost);
          },
          child: const Text("Save"),
        ),
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Title"),
          TextFormField(
            controller: titleC,
          ),
          const SizedBox(height: 8),
          const Text("Content"),
          TextFormField(
            controller: bodyC,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    bodyC.dispose();
    titleC.dispose();
    super.dispose();
  }
}


