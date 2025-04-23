const db = require('../config/db');
const sendEmail = require('../config/email');

const genererRapport = async () => {
    let rapport = "<h1>Rapport de vérification</h1>";

    const sections = [
        { type: 'ajout', table: 'lieux_propose' },
        { type: 'suppression', table: 'demande_suppressions' },
        { type: 'modification', table: 'modifications' }
    ];

    for (const { type, table } of sections) {
        let requete = `
            SELECT id_lieu, etat, score, date_ajout 
            FROM ${table} 
            WHERE etat IN ('validee', 'pending', 'refusee')
        `;
        
        if (type === 'modification') {
            requete = `
                SELECT id_modification AS id_lieu, etat, score, date_proposition AS date_ajout 
                FROM ${table} 
                WHERE etat IN ('validee', 'pending', 'refusee')
                AND date_proposition >= NOW() - INTERVAL '8 days'
            `;
        }
        
        const result = await db.query(requete);
        console.log("Résultats de la requête pour", table, ":", result.rows);
        if (result.rows.length > 0) {
            rapport += `<h2>${type.charAt(0).toUpperCase() + type.slice(1)}s</h2><ul>`;
            result.rows.forEach(({ id_lieu, etat, score }) => {
                let raison = "";
                if (etat === 'refusee') {
                    raison = score < 0 ? "(score négatif)" : "(pas assez de participants)";
                }
                rapport += `<li>ID: ${id_lieu}, Statut: ${etat}, Score: ${score} ${raison}</li>`;
            });
            rapport += "</ul>";
        }
    }

    return rapport;
};

const envoyerRapport = async () => {
    try {
        const rapportHTML = await genererRapport();
        const subject = "Rapport de vérification M'trotter";
        const text = "Veuillez consulter le rapport en HTML.";
        console.log("📄 Rapport généré :", rapportHTML);
        await sendEmail("Thibaud.Paulin@gmail.com", subject, text, rapportHTML);
        console.log("✅ Rapport envoyé avec succès.");
    } catch (error) {
        console.error("❌ Erreur lors de l'envoi du rapport :", error);
    }
};

module.exports = envoyerRapport;
