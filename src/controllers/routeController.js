const { getRoute, getTransit } = require('../services/mapHopperService');
const { getLocationId } = require('../services/tamIdService');

console.log(typeof getRoute); // Devrait afficher "function"

exports.calculateRoute = async (req, res, next) => {
    try {
        const { startName, startLat, startLon, endName, endLat, endLon, mode, date, time } = req.query;

        // Vérification stricte uniquement pour les paramètres de localisation, nécessaires pour tous les modes
        if (!startLat || !startLon || !endLat || !endLon) {
            return res.status(400).json({ error: 'Missing required location parameters' });
        }

        console.log("Calculating route...");

        const start = [parseFloat(startLat), parseFloat(startLon)];
        const end = [parseFloat(endLat), parseFloat(endLon)];

        if (mode === 'transit') {
            // Vérification spécifique pour les paramètres nécessaires au mode transit
            if (!startName || !endName) {
                return res.status(400).json({ error: 'Missing parameters for transit mode' });
            }

            // Récupération des ID des lieux
            const startLocation = await getLocationId(startName, start[0], start[1]);
            const endLocation = await getLocationId(endName, end[0], end[1]);

            if (!startLocation || !endLocation) {
                return res.status(400).json({ error: 'Unable to find location IDs' });
            }

            // Appel du service de transport en commun avec les ID trouvés
            let transit = await getTransit(startLocation.id, endLocation.id, date, time, startLocation.pointType, endLocation.pointType);
            transit = rangeJson(transit);
            return res.status(200).json(transit);
        } else {
            // Calcul d'itinéraire pour les autres modes (ex: marche, vélo, voiture)
            const route = await getRoute(start, end, mode || 'foot');
            return res.status(200).json(route);
        }
    } catch (error) {
        next(error);
    }
};

function rangeJson(json) {
    if (json["Status"]["Code"] != "OK") {
        return "Problème pour touver un itinéraire";
    }
    res = [];
    trips = json["trips"]["Trip"];
    for (let i =0; i<trips.length; i++) {
        elem = trips[i];
        console.log("pour le ",i,"eme trajet : ",elem["sections"]["Section"]);
        partis = [];
        for (let j = 0; j<elem["sections"]["Section"].length; j++) {
            let sexion  = elem["sections"]["Section"][j];
            if (sexion["Leg"]["TransportMode"] == 'WALK'){
                console.log("cette partie est à pied : ", sexion["Leg"])
                chemins = [];
                for (let k = 0; k<sexion["Leg"]["pathLinks"]["PathLink"].length; k++) {
                    chemins.push(sexion["Leg"]["pathLinks"]["PathLink"][k]["Departure"]["Site"]["Position"]);
                }
                sexionparti = {
                    chemin : chemins,
                    arrivée : {nom : sexion["Leg"]["Arrival"]["Site"]["Name"], position : sexion["Leg"]["Arrival"]["Site"]["Position"]},
                    temps : sexion["Leg"]["Duration"]
                };
            } else {
                console.log("cette partie est en transit : ", sexion["PTRide"]["steps"]["Step"][0]["Arrival"]["StopPlace"])
                arrets = []
                for (let k = 0; k<sexion["PTRide"]["steps"]["Step"].length; k++){
                    arrets.push([sexion["PTRide"]["steps"]["Step"][k]["Arrival"]["StopPlace"]["Name"], sexion["PTRide"]["steps"]["Step"][k]["Arrival"]["StopPlace"]["Position"]])
                }
                sexionparti = {
                    ligne : sexion["PTRide"]["Line"]["Name"],
                    Sens : sexion["PTRide"]["Destination"],
                    étape : arrets,
                    arrivée : sexion["PTRide"]["Arrival"],
                    temps : sexion["PTRide"]["Duration"]
                }
            }
            partis.push(sexionparti);
        }
        trip = {
        "heure de départ : " :  elem["DepartureTime"],
        "heure d'arrivée : " : elem["ArrivalTime"],
        "distance : " : elem["Distance"],
        "co2 economisé : " : elem["CarbonFootprint"]["CarCO2"] - elem["CarbonFootprint"]["TripCO2"],
        "trajet : " : partis
        };
        res.push(trip);
    }
    console.log("res : ", res);
    return res;
};