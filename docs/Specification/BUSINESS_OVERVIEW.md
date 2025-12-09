# Business Overview

## Executive Summary

MealDeal is a location-based meal discovery platform that helps users find affordable meals based on real-time supermarket offers. The platform aggregates current deals from multiple supermarket chains, calculates optimal meal prices, and presents users with personalized recommendations based on their postal code.

## Business Model

### Value Proposition

**For End Users:**
- Save money by discovering meals that use ingredients currently on sale
- Save time by automatically calculating best prices instead of manual comparison
- Discover new recipes based on available deals
- Plan meals around current offers

**For Business:**
- Potential partnerships with supermarket chains
- Affiliate revenue from ingredient purchases
- Premium features (meal planning, shopping lists)
- Data insights on consumer preferences

### Target Market

**Primary Segment:**
- Budget-conscious home cooks (ages 25-45)
- Families looking to reduce grocery costs
- Meal planners who want to optimize shopping

**Secondary Segment:**
- Students and young professionals
- Health-conscious individuals
- Users interested in sustainable shopping

### Revenue Streams (Future)

1. **Freemium Model:**
   - Free: Basic dish browsing, limited favorites
   - Premium: Unlimited favorites, meal planning, shopping lists, price alerts

2. **Affiliate Marketing:**
   - Partner with supermarkets for referral commissions
   - Link to online grocery stores

3. **Data Insights:**
   - Anonymized consumer behavior data
   - Market research for food brands

## Market Opportunity

### Problem Size

- **Grocery Shopping:** Average household spends significant portion of income on food
- **Food Waste:** Consumers often buy ingredients that go unused
- **Time Constraint:** Manual price comparison is time-consuming
- **Offer Complexity:** Weekly offers change, difficult to track

### Competitive Advantage

1. **Real-Time Pricing:** Calculates prices based on current offers, not estimates
2. **Location-Specific:** Shows deals relevant to user's area
3. **Automated Calculation:** No manual price comparison needed
4. **Multi-Chain:** Aggregates offers from multiple supermarkets
5. **Recipe-Based:** Shows complete meals, not just ingredients

## User Personas

### Persona 1: "Budget-Conscious Mom" - Sarah

- **Age:** 35
- **Occupation:** Part-time teacher
- **Goals:** Feed family of 4 on a budget
- **Pain Points:** Grocery costs rising, limited time for meal planning
- **Use Case:** Finds 3-4 meals per week based on current deals, saves €20-30/week

### Persona 2: "Meal Prep Enthusiast" - Marcus

- **Age:** 28
- **Occupation:** Software developer
- **Goals:** Prepare healthy meals for the week, optimize costs
- **Pain Points:** Wants variety but also wants to save money
- **Use Case:** Plans weekly meals around offers, bulk purchases

### Persona 3: "Student" - Lisa

- **Age:** 22
- **Occupation:** University student
- **Goals:** Eat well on a tight budget
- **Pain Points:** Limited cooking skills, small budget
- **Use Case:** Finds quick, cheap meals with current offers

## Business Workflows

### User Acquisition Flow

1. **Discovery:** User finds MealDeal through search, social media, or referral
2. **Sign Up:** User creates account (email/password, optional username)
3. **Onboarding:** User enters postal code to see local deals
4. **First Discovery:** User browses dishes, sees savings potential
5. **Engagement:** User favorites dishes, views details, plans meals
6. **Retention:** User returns weekly to check new offers

### Data Collection Flow

1. **Offer Aggregation:** System collects offers from supermarket sources
2. **Data Import:** Admin imports CSV files with offer data
3. **Validation:** System validates offers (dates, prices, regions)
4. **Storage:** Offers stored in database with region mapping
5. **Calculation:** System calculates dish prices in real-time
6. **Display:** Users see updated prices automatically

### Content Management Flow

1. **Recipe Creation:** Admin/chef creates dish recipes
2. **Ingredient Mapping:** System maps dishes to ingredients
3. **Pricing Setup:** Baseline prices set for ingredients
4. **Offer Integration:** System matches offers to ingredients
5. **Price Calculation:** System calculates dish prices
6. **User Display:** Users see dishes with current pricing

## Key Metrics

### User Metrics
- **Active Users:** Daily/weekly active users
- **Retention Rate:** Users returning after first visit
- **Favorites Count:** Average favorites per user
- **PLZ Coverage:** Number of postal codes with active offers

### Business Metrics
- **Dish Views:** Number of dish detail page views
- **Offer Coverage:** Percentage of dishes with active offers
- **Average Savings:** Average savings per dish
- **User Savings:** Total savings calculated for users

### Technical Metrics
- **API Response Time:** Time to calculate dish prices
- **Database Query Performance:** Query execution times
- **CSV Import Success Rate:** Percentage of successful imports
- **Error Rate:** Application errors per session

## Growth Strategy

### Phase 1: Foundation (Current)
- Core functionality: Dish browsing, pricing, favorites
- Basic admin tools: CSV import
- Single region focus (Germany)

### Phase 2: Expansion
- Meal planning features
- Shopping list generation
- Mobile app
- Additional regions/countries

### Phase 3: Monetization
- Premium subscription tier
- Affiliate partnerships
- Advanced features (price alerts, meal suggestions)

### Phase 4: Scale
- API for third-party integrations
- White-label solutions
- Enterprise features for supermarkets

## Competitive Analysis

### Direct Competitors
- **Recipe Apps:** Focus on recipes, not pricing
- **Grocery Apps:** Focus on shopping, not meal planning
- **Deal Aggregators:** Show deals, not complete meals

### Differentiation
- **Meal-Centric:** Focus on complete meals, not individual ingredients
- **Real-Time Pricing:** Calculates actual prices, not estimates
- **Location-Aware:** Shows relevant deals for user's area
- **Savings-Focused:** Emphasizes money saved, not just deals

## Risk Analysis

### Technical Risks
- **Data Quality:** Incorrect offer data leads to wrong prices
- **Scalability:** Database performance with large offer volumes
- **API Reliability:** Supabase downtime affects user experience

### Business Risks
- **Data Sources:** Dependence on offer data availability
- **User Adoption:** Users may not see value in the platform
- **Competition:** Larger players may copy features

### Mitigation Strategies
- **Data Validation:** Multiple validation layers for imported data
- **Performance Optimization:** Database indexing, query optimization
- **User Feedback:** Regular user surveys, feature requests
- **Unique Features:** Focus on meal planning, not just deals

## Success Criteria

### Short-Term (3 months)
- 1,000+ registered users
- 500+ dishes in database
- 10,000+ offers imported
- 80%+ offer coverage for active regions

### Medium-Term (6 months)
- 10,000+ registered users
- 1,000+ dishes in database
- User retention rate > 40%
- Average user savings > €10/week

### Long-Term (12 months)
- 50,000+ registered users
- Premium subscription launch
- Partnership with 3+ supermarket chains
- Mobile app release

