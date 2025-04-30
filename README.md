# Synk - Real-time Chat Application

Synk is a modern real-time chat application built with Flutter that enables seamless communication between users with features like instant messaging, typing indicators, and online status tracking.

![Synk App](https://via.placeholder.com/800x400?text=Synk+Chat+App)

## Features

- **User Authentication**: Secure signup, login, and profile management
- **Real-time Messaging**: Instant message delivery with read receipts
- **User Search**: Find and connect with other users
- **Typing Indicators**: See when others are typing responses
- **Online Status**: Track user availability
- **Profile Management**: Update profile picture and account information

## Tech Stack

- **Frontend**: Flutter
- **State Management**: Provider
- **Real-time Communication**: Socket.io
- **Secure Storage**: Flutter Secure Storage
- **API Communication**: HTTP
- **Environment Configuration**: Flutter dotenv

## Project Structure

```
lib/
  ├── Controller/              # Application logic
  │   ├── Api Services/        # Backend API integration
  │   ├── Local Storage/       # Secure data persistence
  │   ├── Providers/           # State management
  │   └── Socket Services/     # Real-time communication
  ├── Model/                   # Data models
  │   ├── conversation_model.dart
  │   ├── message_model.dart
  │   └── user_model.dart
  ├── View/                    # UI components
  │   ├── Authentication/      # Login and registration screens
  │   └── Interface/           # Application screens
  └── Utils/                   # Utility functions and helpers
```

## Architecture

Synk follows the **Model-View-Controller (MVC)** pattern with Provider for state management:

- **Model**: Data structures and business logic
- **View**: UI components and screens
- **Controller**: Communication with backend APIs and state management

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=2.17.0)
- An IDE (VS Code, Android Studio, etc.)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/synk.git
   cd synk/frontend
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Create a `.env` file in the root directory:
   ```
   BASE_URL=http://your-backend-url.com/api
   ```

4. Run the app:
   ```bash
   flutter run
   ```

## Setting Up the Backend

This repository contains the frontend code for Synk. For the backend server:

1. Set up a Node.js/Express server with Socket.io
2. Implement the required API endpoints:
   - User authentication (register, login)
   - Conversation management
   - Message handling
3. Configure WebSocket events for real-time communication

## Usage

### Authentication

Users can create accounts or log in to access the chat functionality.

### Messaging

1. Search for users using the search icon
2. Tap on a user to start a conversation
3. Type messages in the input field and press send
4. View conversations from the home screen

### Profile Management

1. Access profile from the profile icon
2. Update profile picture by tapping the camera icon
3. View account information

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see below for details:

```
MIT License

Copyright (c) 2023 Synk Chat Application

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## Dependencies

Synk relies on the following key packages:

- `provider`: State management
- `http`: API communication
- `flutter_secure_storage`: Secure data storage
- `socket_io_client`: Real-time communication
- `image_picker`: Image selection for profile pictures
- `flutter_dotenv`: Environment configuration

## Acknowledgments

- [Flutter](https://flutter.dev) - UI framework
- [Socket.io](https://socket.io) - Real-time communication
- [Provider](https://pub.dev/packages/provider) - State management

## Contact

Project Link: [https://github.com/yourusername/synk](https://github.com/yourusername/synk)
