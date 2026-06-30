const admin = require("firebase-admin");

// Fetch service account from env variable
if (!process.env.FIREBASE_SERVICE_ACCOUNT) {
  console.error("FIREBASE_SERVICE_ACCOUNT environment variable is missing!");
  process.exit(1);
}

const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

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

async function run() {
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

      const enabled = deviceData.notificationsEnabled !== false;
      if (!enabled) {
        continue;
      }

      const leadDays = deviceData.notificationLeadDays || 1;
      
      // Generate target date strings for [0, 1, ..., leadDays]
      const allowedTargetDates = [];
      for (let i = 0; i <= leadDays; i++) {
        allowedTargetDates.push(getTargetDateString(i));
      }

      const installmentsSnapshot = await deviceDoc.ref.collection("installments").get();

      for (const instDoc of installmentsSnapshot.docs) {
        const inst = instDoc.data();
        const payments = inst.payments || [];

        for (const payment of payments) {
          if (!payment.isPaid) {
            // Find which offset in the allowed target dates this payment's due date matches
            const matchedOffset = allowedTargetDates.indexOf(payment.dueDate);
            
            if (matchedOffset !== -1) {
              const amountFormatted = Number(payment.amount).toLocaleString('en-US', {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2
              });

              let dueText = "";
              if (matchedOffset === 0) {
                dueText = "is due today.";
              } else if (matchedOffset === 1) {
                dueText = "is due tomorrow.";
              } else {
                dueText = `is due in ${matchedOffset} days.`;
              }

              console.log(`Scheduling notification to device ${deviceToken} for ${inst.name} due on ${payment.dueDate} (${dueText})`);

              messages.push({
                token: deviceToken,
                notification: {
                  title: `Upcoming ${inst.name} Payment`,
                  body: `Installment ${payment.installmentIndex} of Rs. ${amountFormatted} with ${inst.provider} ${dueText}`,
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
    }

    if (messages.length > 0) {
      console.log(`Sending ${messages.length} notification messages...`);
      const response = await admin.messaging().sendEach(messages);
      console.log(`Successfully sent ${response.successCount} messages; ${response.failureCount} failed.`);
    } else {
      console.log("No matching installments due today.");
    }
  } catch (error) {
    console.error("Error sending installment reminders:", error);
    process.exit(1);
  }
}

run();
