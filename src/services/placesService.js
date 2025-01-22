// Vérifie que LPlaces est bien exportée comme fonction
const {ListeLieux} = require('../models/placesModel');

exports.LPlaces = async (Char) => {

  let ListeLieux = await ListeLieux();
    
  let rendu = [];
    
  for (let elem of ListeLieux) {
    let mot = true;
    let charIndex = 0;
      
    for (let le of elem) {
      if (le == Char[charIndex]) {
        charIndex++;
      }
      if (charIndex == Char.length) {
        break;
      }
    }
      
    if (charIndex != Char.length) {
        mot = false;
      }
      
    if (mot) {
      rendu.push(elem);
      if (rendu.length >= 11) {
        break; // Arrête la boucle une fois que la limite de 11 est atteinte
      }
    }
  }
  return rendu;
};
