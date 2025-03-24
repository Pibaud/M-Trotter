require('dotenv').config();
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
    host: "smtp.gmail.com", // Serveur SMTP de Gmail
    port: 587, // TLS = 587, SSL = 465
    secure: false, // false pour TLS, true pour SSL (avec port 465)
    auth: {
        user: process.env.EMAIL_USER, // Adresse Gmail
        pass: process.env.EMAIL_PASS  // Mot de passe d'application
    }
});

// Fonction pour envoyer un e-mail
const sendEmail = async (to, subject, text, html) => {
    try {
        const mailOptions = {
            from: '"M\'trotter" <noreply.mtrotter@gmail.com>',
            to,
            subject,
            text,
            html
        };
        await transporter.sendMail(mailOptions);
        console.log(`📧 Email envoyé à ${to}`);
    } catch (error) {
        console.error("❌ Erreur d'envoi d'email :", error);
    }
};

module.exports = sendEmail;
