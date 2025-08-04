const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendReviewNotifications = functions.pubsub
    .schedule("every 1 minutes") // For testing. Use a less frequent schedule in production.
    .onRun(async (context) => {
      const now = new Date();
      // Note: The function runs on a server, so we need to consider UTC time.
      // For simplicity, we'll assume server and user times align or are handled in-app.
      // A robust solution would involve storing user's UTC offset.
      const currentHour = now.getUTCHours();
      const currentMinute = now.getUTCMinutes();

      console.log(
          `Function running at: ${currentHour}:${currentMinute} (UTC)`,
      );

      const usersSnapshot = await admin.firestore().collection("users").get();

      if (usersSnapshot.empty) {
        console.log("No users found.");
        return null;
      }

      const notificationPromises = [];

      usersSnapshot.forEach((doc) => {
        const user = doc.data();

        if (
          user.notificationEnabled &&
          user.notificationHour === currentHour &&
          user.notificationMinute === currentMinute &&
          user.fcmToken
        ) {
          const message = {
            notification: {
              title: "잊지 말고 복습하세요!",
              body: "어제 배운 내용을 다시 확인하고 기억력을 강화하세요.",
            },
            token: user.fcmToken,
          };

          console.log(`Sending notification to user ${doc.id}`);
          notificationPromises.push(admin.messaging().send(message));
        }
      });

      try {
        await Promise.all(notificationPromises);
        console.log("Successfully sent all notifications.");
      } catch (error) {
        console.error("Error sending notifications:", error);
      }

      return null;
    });
