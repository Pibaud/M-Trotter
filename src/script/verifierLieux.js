require('dotenv').config();
const db = require('../config/db');
const sendEmail = require('../config/email');
const { log } = Math;

const calculerValeurUtilisateur = (fiabilite) => {
    if (fiabilite < 0) return 1 / -fiabilite;
    return (fiabilite + 1) / log(fiabilite + 3);
};

const getLieuxProposes = async (type) => {
    const table = type === 'ajout' ? 'lieux_proposes' : 'demandes_suppression';
    const result = await db.query(`
        SELECT osm_id, propose_par 
        FROM ${table} 
        WHERE etat = 'pending' 
        AND date_ajout <= NOW() - INTERVAL '7 days'
    `);
    return result.rows;
};

const getVotes = async (id_lieu, type) => {
    const result = await db.query(`
        SELECT v.vote, u.fiabilite 
        FROM validation_${type} v
        JOIN users u ON v.id_utilisateur = u.id
        WHERE v.osm_id = $1
    `, [id_lieu]);
    return result.rows;
};

const updateEtat = async (type, id_lieu, etat) => {
    const table = type === 'ajout' ? 'lieux_proposes' : 'demandes_suppression';
    await db.query(`UPDATE ${table} SET etat = $1 WHERE osm_id = $2`, [etat, id_lieu]);
};

const getUserAndLieu = async (id_lieu, type) => {
    const table = type === 'ajout' ? 'lieux_proposes' : 'demandes_suppression';
    const result = await db.query(`
        SELECT u.email, l.nom AS nomlieu 
        FROM users u 
        JOIN ${table} l ON u.id = l.propose_par 
        WHERE l.osm_id = $1
    `, [id_lieu]);
    return result.rows[0];
};

const verifierLieux = async () => {
    try {
        for (const type of ['ajout', 'suppression']) {
            const demandes = await getLieuxProposes(type);

            for (const { id_lieu, propose_par } of demandes) {
                const votes = await getVotes(id_lieu, type);

                if (votes.length < 20) {
                    await updateEtat(type, id_lieu, 'refusee');
                    continue;
                }

                let score = votes.reduce((total, { vote, fiabilite }) => {
                    return total + (vote === 'confirm' ? calculerValeurUtilisateur(fiabilite) : -calculerValeurUtilisateur(fiabilite));
                }, 0);

                const etatFinal = score > 0 ? 'validee' : 'refusee';
                await updateEtat(type, id_lieu, etatFinal);

                const { email, nomlieu } = await getUserAndLieu(id_lieu, type);
                const action = type === 'ajout' ? "ajouté" : "supprimé";
                const subject = `M'trotter - Demande de ${type}`;
                const text = `Bonjour, votre demande de ${type} pour le lieu ${nomlieu} a été ${etatFinal} !`;
                const html = `<p>Bonjour,</p><p>Votre demande de ${type} pour le lieu <strong>${nomlieu}</strong> a été <strong>${etatFinal}</strong>.</p>`;

                await sendEmail(email, subject, text, html);
            }
        }
        console.log("✅ Vérification des ajouts et suppressions terminée.");
    } catch (error) {
        console.error("❌ Erreur dans la vérification des lieux :", error);
    }
};

// Exécuter le script si lancé directement
if (require.main === module) {
    (async () => {
        console.log("🔍 Vérification des ajouts et suppressions en cours...");
        await verifierLieux();
        process.exit(0);
    })();
}

module.exports = verifierLieux;
