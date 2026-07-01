import 'package:get/get.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/core/routes/auth_guest_middleware.dart';
import 'package:soccer_sys/core/routes/auth_required_middleware.dart';
import 'package:soccer_sys/core/routes/subscription_required_middleware.dart';
import 'package:soccer_sys/modules/auth/bindings/auth_binding.dart';
import 'package:soccer_sys/modules/auth/views/forgot_password_view.dart';
import 'package:soccer_sys/modules/auth/views/login_view.dart';
import 'package:soccer_sys/modules/auth/views/register_view.dart';
import 'package:soccer_sys/modules/activity/bindings/activity_binding.dart';
import 'package:soccer_sys/modules/activity/views/activity_day_detail_view.dart';
import 'package:soccer_sys/modules/activity/views/activity_history_view.dart';
import 'package:soccer_sys/modules/calls/views/call_view.dart';
import 'package:soccer_sys/modules/chat/bindings/chat_room_binding.dart';
import 'package:soccer_sys/modules/chat/views/chat_room_view.dart';
import 'package:soccer_sys/modules/coaching/bindings/coaching_binding.dart';
import 'package:soccer_sys/modules/coaching/views/choose_trainer_view.dart';
import 'package:soccer_sys/modules/coaching/views/trainee_activity_history_view.dart';
import 'package:soccer_sys/modules/coaching/views/trainee_detail_view.dart';
import 'package:soccer_sys/modules/home/bindings/home_binding.dart';
import 'package:soccer_sys/modules/home/views/home_view.dart';
import 'package:soccer_sys/modules/profile/bindings/profile_binding.dart';
import 'package:soccer_sys/modules/profile/views/profile_edit_view.dart';
import 'package:soccer_sys/modules/nutrition/bindings/nutrition_binding.dart';
import 'package:soccer_sys/modules/nutrition/views/meal_form_view.dart';
import 'package:soccer_sys/modules/nutrition/views/nutrition_meals_view.dart';
import 'package:soccer_sys/modules/workouts/bindings/workout_binding.dart';
import 'package:soccer_sys/modules/workouts/views/exercise_form_view.dart';
import 'package:soccer_sys/modules/workouts/views/workout_day_detail_view.dart';
import 'package:soccer_sys/modules/workouts/views/workout_weekly_view.dart';
import 'package:soccer_sys/modules/progress/bindings/progress_binding.dart';
import 'package:soccer_sys/modules/progress/views/add_progress_entry_view.dart';
import 'package:soccer_sys/modules/progress/views/progress_entry_detail_view.dart';
import 'package:soccer_sys/modules/progress/views/progress_gallery_view.dart';
import 'package:soccer_sys/modules/splash/bindings/splash_binding.dart';
import 'package:soccer_sys/modules/subscriptions/bindings/subscription_views_binding.dart';
import 'package:soccer_sys/modules/subscriptions/views/subscription_checkout_view.dart';
import 'package:soccer_sys/modules/subscriptions/views/subscription_success_view.dart';
import 'package:soccer_sys/modules/subscriptions/views/trainee_plans_view.dart';
import 'package:soccer_sys/modules/subscriptions/views/trainer_plan_form_view.dart';
import 'package:soccer_sys/modules/subscriptions/views/trainer_plans_view.dart';
import 'package:soccer_sys/modules/subscriptions/views/trainer_assign_subscription_view.dart';
import 'package:soccer_sys/modules/subscriptions/views/trainer_subscribers_view.dart';
import 'package:soccer_sys/modules/subscriptions/views/trainer_subscription_edit_view.dart';
import 'package:soccer_sys/modules/splash/views/splash_view.dart';

abstract final class AppPages {
  static final _guestMiddleware = [AuthGuestMiddleware()];
  static final _authMiddleware = [AuthRequiredMiddleware()];
  static final _subscriptionMiddleware = [
    AuthRequiredMiddleware(),
    SubscriptionRequiredMiddleware(),
  ];

  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: SplashView.new,
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: LoginView.new,
      binding: AuthBinding(),
      middlewares: _guestMiddleware,
    ),
    GetPage(
      name: AppRoutes.register,
      page: RegisterView.new,
      binding: AuthBinding(),
      middlewares: _guestMiddleware,
    ),
    GetPage(
      name: AppRoutes.forgotPassword,
      page: ForgotPasswordView.new,
      binding: AuthBinding(),
      middlewares: _guestMiddleware,
    ),
    GetPage(
      name: AppRoutes.home,
      page: HomeView.new,
      binding: HomeBinding(),
      middlewares: _authMiddleware,
    ),
    GetPage(
      name: AppRoutes.chatRoom,
      page: ChatRoomView.new,
      binding: ChatRoomBinding(),
      middlewares: _authMiddleware,
    ),
    GetPage(
      name: AppRoutes.callActive,
      page: CallView.new,
      middlewares: _authMiddleware,
    ),
    GetPage(
      name: AppRoutes.activityHistory,
      page: ActivityHistoryView.new,
      binding: ActivityHistoryBinding(),
      middlewares: _subscriptionMiddleware,
    ),
    GetPage(
      name: AppRoutes.activityDay,
      page: ActivityDayDetailView.new,
      binding: ActivityDayBinding(),
      middlewares: _subscriptionMiddleware,
    ),
    GetPage(
      name: AppRoutes.profileEdit,
      page: ProfileEditView.new,
      binding: ProfileEditBinding(),
      middlewares: _authMiddleware,
    ),
    GetPage(
      name: AppRoutes.chooseTrainer,
      page: ChooseTrainerView.new,
      binding: ChooseTrainerBinding(),
      middlewares: _authMiddleware,
    ),
    GetPage(
      name: AppRoutes.traineeDetail,
      page: TraineeDetailView.new,
      binding: TraineeDetailBinding(),
      middlewares: _authMiddleware,
    ),
    GetPage(
      name: AppRoutes.traineeActivityHistory,
      page: TraineeActivityHistoryView.new,
      binding: TraineeActivityHistoryBinding(),
      middlewares: _authMiddleware,
    ),
    GetPage(
      name: AppRoutes.nutritionMeals,
      page: NutritionMealsView.new,
      binding: TraineeNutritionBinding(),
      middlewares: _subscriptionMiddleware,
    ),
    GetPage(
      name: AppRoutes.nutritionMealForm,
      page: MealFormView.new,
      binding: MealFormBinding(),
      middlewares: _subscriptionMiddleware,
    ),
    GetPage(
      name: AppRoutes.workoutWeekly,
      page: WorkoutWeeklyView.new,
      binding: TraineeWorkoutBinding(),
      middlewares: _subscriptionMiddleware,
    ),
    GetPage(
      name: AppRoutes.workoutDay,
      page: WorkoutDayDetailView.new,
      binding: WorkoutDayBinding(),
      middlewares: _subscriptionMiddleware,
    ),
    GetPage(
      name: AppRoutes.workoutExerciseForm,
      page: ExerciseFormView.new,
      binding: ExerciseFormBinding(),
      middlewares: _subscriptionMiddleware,
    ),
    GetPage(
      name: AppRoutes.progressGallery,
      page: ProgressGalleryView.new,
      binding: ProgressBinding(),
      middlewares: _subscriptionMiddleware,
    ),
    GetPage(
      name: AppRoutes.progressAddEntry,
      page: AddProgressEntryView.new,
      binding: ProgressAddEntryBinding(),
      middlewares: _subscriptionMiddleware,
    ),
    GetPage(
      name: AppRoutes.progressEntryDetail,
      page: ProgressEntryDetailView.new,
      binding: ProgressEntryDetailBinding(),
      middlewares: _subscriptionMiddleware,
    ),
    GetPage(
      name: AppRoutes.subscriptionPlans,
      page: TraineePlansView.new,
      binding: TraineePlansBinding(),
      middlewares: _authMiddleware,
    ),
    GetPage(
      name: AppRoutes.subscriptionCheckout,
      page: SubscriptionCheckoutView.new,
      binding: SubscriptionCheckoutBinding(),
      middlewares: _authMiddleware,
    ),
    GetPage(
      name: AppRoutes.subscriptionSuccess,
      page: SubscriptionSuccessView.new,
      middlewares: _authMiddleware,
    ),
    GetPage(
      name: AppRoutes.trainerSubscriptionPlans,
      page: TrainerPlansView.new,
      binding: TrainerPlansBinding(),
      middlewares: _authMiddleware,
    ),
    GetPage(
      name: AppRoutes.trainerPlanForm,
      page: TrainerPlanFormView.new,
      binding: TrainerPlanFormBinding(),
      middlewares: _authMiddleware,
    ),
    GetPage(
      name: AppRoutes.trainerSubscribers,
      page: TrainerSubscribersView.new,
      binding: TrainerSubscribersBinding(),
      middlewares: _authMiddleware,
    ),
    GetPage(
      name: AppRoutes.trainerSubscriptionEdit,
      page: TrainerSubscriptionEditView.new,
      binding: TrainerSubscriptionEditBinding(),
      middlewares: _authMiddleware,
    ),
    GetPage(
      name: AppRoutes.trainerAssignSubscription,
      page: TrainerAssignSubscriptionView.new,
      binding: TrainerAssignSubscriptionBinding(),
      middlewares: _authMiddleware,
    ),
  ];
}
