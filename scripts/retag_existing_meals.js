const admin = require("../functions/node_modules/firebase-admin");
const {
  MEALS_COLLECTION,
  getMealName,
  tagMealWithGemini,
} = require("../functions/meal_tagger");

let serviceAccount;

try {
  serviceAccount = require("../functions/serviceAccountKey.json");
} catch (error) {
  console.error(
    "Missing functions/serviceAccountKey.json. Add a Firebase service account key before running this script."
  );
  process.exit(1);
}

if (!process.env.GEMINI_API_KEY) {
  console.error("Missing GEMINI_API_KEY environment variable.");
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function tagAll() {
  const snap = await db.collection(MEALS_COLLECTION).get();
  console.log(`Found ${snap.size} meals to process`);

  let tagged = 0;
  let skipped = 0;
  let failed = 0;

  for (const doc of snap.docs) {
    const meal = doc.data();

    if (meal.autoTagged === true) {
      console.log(`SKIP: ${getMealName(meal) || doc.id}`);
      skipped++;
      continue;
    }

    try {
      const tagData = await tagMealWithGemini({
        mealId: doc.id,
        mealData: meal,
        apiKey: process.env.GEMINI_API_KEY,
        admin,
        log: console,
      });

      // Clear autoTagError on success, keep it on failure
      if (tagData.autoTagged === true) {
        tagData.autoTagError = admin.firestore.FieldValue.delete();
      }

      await doc.ref.update(tagData);
      if (tagData.autoTagged === true) {
        console.log(`OK: ${getMealName(meal)} -> [${tagData.tags.join(", ")}]`);
        tagged++;
      } else {
        console.error(
          `FAIL: ${getMealName(meal) || doc.id} - ${tagData.autoTagError || "Unknown Gemini error"}`
        );
        failed++;
      }
    } catch (err) {
      console.error(`FAIL: ${getMealName(meal) || doc.id} - ${err.message}`);
      failed++;
    }

    await new Promise((resolve) => setTimeout(resolve, 3000));
  }

  // Fallback: manually tag known failed meals
  const knownFailed = [
    {
      docId: '0tDd9WPQJdmJ0lsi4Cqw',
      name: 'Aloo Samosa (4 pcs)',
      tags: ['fried', 'heavy', 'comfort', 'spicy', 'complex_carb', 'fatty'],
      allergens: ['gluten'],
      dietaryLabels: ['vegetarian'],
      protein: 8,
      prepStyle: 'fried',
    },
  ];

  for (const item of knownFailed) {
    const ref = db.collection(MEALS_COLLECTION).doc(item.docId);
    const snap = await ref.get();
    if (snap.exists && snap.data().autoTagged !== true) {
      await ref.update({
        tags:          item.tags,
        allergens:     item.allergens,
        dietaryLabels: item.dietaryLabels,
        protein:       item.protein,
        prepStyle:     item.prepStyle,
        autoTagged:    true,
        autoTaggedAt:  admin.firestore.FieldValue.serverTimestamp(),
        autoTagModel:  'manual',
        autoTagError:  admin.firestore.FieldValue.delete(),
      });
      console.log(`Manually tagged fallback: ${item.name}`);
    }
  }

  console.log(
    `\nDone. Tagged: ${tagged} | Skipped: ${skipped} | Failed: ${failed}`
  );
  process.exit(0);
}

tagAll().catch((error) => {
  console.error(`Fatal error: ${error.message}`);
  process.exit(1);
});
