# Lifestyle Fit - Flutter Architecture

This project follows a modern, scalable **MVC + Clean Architecture** approach using **GetX** and **Supabase**.

## 🏗 Folder Structure

- `core/`: Contains app-wide constants, themes, localization, and shared utilities.
- `data/`: The data layer handling models, repositories, and external services (Supabase).
- `modules/`: Feature-based modules (Auth, Splash, etc.). Each module contains its own Bindings, Controllers, and Views.
- `routes/`: Centralized route management.
- `shared/`: Reusable widgets and styles used across multiple features.

## 🚀 Key Technologies

- **GetX**: Handles state management (Rx), dependency injection (`Get.find`, `Get.put`), and routing.
- **Supabase**: Backend-as-a-service for Authentication, Database, and Real-time features.
- **ScreenUtil**: Ensures the UI is responsive across different screen sizes.
- **Localization**: Full support for English and Arabic using GetX `Translations`.

## 🔐 Authentication Flow

1. **Splash**: Checks for an existing Supabase session.
2. **Onboarding**: Shown to new users.
3. **Login/Register**: Integrated with Supabase Auth.
4. **Role Selection**: Users choose between 'Trainer' and 'Trainee' during registration, which is saved in a Supabase `profiles` table.

## 🎨 Theme System

- Centralized `AppColors` for consistency.
- `AppTheme` provides both Light and Dark modes.
- Custom `InputDecoration` and `Button` themes for a modern glassmorphism/premium feel.

## ✅ Best Practices Applied

- **Separation of Concerns**: Controllers handle logic, Repositories handle data, and Views handle UI.
- **Strong Typing**: All data models are strongly typed with JSON serialization.
- **Dependency Injection**: Services are initialized at app startup and injected where needed.
- **Scalability**: New features can be added by creating new modules without affecting existing ones.
