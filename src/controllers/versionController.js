exports.getVersion = (req, res) => {
    const currentVersion = "1.0.0"; // Version actuelle (doit correspondre à celle du pubspec.yaml)
    res.status(200).json({ version: currentVersion });
};