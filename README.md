# Task Manager App

## 📌 Project Overview
The **Task Manager** app is a simple yet efficient task management application built using **Flutter**. It allows users to create, update, and manage tasks with priorities, deadlines, and categories.

## 🚀 Features
- 📝 **Add Tasks**: Users can create new tasks.
- ✏️ **Edit Tasks**: Update task details like title, priority, deadline, and category.
- ✅ **Mark as Completed**: Mark tasks as completed or incomplete.
- 📊 **Statistics Display**: View task statistics using a custom widget.
- 🎨 **Responsive UI**: A clean and user-friendly design.

## 🛠️ Tech Stack
- **Frontend**: Flutter (Dart)
- **State Management**: setState (Can be upgraded to BLoC or Provider)
- **UI Components**: Material Design Widgets

## 📂 Project Structure
```
lib/
│── main.dart                 # Entry point of the app
│
├── screens/
│   ├── home_screen.dart      # Main task listing screen
│   ├── task_dialog.dart      # Task creation/editing dialog
│
├── models/
│   ├── task.dart             # Task model (Task, TaskPriority, TaskCategory)
│
├── widgets/
│   ├── stat_item.dart        # Statistics display widget
```

## 🔧 Installation & Setup
1. **Clone the Repository:**
   ```bash
   git clone https://github.com/robiulsunnyemon/codsoft_taskmanager_app.git
   cd codsoft_taskmanager_app
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the App:**
   ```bash
   flutter run
   ```

## 📜 Code Explanation
### **1. `main.dart` (Entry Point)**
- Sets up `MaterialApp` and calls `HomeScreen`.

### **2. `models/task.dart` (Task Model)**
- Defines the `Task` class with `toJson()` and `fromJson()` methods.
- Includes `TaskPriority` and `TaskCategory` enums.

### **3. `screens/home_screen.dart` (Home Screen)**
- Displays the list of tasks.
- Provides options to add, edit, or delete tasks.

### **4. `screens/task_dialog.dart` (Task Dialog)**
- A modal dialog for adding or editing tasks.
- Allows users to set task name, priority, deadline, and category.

### **5. `widgets/stat_item.dart` (Statistics Widget)**
- Displays task completion stats with icons and text.

## 🎯 Future Improvements
- 🔄 **State Management**: Implement BLoC or Provider.
- ☁️ **Backend Integration**: Sync tasks with Firebase or Django REST API.
- 📅 **Notifications**: Reminders for upcoming deadlines.

## 📩 Contributing
Feel free to submit pull requests or raise issues. Any contributions are welcome!

---
Made with ❤️ using Flutter 🚀

