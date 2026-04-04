// 🔥 FINAL CLOUD FUNCTIONS (PRO MAX++ ELITE BACKEND)

const { setGlobalOptions } = require("firebase-functions");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

admin.initializeApp();
setGlobalOptions({ maxInstances: 10 });

const db = admin.firestore();

// ================= 🔐 CHECK USER ACCESS =================
exports.checkUserAccess = onCall(async (request) => {

  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول");
  }

  const userDoc = await db.collection("users").doc(uid).get();

  if (!userDoc.exists) {
    throw new HttpsError("not-found", "المستخدم غير موجود");
  }

  const user = userDoc.data();

  if (user.blocked) {
    throw new HttpsError("permission-denied", "الحساب محظور");
  }

  if (!user.subscribed) {
    throw new HttpsError("permission-denied", "غير مشترك");
  }

  return {
    success: true,
    message: "مسموح بالدخول"
  };
});


// ================= 🎥 GENERATE VIDEO TOKEN =================
exports.generateVideoToken = onCall(async (request) => {

  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول");
  }

  const videoId = request.data?.videoId;

  if (!videoId) {
    throw new HttpsError("invalid-argument", "videoId مطلوب");
  }

  const userDoc = await db.collection("users").doc(uid).get();

  if (!userDoc.exists) {
    throw new HttpsError("not-found", "المستخدم غير موجود");
  }

  const user = userDoc.data();

  if (!user.subscribed) {
    throw new HttpsError("permission-denied", "غير مشترك");
  }

  const token = `${uid}_${videoId}_${Date.now()}`;

  return { token };
});


// ================= 🔔 SEND NOTIFICATION (PRO) =================
exports.sendNotification = onCall(async (request) => {

  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول");
  }

  const adminDoc = await db.collection("users").doc(uid).get();

  if (!adminDoc.exists || !adminDoc.data().isAdmin) {
    throw new HttpsError("permission-denied", "Admins فقط");
  }

  const { title, body, userId, data } = request.data;

  if (!title || !body) {
    throw new HttpsError("invalid-argument", "العنوان والمحتوى مطلوبين");
  }

  if (userId) {

    const userDoc = await db.collection("users").doc(userId).get();

    const tokens = userDoc.data()?.fcmTokens || [];

    if (!tokens.length) {
      throw new HttpsError("not-found", "لا يوجد token للمستخدم");
    }

    await admin.messaging().sendMulticast({
      tokens: tokens,
      notification: { title, body },
      data: {
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        title: title || "",
        ...(data || {})
      }
    });

    return { success: true, type: "user" };
  }

  await admin.messaging().send({
    topic: "allUsers",
    notification: { title, body },
    data: {
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      title: title || "",
      ...(data || {})
    }
  });

  return { success: true, type: "all" };
});


// ================= 👑 MAKE ADMIN (SECURE) =================
exports.makeAdmin = onCall(async (request) => {

  const uid = request.auth?.uid;

  if (!uid) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول");
  }

  const caller = await db.collection("users").doc(uid).get();

  if (!caller.exists || !caller.data().isAdmin) {
    throw new HttpsError("permission-denied", "غير مصرح");
  }

  const userId = request.data?.userId;

  if (!userId) {
    throw new HttpsError("invalid-argument", "userId مطلوب");
  }

  await db.collection("users").doc(userId).update({
    isAdmin: true
  });

  return { success: true };
});