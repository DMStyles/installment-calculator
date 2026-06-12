const { onSchedule } = require("firebase-functions/v2/scheduler");
const admin = require("firebase-admin");

admin.initializeApp();

// Helper to get formatted date string 'YYYY-MM-DD' for Sri Lanka timezone plus leadDays
function getTargetDateString(leadDays) {
  const d = new Date();
  // UTC time
  const utc = d.getTime() + (d.getTimezoneOffset() * 60000);
  // Sri Lanka is UTC +5:30
  const lkTime = new Date(utc + (3600000 * 5.5));
  lkTime.setDate(lkTime.getDate() + leadDays);

  const yyyy = lkTime.getFullYear();
  const mm = String(lkTime.getMonth() + 1).padStart(2, '0');
  const dd = String(lkTime.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

exports.sendInstallmentReminders = onSchedule({
  schedule: "0 9 * * *", // 9:00 AM daily
  timeZone: "Asia/Colombo",
  memory: "256MiB",
}, async (event) => {
  const db = admin.firestore();
  console.log("Starting daily installment reminders scan...");

  try {
    const devicesSnapshot = await db.collection("devices").get();
    if (devicesSnapshot.empty) {
      console.log("No registered devices found.");
      return;
    }

    const messages = [];

    for (const deviceDoc of devicesSnapshot.docs) {
      const deviceToken = deviceDoc.id;
      const deviceData = deviceDoc.data();

      // Check if notifications are disabled for this device
      const enabled = deviceData.notificationsEnabled !== false; // default to true
      if (!enabled) {
        continue;
      }

      const leadDays = deviceData.notificationLeadDays || 1; // default to 1 day
      const targetDateStr = getTargetDateString(leadDays);

      // Fetch installments for this device
      const installmentsSnapshot = await deviceDoc.ref.collection("installments").get();

      for (const instDoc of installmentsSnapshot.docs) {
        const inst = instDoc.data();
        const payments = inst.payments || [];

        for (const payment of payments) {
          // Check if unpaid and due date matches target date
          if (!payment.isPaid && payment.dueDate === targetDateStr) {
            const amountFormatted = Number(payment.amount).toLocaleString('en-US', {
              minimumFractionDigits: 2,
              maximumFractionDigits: 2
            });

            console.log(`Scheduling notification to device ${deviceToken} for ${inst.name} due on ${payment.dueDate}`);

            messages.push({
              token: deviceToken,
              notification: {
                title: `Upcoming ${inst.name} Payment`,
                body: `Installment ${payment.installmentIndex} of Rs. ${amountFormatted} with ${inst.provider} is due in ${leadDays} day${leadDays > 1 ? 's' : ''}.`,
              },
              data: {
                installmentId: inst.id || "",
                dueDate: payment.dueDate || "",
              }
            });
          }
        }
      }
    }

    if (messages.length > 0) {
      // Firebase Cloud Messaging lets you send up to 500 messages at a time using sendEach
      console.log(`Sending ${messages.length} notification messages...`);
      const response = await admin.messaging().sendEach(messages);
      console.log(`Successfully sent ${response.successCount} messages; ${response.failureCount} failed.`);
    } else {
      console.log("No matching installments due today.");
    }
  } catch (error) {
    console.error("Error sending installment reminders:", error);
  }
});
