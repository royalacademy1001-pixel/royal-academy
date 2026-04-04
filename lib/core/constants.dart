import '../core/firebase_service.dart';

class AppConstants {

  static const int xpPerLesson = 10;
  static const int xpPerQuiz = 20;
  static const int xpDailyLogin = 5;

  static const List<int> levelThresholds = [
    0, 100, 300, 700, 1500, 3000,
  ];

  static const int streakRewardXP = 5;
  static const int maxStreakDays = 365;

  static const String notifCourse = "course";
  static const String notifLesson = "lesson";
  static const String notifGeneral = "general";

  static const bool enableXPSystem = true;
  static const bool enableStreakSystem = true;
  static const bool enableLeaderboard = true;

  static const bool allowMultipleDevices = true;
  static const bool enableAntiCheat = true;

  static const int maxBatchQuery = 10;
  static const int maxLeaderboardUsers = 50;

  static const String users = "users";
  static const String courses = "courses";
  static const String lessons = "lessons";
  static const String payments = "payments";
  static const String progress = "progress";
  static const String notifications = "notifications";

  static const String lastWatch = "lastWatch";
  static const String lastWatchAlt = "last_watch";

  static const String categories = "categories";
  static const String sections = "sections";
  static const String reviews = "reviews";
  static const String certificates = "certificates";

  static const String comments = "comments";
  static const String ratings = "ratings";
  static const String recommendations = "recommendations";
  static const String quizzes = "quizzes";
  static const String answers = "answers";

  static const String analytics = "analytics";
  static const String logs = "logs";

  static const String paymentFolder = "payments";
  static const String profileFolder = "profiles";
  static const String videosFolder = "videos";
  static const String coursesFolder = "courses";
  static const String pdfFolder = "pdfs";
  static const String audioFolder = "audios";
  static const String thumbnailsFolder = "thumbnails";

  static const String planMonthly = "monthly";
  static const String planYearly = "yearly";
  static const String planSingleCourse = "single_course";

  static const String planMonthlyAr = "شهري";
  static const String planYearlyAr = "سنوي";
  static const String planSingleCourseAr = "كورس واحد";

  static const Map<String, String> planNames = {
    planMonthly: planMonthlyAr,
    planYearly: planYearlyAr,
    planSingleCourse: planSingleCourseAr,
  };

  static const int monthlyPrice = 100;
  static const int yearlyPrice = 900;
  static const int singleCoursePrice = 50;

  static int dynamicMonthlyPrice = monthlyPrice;
  static int dynamicYearlyPrice = yearlyPrice;

  static Future<void> loadPrices() async {
    try {
      final doc = await FirebaseService.firestore
          .collection("settings")
          .doc("pricing")
          .get();

      final data = doc.data() ?? {};

      dynamicMonthlyPrice =
          int.tryParse(data['monthly']?.toString() ?? "") ??
              monthlyPrice;

      dynamicYearlyPrice =
          int.tryParse(data['yearly']?.toString() ?? "") ??
              yearlyPrice;

    } catch (_) {}
  }

  static const Map<String, int> planPrices = {
    planMonthly: monthlyPrice,
    planYearly: yearlyPrice,
    planSingleCourse: singleCoursePrice,
  };

  static const String paymentPending = "pending";
  static const String paymentApproved = "approved";
  static const String paymentRejected = "rejected";

  static const List<String> paymentStatuses = [
    paymentPending,
    paymentApproved,
    paymentRejected,
  ];

  static const String roleAdmin = "admin";
  static const String roleStudent = "student";
  static const String roleInstructor = "instructor";

  static const List<String> roles = [
    roleAdmin,
    roleStudent,
    roleInstructor,
  ];

  static const String topicAllUsers = "all_users";
  static const String topicSubscribed = "subscribed_users";
  static const String topicFreeUsers = "free_users";
  static const String topicInstructors = "instructors";

  static const int videoTokenExpiryMinutes = 5;

  static const int freeLessonsCount = 1;
  static const int passPercentage = 70;
  static const int maxLessonsPerCourse = 500;

  static const String lastCourseId = "lastCourseId";
  static const String lastLessonId = "lastLessonId";
  static const String watchTime = "watchTime";

  static const String eventWatch = "watch";
  static const String eventEnroll = "enroll";
  static const String eventPurchase = "purchase";

  static const String eventOpenCourse = "open_course";
  static const String eventCompleteLesson = "complete_lesson";

  static const String instructorRequest = "instructorRequest";
  static const String instructorApproved = "instructorApproved";
  static const String instructorRejected = "instructorRejected";

  static const String courseStatus = "status";
  static const String coursePending = "pending";
  static const String courseApproved = "approved";
  static const String courseRejected = "rejected";
  static const String rejectReason = "rejectReason";

  static const String defaultImage =
      "https://via.placeholder.com/300";

  static const String defaultAvatar =
      "https://ui-avatars.com/api/?name=User";

  static const int maxCoursesHome = 5;
  static const int maxUploadSizeMB = 200;
  static const int cacheSeconds = 30;
  static const int pageSize = 10;

  static const int maxCommentLength = 500;
  static const int maxReviewsPerUser = 1;

  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration animationDuration =
      Duration(milliseconds: 300);

  static const String fieldUserId = "userId";
  static const String fieldCourseId = "courseId";
  static const String fieldLessonId = "lessonId";

  static const String fieldCreatedAt = "createdAt";
  static const String fieldUpdatedAt = "updatedAt";
  static const String fieldStatus = "status";

  static const String fieldEmail = "email";
  static const String fieldPhone = "phone";
  static const String fieldName = "name";

  static const String averageRating = "averageRating";
  static const String totalRatings = "totalRatings";
  static const String userInterests = "userInterests";
  static const String points = "points";
  static const String level = "level";
  static const String streak = "streak";
  static const String score = "score";

  static const bool enableCertificates = true;
  static const bool enableInstructorSystem = true;
  static const bool enableNotifications = true;
  static const bool enableReviews = true;
}