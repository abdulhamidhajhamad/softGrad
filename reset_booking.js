const { MongoClient, ObjectId } = require("mongodb");
async function run() {
    const client = new MongoClient("mongodb+srv://abdulhamid:0592370454@weddingplanner.yq50n6g.mongodb.net/");
    await client.connect();
    const db = client.db("test");
    
    // Reset isReviewed for the booking
    const result = await db.collection("bookings").updateOne(
        { _id: new ObjectId("6958927b4848c93a8da3731f") },
        { $set: { isReviewed: false } }
    );
    
    console.log("Updated:", result.modifiedCount);
    
    // Check the booking
    const booking = await db.collection("bookings").findOne({ _id: new ObjectId("6958927b4848c93a8da3731f") });
    console.log("isReviewed:", booking.isReviewed);
    console.log("serviceId:", booking.serviceId);
    
    await client.close();
}
run();
