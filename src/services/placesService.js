// Vérifie que LPlaces est bien exportée comme fonction
exports.LPlaces = async (Char) => {
    let ListeLieux = [
        "cavapizza", "tokyoburger", "mcdonaldsComedie", "leclocher", "laopportunite",
        "chezjeremie", "lepetitvieux", "lestroispoissons", "lestroisptitscochons", "l'atelierdesvins",
        "lestroiscuisines", "aucoeurdelamour", "restaurationlagrande", "lefrancais", "lebanian", 
        "lafontaine", "l'arome", "lalune", "lemediterraneen", "ledomaine", "lebijou", "lecharpentier", 
        "lemarocain", "laupieddecane", "lascoutade", "lacuisineparisienne", "legosier", "lamedina", 
        "lechefsouslesetoiles", "lapoissondansletoit", "lecoqchic", "lepainmolle", "laplanche", 
        "lepotagerdelamarguerite", "lecompte", "latablemontpellier", "laforgeron", "lenormand", "latraversee", 
        "lesbistrots", "lesconfidences", "lajoie", "lebourbon", "laveilleville", "l'atelierargentin", 
        "lavillegreen", "lestartle", "lecampanile", "lacaille", "laferme", "labrasserie", "laluneblanche"
    ];
    let rendu = [];
    for (let elem of ListeLieux) {
        let result = elem.slice(0, Char.length);
        if (result === Char) {
            rendu.push(elem);
            if (rendu.length >= 11) {
                break;  // Arrête la boucle une fois que la limite de 11 est atteinte
            }
        }
    }
    return rendu;
};
