const fs = require("fs");
const path = "d:/Abdulhamid/SoftGradu/Code/soft-grad/backend/src/booking/booking.service.ts";
let content = fs.readFileSync(path, "utf8");

const lines = content.split("\n");
let modified = false;

// Line 360 is the client bookingDate line
for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes("bookingDate: bookingObject.bookingDetails") && 
        lines[i].includes("إضافة التاريخ للمستخدم")) {
        // Check if isReviewed already added
        if (i + 1 < lines.length && lines[i + 1].includes("isReviewed")) {
            console.log("isReviewed already exists");
            break;
        }
        // Get indentation from the current line
        const indent = "                  ";
        const isReviewedLine = indent + "isReviewed: bookingObject.isReviewed || false, //  حالة الريفيو";
        lines.splice(i + 1, 0, isReviewedLine);
        modified = true;
        console.log("Added isReviewed after line " + (i+1));
        break;
    }
}

if (modified) {
    fs.writeFileSync(path, lines.join("\n"), "utf8");
    console.log("File updated");
} else {
    console.log("Not modified");
}
