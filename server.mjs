import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const PORT = Number(process.env.PORT || 3000);

const MIME_TYPES = {
  ".html": "text/html; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".js": "application/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon",
  ".webp": "image/webp"
};

const QUEUE_TIMES_PARK_URLS = {
  magicKingdom: "https://queue-times.com/parks/6/queue_times.json",
  epcot: "https://queue-times.com/parks/5/queue_times.json",
  animalKingdom: "https://queue-times.com/parks/8/queue_times.json",
  hollywoodStudios: "https://queue-times.com/parks/7/queue_times.json"
};

const DISNEY_RIDES = [
  { parkKey: "magicKingdom", rideId: 138, label: "Space Mountain" },
  { parkKey: "epcot", rideId: 159, label: "Spaceship Earth" },
  { parkKey: "animalKingdom", rideId: 110, label: "Expedition Everest" },
  { parkKey: "hollywoodStudios", rideId: 123, label: "Tower of Terror" }
];

function sendJson(res, statusCode, payload) {
  res.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    "Access-Control-Allow-Origin": "*"
  });
  res.end(JSON.stringify(payload));
}

function flattenParkRides(data) {
  const topLevelRides = Array.isArray(data?.rides) ? data.rides : [];
  const landRides = Array.isArray(data?.lands)
    ? data.lands.flatMap((land) => Array.isArray(land?.rides) ? land.rides : [])
    : [];
  return [...topLevelRides, ...landRides];
}

function formatRideWait(ride) {
  if (!ride) return "--";
  if (ride.is_open === false) return "Closed";
  if (typeof ride.wait_time === "number") return `${ride.wait_time} min`;
  return "--";
}

async function handleDisneyWaits(res) {
  try {
    const parkEntries = await Promise.all(
      Object.entries(QUEUE_TIMES_PARK_URLS).map(async ([parkKey, url]) => {
        const resp = await fetch(url, {
          headers: {
            "User-Agent": "PocketSteak Command Center"
          }
        });
        if (!resp.ok) {
          throw new Error(`Queue-Times request failed for ${parkKey}: ${resp.status}`);
        }
        const data = await resp.json();
        return [parkKey, flattenParkRides(data)];
      })
    );

    const ridesByPark = new Map(parkEntries);
    const rides = DISNEY_RIDES.map((rideConfig) => {
      const parkRides = ridesByPark.get(rideConfig.parkKey) || [];
      const ride = parkRides.find((entry) => Number(entry.id) === rideConfig.rideId);
      return {
        label: rideConfig.label,
        wait: formatRideWait(ride),
        rideId: rideConfig.rideId,
        parkKey: rideConfig.parkKey
      };
    });

    sendJson(res, 200, {
      source: "queue-times",
      updatedAt: new Date().toISOString(),
      rides
    });
  } catch (error) {
    console.error(error);
    sendJson(res, 502, {
      error: "Failed to load Disney wait times."
    });
  }
}

function resolveFilePath(urlPath) {
  const cleanPath = decodeURIComponent(urlPath.split("?")[0]);
  const safePath = cleanPath.replace(/^\/+/, "");
  let filePath = path.join(__dirname, safePath || "index.html");

  if (!path.extname(filePath)) {
    filePath = path.join(filePath, "index.html");
  }

  return filePath;
}

async function handleStatic(req, res) {
  try {
    let filePath = resolveFilePath(req.url || "/");
    if (!filePath.startsWith(__dirname)) {
      res.writeHead(403);
      res.end("Forbidden");
      return;
    }

    let data;
    try {
      data = await readFile(filePath);
    } catch {
      if (!path.extname(filePath)) {
        throw new Error("Not found");
      }
      const fallback = path.join(path.dirname(filePath), "index.html");
      filePath = fallback;
      data = await readFile(filePath);
    }

    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || "application/octet-stream";
    res.writeHead(200, { "Content-Type": contentType });
    res.end(data);
  } catch {
    res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
    res.end("Not found");
  }
}

const server = createServer(async (req, res) => {
  if (!req.url) {
    res.writeHead(400);
    res.end("Bad request");
    return;
  }

  if (req.url.startsWith("/api/disney-waits")) {
    await handleDisneyWaits(res);
    return;
  }

  await handleStatic(req, res);
});

server.listen(PORT, () => {
  console.log(`PocketSteak Apps Hub running at http://localhost:${PORT}`);
});
