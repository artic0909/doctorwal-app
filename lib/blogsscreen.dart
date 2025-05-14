import 'dart:convert';
import 'package:demoapp/Models/blog_model.dart';
import 'package:demoapp/singleblogdetailsscreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BlogsScreen extends StatefulWidget {
  const BlogsScreen({super.key});

  @override
  State<BlogsScreen> createState() => _BlogsScreenState();
}

class _BlogsScreenState extends State<BlogsScreen> {
  late Future<List<Blog>> blogsFuture;

  @override
  void initState() {
    super.initState();
    blogsFuture = fetchBlogs();
  }

  Future<List<Blog>> fetchBlogs() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/blogs'),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> blogsJson = jsonData['blogs'];
      return blogsJson.map((json) => Blog.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load blogs');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(65),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: AppBar(
            title: const Text(
              'Blogs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.blue[900],
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: FutureBuilder<List<Blog>>(
          future: blogsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No blogs available'));
            }

            final blogs = snapshot.data!;
            return ListView(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:
                      blogs.map((blog) {
                        return SizedBox(
                          width: (MediaQuery.of(context).size.width / 2) - 18,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => SingleBlogDetailsScreen(
                                        imageUrl: blog.imageUrl,
                                        title: blog.title,
                                        date: blog.date,
                                        content: blog.content,
                                      ),
                                ),
                              );
                            },
                            child: _buildBlogCard(
                              imageUrl: blog.imageUrl,
                              title: blog.title,
                              date: blog.date,
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBlogCard({
    required String imageUrl,
    required String title,
    required String date,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              imageUrl,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) =>
                      Image(image: AssetImage('assets/images/logo.png')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
