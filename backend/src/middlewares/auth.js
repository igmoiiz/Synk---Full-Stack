const jwt = require('jsonwebtoken');
module.exports = function (req, res, next) {
    const authHeader = req.headers.authorization;
    const token = authHeader && authHeader.split(" ")[1];

    if(!token) return res.status(401).json({error: "Access Denied"});
    
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = decoded;
        next();

    } catch(err){
        return res.status(403).json({ error: err.message && " Invalid Token"});
    }
}