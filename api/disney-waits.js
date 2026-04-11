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

module.exports = async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Cache-Control", "s-maxage=120, stale-while-revalidate=300");

  try {
    const parkEntries = await Promise.all(
      Object.entries(QUEUE_TIMES_PARK_URLS).map(async ([parkKey, url]) => {
        const response = await fetch(url, {
          headers: {
            "User-Agent": "PocketSteak Command Center"
          }
        });

        if (!response.ok) {
          throw new Error(`Queue-Times request failed for ${parkKey}: ${response.status}`);
        }

        const data = await response.json();
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

    res.status(200).json({
      source: "queue-times",
      updatedAt: new Date().toISOString(),
      rides
    });
  } catch (error) {
    console.error(error);
    res.status(502).json({
      error: "Failed to load Disney wait times."
    });
  }
};
