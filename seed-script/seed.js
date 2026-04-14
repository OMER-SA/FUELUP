/**
 * FuelUp — Firebase Demo Seed Script
 *
 * Populates:
 *   - Firebase Auth (2 chefs, 3 customers)
 *   - Firestore: users, cheffs, customers, mealCategory, kitchenMeals, recipie
 *   - Realtime Database: orders (with realistic status flow)
 *
 * Run: node seed.js
 */

const admin = require("firebase-admin");
const serviceAccount = require("./credentials.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://fuelup-2e090-default-rtdb.firebaseio.com",
});

const db = admin.firestore();
const rtdb = admin.database();
const auth = admin.auth();

// ─── Helpers ────────────────────────────────────────────────────────────────

function log(msg) { console.log(`[seed] ${msg}`); }

function isoDate(daysAgo = 0) {
  const d = new Date();
  d.setDate(d.getDate() - daysAgo);
  return d.toISOString();
}

// ─── Users ───────────────────────────────────────────────────────────────────

const CHEFS = [
  {
    email: "zara.kitchen@fuelup.pk",
    password: "Demo@1234",
    kitchenName: "Zara's Home Kitchen",
    phone: "03001234567",
    address: "Street 5, F-7/2, Islamabad",
  },
  {
    email: "ahmed.bites@fuelup.pk",
    password: "Demo@1234",
    kitchenName: "Ahmed's Desi Bites",
    phone: "03219876543",
    address: "Block C, Gulberg III, Lahore",
  },
];

const CUSTOMERS = [
  {
    email: "ali.student@fuelup.pk",
    password: "Demo@1234",
    firstName: "Ali",
    lastName: "Hassan",
    phone: "03331112233",
    address: "Hostel 4, NUST, Islamabad",
    age: 21,
    height: 175.0,
    weight: 68,
    alergies: ["nuts"],
    dietaryPreferences: ["high_protein"],
    gender: "male",
    activityLevel: "moderate",
    targetWeight: 65.0,
  },
  {
    email: "sara.malik@fuelup.pk",
    password: "Demo@1234",
    firstName: "Sara",
    lastName: "Malik",
    phone: "03124445566",
    address: "DHA Phase 2, Karachi",
    age: 24,
    height: 162.0,
    weight: 58,
    alergies: ["dairy"],
    dietaryPreferences: ["low_carb", "vegetarian"],
    gender: "female",
    activityLevel: "light",
    targetWeight: 55.0,
  },
  {
    email: "usman.ch@fuelup.pk",
    password: "Demo@1234",
    firstName: "Usman",
    lastName: "Ch",
    phone: "03458889900",
    address: "Model Town, Lahore",
    age: 27,
    height: 180.0,
    weight: 85,
    alergies: [],
    dietaryPreferences: ["halal"],
    gender: "male",
    activityLevel: "active",
    targetWeight: 80.0,
  },
];

// ─── Meal Categories ─────────────────────────────────────────────────────────

const CATEGORIES = ["Breakfast", "Lunch", "Dinner", "Snacks", "Healthy"];

// ─── Meals per chef ──────────────────────────────────────────────────────────

function zarasMeals(chefId, kitchenName) {
  return [
    {
      mealName: "Chicken Karahi",
      category: "Dinner",
      price: 450,
      description: "Slow-cooked chicken in a rich tomato and ginger sauce, served with naan.",
      calories: 620,
      cheffId: chefId,
      kitchenName,
      mealPicture: "https://upload.wikimedia.org/wikipedia/commons/thumb/4/45/A_small_cup_of_coffee.JPG/640px-A_small_cup_of_coffee.JPG",
      recipie: [
        { ingredient: "Chicken", measurement: "500g", calories: 335, isChangeAble: false },
        { ingredient: "Tomatoes", measurement: "3 medium", calories: 66, isChangeAble: true },
        { ingredient: "Ginger", measurement: "1 tbsp", calories: 5, isChangeAble: true },
        { ingredient: "Garlic", measurement: "4 cloves", calories: 18, isChangeAble: true },
        { ingredient: "Cooking Oil", measurement: "3 tbsp", calories: 120, isChangeAble: true },
        { ingredient: "Green Chillies", measurement: "3", calories: 6, isChangeAble: true },
        { ingredient: "Salt & Spices", measurement: "to taste", calories: 10, isChangeAble: true },
        { ingredient: "Fresh Coriander", measurement: "handful", calories: 5, isChangeAble: true },
      ],
    },
    {
      mealName: "Halwa Puri Breakfast",
      category: "Breakfast",
      price: 220,
      description: "Classic Pakistani breakfast with fluffy puris, sweet halwa, and chickpea curry.",
      calories: 780,
      cheffId: chefId,
      kitchenName,
      mealPicture: null,
      recipie: [
        { ingredient: "Whole Wheat Flour", measurement: "200g", calories: 340, isChangeAble: false },
        { ingredient: "Semolina", measurement: "100g", calories: 360, isChangeAble: true },
        { ingredient: "Sugar", measurement: "4 tbsp", calories: 80, isChangeAble: true },
        { ingredient: "Ghee", measurement: "2 tbsp", calories: 240, isChangeAble: true },
        { ingredient: "Chickpeas", measurement: "150g cooked", calories: 182, isChangeAble: true },
        { ingredient: "Oil for frying", measurement: "as needed", calories: 120, isChangeAble: true },
      ],
    },
    {
      mealName: "Grilled Chicken Salad",
      category: "Healthy",
      price: 320,
      description: "Fresh garden salad with grilled chicken breast, olive oil dressing, and lemon.",
      calories: 310,
      cheffId: chefId,
      kitchenName,
      mealPicture: null,
      recipie: [
        { ingredient: "Chicken Breast", measurement: "200g", calories: 165, isChangeAble: false },
        { ingredient: "Lettuce", measurement: "2 cups", calories: 15, isChangeAble: true },
        { ingredient: "Cherry Tomatoes", measurement: "10", calories: 35, isChangeAble: true },
        { ingredient: "Cucumber", measurement: "1 medium", calories: 16, isChangeAble: true },
        { ingredient: "Olive Oil", measurement: "1 tbsp", calories: 60, isChangeAble: true },
        { ingredient: "Lemon Juice", measurement: "1 tbsp", calories: 4, isChangeAble: true },
        { ingredient: "Salt & Pepper", measurement: "to taste", calories: 5, isChangeAble: true },
      ],
    },
  ];
}

function ahmedsMeals(chefId, kitchenName) {
  return [
    {
      mealName: "Beef Biryani",
      category: "Lunch",
      price: 380,
      description: "Aromatic basmati rice layered with spiced beef, saffron, and caramelised onions.",
      calories: 720,
      cheffId: chefId,
      kitchenName,
      mealPicture: null,
      recipie: [
        { ingredient: "Basmati Rice", measurement: "300g", calories: 340, isChangeAble: false },
        { ingredient: "Beef", measurement: "400g", calories: 280, isChangeAble: false },
        { ingredient: "Onions", measurement: "2 large", calories: 80, isChangeAble: true },
        { ingredient: "Yogurt", measurement: "100g", calories: 60, isChangeAble: true },
        { ingredient: "Biryani Spice Mix", measurement: "2 tbsp", calories: 20, isChangeAble: true },
        { ingredient: "Saffron", measurement: "pinch", calories: 2, isChangeAble: true },
        { ingredient: "Cooking Oil", measurement: "3 tbsp", calories: 120, isChangeAble: true },
        { ingredient: "Mint Leaves", measurement: "handful", calories: 5, isChangeAble: true },
      ],
    },
    {
      mealName: "Daal Makhani",
      category: "Dinner",
      price: 280,
      description: "Slow-cooked black lentils in a creamy tomato butter sauce. Vegan-friendly.",
      calories: 420,
      cheffId: chefId,
      kitchenName,
      mealPicture: null,
      recipie: [
        { ingredient: "Black Lentils", measurement: "200g", calories: 230, isChangeAble: false },
        { ingredient: "Tomatoes", measurement: "3 medium", calories: 66, isChangeAble: true },
        { ingredient: "Butter", measurement: "2 tbsp", calories: 102, isChangeAble: true },
        { ingredient: "Cream", measurement: "2 tbsp", calories: 60, isChangeAble: true },
        { ingredient: "Garlic Ginger Paste", measurement: "1 tbsp", calories: 15, isChangeAble: true },
        { ingredient: "Cumin", measurement: "1 tsp", calories: 8, isChangeAble: true },
        { ingredient: "Salt & Chilli", measurement: "to taste", calories: 5, isChangeAble: true },
      ],
    },
    {
      mealName: "Aloo Samosa (4 pcs)",
      category: "Snacks",
      price: 150,
      description: "Crispy golden samosas stuffed with spiced potato and peas. Perfect tea-time snack.",
      calories: 480,
      cheffId: chefId,
      kitchenName,
      mealPicture: null,
      recipie: [
        { ingredient: "Potatoes", measurement: "300g boiled", calories: 231, isChangeAble: false },
        { ingredient: "Green Peas", measurement: "50g", calories: 42, isChangeAble: true },
        { ingredient: "Samosa Pastry", measurement: "8 sheets", calories: 140, isChangeAble: false },
        { ingredient: "Cumin Seeds", measurement: "1 tsp", calories: 8, isChangeAble: true },
        { ingredient: "Coriander Powder", measurement: "1 tsp", calories: 5, isChangeAble: true },
        { ingredient: "Oil for frying", measurement: "as needed", calories: 120, isChangeAble: true },
        { ingredient: "Salt & Chilli", measurement: "to taste", calories: 5, isChangeAble: true },
      ],
    },
    {
      mealName: "Protein Oat Bowl",
      category: "Breakfast",
      price: 250,
      description: "High-protein oat bowl with banana, peanut butter, chia seeds, and honey.",
      calories: 490,
      cheffId: chefId,
      kitchenName,
      mealPicture: null,
      recipie: [
        { ingredient: "Rolled Oats", measurement: "80g", calories: 297, isChangeAble: false },
        { ingredient: "Banana", measurement: "1 medium", calories: 89, isChangeAble: true },
        { ingredient: "Peanut Butter", measurement: "1 tbsp", calories: 94, isChangeAble: true },
        { ingredient: "Chia Seeds", measurement: "1 tbsp", calories: 58, isChangeAble: true },
        { ingredient: "Honey", measurement: "1 tsp", calories: 21, isChangeAble: true },
        { ingredient: "Milk", measurement: "150ml", calories: 98, isChangeAble: true },
      ],
    },
  ];
}

// ─── Main seed function ───────────────────────────────────────────────────────

async function seed() {
  log("Starting FuelUp demo seed...");

  // ── 1. Create Auth users + Firestore docs ──────────────────────────────────

  const chefIds = [];
  for (const chef of CHEFS) {
    log(`Creating chef: ${chef.email}`);
    let uid;
    try {
      const existing = await auth.getUserByEmail(chef.email);
      uid = existing.uid;
      log(`  Auth user already exists (${uid}), reusing`);
    } catch {
      const created = await auth.createUser({ email: chef.email, password: chef.password, emailVerified: true });
      uid = created.uid;
      log(`  Created auth user (${uid})`);
    }

    await db.collection("users").doc(uid).set({
      email: chef.email,
      role: "cheff",
      fcmToken: "",
    });

    await db.collection("cheffs").doc(uid).set({
      uid,
      kitchenName: chef.kitchenName,
      phone: chef.phone,
      bannerPicture: null,
      profilePicture: null,
      address: chef.address,
    });

    chefIds.push({ uid, ...chef });
    log(`  Chef Firestore docs written`);
  }

  const customerIds = [];
  for (const customer of CUSTOMERS) {
    log(`Creating customer: ${customer.email}`);
    let uid;
    try {
      const existing = await auth.getUserByEmail(customer.email);
      uid = existing.uid;
      log(`  Auth user already exists (${uid}), reusing`);
    } catch {
      const created = await auth.createUser({ email: customer.email, password: customer.password, emailVerified: true });
      uid = created.uid;
      log(`  Created auth user (${uid})`);
    }

    await db.collection("users").doc(uid).set({
      email: customer.email,
      role: "customer",
      fcmToken: "",
    });

    await db.collection("customers").doc(uid).set({
      uid,
      firstName: customer.firstName,
      lastName: customer.lastName,
      phone: customer.phone,
      address: customer.address,
      weight: customer.weight,
      height: customer.height,
      alergies: customer.alergies,
      age: customer.age,
      profilePicture: null,
      dietaryPreferences: customer.dietaryPreferences,
      gender: customer.gender,
      activityLevel: customer.activityLevel,
      targetWeight: customer.targetWeight,
    });

    customerIds.push({ uid, ...customer });
    log(`  Customer Firestore docs written`);
  }

  // ── 2. Meal Categories ─────────────────────────────────────────────────────

  log("Writing meal categories...");
  for (const category of CATEGORIES) {
    await db.collection("mealCategory").doc(category).set({ category });
  }
  log(`  ${CATEGORIES.length} categories written`);

  // ── 3. Meals ───────────────────────────────────────────────────────────────

  log("Writing kitchenMeals...");
  const [zara, ahmed] = chefIds;

  const allMeals = [
    ...zarasMeals(zara.uid, zara.kitchenName),
    ...ahmedsMeals(ahmed.uid, ahmed.kitchenName),
  ];

  const mealDocs = [];
  for (const meal of allMeals) {
    const ref = await db.collection("kitchenMeals").add(meal);
    await ref.update({ idMeal: ref.id });
    mealDocs.push({ id: ref.id, ...meal });
    log(`  Meal: "${meal.mealName}" (${ref.id})`);
  }

  // ── 4. Recipie collection (mirrors kitchenMeals for legacy getRecipie) ─────

  log("Writing recipie collection...");
  for (const meal of mealDocs) {
    const recipieMap = {};
    for (const item of meal.recipie) {
      recipieMap[item.ingredient] = {
        measurement: item.measurement,
        isChangeAble: item.isChangeAble,
      };
    }
    await db.collection("recipie").doc(meal.id).set({
      idMeal: meal.id,
      strMeal: meal.mealName,
      strCategory: meal.category,
      strArea: "Pakistani",
      strInstructions: `Prepare ${meal.mealName} using the listed ingredients. Cook thoroughly and serve hot.`,
      strMealThumb: meal.mealPicture || "",
      strTags: meal.category,
      price: meal.price,
      strYoutube: "",
      recipie: recipieMap,
    });
    log(`  Recipie: "${meal.mealName}"`);
  }

  // ── 5. Orders in Realtime Database ────────────────────────────────────────

  log("Writing RTDB orders...");
  const ordersRef = rtdb.ref("/orders");

  const [ali, sara, usman] = customerIds;

  // Helper to push an order
  async function addOrder(customer, meal, chef, status, daysAgo) {
    const orderRef = ordersRef.push();
    const orderId = orderRef.key;
    await orderRef.set({
      orderId,
      customerId: customer.uid,
      kitchenId: chef.uid,
      mealId: meal.id,
      quantity: 1,
      orderDate: isoDate(daysAgo),
      status,
      price: meal.price,
      kitchenName: chef.kitchenName,
      kitchenAddress: chef.address,
      mealName: meal.mealName,
      address: customer.address,
      recipe: meal.recipie,
      customerName: `${customer.firstName} ${customer.lastName}`,
      mealPicture: meal.mealPicture || "",
      originalRecipe: meal.recipie,
    });
    log(`  Order: "${meal.mealName}" for ${customer.firstName} — status: ${status}`);
    return orderId;
  }

  const zaraKarahi   = mealDocs.find(m => m.mealName === "Chicken Karahi");
  const zaraHalwa    = mealDocs.find(m => m.mealName === "Halwa Puri Breakfast");
  const zaraSalad    = mealDocs.find(m => m.mealName === "Grilled Chicken Salad");
  const ahmedBiryani = mealDocs.find(m => m.mealName === "Beef Biryani");
  const ahmedDaal    = mealDocs.find(m => m.mealName === "Daal Makhani");
  const ahmedSamosa  = mealDocs.find(m => m.mealName === "Aloo Samosa (4 pcs)");
  const ahmedOats    = mealDocs.find(m => m.mealName === "Protein Oat Bowl");

  // Delivered orders (history)
  await addOrder(ali,   zaraKarahi,   zara,  "Order Received", 5);
  await addOrder(sara,  ahmedBiryani, ahmed, "Order Received", 4);
  await addOrder(usman, zaraHalwa,    zara,  "Order Received", 3);
  await addOrder(ali,   ahmedSamosa,  ahmed, "Order Received", 2);
  await addOrder(sara,  zaraSalad,    zara,  "Order Received", 1);

  // Active orders (in progress — visible in chef kitchen screen)
  await addOrder(usman, ahmedBiryani, ahmed, "Preparing",          0);
  await addOrder(ali,   ahmedOats,    ahmed, "Order Placed",       0);
  await addOrder(sara,  ahmedDaal,    ahmed, "Delivery in Progress", 0);
  await addOrder(usman, zaraKarahi,   zara,  "Ready",              0);

  log("\n✅ Seed complete!");
  log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
  log("Demo Accounts:");
  log("");
  log("CHEFS:");
  for (const c of CHEFS) {
    log(`  ${c.kitchenName}`);
    log(`  Email:    ${c.email}`);
    log(`  Password: ${c.password}`);
    log("");
  }
  log("CUSTOMERS:");
  for (const c of CUSTOMERS) {
    log(`  ${c.firstName} ${c.lastName}`);
    log(`  Email:    ${c.email}`);
    log(`  Password: ${c.password}`);
    log("");
  }
  log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

  process.exit(0);
}

seed().catch((err) => {
  console.error("[seed] Fatal error:", err);
  process.exit(1);
});
