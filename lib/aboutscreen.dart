import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
              'About',
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
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Jio Ji Bharka",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 10, 10),
              ),
            ),
            SizedBox(height: 15),
            Text(
              "DoctorWala.info is a leading local search engine dedicated to helping individuals in India find the right doctors, pathologists, and OPDs in their local areas. Our platform is designed to simplify the process of locating and connecting with healthcare professionals, ensuring that you receive the best possible care. With the vast number of medical practitioners across the country, finding the right doctor can often be a daunting task. At DoctorWala.info, we strive to make this process easier for you by providing a comprehensive directory of doctors and healthcare facilities in your vicinity. Whether you are looking for a general physician, a specialist, or a specific healthcare service, our platform offers a user-friendly interface that enables you to search, compare, and make informed decisions. Our search engine features a wide range of healthcare providers, including doctors from various specialties such as cardiology, orthopedics, dermatology, gynecology, pediatrics, and more. We understand that everyone's healthcare needs are unique, which is why we aim to provide a diverse selection of professionals to cater to your specific requirements.",
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            SizedBox(height: 25),
            Text(
              "Mission",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 5),
            Text(
              "Using DoctorWala.info is simple and convenient. You can search for doctors, pathologists, and OPDs by location, specialty, or medical condition. Our platform provides detailed profiles of each healthcare professional, including their qualifications, experience, contact information, and patient reviews. This information allows you to make an informed decision when choosing the right healthcare provider for your needs.",
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 15),
            Text(
              "At DoctorWala.info, we prioritize your privacy and security. We maintain strict confidentiality of your personal information, ensuring that your search for healthcare professionals remains confidential and secure. ",
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 25),
            Text(
              "Vision",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 5),
            Text(
              "Whether you are seeking primary care, specialized treatment, or diagnostic services, DoctorWala.info is committed to being your trusted companion on your healthcare journey. We strive to connect you with the best doctors, pathologists, and OPDs in your area, empowering you to make informed decisions about your healthcare.",
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 15),
            Text(
              "Welcome to DoctorWala.info! In addition to doctors, we also connect you with pathologists and OPDs.",
              textAlign: TextAlign.justify,
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 25),
            Text(
              "Version",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 5),
            Text("1.0.0", style: TextStyle(fontSize: 14)),
            SizedBox(height: 25),
            Text(
              "Developed By",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 5),
            Text(
              "Graphicode India – Web & App Development",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 40),
            Center(
              child: Text(
                '© 2025 DoctorWala.info. All rights reserved.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
