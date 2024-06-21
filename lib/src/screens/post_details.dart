import 'package:flutter/material.dart';
import 'package:state_change_demo/src/models/post.model.dart';

class PostDetailsScreen extends StatefulWidget {
  final Post post;
  const PostDetailsScreen({required this.post, Key? key}) : super(key: key );

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}