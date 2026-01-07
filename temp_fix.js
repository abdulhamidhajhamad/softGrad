const fs = require("fs");
const path = "d:/Abdulhamid/SoftGradu/Code/soft-grad/backend/src/booking/booking.service.ts";
let content = fs.readFileSync(path, "utf8");

const lines = content.split("\n");
let modified = false;
let inClientBlock = false;

for (let i = 0; i < lines.length; i++) {
    if (lines[i].includes("Client:") && lines[i].includes("status")) {
        inClientBlock = true;
    }
    if (inClientBlock && lines[i].includes("serviceName: bookingObject.serviceName")) {
        if (i + 1 < lines.length && lines[i+1].includes("status:") && !lines[i+1].includes("serviceId")) {
            const indent = lines[i+1].match(/^\s*/)[0];
            const serviceIdLine = indent + "serviceId: bookingObject.serviceId,";
            lines.splice(i + 1, 0, serviceIdLine);
            modified = true;
            console.log("Added serviceId after line " + (i+1));
            break;
        }
    }
}

if (modified) {
    fs.writeFileSync(path, lines.join("\n"), "utf8");
    console.log("File updated");
} else {
    console.log("Could not find location");
}
