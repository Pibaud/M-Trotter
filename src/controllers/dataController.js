exports.getData = (req, res) => {
    res.json({ message: "Hello, client! Voici des données du serveur." });
};

exports.postData = (req, res) => {
    const { data } = req.body;
    console.log("Données reçues du client :", data);
    res.json({ status: "Données bien reçues", receivedData: data });
};