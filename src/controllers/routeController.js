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
    if (json["Status"]["Code"] !== "OK") {
        return "Problème pour trouver un itinéraire";
    }

    let res = [];
    const trips = json["trips"]["Trip"];

    for (let i = 0; i < trips.length; i++) {
        const elem = trips[i];
        let partis = [];

        for (let j = 0; j < elem["sections"]["Section"].length; j++) {
            const section = elem["sections"]["Section"][j];
            let sectionTrajet;

            if (section["Leg"]["TransportMode"] === 'WALK') {
                let cheminMarche = [];
                for (let k = 0; k < section["Leg"]["pathLinks"]["PathLink"].length; k++) {
                    cheminMarche.push(section["Leg"]["pathLinks"]["PathLink"][k]["Departure"]["Site"]["Position"]);
                }
                sectionTrajet = {
                    chemin_marche: cheminMarche,
                    arrivée: {
                        nom: section["Leg"]["Arrival"]["Site"]["Name"],
                        position: section["Leg"]["Arrival"]["Site"]["Position"]
                    },
                    durée: section["Leg"]["Duration"]
                };
            } else {
                let arretsTransports = [];
                for (let k = 0; k < section["PTRide"]["steps"]["Step"].length; k++) {
                    arretsTransports.push({
                        nom: section["PTRide"]["steps"]["Step"][k]["Arrival"]["StopPlace"]["Name"],
                        position: section["PTRide"]["steps"]["Step"][k]["Arrival"]["StopPlace"]["Position"]
                    });
                }
                sectionTrajet = {
                    ligne: section["PTRide"]["Line"]["Name"],
                    direction: section["PTRide"]["Destination"],
                    étapes_tram: arretsTransports,
                    arrivée: {
                        nom: section["PTRide"]["Arrival"]["StopPlace"]["Name"],
                        position: section["PTRide"]["Arrival"]["StopPlace"]["Position"]
                    },
                    durée: section["PTRide"]["Duration"]
                };
            }
            partis.push(sectionTrajet);
        }

        const trajet = {
            heure_de_départ: elem["DepartureTime"],
            heure_d_arrivée: elem["ArrivalTime"],
            distance: elem["Distance"],
            co2_économisé: elem["CarbonFootprint"]["CarCO2"] - elem["CarbonFootprint"]["TripCO2"],
            itinéraire: partis
        };
        res.push(trajet);
    }
    return res;
};
