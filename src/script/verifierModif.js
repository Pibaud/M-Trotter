const db = require('../config/db');
const sendEmail = require('../config/email');
const { log } = Math;

const calculerValeurUtilisateur = (fiabilite) => {
    if (fiabilite < 0) return 1 / -fiabilite;
    return (fiabilite + 1) / log(fiabilite + 3);
};

const verifierModifications = async () => {
    try {
        const modifications = await db.query(`
            SELECT id_modification, propose_par, osm_id, champ_modifie, nouvelle_valeur
            FROM modifications
            WHERE etat = 'pending' AND date_proposition <= NOW() - INTERVAL '7 days'
        `);

        const rapport = {
            validees: [],
            refusees_score: [],
            refusees_nb: [],
        };

        for (const { id_modification, propose_par, osm_id, champ_modifie, nouvelle_valeur } of modifications.rows) {
            const votes = await db.query(`
                SELECT v.vote, v.id_utilisateur, u.fiabilite
                FROM validation_modification v
                JOIN users u ON v.id_utilisateur = u.id
                WHERE v.id_modification = $1
            `, [id_modification]);

            if (votes.rows.length < 20) {
                await db.query(`
                    UPDATE modifications SET etat = 'refusee' WHERE id_modification = $1
                `, [id_modification]);
                rapport.refusees_nb.push({ id_modification, raison: "pas assez de participants" });
                continue;
            }

            let score = 0;
            votes.rows.forEach(({ vote, fiabilite }) => {
                const valeur = calculerValeurUtilisateur(fiabilite);
                score += (vote === 'confirm' ? valeur : -valeur);
            });

            const nouveauEtat = score > 0 ? 'validee' : 'refusee';

            const userAndLieu = await db.query(`
                SELECT u.email, l.nom AS nomlieu
                FROM users u
                JOIN modifications m ON u.id = m.propose_par
                JOIN lieux l ON m.osm_id = l.id
                WHERE m.id_modification = $1
            `, [id_modification]);

            const { email, nomlieu } = userAndLieu.rows[0];

            const subject = "Demande de modification lieux M'trotter";
            let text, html;

            if (nouveauEtat === 'validee') {
                text = `Bonjour, votre demande de modification pour le lieu ${nomlieu} a été acceptée !`;
                html = `<p>Bonjour,</p>
                        <p>Votre modification pour le lieu <strong>${nomlieu}</strong> a été acceptée.</p>
                        <p>Merci pour votre contribution à M'trotter !</p>`;

                await db.query(`
                    UPDATE planet_osm_point
                    SET ${champ_modifie} = $1
                    WHERE id = $2
                `, [nouvelle_valeur, osm_id]);

                rapport.validees.push({ id_modification, score });
            } else {
                text = `Bonjour, votre demande de modification pour le lieu ${nomlieu} a été refusée !`;
                html = `<p>Bonjour,</p>
                        <p>Votre modification pour le lieu <strong>${nomlieu}</strong> a été refusée.</p>
                        <p>Merci pour votre contribution à M'trotter !</p>`;
                rapport.refusees_score.push({ id_modification, score });
            }

            await sendEmail(email, subject, text, html);

            await db.query('BEGIN');
            try {
                await db.query(`
                    UPDATE modifications SET etat = $1 WHERE id_modification = $2
                `, [nouveauEtat, id_modification]);

                const queries = votes.rows.map(({ vote, id_utilisateur }) => {
                    const bonChoix = (vote === 'confirm' && nouveauEtat === 'validee') ||
                                     (vote === 'infirme' && nouveauEtat === 'refusee');
                    return `WHEN id = ${id_utilisateur} THEN fiabilite + (${bonChoix ? 1 : -1})`;
                });

                if (queries.length > 0) {
                    await db.query(`
                        UPDATE users
                        SET fiabilite = CASE ${queries.join(" ")} END
                        WHERE id IN (${votes.rows.map(v => v.id_utilisateur).join(",")})
                    `);
                }

                await db.query('COMMIT');
            } catch (err) {
                await db.query('ROLLBACK');
                console.error(`Erreur transaction fiabilité pour modif ${id_modification} :`, err);
            }

            console.log(`Modification ${id_modification} => ${nouveauEtat}`);
        }

        // Génération du mail de rapport
        const htmlRapport = `
            <h2>Rapport hebdomadaire des modifications</h2>
            <h3>Modifications acceptées (${rapport.validees.length})</h3>
            <ul>${rapport.validees.map(r => `<li>ID ${r.id_modification} (score: ${r.score.toFixed(2)})</li>`).join('')}</ul>
            <h3>Modifications refusées - score insuffisant (${rapport.refusees_score.length})</h3>
            <ul>${rapport.refusees_score.map(r => `<li>ID ${r.id_modification} (score: ${r.score.toFixed(2)})</li>`).join('')}</ul>
            <h3>Modifications refusées - manque de participants (${rapport.refusees_nb.length})</h3>
            <ul>${rapport.refusees_nb.map(r => `<li>ID ${r.id_modification} (${r.raison})</li>`).join('')}</ul>
        `;

        await sendEmail("Thibaud.Paulin@gmail.com", "Rapport hebdo - Modifications M'trotter", "Voir rapport ci-joint", htmlRapport);

    } catch (error) {
        console.error("Erreur lors de la vérification des modifications :", error);
    }
};

module.exports = verifierModifications;
