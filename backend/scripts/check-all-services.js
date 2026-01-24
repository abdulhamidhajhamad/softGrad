const mongoose = require('mongoose');

mongoose.connect('mongodb+srv://fordep:0592370454@weddingplanner.ledafad.mongodb.net/weddingPlanner')
  .then(async () => {
    console.log('Connected to MongoDB');
    
    const services = await mongoose.connection.db.collection('services')
      .find({ 'location.city': { $regex: 'Nablus', $options: 'i' } })
      .toArray();
    
    const byCategory = {};
    
    services.forEach(s => {
      if (!byCategory[s.category]) byCategory[s.category] = [];
      byCategory[s.category].push({
        name: s.serviceName,
        price: s.price,
        payType: s.payType,
        capacity: s.additionalInfo?.capacity || s.additionalInfo?.maxCapacity || 'N/A'
      });
    });
    
    console.log('\n========================================');
    console.log('SERVICES IN NABLUS - PRICE SUMMARY');
    console.log('========================================\n');
    
    Object.keys(byCategory).sort().forEach(cat => {
      console.log(`\n=== ${cat} (${byCategory[cat].length} services) ===`);
      byCategory[cat].forEach(s => {
        console.log(`  ${s.name}: ${s.price} ILS (${s.payType}) - Capacity: ${s.capacity}`);
      });
    });
    
    // Calculate realistic budget for 150 guests, 2 hours event
    console.log('\n\n========================================');
    console.log('CALCULATED PRICES FOR 150 GUESTS, 2 HOURS');
    console.log('========================================\n');
    
    Object.keys(byCategory).sort().forEach(cat => {
      console.log(`\n=== ${cat} ===`);
      byCategory[cat].forEach(s => {
        let calculatedPrice = s.price;
        if (s.payType === 'per person') {
          calculatedPrice = s.price * 150;
        } else if (s.payType === 'per hour') {
          calculatedPrice = s.price * 2;
        }
        console.log(`  ${s.name}: ${calculatedPrice} ILS (base: ${s.price} ${s.payType})`);
      });
    });
    
    await mongoose.disconnect();
    console.log('\nDone!');
  })
  .catch(err => {
    console.error('Error:', err);
    process.exit(1);
  });
