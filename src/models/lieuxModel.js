const db = require('../config/db');  // Assurez-vous d'importer votre configuration de base de données

// Ajouter un lieu proposé
const ajouterLieu = async (nom, amenity, latitude, longitude, userId) => {
  const query = `
    INSERT INTO lieux_proposes (nom, amenity, latitude, longitude, propose_par)
    VALUES ($1, $2, $3, $4, $5) RETURNING id;
  `;
  const values = [nom, amenity, latitude, longitude, userId];
  const result = await db.query(query, values);
  return result.rows[0].id;  // Retourne l'id du lieu ajouté
};

// Ajouter une demande de suppression
const demanderSuppression = async (osm_id, userId) => {
  const query = `
    INSERT INTO demandes_suppression (osm_id, propose_par)
    VALUES ($1, $2) RETURNING id;
  `;
  const values = [osm_id, userId];
  const result = await db.query(query, values);
  return result.rows[0].id;  // Retourne l'id de la demande de suppression
};

// Voter pour l'ajout d'un lieu
const voterAjout = async (idLieu, userId, vote) => {
  const query = `
    INSERT INTO validations_lieux (id_lieu, id_utilisateur, vote)
    VALUES ($1, $2, $3) ON CONFLICT (id_lieu, id_utilisateur) DO UPDATE SET vote = $3;
  `;
  const values = [idLieu, userId, vote];
  await db.query(query, values);
};

// Voter pour la suppression d'un lieu
const voterSuppression = async (idDemande, userId, vote) => {
  const query = `
    INSERT INTO validations_suppression (id_demande, id_utilisateur, vote)
    VALUES ($1, $2, $3) ON CONFLICT (id_demande, id_utilisateur) DO UPDATE SET vote = $3;
  `;
  const values = [idDemande, userId, vote];
  await db.query(query, values);
};


module.exports = {
  ajouterLieu,
  demanderSuppression,
  voterAjout,
  voterSuppression
};
