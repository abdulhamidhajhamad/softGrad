const { MongoClient, ObjectId } = require("mongodb");
async function run() {
    const client = new MongoClient("mongodb+srv://abdulhamid:0592370454@weddingplanner.yq50n6g.mongodb.net/");
    await client.connect();
    const db = client.db("test");
    
    // Count all bookings
    const count = await db.collection("bookings").countDocuments();
    console.log("Total bookings in database:", count);
    
    // Find any booking
    const bookings = await db.collection("bookings").find({}).limit(3).toArray();
    bookings.forEach(b => {
        console.log("ID:", b._id.toString(), "| User:", b.userId?.toString(), "| Service:", b.serviceName, "| isReviewed:", b.isReviewed);
    });
    
    await client.close();
}
run();
