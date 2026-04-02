// Quick recipe seed script (plain JS, no TypeScript compilation needed)
const { PrismaClient } = require('@prisma/client');
const { Pool } = require('pg');
const { PrismaPg } = require('@prisma/adapter-pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter, log: ['error', 'warn'] });

const recipes = [
  // ── New York ──
  {
    name: 'Classic New York Cheesecake',
    description: 'Rich and creamy cheesecake with a buttery graham cracker crust. A timeless NYC dessert.',
    prepTime: 30, cookTime: 60, servings: 12, calories: 410, protein: 7, carbs: 32, fat: 29,
    difficulty: 'INTERMEDIATE', dietaryTags: ['vegetarian'], cuisineType: 'AMERICAN', mealType: 'DESSERT',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'New York',
    latitude: 40.7128, longitude: -74.006,
    engagementLoves: 2840, engagementBookmarks: 1520, engagementViews: 18500,
    isViral: true, velocityScore: 92.5,
    ingredients: [
      { name: 'cream cheese', quantity: '900', unit: 'g', orderIndex: 0 },
      { name: 'sugar', quantity: '200', unit: 'g', orderIndex: 1 },
      { name: 'eggs', quantity: '4', unit: 'large', orderIndex: 2 },
      { name: 'sour cream', quantity: '240', unit: 'ml', orderIndex: 3 },
      { name: 'vanilla extract', quantity: '2', unit: 'tsp', orderIndex: 4 },
      { name: 'graham crackers', quantity: '200', unit: 'g', orderIndex: 5 },
      { name: 'butter', quantity: '75', unit: 'g', orderIndex: 6 },
    ],
    steps: [
      { orderIndex: 0, text: 'Preheat oven to 160°C (325°F). Crush graham crackers and mix with melted butter. Press into the bottom of a 9-inch springform pan.', duration: 600, techniqueTag: 'prep' },
      { orderIndex: 1, text: 'Beat cream cheese and sugar until smooth. Add eggs one at a time, mixing on low after each addition.', duration: 480, techniqueTag: 'mix' },
      { orderIndex: 2, text: 'Fold in sour cream and vanilla extract until just combined. Do not overmix.', duration: 120, techniqueTag: 'fold' },
      { orderIndex: 3, text: 'Pour filling over crust. Bake for 55-60 minutes until edges are set but center still jiggles slightly.', duration: 3600, techniqueTag: 'bake' },
      { orderIndex: 4, text: 'Turn off oven, crack the door, and let cheesecake cool inside for 1 hour. Refrigerate at least 4 hours before serving.', duration: 3600, techniqueTag: 'rest' },
    ],
  },
  {
    name: 'NYC Bacon Egg & Cheese on a Roll',
    description: 'The quintessential New York bodega breakfast sandwich. Crispy bacon, fluffy eggs, melted American cheese on a kaiser roll.',
    prepTime: 5, cookTime: 10, servings: 1, calories: 520, protein: 28, carbs: 35, fat: 30,
    difficulty: 'BEGINNER', dietaryTags: [], cuisineType: 'AMERICAN', mealType: 'BREAKFAST',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'New York',
    latitude: 40.7128, longitude: -74.006,
    engagementLoves: 3200, engagementBookmarks: 980, engagementViews: 22000,
    isViral: true, velocityScore: 95.0,
    ingredients: [
      { name: 'bacon', quantity: '3', unit: 'strips', orderIndex: 0 },
      { name: 'eggs', quantity: '2', unit: 'large', orderIndex: 1 },
      { name: 'American cheese', quantity: '2', unit: 'slices', orderIndex: 2 },
      { name: 'kaiser roll', quantity: '1', unit: 'piece', orderIndex: 3 },
      { name: 'butter', quantity: '1', unit: 'tbsp', orderIndex: 4 },
    ],
    steps: [
      { orderIndex: 0, text: 'Cook bacon in a skillet over medium heat until crispy. Set aside on paper towels.', duration: 360, techniqueTag: 'fry' },
      { orderIndex: 1, text: 'Scramble eggs in the bacon fat with a little butter. Season with salt and pepper.', duration: 120, techniqueTag: 'scramble' },
      { orderIndex: 2, text: 'Slice the kaiser roll and toast it lightly on the griddle.', duration: 60, techniqueTag: 'toast' },
      { orderIndex: 3, text: 'Layer eggs on the bottom roll, top with cheese slices and bacon. Close the roll.', duration: 30, techniqueTag: 'assemble' },
    ],
  },
  {
    name: 'Dollar Slice Pepperoni Pizza',
    description: 'Thin-crust, foldable New York-style pepperoni pizza. Crispy bottom, tangy sauce, stretchy mozzarella.',
    prepTime: 120, cookTime: 15, servings: 8, calories: 285, protein: 12, carbs: 33, fat: 12,
    difficulty: 'INTERMEDIATE', dietaryTags: [], cuisineType: 'ITALIAN', mealType: 'DINNER',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'New York',
    latitude: 40.7128, longitude: -74.006,
    engagementLoves: 1950, engagementBookmarks: 870, engagementViews: 14200,
    isViral: true, velocityScore: 85.0,
    ingredients: [
      { name: 'bread flour', quantity: '500', unit: 'g', orderIndex: 0 },
      { name: 'water', quantity: '325', unit: 'ml', orderIndex: 1 },
      { name: 'instant yeast', quantity: '5', unit: 'g', orderIndex: 2 },
      { name: 'crushed tomatoes', quantity: '400', unit: 'g', orderIndex: 3 },
      { name: 'mozzarella', quantity: '250', unit: 'g', orderIndex: 4 },
      { name: 'pepperoni', quantity: '100', unit: 'g', orderIndex: 5 },
    ],
    steps: [
      { orderIndex: 0, text: 'Mix flour, water, yeast, salt, and olive oil. Knead 8 minutes until smooth. Cover and rise 1.5 hours.', duration: 6000, techniqueTag: 'knead' },
      { orderIndex: 1, text: 'Preheat oven to maximum (260°C / 500°F) with a baking steel inside.', duration: 1800, techniqueTag: 'preheat' },
      { orderIndex: 2, text: 'Stretch dough into a thin 14-inch round. Spread sauce, top with mozzarella and pepperoni.', duration: 300, techniqueTag: 'assemble' },
      { orderIndex: 3, text: 'Bake 10-12 minutes until crust is golden and cheese is bubbly with charred spots.', duration: 720, techniqueTag: 'bake' },
    ],
  },

  // ── London ──
  {
    name: 'Full English Breakfast',
    description: 'The ultimate British fry-up: bacon, eggs, sausages, beans, toast, grilled tomatoes, and mushrooms.',
    prepTime: 10, cookTime: 25, servings: 2, calories: 780, protein: 42, carbs: 48, fat: 45,
    difficulty: 'BEGINNER', dietaryTags: [], cuisineType: 'BRITISH', mealType: 'BREAKFAST',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'London',
    latitude: 51.5074, longitude: -0.1278,
    engagementLoves: 2100, engagementBookmarks: 890, engagementViews: 15800,
    isViral: true, velocityScore: 88.0,
    ingredients: [
      { name: 'back bacon', quantity: '4', unit: 'rashers', orderIndex: 0 },
      { name: 'pork sausages', quantity: '4', unit: 'pieces', orderIndex: 1 },
      { name: 'eggs', quantity: '2', unit: 'large', orderIndex: 2 },
      { name: 'baked beans', quantity: '200', unit: 'g', orderIndex: 3 },
      { name: 'mushrooms', quantity: '100', unit: 'g', orderIndex: 4 },
      { name: 'tomatoes', quantity: '2', unit: 'halved', orderIndex: 5 },
      { name: 'bread', quantity: '2', unit: 'slices', orderIndex: 6 },
    ],
    steps: [
      { orderIndex: 0, text: 'Start sausages in a cold pan over medium heat. Cook 12-15 minutes, turning regularly.', duration: 900, techniqueTag: 'fry' },
      { orderIndex: 1, text: 'Add bacon. Fry 3-4 minutes each side. Add halved tomatoes and mushrooms.', duration: 480, techniqueTag: 'fry' },
      { orderIndex: 2, text: 'Heat baked beans in a small saucepan over low heat.', duration: 300, techniqueTag: 'simmer' },
      { orderIndex: 3, text: 'Fry eggs in butter. Toast the bread. Plate everything together.', duration: 180, techniqueTag: 'fry' },
    ],
  },
  {
    name: 'Chicken Tikka Masala',
    description: "Britain's unofficial national dish. Tender spiced chicken in a rich, creamy tomato sauce.",
    prepTime: 30, cookTime: 35, servings: 4, calories: 490, protein: 38, carbs: 18, fat: 28,
    difficulty: 'INTERMEDIATE', dietaryTags: ['gluten-free'], cuisineType: 'BRITISH', mealType: 'DINNER',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'London',
    latitude: 51.5074, longitude: -0.1278,
    engagementLoves: 3500, engagementBookmarks: 2100, engagementViews: 25000,
    isViral: true, velocityScore: 96.0,
    ingredients: [
      { name: 'chicken breast', quantity: '600', unit: 'g', orderIndex: 0 },
      { name: 'yogurt', quantity: '150', unit: 'g', orderIndex: 1 },
      { name: 'garam masala', quantity: '2', unit: 'tbsp', orderIndex: 2 },
      { name: 'crushed tomatoes', quantity: '400', unit: 'g', orderIndex: 3 },
      { name: 'heavy cream', quantity: '200', unit: 'ml', orderIndex: 4 },
      { name: 'onions', quantity: '2', unit: 'medium', orderIndex: 5 },
      { name: 'garlic', quantity: '4', unit: 'cloves', orderIndex: 6 },
      { name: 'ginger', quantity: '1', unit: 'inch', orderIndex: 7 },
      { name: 'butter', quantity: '30', unit: 'g', orderIndex: 8 },
    ],
    steps: [
      { orderIndex: 0, text: 'Marinate chicken in yogurt, garam masala, cumin, turmeric, salt and pepper. Refrigerate 30 minutes.', duration: 1800, techniqueTag: 'marinate' },
      { orderIndex: 1, text: 'Grill marinated chicken until charred and cooked through. Set aside.', duration: 600, techniqueTag: 'grill' },
      { orderIndex: 2, text: 'Melt butter, sauté onions until golden. Add garlic and ginger, cook 1 minute.', duration: 480, techniqueTag: 'sauté' },
      { orderIndex: 3, text: 'Add tomato paste and crushed tomatoes. Simmer 15 minutes until thickened.', duration: 900, techniqueTag: 'simmer' },
      { orderIndex: 4, text: 'Stir in cream and cooked chicken. Simmer 5 minutes. Serve with rice and naan.', duration: 300, techniqueTag: 'simmer' },
    ],
  },
  {
    name: 'Fish & Chips',
    description: 'Golden beer-battered cod with thick-cut chips. Served with mushy peas and malt vinegar.',
    prepTime: 20, cookTime: 30, servings: 4, calories: 680, protein: 32, carbs: 65, fat: 32,
    difficulty: 'INTERMEDIATE', dietaryTags: [], cuisineType: 'BRITISH', mealType: 'DINNER',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'London',
    latitude: 51.5074, longitude: -0.1278,
    engagementLoves: 1800, engagementBookmarks: 720, engagementViews: 12400,
    isViral: true, velocityScore: 82.0,
    ingredients: [
      { name: 'cod fillets', quantity: '4', unit: 'pieces', orderIndex: 0 },
      { name: 'flour', quantity: '200', unit: 'g', orderIndex: 1 },
      { name: 'beer', quantity: '250', unit: 'ml', orderIndex: 2 },
      { name: 'potatoes', quantity: '1', unit: 'kg', orderIndex: 3 },
      { name: 'vegetable oil', quantity: '1', unit: 'L', orderIndex: 4 },
    ],
    steps: [
      { orderIndex: 0, text: 'Cut potatoes into thick chips. Soak in cold water 30 minutes, pat dry.', duration: 2100, techniqueTag: 'prep' },
      { orderIndex: 1, text: 'Blanch chips at 130°C for 5-6 minutes. Drain and set aside.', duration: 480, techniqueTag: 'fry' },
      { orderIndex: 2, text: 'Mix flour, baking powder, salt, and cold beer into a smooth batter.', duration: 720, techniqueTag: 'mix' },
      { orderIndex: 3, text: 'Dip cod in batter, fry at 180°C for 6-7 minutes until golden.', duration: 480, techniqueTag: 'fry' },
      { orderIndex: 4, text: 'Return chips to 180°C oil, fry 3-4 minutes until crispy. Season with salt.', duration: 240, techniqueTag: 'fry' },
    ],
  },

  // ── Istanbul ──
  {
    name: 'Iskender Kebab',
    description: 'Thinly sliced döner over pide bread, drenched in tomato sauce and sizzling browned butter, with yogurt.',
    prepTime: 30, cookTime: 45, servings: 4, calories: 620, protein: 45, carbs: 38, fat: 30,
    difficulty: 'ADVANCED', dietaryTags: ['halal'], cuisineType: 'TURKISH', mealType: 'DINNER',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'Istanbul',
    latitude: 41.0082, longitude: 28.9784,
    engagementLoves: 2600, engagementBookmarks: 1800, engagementViews: 19500,
    isViral: true, velocityScore: 91.0,
    ingredients: [
      { name: 'lamb', quantity: '500', unit: 'g', orderIndex: 0 },
      { name: 'pide bread', quantity: '2', unit: 'pieces', orderIndex: 1 },
      { name: 'yogurt', quantity: '200', unit: 'g', orderIndex: 2 },
      { name: 'tomato paste', quantity: '2', unit: 'tbsp', orderIndex: 3 },
      { name: 'tomatoes', quantity: '3', unit: 'medium', orderIndex: 4 },
      { name: 'butter', quantity: '80', unit: 'g', orderIndex: 5 },
      { name: 'red pepper flakes', quantity: '1', unit: 'tsp', orderIndex: 6 },
    ],
    steps: [
      { orderIndex: 0, text: 'Season lamb slices with salt, pepper, cumin. Grill over high heat until charred.', duration: 360, techniqueTag: 'grill' },
      { orderIndex: 1, text: 'Make sauce: sauté onion and garlic, add tomatoes and tomato paste. Simmer 15 minutes.', duration: 1020, techniqueTag: 'simmer' },
      { orderIndex: 2, text: 'Cut pide into pieces. Layer on plate with grilled lamb and hot sauce.', duration: 180, techniqueTag: 'assemble' },
      { orderIndex: 3, text: 'Brown butter with red pepper flakes, pour sizzling over plate. Serve with yogurt.', duration: 120, techniqueTag: 'sauce' },
    ],
  },
  {
    name: 'Menemen',
    description: 'Turkish scrambled eggs simmered with tomatoes, green peppers, and spices. A breakfast staple.',
    prepTime: 5, cookTime: 15, servings: 2, calories: 280, protein: 14, carbs: 12, fat: 20,
    difficulty: 'BEGINNER', dietaryTags: ['vegetarian', 'gluten-free'], cuisineType: 'TURKISH', mealType: 'BREAKFAST',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'Istanbul',
    latitude: 41.0082, longitude: 28.9784,
    engagementLoves: 1400, engagementBookmarks: 650, engagementViews: 9800,
    isViral: true, velocityScore: 78.0,
    ingredients: [
      { name: 'eggs', quantity: '4', unit: 'large', orderIndex: 0 },
      { name: 'tomatoes', quantity: '3', unit: 'medium', orderIndex: 1 },
      { name: 'green peppers', quantity: '2', unit: 'pieces', orderIndex: 2 },
      { name: 'onions', quantity: '1', unit: 'small', orderIndex: 3 },
      { name: 'olive oil', quantity: '2', unit: 'tbsp', orderIndex: 4 },
      { name: 'red pepper flakes', quantity: '1', unit: 'tsp', orderIndex: 5 },
    ],
    steps: [
      { orderIndex: 0, text: 'Sauté diced onion and peppers in olive oil until softened, about 3 minutes.', duration: 240, techniqueTag: 'sauté' },
      { orderIndex: 1, text: 'Add grated tomatoes. Cook until thickened, about 8 minutes. Season with salt and red pepper flakes.', duration: 480, techniqueTag: 'simmer' },
      { orderIndex: 2, text: 'Crack eggs into the pan. Gently stir to create soft curds. Cook 2-3 minutes until just set.', duration: 180, techniqueTag: 'scramble' },
      { orderIndex: 3, text: 'Serve immediately in the pan with crusty bread.', duration: 30, techniqueTag: 'serve' },
    ],
  },
  {
    name: 'Lahmacun',
    description: 'Paper-thin Turkish flatbread topped with spiced minced meat, herbs, and vegetables.',
    prepTime: 40, cookTime: 8, servings: 6, calories: 320, protein: 18, carbs: 38, fat: 12,
    difficulty: 'INTERMEDIATE', dietaryTags: ['halal'], cuisineType: 'TURKISH', mealType: 'LUNCH',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'Istanbul',
    latitude: 41.0082, longitude: 28.9784,
    engagementLoves: 2200, engagementBookmarks: 1100, engagementViews: 16000,
    isViral: true, velocityScore: 87.0,
    ingredients: [
      { name: 'flour', quantity: '300', unit: 'g', orderIndex: 0 },
      { name: 'ground beef', quantity: '250', unit: 'g', orderIndex: 1 },
      { name: 'onions', quantity: '2', unit: 'medium', orderIndex: 2 },
      { name: 'tomatoes', quantity: '2', unit: 'medium', orderIndex: 3 },
      { name: 'parsley', quantity: '1', unit: 'bunch', orderIndex: 4 },
      { name: 'red pepper flakes', quantity: '1', unit: 'tbsp', orderIndex: 5 },
      { name: 'lemon', quantity: '1', unit: 'piece', orderIndex: 6 },
    ],
    steps: [
      { orderIndex: 0, text: 'Make dough: mix flour, water, salt, oil. Knead until smooth. Rest 30 minutes.', duration: 2100, techniqueTag: 'knead' },
      { orderIndex: 1, text: 'Mix ground meat with finely chopped vegetables, spices into a paste.', duration: 600, techniqueTag: 'mix' },
      { orderIndex: 2, text: 'Roll dough paper-thin into ovals. Spread meat mixture thinly over each.', duration: 900, techniqueTag: 'roll' },
      { orderIndex: 3, text: 'Bake at 250°C+ for 6-8 minutes until crispy. Roll with parsley and lemon.', duration: 480, techniqueTag: 'bake' },
    ],
  },

  // ── Paris ──
  {
    name: 'Croque Monsieur',
    description: 'The iconic French grilled ham and cheese sandwich with creamy béchamel and Gruyère.',
    prepTime: 15, cookTime: 15, servings: 2, calories: 520, protein: 28, carbs: 32, fat: 32,
    difficulty: 'BEGINNER', dietaryTags: [], cuisineType: 'FRENCH', mealType: 'LUNCH',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'Paris',
    latitude: 48.8566, longitude: 2.3522,
    engagementLoves: 1600, engagementBookmarks: 780, engagementViews: 11200,
    isViral: true, velocityScore: 80.0,
    ingredients: [
      { name: 'bread', quantity: '4', unit: 'slices', orderIndex: 0 },
      { name: 'ham', quantity: '4', unit: 'slices', orderIndex: 1 },
      { name: 'Gruyère cheese', quantity: '150', unit: 'g', orderIndex: 2 },
      { name: 'butter', quantity: '30', unit: 'g', orderIndex: 3 },
      { name: 'flour', quantity: '20', unit: 'g', orderIndex: 4 },
      { name: 'milk', quantity: '200', unit: 'ml', orderIndex: 5 },
    ],
    steps: [
      { orderIndex: 0, text: 'Make béchamel: melt butter, whisk in flour, gradually add milk until thick.', duration: 480, techniqueTag: 'sauce' },
      { orderIndex: 1, text: 'Spread béchamel on bread. Layer ham and half the Gruyère. Top with bread.', duration: 180, techniqueTag: 'assemble' },
      { orderIndex: 2, text: 'Spread more béchamel on top. Pile remaining Gruyère on top.', duration: 60, techniqueTag: 'assemble' },
      { orderIndex: 3, text: 'Bake at 200°C for 10-12 minutes until golden and bubbly.', duration: 720, techniqueTag: 'bake' },
    ],
  },
  {
    name: 'Ratatouille',
    description: 'Provençal vegetable stew with layers of zucchini, eggplant, tomatoes, and bell peppers.',
    prepTime: 30, cookTime: 60, servings: 6, calories: 180, protein: 4, carbs: 22, fat: 9,
    difficulty: 'INTERMEDIATE', dietaryTags: ['vegan', 'gluten-free'], cuisineType: 'FRENCH', mealType: 'DINNER',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'Paris',
    latitude: 48.8566, longitude: 2.3522,
    engagementLoves: 2400, engagementBookmarks: 1300, engagementViews: 17000,
    isViral: true, velocityScore: 89.0,
    ingredients: [
      { name: 'zucchini', quantity: '2', unit: 'medium', orderIndex: 0 },
      { name: 'eggplant', quantity: '1', unit: 'large', orderIndex: 1 },
      { name: 'bell peppers', quantity: '2', unit: 'pieces', orderIndex: 2 },
      { name: 'tomatoes', quantity: '4', unit: 'medium', orderIndex: 3 },
      { name: 'onions', quantity: '1', unit: 'large', orderIndex: 4 },
      { name: 'garlic', quantity: '4', unit: 'cloves', orderIndex: 5 },
      { name: 'olive oil', quantity: '60', unit: 'ml', orderIndex: 6 },
      { name: 'thyme', quantity: '4', unit: 'sprigs', orderIndex: 7 },
      { name: 'basil', quantity: '1', unit: 'bunch', orderIndex: 8 },
    ],
    steps: [
      { orderIndex: 0, text: 'Sauté onion and peppers. Add garlic. Cook 1 minute.', duration: 480, techniqueTag: 'sauté' },
      { orderIndex: 1, text: 'Add diced tomatoes. Simmer 10 minutes. Spread in oven dish.', duration: 720, techniqueTag: 'simmer' },
      { orderIndex: 2, text: 'Arrange thin zucchini and eggplant slices in a spiral over the sauce.', duration: 600, techniqueTag: 'assemble' },
      { orderIndex: 3, text: 'Cover and bake at 190°C for 40 minutes, then uncover for 15 more.', duration: 3300, techniqueTag: 'bake' },
    ],
  },

  // ── Tokyo ──
  {
    name: 'Tonkotsu Ramen',
    description: 'Rich, milky pork bone broth ramen with chashu pork, soft-boiled egg, and green onions.',
    prepTime: 30, cookTime: 720, servings: 4, calories: 650, protein: 38, carbs: 62, fat: 28,
    difficulty: 'ADVANCED', dietaryTags: [], cuisineType: 'JAPANESE', mealType: 'DINNER',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'Tokyo',
    latitude: 35.6762, longitude: 139.6503,
    engagementLoves: 4100, engagementBookmarks: 2800, engagementViews: 32000,
    isViral: true, velocityScore: 98.0,
    ingredients: [
      { name: 'pork bones', quantity: '1.5', unit: 'kg', orderIndex: 0 },
      { name: 'pork belly', quantity: '500', unit: 'g', orderIndex: 1 },
      { name: 'ramen noodles', quantity: '400', unit: 'g', orderIndex: 2 },
      { name: 'eggs', quantity: '4', unit: 'large', orderIndex: 3 },
      { name: 'soy sauce', quantity: '100', unit: 'ml', orderIndex: 4 },
      { name: 'ginger', quantity: '1', unit: 'large piece', orderIndex: 5 },
      { name: 'garlic', quantity: '8', unit: 'cloves', orderIndex: 6 },
      { name: 'scallions', quantity: '4', unit: 'stalks', orderIndex: 7 },
    ],
    steps: [
      { orderIndex: 0, text: 'Blanch pork bones 10 minutes. Drain, rinse, scrub clean.', duration: 900, techniqueTag: 'blanch' },
      { orderIndex: 1, text: 'Simmer bones with ginger and garlic 10-12 hours, adding water as needed.', duration: 43200, techniqueTag: 'simmer' },
      { orderIndex: 2, text: 'Roll and sear pork belly. Braise in soy sauce mixture 2 hours.', duration: 7500, techniqueTag: 'braise' },
      { orderIndex: 3, text: 'Soft-boil eggs (6.5 min). Marinate in chashu braising liquid 2 hours.', duration: 7500, techniqueTag: 'boil' },
      { orderIndex: 4, text: 'Strain broth, season with soy and sesame oil. Assemble bowls with noodles, broth, chashu, egg, scallions.', duration: 600, techniqueTag: 'assemble' },
    ],
  },
  {
    name: 'Okonomiyaki',
    description: 'Savory Japanese cabbage pancake with special sauce and Kewpie mayo.',
    prepTime: 15, cookTime: 15, servings: 2, calories: 420, protein: 18, carbs: 45, fat: 19,
    difficulty: 'BEGINNER', dietaryTags: [], cuisineType: 'JAPANESE', mealType: 'DINNER',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'Tokyo',
    latitude: 35.6762, longitude: 139.6503,
    engagementLoves: 1800, engagementBookmarks: 920, engagementViews: 13500,
    isViral: true, velocityScore: 83.0,
    ingredients: [
      { name: 'cabbage', quantity: '300', unit: 'g', orderIndex: 0 },
      { name: 'flour', quantity: '100', unit: 'g', orderIndex: 1 },
      { name: 'eggs', quantity: '2', unit: 'large', orderIndex: 2 },
      { name: 'bacon', quantity: '4', unit: 'strips', orderIndex: 3 },
      { name: 'scallions', quantity: '2', unit: 'stalks', orderIndex: 4 },
      { name: 'Kewpie mayonnaise', quantity: '2', unit: 'tbsp', orderIndex: 5 },
    ],
    steps: [
      { orderIndex: 0, text: 'Shred cabbage. Mix flour, eggs, water, dashi into a batter. Fold in cabbage.', duration: 360, techniqueTag: 'mix' },
      { orderIndex: 1, text: 'Pour batter into a hot oiled pan. Lay bacon on top. Cook 5-6 minutes.', duration: 360, techniqueTag: 'fry' },
      { orderIndex: 2, text: 'Flip carefully. Cook another 5 minutes until crispy.', duration: 300, techniqueTag: 'fry' },
      { orderIndex: 3, text: 'Drizzle with sauce and Kewpie mayo. Top with bonito flakes.', duration: 60, techniqueTag: 'garnish' },
    ],
  },

  // ── Mexico City ──
  {
    name: 'Tacos al Pastor',
    description: 'Spit-grilled marinated pork tacos with pineapple, cilantro, and onion.',
    prepTime: 60, cookTime: 30, servings: 6, calories: 380, protein: 25, carbs: 35, fat: 16,
    difficulty: 'INTERMEDIATE', dietaryTags: [], cuisineType: 'MEXICAN', mealType: 'DINNER',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'Mexico City',
    latitude: 19.4326, longitude: -99.1332,
    engagementLoves: 3800, engagementBookmarks: 2200, engagementViews: 28000,
    isViral: true, velocityScore: 97.0,
    ingredients: [
      { name: 'pork shoulder', quantity: '800', unit: 'g', orderIndex: 0 },
      { name: 'dried guajillo chiles', quantity: '4', unit: 'pieces', orderIndex: 1 },
      { name: 'pineapple', quantity: '200', unit: 'g', orderIndex: 2 },
      { name: 'corn tortillas', quantity: '12', unit: 'pieces', orderIndex: 3 },
      { name: 'cilantro', quantity: '1', unit: 'bunch', orderIndex: 4 },
      { name: 'onions', quantity: '1', unit: 'medium', orderIndex: 5 },
      { name: 'lime', quantity: '2', unit: 'pieces', orderIndex: 6 },
    ],
    steps: [
      { orderIndex: 0, text: 'Toast and rehydrate guajillo chiles. Blend with achiote paste, vinegar, garlic into a marinade.', duration: 1200, techniqueTag: 'blend' },
      { orderIndex: 1, text: 'Slice pork thin. Coat in marinade and refrigerate at least 1 hour.', duration: 3600, techniqueTag: 'marinate' },
      { orderIndex: 2, text: 'Grill pork over high heat until charred. Chop finely. Grill pineapple slices.', duration: 900, techniqueTag: 'grill' },
      { orderIndex: 3, text: 'Warm tortillas. Pile pork, diced pineapple, onion, cilantro, lime.', duration: 360, techniqueTag: 'assemble' },
    ],
  },
  {
    name: 'Churros con Chocolate',
    description: 'Crispy fried dough sticks in cinnamon sugar with rich thick hot chocolate for dipping.',
    prepTime: 15, cookTime: 20, servings: 4, calories: 380, protein: 5, carbs: 48, fat: 20,
    difficulty: 'INTERMEDIATE', dietaryTags: ['vegetarian'], cuisineType: 'MEXICAN', mealType: 'DESSERT',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'Mexico City',
    latitude: 19.4326, longitude: -99.1332,
    engagementLoves: 2700, engagementBookmarks: 1400, engagementViews: 20000,
    isViral: true, velocityScore: 90.0,
    ingredients: [
      { name: 'flour', quantity: '150', unit: 'g', orderIndex: 0 },
      { name: 'butter', quantity: '60', unit: 'g', orderIndex: 1 },
      { name: 'eggs', quantity: '2', unit: 'large', orderIndex: 2 },
      { name: 'sugar', quantity: '100', unit: 'g', orderIndex: 3 },
      { name: 'cinnamon', quantity: '2', unit: 'tsp', orderIndex: 4 },
      { name: 'dark chocolate', quantity: '150', unit: 'g', orderIndex: 5 },
      { name: 'milk', quantity: '200', unit: 'ml', orderIndex: 6 },
    ],
    steps: [
      { orderIndex: 0, text: 'Boil water, butter, sugar, and salt. Stir in flour. Cool, then beat in eggs one at a time.', duration: 600, techniqueTag: 'mix' },
      { orderIndex: 1, text: 'Pipe 15cm strips into 180°C oil. Fry 3-4 minutes until golden.', duration: 600, techniqueTag: 'fry' },
      { orderIndex: 2, text: 'Roll hot churros in cinnamon sugar.', duration: 120, techniqueTag: 'coat' },
      { orderIndex: 3, text: 'Heat milk with chopped chocolate until smooth. Serve for dipping.', duration: 300, techniqueTag: 'melt' },
    ],
  },

  // ── Bangkok ──
  {
    name: 'Pad Thai',
    description: "Thailand's most famous stir-fried noodle dish with shrimp, tofu, peanuts, and tamarind sauce.",
    prepTime: 20, cookTime: 10, servings: 2, calories: 440, protein: 22, carbs: 52, fat: 18,
    difficulty: 'INTERMEDIATE', dietaryTags: ['gluten-free'], cuisineType: 'THAI', mealType: 'DINNER',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'Bangkok',
    latitude: 13.7563, longitude: 100.5018,
    engagementLoves: 3100, engagementBookmarks: 1900, engagementViews: 24000,
    isViral: true, velocityScore: 94.0,
    ingredients: [
      { name: 'rice noodles', quantity: '200', unit: 'g', orderIndex: 0 },
      { name: 'shrimp', quantity: '150', unit: 'g', orderIndex: 1 },
      { name: 'tofu', quantity: '100', unit: 'g', orderIndex: 2 },
      { name: 'eggs', quantity: '2', unit: 'large', orderIndex: 3 },
      { name: 'bean sprouts', quantity: '100', unit: 'g', orderIndex: 4 },
      { name: 'peanuts', quantity: '50', unit: 'g', orderIndex: 5 },
      { name: 'tamarind paste', quantity: '2', unit: 'tbsp', orderIndex: 6 },
      { name: 'fish sauce', quantity: '2', unit: 'tbsp', orderIndex: 7 },
      { name: 'lime', quantity: '1', unit: 'piece', orderIndex: 8 },
    ],
    steps: [
      { orderIndex: 0, text: 'Soak rice noodles in warm water 30 minutes. Mix tamarind, fish sauce, sugar for sauce.', duration: 1920, techniqueTag: 'prep' },
      { orderIndex: 1, text: 'Stir-fry tofu until golden. Add shrimp until pink.', duration: 240, techniqueTag: 'stir-fry' },
      { orderIndex: 2, text: 'Crack eggs in wok, scramble, add noodles and sauce. Toss 2-3 minutes.', duration: 180, techniqueTag: 'stir-fry' },
      { orderIndex: 3, text: 'Add bean sprouts and scallions. Toss briefly.', duration: 30, techniqueTag: 'toss' },
      { orderIndex: 4, text: 'Serve with crushed peanuts and lime wedges.', duration: 60, techniqueTag: 'garnish' },
    ],
  },

  // ── Seoul ──
  {
    name: 'Bibimbap',
    description: 'Korean rice bowl with sautéed vegetables, spicy gochujang, and a fried egg.',
    prepTime: 30, cookTime: 20, servings: 2, calories: 520, protein: 24, carbs: 68, fat: 16,
    difficulty: 'INTERMEDIATE', dietaryTags: ['gluten-free'], cuisineType: 'KOREAN', mealType: 'DINNER',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'Seoul',
    latitude: 37.5665, longitude: 126.978,
    engagementLoves: 2900, engagementBookmarks: 1700, engagementViews: 21000,
    isViral: true, velocityScore: 93.0,
    ingredients: [
      { name: 'rice', quantity: '300', unit: 'g', orderIndex: 0 },
      { name: 'spinach', quantity: '150', unit: 'g', orderIndex: 1 },
      { name: 'carrots', quantity: '1', unit: 'medium', orderIndex: 2 },
      { name: 'zucchini', quantity: '1', unit: 'small', orderIndex: 3 },
      { name: 'mushrooms', quantity: '100', unit: 'g', orderIndex: 4 },
      { name: 'eggs', quantity: '2', unit: 'large', orderIndex: 5 },
      { name: 'gochujang', quantity: '2', unit: 'tbsp', orderIndex: 6 },
      { name: 'sesame oil', quantity: '2', unit: 'tbsp', orderIndex: 7 },
    ],
    steps: [
      { orderIndex: 0, text: 'Cook rice. Blanch spinach, squeeze dry, season with sesame oil and salt.', duration: 900, techniqueTag: 'prep' },
      { orderIndex: 1, text: 'Sauté julienned carrots, zucchini, and mushrooms separately with salt.', duration: 600, techniqueTag: 'sauté' },
      { orderIndex: 2, text: 'Fry eggs sunny-side up in sesame oil.', duration: 180, techniqueTag: 'fry' },
      { orderIndex: 3, text: 'Assemble: rice in center, vegetables arranged around it, egg on top with gochujang.', duration: 150, techniqueTag: 'assemble' },
    ],
  },

  // ── Rome ──
  {
    name: 'Cacio e Pepe',
    description: 'Roman pasta perfection: pecorino, black pepper, and pasta water transformed into a silky sauce.',
    prepTime: 5, cookTime: 15, servings: 2, calories: 480, protein: 18, carbs: 58, fat: 20,
    difficulty: 'INTERMEDIATE', dietaryTags: ['vegetarian'], cuisineType: 'ITALIAN', mealType: 'DINNER',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'Rome',
    latitude: 41.9028, longitude: 12.4964,
    engagementLoves: 3600, engagementBookmarks: 2400, engagementViews: 27000,
    isViral: true, velocityScore: 96.5,
    ingredients: [
      { name: 'spaghetti', quantity: '200', unit: 'g', orderIndex: 0 },
      { name: 'Pecorino Romano', quantity: '150', unit: 'g', orderIndex: 1 },
      { name: 'black pepper', quantity: '2', unit: 'tbsp', orderIndex: 2 },
    ],
    steps: [
      { orderIndex: 0, text: 'Toast peppercorns, crack coarsely.', duration: 120, techniqueTag: 'toast' },
      { orderIndex: 1, text: 'Boil pasta 1 minute short of al dente. Reserve 2 cups pasta water.', duration: 600, techniqueTag: 'boil' },
      { orderIndex: 2, text: 'Mix grated Pecorino with pasta water into a smooth paste.', duration: 120, techniqueTag: 'mix' },
      { orderIndex: 3, text: 'Toss pasta with pepper and pasta water over medium-low heat.', duration: 120, techniqueTag: 'toss' },
      { orderIndex: 4, text: 'Off heat, add cheese paste. Toss vigorously for a creamy emulsion. Serve immediately.', duration: 120, techniqueTag: 'emulsify' },
    ],
  },

  // ── Mumbai ──
  {
    name: 'Butter Chicken (Murgh Makhani)',
    description: 'Tender tandoori-spiced chicken in a luscious tomato-butter sauce. Ultimate Indian comfort food.',
    prepTime: 30, cookTime: 40, servings: 4, calories: 510, protein: 36, carbs: 14, fat: 35,
    difficulty: 'INTERMEDIATE', dietaryTags: ['gluten-free'], cuisineType: 'INDIAN', mealType: 'DINNER',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'Mumbai',
    latitude: 19.076, longitude: 72.8777,
    engagementLoves: 3400, engagementBookmarks: 2000, engagementViews: 26000,
    isViral: true, velocityScore: 95.5,
    ingredients: [
      { name: 'chicken thighs', quantity: '600', unit: 'g', orderIndex: 0 },
      { name: 'yogurt', quantity: '100', unit: 'g', orderIndex: 1 },
      { name: 'butter', quantity: '60', unit: 'g', orderIndex: 2 },
      { name: 'crushed tomatoes', quantity: '400', unit: 'g', orderIndex: 3 },
      { name: 'heavy cream', quantity: '150', unit: 'ml', orderIndex: 4 },
      { name: 'garam masala', quantity: '2', unit: 'tsp', orderIndex: 5 },
      { name: 'garlic', quantity: '4', unit: 'cloves', orderIndex: 6 },
      { name: 'ginger', quantity: '1', unit: 'inch', orderIndex: 7 },
    ],
    steps: [
      { orderIndex: 0, text: 'Marinate chicken in yogurt, turmeric, chili, garam masala. Rest 30 minutes.', duration: 1800, techniqueTag: 'marinate' },
      { orderIndex: 1, text: 'Grill chicken until charred. Cut into pieces.', duration: 600, techniqueTag: 'grill' },
      { orderIndex: 2, text: 'Melt butter, sauté garlic and ginger. Add tomatoes, simmer 20 minutes.', duration: 1320, techniqueTag: 'simmer' },
      { orderIndex: 3, text: 'Blend sauce smooth. Stir in cream, sugar, fenugreek leaves.', duration: 180, techniqueTag: 'blend' },
      { orderIndex: 4, text: 'Add chicken to sauce. Simmer 10 minutes. Serve with naan.', duration: 600, techniqueTag: 'simmer' },
    ],
  },

  // ── Barcelona ──
  {
    name: 'Patatas Bravas',
    description: "Crispy fried potato cubes with smoky, spicy tomato sauce and garlic aioli. Spain's favorite tapa.",
    prepTime: 15, cookTime: 25, servings: 4, calories: 320, protein: 5, carbs: 38, fat: 18,
    difficulty: 'BEGINNER', dietaryTags: ['vegan', 'gluten-free'], cuisineType: 'SPANISH', mealType: 'APPETIZER',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'Barcelona',
    latitude: 41.3874, longitude: 2.1686,
    engagementLoves: 1900, engagementBookmarks: 850, engagementViews: 13000,
    isViral: true, velocityScore: 81.0,
    ingredients: [
      { name: 'potatoes', quantity: '600', unit: 'g', orderIndex: 0 },
      { name: 'olive oil', quantity: '100', unit: 'ml', orderIndex: 1 },
      { name: 'crushed tomatoes', quantity: '200', unit: 'g', orderIndex: 2 },
      { name: 'smoked paprika', quantity: '1', unit: 'tsp', orderIndex: 3 },
      { name: 'garlic', quantity: '3', unit: 'cloves', orderIndex: 4 },
      { name: 'mayonnaise', quantity: '100', unit: 'g', orderIndex: 5 },
    ],
    steps: [
      { orderIndex: 0, text: 'Cut potatoes into 3cm cubes. Parboil 8 minutes. Drain and steam dry.', duration: 660, techniqueTag: 'boil' },
      { orderIndex: 1, text: 'Make bravas sauce: sauté garlic, add tomatoes, paprika, cayenne. Simmer 10 min.', duration: 720, techniqueTag: 'simmer' },
      { orderIndex: 2, text: 'Make aioli: mix mayo with minced garlic and lemon juice.', duration: 120, techniqueTag: 'mix' },
      { orderIndex: 3, text: 'Fry potatoes until golden and crispy. Drizzle with bravas sauce and aioli.', duration: 660, techniqueTag: 'fry' },
    ],
  },

  // ── Vilnius ──
  {
    name: 'Cepelinai (Zeppelin Dumplings)',
    description: "Lithuania's national dish: massive potato dumplings stuffed with seasoned meat, served with sour cream.",
    prepTime: 45, cookTime: 30, servings: 4, calories: 580, protein: 25, carbs: 65, fat: 24,
    difficulty: 'ADVANCED', dietaryTags: ['gluten-free'], cuisineType: 'OTHER', mealType: 'DINNER',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'Vilnius',
    latitude: 54.6872, longitude: 25.2797,
    engagementLoves: 1100, engagementBookmarks: 620, engagementViews: 7500,
    isViral: true, velocityScore: 72.0,
    ingredients: [
      { name: 'potatoes', quantity: '1.5', unit: 'kg', orderIndex: 0 },
      { name: 'ground pork', quantity: '300', unit: 'g', orderIndex: 1 },
      { name: 'onions', quantity: '2', unit: 'medium', orderIndex: 2 },
      { name: 'sour cream', quantity: '200', unit: 'g', orderIndex: 3 },
      { name: 'bacon', quantity: '150', unit: 'g', orderIndex: 4 },
      { name: 'potato starch', quantity: '2', unit: 'tbsp', orderIndex: 5 },
    ],
    steps: [
      { orderIndex: 0, text: 'Grate 2/3 potatoes raw, boil 1/3. Squeeze raw potatoes dry. Mix together with starch.', duration: 1800, techniqueTag: 'prep' },
      { orderIndex: 1, text: 'Mix ground pork with diced onion, salt, and pepper for filling.', duration: 300, techniqueTag: 'mix' },
      { orderIndex: 2, text: 'Shape potato dough around filling into large zeppelin ovals.', duration: 900, techniqueTag: 'shape' },
      { orderIndex: 3, text: 'Simmer in salted water 25-30 minutes until they float.', duration: 1800, techniqueTag: 'boil' },
      { orderIndex: 4, text: 'Fry bacon until crispy. Serve dumplings with sour cream and bacon.', duration: 360, techniqueTag: 'fry' },
    ],
  },
  {
    name: 'Šaltibarščiai (Cold Beet Soup)',
    description: 'Vibrant pink Lithuanian cold soup made from kefir and beets. Refreshing summer classic.',
    prepTime: 20, cookTime: 30, servings: 4, calories: 220, protein: 8, carbs: 28, fat: 9,
    difficulty: 'BEGINNER', dietaryTags: ['vegetarian', 'gluten-free'], cuisineType: 'OTHER', mealType: 'LUNCH',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'Vilnius',
    latitude: 54.6872, longitude: 25.2797,
    engagementLoves: 800, engagementBookmarks: 420, engagementViews: 5200,
    isViral: true, velocityScore: 65.0,
    ingredients: [
      { name: 'beets', quantity: '3', unit: 'medium', orderIndex: 0 },
      { name: 'kefir', quantity: '500', unit: 'ml', orderIndex: 1 },
      { name: 'cucumber', quantity: '1', unit: 'large', orderIndex: 2 },
      { name: 'eggs', quantity: '3', unit: 'hard-boiled', orderIndex: 3 },
      { name: 'dill', quantity: '1', unit: 'large bunch', orderIndex: 4 },
      { name: 'potatoes', quantity: '4', unit: 'medium', orderIndex: 5 },
      { name: 'sour cream', quantity: '100', unit: 'g', orderIndex: 6 },
    ],
    steps: [
      { orderIndex: 0, text: 'Boil beets until tender (30 min). Cool, peel, grate. Save some cooking liquid.', duration: 2100, techniqueTag: 'boil' },
      { orderIndex: 1, text: 'Dice cucumber, chop dill, dice hard-boiled eggs.', duration: 300, techniqueTag: 'prep' },
      { orderIndex: 2, text: 'Mix grated beets with kefir and beet liquid. Add cucumber, dill, eggs. Season.', duration: 180, techniqueTag: 'mix' },
      { orderIndex: 3, text: 'Refrigerate until very cold. Boil potatoes separately.', duration: 3600, techniqueTag: 'chill' },
      { orderIndex: 4, text: 'Serve cold with sour cream and hot potatoes on the side.', duration: 60, techniqueTag: 'serve' },
    ],
  },

  // ── Marrakech ──
  {
    name: 'Chicken Tagine with Preserved Lemons',
    description: 'Slow-cooked Moroccan chicken with preserved lemons, olives, and fragrant spices.',
    prepTime: 20, cookTime: 60, servings: 4, calories: 420, protein: 35, carbs: 12, fat: 26,
    difficulty: 'INTERMEDIATE', dietaryTags: ['gluten-free', 'halal'], cuisineType: 'MOROCCAN', mealType: 'DINNER',
    imageStatus: 'COMPLETED', scrapedFrom: 'curated', location: 'Marrakech',
    latitude: 31.6295, longitude: -7.9811,
    engagementLoves: 1500, engagementBookmarks: 890, engagementViews: 10500,
    isViral: true, velocityScore: 79.0,
    ingredients: [
      { name: 'chicken thighs', quantity: '8', unit: 'pieces', orderIndex: 0 },
      { name: 'preserved lemon', quantity: '1', unit: 'large', orderIndex: 1 },
      { name: 'green olives', quantity: '150', unit: 'g', orderIndex: 2 },
      { name: 'onions', quantity: '2', unit: 'large', orderIndex: 3 },
      { name: 'garlic', quantity: '4', unit: 'cloves', orderIndex: 4 },
      { name: 'saffron', quantity: '1', unit: 'pinch', orderIndex: 5 },
      { name: 'cilantro', quantity: '1', unit: 'bunch', orderIndex: 6 },
      { name: 'olive oil', quantity: '3', unit: 'tbsp', orderIndex: 7 },
    ],
    steps: [
      { orderIndex: 0, text: 'Season chicken with salt, ginger, turmeric, saffron. Brown in olive oil.', duration: 600, techniqueTag: 'sear' },
      { orderIndex: 1, text: 'Sauté onions until golden. Add garlic. Return chicken to pot.', duration: 600, techniqueTag: 'sauté' },
      { orderIndex: 2, text: 'Add water halfway up. Add cilantro stems. Cover, simmer 40 minutes.', duration: 2400, techniqueTag: 'braise' },
      { orderIndex: 3, text: 'Add preserved lemon strips and olives. Cook 15 minutes uncovered.', duration: 900, techniqueTag: 'simmer' },
      { orderIndex: 4, text: 'Garnish with fresh cilantro. Serve with couscous.', duration: 60, techniqueTag: 'garnish' },
    ],
  },
];

async function main() {
  console.log('🍳 Seeding recipes...');

  let count = 0;
  for (const { ingredients, steps, ...data } of recipes) {
    const existing = await prisma.recipe.findFirst({
      where: { name: data.name, location: data.location },
    });
    if (existing) {
      console.log(`  ⏭  Skipping "${data.name}" (already exists)`);
      continue;
    }

    await prisma.recipe.create({
      data: {
        ...data,
        ingredients: { create: ingredients },
        steps: { create: steps },
      },
    });
    console.log(`  ✅ ${data.name} (${data.location})`);
    count++;
  }

  console.log(`\n✅ Seeded ${count} recipes across ${[...new Set(recipes.map(r => r.location))].length} cities`);
  console.log(`   Cities: ${[...new Set(recipes.map(r => r.location))].join(', ')}`);
}

main()
  .catch((e) => { console.error('❌ Seed failed:', e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); await pool.end(); });
