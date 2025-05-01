import 'package:demoapp/singleblogdetailsscreen.dart';
import 'package:flutter/material.dart'; // Import the details screen

class BlogsScreen extends StatelessWidget {
  const BlogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final blogs = List.generate(
      20,
      (index) => {
        "imageUrl": "assets/images/blog.jpg",
        "title": 'Today\'s news is very interesting and impactful...',
        "date": 'April 29, 2025',
        "content":
            'This is the full blog content for blog post #$index. '
            'Here you can add more detailed information and format it as needed.',
      },
    );

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
        child: ListView(
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
                                    imageUrl: blog['imageUrl']!,
                                    title: blog['title']!,
                                    date: blog['date']!,
                                    content: blog['content']!,
                                  ),
                            ),
                          );
                        },
                        child: _buildBlogCard(
                          imageUrl: blog['imageUrl']!,
                          title: blog['title']!,
                          date: blog['date']!,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
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
            child: Image.asset(
              //use Image.network for importing network image
              imageUrl,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
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
