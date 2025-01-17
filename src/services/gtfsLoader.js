const protobuf = require("protobufjs");

async function loadGTFSProto(filePath) {
  const root = await protobuf.load("path/to/gtfs-realtime.proto"); // Assurez-vous d'avoir le fichier proto
  const FeedMessage = root.lookupType("transit_realtime.FeedMessage");
  
  const fs = require("fs");
  const buffer = fs.readFileSync(filePath);
  const message = FeedMessage.decode(buffer);
  
  return FeedMessage.toObject(message, {
    enums: String,  // Convert enums to strings
    longs: String,  // Convert longs to strings
    defaults: true, // Include default values
    arrays: true,   // Populate empty arrays
    objects: true   // Populate empty objects
  });
}

module.exports = loadGTFSProto;
