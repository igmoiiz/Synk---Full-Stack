//  Authentication Middleware for socket.io
module.exports = function (socket, next) {
    if (socket.handshake.auth && socket.handshake.auth.token) {
        jwt.verify(socket.handshake.auth.token, process.env.JWT_SECRET, (error, decoded) => {
            if (error)
                return next(new Error("Authentication Error"));
            
            socket.user = decoded;
            next();
        });
    } else {
        next(new Error("Authentication Error"));
    }
}