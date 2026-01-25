const { MongoClient } = require('mongodb');

const uri = 'mongodb+srv://fordep:0592370454@weddingplanner.ledafad.mongodb.net/weddingPlanner';

async function main() {
    const client = new MongoClient(uri);
    await client.connect();
    const db = client.db();
    
    // Check Catering services in Nablus
    const catering = await db.collection('services').find({
        category: { $regex: 'Catering', $options: 'i' },
        'location.city': { $regex: 'Nablus', $options: 'i' }
    }).project({
        serviceName: 1,
        price: 1,
        payType: 1,
        category: 1
    }).toArray();
    
    console.log('=== CATERING SERVICES IN NABLUS ===');
    console.log(JSON.stringify(catering, null, 2));
    console.log(`Total: ${catering.length} services`);
    
    // Check all Catering services in all cities
    const allCatering = await db.collection('services').find({
        category: { $regex: 'Catering', $options: 'i' }
    }).project({
        serviceName: 1,
        price: 1,
        payType: 1,
        'location.city': 1
    }).toArray();
    
    console.log('\n=== ALL CATERING SERVICES ===');
    console.log(JSON.stringify(allCatering, null, 2));
    console.log(`Total: ${allCatering.length} services`);
    
    await client.close();
}

main().catch(console.error);
