const path = require('path');
const admin = require('../functions/node_modules/firebase-admin');

const serviceAccountPath = path.resolve(
  __dirname,
  '..',
  'functions',
  'serviceAccountKey.json',
);

let serviceAccount;

try {
  serviceAccount = require(serviceAccountPath);
} catch (error) {
  console.error(
    'Missing functions/serviceAccountKey.json. Add a Firebase service account key before running this script.',
  );
  process.exit(1);
}

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id,
  });
}

const db = admin.firestore();
const kitchenMeals = db.collection('kitchenMeals');

const ingredient = (ingredientName, measurement, calories = 0) => ({
  ingredient: ingredientName,
  measurement,
  calories,
  isChangeAble: false,
});

const meals = [
  {
    mealName: 'Plain Boiled Rice with Lentils',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Main Course',
    description: 'Plain boiled rice with lentils for a steady, balanced meal.',
    calories: 320,
    price: 120,
    mealPicture: null,
    tags: ['plain', 'boiled', 'balanced', 'fresh'],
    allergens: [],
    dietaryLabels: ['vegetarian', 'vegan', 'halal'],
    protein: 14,
    prepStyle: 'boiled',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('basmati rice', '150g'),
      ingredient('red lentils', '80g'),
      ingredient('turmeric', 'pinch'),
      ingredient('salt', 'to taste'),
    ],
  },
  {
    mealName: 'Steamed Chicken with Vegetables',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Healthy',
    description: 'Steamed chicken with vegetables for a light balanced plate.',
    calories: 340,
    price: 140,
    mealPicture: null,
    tags: ['steamed', 'balanced', 'fresh', 'light'],
    allergens: [],
    dietaryLabels: ['halal', 'high_protein', 'gluten_free'],
    protein: 32,
    prepStyle: 'steamed',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('chicken breast', '200g'),
      ingredient('broccoli', '100g'),
      ingredient('carrots', '80g'),
      ingredient('salt', 'to taste'),
      ingredient('pepper', 'to taste'),
    ],
  },
  {
    mealName: 'Fresh Cucumber Yogurt Salad',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Salads',
    description: 'Fresh cucumber yogurt salad with mint and lemon.',
    calories: 180,
    price: 90,
    mealPicture: null,
    tags: ['fresh', 'plain', 'balanced', 'light'],
    allergens: ['dairy'],
    dietaryLabels: ['vegetarian', 'gluten_free'],
    protein: 8,
    prepStyle: 'raw',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('cucumber', '200g'),
      ingredient('plain yogurt', '150g'),
      ingredient('mint leaves', 'few'),
      ingredient('salt', 'to taste'),
      ingredient('lemon juice', '1tbsp'),
    ],
  },
  {
    mealName: 'Plain Oat Porridge',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Breakfast',
    description: 'Plain oat porridge with banana and a little honey.',
    calories: 280,
    price: 110,
    mealPicture: null,
    tags: ['plain', 'balanced', 'boiled', 'whole_grain', 'fiber'],
    allergens: [],
    dietaryLabels: ['vegetarian', 'vegan'],
    protein: 9,
    prepStyle: 'boiled',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('rolled oats', '80g'),
      ingredient('water', '250ml'),
      ingredient('banana', 'half'),
      ingredient('honey', '1tsp'),
    ],
  },
  {
    mealName: 'Rainbow Veggie Wrap',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Lunch',
    description: 'Rainbow wrap packed with fresh vegetables and hummus.',
    calories: 420,
    price: 150,
    mealPicture: null,
    tags: ['colorful', 'fresh', 'varied', 'healthy', 'balanced'],
    allergens: ['gluten'],
    dietaryLabels: ['vegetarian'],
    protein: 18,
    prepStyle: 'raw',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('whole wheat wrap', '1'),
      ingredient('hummus', '3tbsp'),
      ingredient('mixed peppers', '100g'),
      ingredient('spinach', '50g'),
      ingredient('grated carrot', '50g'),
      ingredient('purple cabbage', '30g'),
    ],
  },
  {
    mealName: 'Grilled Chicken and Mango Salad',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Healthy',
    description: 'Grilled chicken and mango salad with bright fresh flavours.',
    calories: 380,
    price: 180,
    mealPicture: null,
    tags: ['colorful', 'fresh', 'healthy', 'balanced', 'protein'],
    allergens: [],
    dietaryLabels: ['halal', 'high_protein', 'gluten_free'],
    protein: 30,
    prepStyle: 'grilled',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('chicken breast', '180g'),
      ingredient('mango', '100g'),
      ingredient('mixed greens', '80g'),
      ingredient('cherry tomatoes', '60g'),
      ingredient('olive oil', '1tbsp'),
      ingredient('lime juice', '1tbsp'),
    ],
  },
  {
    mealName: 'Berry Smoothie Bowl',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Breakfast',
    description: 'Berry smoothie bowl topped with granola and chia seeds.',
    calories: 310,
    price: 130,
    mealPicture: null,
    tags: ['colorful', 'fresh', 'varied', 'healthy', 'light'],
    allergens: ['dairy'],
    dietaryLabels: ['vegetarian'],
    protein: 10,
    prepStyle: 'raw',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('mixed berries', '150g'),
      ingredient('banana', '1'),
      ingredient('Greek yogurt', '100g'),
      ingredient('granola', '30g'),
      ingredient('chia seeds', '1tsp'),
      ingredient('honey', 'drizzle'),
    ],
  },
  {
    mealName: 'Pasta with Fresh Tomato Sauce',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Main Course',
    description: 'Pasta with fresh tomato sauce and basil.',
    calories: 490,
    price: 170,
    mealPicture: null,
    tags: ['colorful', 'varied', 'fresh', 'balanced', 'healthy'],
    allergens: ['gluten'],
    dietaryLabels: ['vegetarian'],
    protein: 15,
    prepStyle: 'boiled',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('penne pasta', '150g'),
      ingredient('fresh tomatoes', '200g'),
      ingredient('basil leaves', 'few'),
      ingredient('garlic', '3 cloves'),
      ingredient('olive oil', '2tbsp'),
      ingredient('parmesan', '20g'),
    ],
  },
  {
    mealName: 'Spicy Chicken Stir Fry',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Main Course',
    description: 'Spicy chicken stir fry with peppers and ginger.',
    calories: 460,
    price: 190,
    mealPicture: null,
    tags: ['spicy', 'energetic', 'colorful', 'protein', 'pepper'],
    allergens: ['soy'],
    dietaryLabels: ['halal', 'high_protein', 'gluten_free'],
    protein: 34,
    prepStyle: 'fried',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('chicken', '200g'),
      ingredient('mixed peppers', '150g'),
      ingredient('chilli', '2'),
      ingredient('ginger', '1tbsp'),
      ingredient('soy sauce', '1tbsp'),
      ingredient('sesame oil', '1tsp'),
      ingredient('garlic', '4 cloves'),
    ],
  },
  {
    mealName: 'Seekh Kebab with Chutney',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Main Course',
    description: 'Seekh kebab with chutney for a punchy energetic meal.',
    calories: 520,
    price: 220,
    mealPicture: null,
    tags: ['spicy', 'energetic', 'novel', 'protein', 'pepper'],
    allergens: [],
    dietaryLabels: ['halal', 'high_protein'],
    protein: 38,
    prepStyle: 'grilled',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('minced beef', '250g'),
      ingredient('green chilli', '2'),
      ingredient('coriander', '2tbsp'),
      ingredient('cumin', '1tsp'),
      ingredient('garam masala', '1tsp'),
      ingredient('ginger garlic paste', '1tbsp'),
    ],
  },
  {
    mealName: 'Spicy Egg Fried Rice',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Main Course',
    description: 'Spicy egg fried rice with vegetables and spring onions.',
    calories: 480,
    price: 180,
    mealPicture: null,
    tags: ['spicy', 'energetic', 'varied', 'bright', 'pepper'],
    allergens: ['eggs', 'soy'],
    dietaryLabels: ['vegetarian'],
    protein: 18,
    prepStyle: 'fried',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('cooked rice', '200g'),
      ingredient('eggs', '2'),
      ingredient('mixed vegetables', '100g'),
      ingredient('chilli sauce', '1tbsp'),
      ingredient('soy sauce', '1tbsp'),
      ingredient('spring onions', 'few'),
    ],
  },
  {
    mealName: 'Chilli Prawn Skewers',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Snacks',
    description: 'Chilli prawn skewers with lime and garlic.',
    calories: 290,
    price: 160,
    mealPicture: null,
    tags: ['spicy', 'novel', 'bright', 'energetic', 'pepper', 'protein'],
    allergens: ['shellfish'],
    dietaryLabels: ['halal', 'gluten_free', 'high_protein'],
    protein: 28,
    prepStyle: 'grilled',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('prawns', '200g'),
      ingredient('red chilli', '2'),
      ingredient('lime juice', 'to taste'),
      ingredient('garlic', '3 cloves'),
      ingredient('olive oil', '1tbsp'),
      ingredient('paprika', '1tsp'),
    ],
  },
  {
    mealName: 'Warm Lentil Soup',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Soup',
    description: 'Warm lentil soup with herbs and a mild finish.',
    calories: 290,
    price: 100,
    mealPicture: null,
    tags: ['warm', 'herbal', 'mild', 'comfort_food', 'light', 'balanced'],
    allergens: [],
    dietaryLabels: ['vegetarian', 'vegan', 'halal'],
    protein: 16,
    prepStyle: 'boiled',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('red lentils', '150g'),
      ingredient('tomato', '1'),
      ingredient('onion', '1'),
      ingredient('cumin', '1tsp'),
      ingredient('turmeric', '0.5tsp'),
      ingredient('fresh coriander', 'few'),
      ingredient('olive oil', '1tbsp'),
    ],
  },
  {
    mealName: 'Mild Chicken Khichdi',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Main Course',
    description: 'Mild chicken khichdi for warm comfort.',
    calories: 380,
    price: 150,
    mealPicture: null,
    tags: ['warm', 'mild', 'comfort_food', 'light', 'herbal'],
    allergens: [],
    dietaryLabels: ['halal', 'gluten_free'],
    protein: 22,
    prepStyle: 'boiled',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('rice', '100g'),
      ingredient('yellow lentils', '80g'),
      ingredient('chicken pieces', '150g'),
      ingredient('cumin', '1tsp'),
      ingredient('turmeric', '0.5tsp'),
      ingredient('ghee', '1tsp'),
    ],
  },
  {
    mealName: 'Chamomile Honey Oat Bowl',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Breakfast',
    description: 'Chamomile honey oat bowl with a soft herbal note.',
    calories: 310,
    price: 120,
    mealPicture: null,
    tags: ['warm', 'herbal', 'mild', 'comfort_food', 'light', 'whole_grain'],
    allergens: [],
    dietaryLabels: ['vegetarian', 'vegan'],
    protein: 9,
    prepStyle: 'boiled',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('oats', '80g'),
      ingredient('chamomile tea brewed', '200ml'),
      ingredient('honey', '2tsp'),
      ingredient('cinnamon', 'pinch'),
      ingredient('banana', 'half'),
    ],
  },
  {
    mealName: 'Plain Daal with Roti',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Main Course',
    description: 'Plain daal with roti and gentle spices.',
    calories: 430,
    price: 140,
    mealPicture: null,
    tags: ['warm', 'mild', 'comfort_food', 'herbal', 'balanced'],
    allergens: ['gluten'],
    dietaryLabels: ['vegetarian', 'vegan', 'halal'],
    protein: 18,
    prepStyle: 'boiled',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('masoor daal', '150g'),
      ingredient('whole wheat roti', '2'),
      ingredient('onion', '1'),
      ingredient('tomato', '1'),
      ingredient('cumin', '1tsp'),
      ingredient('turmeric', '0.5tsp'),
      ingredient('oil', '1tbsp'),
    ],
  },
  {
    mealName: 'Grilled Salmon Fillet',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Main Course',
    description: 'Grilled salmon fillet with lemon, dill, and garlic.',
    calories: 440,
    price: 240,
    mealPicture: null,
    tags: ['healthy', 'fresh', 'light', 'balanced', 'protein', 'omega3'],
    allergens: ['fish'],
    dietaryLabels: ['halal', 'gluten_free', 'high_protein', 'low_fat'],
    protein: 38,
    prepStyle: 'grilled',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('salmon fillet', '220g'),
      ingredient('lemon', '1'),
      ingredient('olive oil', '1tsp'),
      ingredient('dill', '1tsp'),
      ingredient('garlic', '2 cloves'),
    ],
  },
  {
    mealName: 'Vegetable Brown Rice Bowl',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Healthy',
    description: 'Vegetable brown rice bowl with chickpeas and tahini.',
    calories: 390,
    price: 160,
    mealPicture: null,
    tags: ['balanced', 'fresh', 'whole_grain', 'fiber', 'colorful', 'healthy'],
    allergens: [],
    dietaryLabels: ['vegetarian', 'vegan', 'halal'],
    protein: 12,
    prepStyle: 'steamed',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('brown rice', '150g'),
      ingredient('roasted vegetables', '200g'),
      ingredient('chickpeas', '100g'),
      ingredient('tahini', '1tbsp'),
      ingredient('lemon juice', 'to taste'),
    ],
  },
  {
    mealName: 'Plain Greek Yogurt with Fruit',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Breakfast',
    description: 'Plain Greek yogurt with fruit and chia seeds.',
    calories: 220,
    price: 100,
    mealPicture: null,
    tags: ['fresh', 'plain', 'light', 'balanced', 'healthy'],
    allergens: ['dairy'],
    dietaryLabels: ['vegetarian', 'gluten_free'],
    protein: 12,
    prepStyle: 'raw',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('Greek yogurt', '200g'),
      ingredient('mixed fruit', '100g'),
      ingredient('honey', '1tsp'),
      ingredient('chia seeds', '1tsp'),
    ],
  },
  {
    mealName: 'Whole Wheat Toast with Avocado',
    kitchenName: 'FuelUp Sample Kitchen',
    cheffId: 'system_seed',
    category: 'Breakfast',
    description: 'Whole wheat toast with avocado and cherry tomatoes.',
    calories: 360,
    price: 140,
    mealPicture: null,
    tags: ['fresh', 'healthy', 'balanced', 'light', 'whole_grain'],
    allergens: ['gluten'],
    dietaryLabels: ['vegetarian', 'vegan'],
    protein: 10,
    prepStyle: 'raw',
    autoTagged: true,
    autoTagModel: 'manual_seed',
    available: true,
    recipie: [
      ingredient('whole wheat bread', '2 slices'),
      ingredient('avocado', '1'),
      ingredient('cherry tomatoes', '50g'),
      ingredient('lemon juice', 'to taste'),
      ingredient('salt', 'to taste'),
      ingredient('black pepper', 'to taste'),
      ingredient('chilli flakes', 'optional'),
    ],
  },
];

async function mealExistsByName(mealName) {
  const snapshot = await kitchenMeals.where('mealName', '==', mealName).limit(1).get();
  return !snapshot.empty;
}

async function seedMeals() {
  let inserted = 0;
  let skipped = 0;

  for (const meal of meals) {
    const exists = await mealExistsByName(meal.mealName);

    if (exists) {
      console.log(`EXISTS: ${meal.mealName} - skipped`);
      skipped += 1;
      continue;
    }

    await kitchenMeals.add(meal);
    console.log(`INSERTED: ${meal.mealName}`);
    inserted += 1;
  }

  // MIGRATION: backfill available:true on any already-seeded docs
  // that were inserted before this field existed.
  console.log('\nRunning availability migration...');
  const snapshot = await kitchenMeals
    .where('available', '==', null)
    .get()
    .catch(() => null);

  // Firestore does not support where('field', '==', null) reliably.
  // Instead fetch all docs missing the field using a direct scan.
  const allDocs = await kitchenMeals.get();
  let migrated = 0;
  const batch = db.batch();
  allDocs.forEach(doc => {
    const data = doc.data();
    if (data.available === undefined || data.available === null) {
      batch.update(doc.ref, { available: true });
      migrated++;
    }
  });
  if (migrated > 0) {
    await batch.commit();
    console.log(`Migration: set available=true on ${migrated} existing docs.`);
  } else {
    console.log('Migration: no docs needed backfill.');
  }

  console.log(
    `Done. Inserted: ${inserted} | Skipped: ${skipped} | Migrated: ${migrated}`
  );
}

seedMeals().catch((error) => {
  console.error(`Fatal error: ${error.message}`);
  process.exit(1);
});
