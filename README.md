# 🚀 SkillShare Mobile App

## 📖 Overview

**SkillShare** is a Flutter-based mobile application designed to connect people with skilled workers in their local community. The platform enables users to discover skilled professionals, book their services, provide feedback, and help workers build a trusted reputation through ratings and AI-generated insights.

The goal of this project is to create a simple, accessible, and intelligent platform where individuals can easily share their skills, offer services, and connect with people who need them. Whether it's tutoring, home maintenance, tailoring, electrical work, or any other skill, SkillShare simplifies the process of finding the right person for the job.

This project was developed using **Flutter**, **Firebase**, and AI concepts to provide a modern, scalable, and user-friendly mobile application.

---

# 🎯 Problem Statement

Finding reliable local service providers can be difficult. Most people rely on word of mouth or multiple social media platforms to search for skilled workers, making the process time-consuming and uncertain.

SkillShare solves this problem by providing:

* A centralized platform for skilled workers.
* Easy service discovery.
* Smart booking management.
* Customer feedback and ratings.
* AI-generated feedback summaries.
* A seamless mobile experience.

---

# 💡 Objectives

* Connect users with skilled professionals.
* Simplify the booking process.
* Build trust through ratings and feedback.
* Help workers improve using AI-generated feedback summaries.
* Create an easy-to-use mobile application for everyday services.

---

# ✨ Features

### 🔐 Authentication

* User Registration
* Secure Login
* Firebase Authentication
* User Session Management

---

### 👤 User Profile

Users can:

* Create personal profiles
* Edit profile information
* View booking history
* Search for skilled workers
* Submit feedback

Workers can:

* Create professional profiles
* Mention their skills
* Set availability
* View customer bookings
* Receive customer feedback

---

### 🔍 Smart Worker Search

Users can search workers based on:

* Skill
* Category
* Availability

---

### 📅 Booking System

The booking module allows users to:

* Select a worker
* Choose booking date
* Select booking time
* Send booking request
* Prevent duplicate bookings
* Manage booking status

---

### ⭐ Feedback & Rating

After the service:

* Users submit ratings
* Write reviews
* Help other users make informed decisions

---

### 🤖 AI Feedback Summarization

One of the unique features of SkillShare is AI-powered feedback analysis.

Instead of reading hundreds of customer reviews, workers receive:

* Overall summary
* Positive highlights
* Improvement suggestions
* Customer sentiment overview

This helps workers quickly understand customer opinions and improve their services.

---

# 🏗️ System Architecture

The application consists of:

Flutter Mobile App

↓

Firebase Authentication

↓

Cloud Firestore Database

↓

Booking Management

↓

Feedback Collection

↓

AI Feedback Summarization

---

# 🛠️ Tech Stack

### Frontend

* Flutter
* Dart

### Backend

* Firebase Authentication
* Cloud Firestore

### Database

* Firebase Cloud Firestore

### AI

* AI-based Feedback Summarization

### Development Tools

* Android Studio
* Visual Studio Code
* Git
* GitHub

---

# 📱 Application Modules

## User Module

* Register
* Login
* Browse workers
* Book services
* Submit feedback
* View booking history

---

## Worker Module

* Register
* Login
* Update profile
* Manage availability
* Accept bookings
* Reject bookings
* View AI-generated feedback summaries

---

## Admin (Future Scope)

* Manage users
* Manage workers
* View reports
* Monitor bookings

---

# 📂 Project Structure

```text
lib/
├── main.dart
├── login.dart
├── signup.dart
├── homepage.dart
├── booking_page.dart
├── profile_page.dart
├── feedback.dart
├── summaries_page.dart
├── worker_dashboard.dart
└── worker_feedback_details.dart
```

---

# 🔄 Workflow

1. User registers.
2. User logs in.
3. User searches for skilled workers.
4. Worker profile is displayed.
5. User books a service.
6. Worker receives booking request.
7. Worker accepts or rejects the booking.
8. Service is completed.
9. User submits feedback.
10. AI summarizes the feedback.
11. Worker views performance insights.

---

# 🚀 How to Run

### Clone Repository

```bash
git clone https://github.com/Nireeksha-Naik/SkillshareMobileApp.git
```

### Open Project

Open the project using:

* Android Studio
* Visual Studio Code

### Install Dependencies

```bash
flutter pub get
```

### Configure Firebase

* Create a Firebase project.
* Enable Firebase Authentication.
* Enable Cloud Firestore.
* Add the Firebase configuration files.

### Run the Application

```bash
flutter run
```

---

# 📸 Screenshots

You can add screenshots of:

* Login Screen
* Registration Screen
* Home Page
* Worker Profile
* Booking Page
* Feedback Screen
* AI Summary Screen

---

# 🌟 My Learning with Gemini

Gemini played an important role throughout the development of this project. Rather than simply generating code, it acted as a learning partner and helped me understand mobile app development concepts.

Gemini assisted me in:

* Designing the application architecture
* Planning the user and worker workflow
* Building Flutter UI screens
* Implementing Firebase Authentication
* Integrating Cloud Firestore
* Designing the booking workflow
* Handling booking conflicts
* Developing the AI-powered feedback summarization feature
* Debugging Flutter and Firebase errors
* Explaining programming concepts and best practices
* Improving code organization and project structure

Using Gemini significantly reduced development time and improved my understanding of Flutter, Firebase, and AI integration. It enabled me to transform an initial idea into a complete working application that addresses a real-world problem.

---

# 🔮 Future Enhancements

* Google Sign-In
* Online Payment Integration
* Real-Time Chat
* Push Notifications
* Voice Search
* Multi-language Support
* AI Worker Recommendation System
* GPS-Based Worker Discovery
* Service Categories
* Dark Mode
* Admin Dashboard
* Analytics Dashboard

---

# 👩‍💻 Author

**Nireeksha P**

Computer Science Engineering Student

Google Student Ambassador

Flutter Developer | AI Enthusiast | Firebase Developer

---

# 📄 License

This project is developed for educational, learning, and demonstration purposes.
