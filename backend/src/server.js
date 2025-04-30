require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const multer = require('multer');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const http = require('http');
const socketIO = require('socket.io');

const User = require('./model/user');
const Message = require('./model/message');
const auth = require('./middlewares/auth');
const socketAuth = require('./middlewares/socketAuth');

const app = express();
const server = http.createServer(app);
const io = socketIO(server, {
  cors: {
    origin: "*", // Update this to your Flutter app's origin in production
    methods: ["GET", "POST"]
  }
});

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('uploads'));

const PORT = process.env.PORT || 8080;

//========================== MONGO DB CONNECTION
mongoose.connect(process.env.MONGO_URI)
    .then(() => {
        console.log("Connected to MongoDB.");
    })
    .catch((error) => {
        console.error("MongoDB connection error:", error);
    });

//========================== MULTER CONFIGURATION
const storage = multer.diskStorage({
    destination: function (_, __, cb) {
        const dir = "./uploads";
        if (!fs.existsSync(dir)) fs.mkdirSync(dir);
        cb(null, dir);
    },
    filename: function (_, file, cb) {
        const ext = path.extname(file.originalname);
        const name = `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`;
        cb(null, name);
    },
});

const fileFilter = function (req, file, cb) {
    const allowedTypes = ['image/jpeg', 'image/png'];
    if (allowedTypes.includes(file.mimetype)) cb(null, true);
    else cb(new Error("Only JPEG and PNG format for Images are Allowed"), false);
}

const upload = multer({ storage, fileFilter, limits: { fileSize: 5 * 1024 * 1024 } });

//========================== SOCKET.IO MIDDLEWARE

io.use(socketAuth);

// Store online users
const onlineUsers = new Map();

// Socket.IO connection handling
io.on('connection', (socket) => {
    console.log(`User connected: ${socket.user.id}`);
    
    // Add user to online users
    onlineUsers.set(socket.user.id, socket.id);
    
    // Emit online status to all users
    io.emit('userStatus', {
        userId: socket.user.id,
        status: 'online'
    });
    
    // Send message
    socket.on('sendMessage', async (data) => {
        try {
            const { receiverId, content } = data;
            
            // Save message to database
            const message = new Message({
                sender: socket.user.id,
                receiver: receiverId,
                content: content
            });
            
            await message.save();
            
            // Get populated message
            const populatedMessage = await Message.findById(message._id)
                .populate('sender', 'name profilePicture')
                .populate('receiver', 'name profilePicture');
            
            // Send to receiver if online
            const receiverSocketId = onlineUsers.get(receiverId);
            if (receiverSocketId) {
                io.to(receiverSocketId).emit('newMessage', populatedMessage);
            }
            
            // Send back to sender
            socket.emit('messageSent', populatedMessage);
        } catch (error) {
            console.error('Message error:', error);
            socket.emit('error', { message: 'Failed to send message' });
        }
    });
    
    // Mark messages as read
    socket.on('markAsRead', async (data) => {
        try {
            const { messageId } = data;
            
            const message = await Message.findById(messageId);
            
            if (message && message.receiver.toString() === socket.user.id) {
                message.read = true;
                await message.save();
                
                // Notify the sender that their message has been read
                const senderSocketId = onlineUsers.get(message.sender.toString());
                if (senderSocketId) {
                    io.to(senderSocketId).emit('messageRead', { messageId });
                }
            }
        } catch (error) {
            console.error('Read status error:', error);
        }
    });
    
    // Handle typing status
    socket.on('typing', (data) => {
        const receiverSocketId = onlineUsers.get(data.receiverId);
        if (receiverSocketId) {
            io.to(receiverSocketId).emit('userTyping', {
                userId: socket.user.id,
                isTyping: data.isTyping
            });
        }
    });
    
    // Disconnect
    socket.on('disconnect', () => {
        console.log(`User disconnected: ${socket.user.id}`);
        
        // Remove from online users
        onlineUsers.delete(socket.user.id);
        
        // Emit offline status to all users
        io.emit('userStatus', {
            userId: socket.user.id,
            status: 'offline'
        });
    });
});

//========================== ROUTES

// Register
app.post('/register', async (req, res) => {
    const { name, email, password } = req.body;
    try {
        if (!name || !email || !password) {
            return res.status(400).json({ error: "All fields are required" });
        }

        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(409).json({ error: "User already exists!" });
        }

        const hashedPassword = await bcrypt.hash(password, 10);
        const user = new User({ name, email, password: hashedPassword });
        await user.save();

        res.status(201).json({ message: "User registration successful!" });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Server error" });
    }
});

// Login
app.post('/login', async (req, res) => {
    const { email, password } = req.body;
    try {
        const user = await User.findOne({ email });
        if (!user) return res.status(404).json({ error: "User not found!" });

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) return res.status(403).json({ error: "Invalid credentials!" });

        const token = jwt.sign(
            { id: user._id, email: user.email },
            process.env.JWT_SECRET,
            { expiresIn: '30d' } // Extended token validity
        );

        res.json({
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                profilePicture: user.profilePicture || null
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Server error" });
    }
});

// Upload profile picture
app.put('/profile-picture', auth, upload.single('image'), async (req, res) => {
    try {
        const imageUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
        const user = await User.findByIdAndUpdate(
            req.user.id,
            { profilePicture: imageUrl },
            { new: true }
        );
        res.json({ message: "Profile picture updated", profilePicture: user.profilePicture });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Upload failed" });
    }
});

// Get conversations (chat list)
app.get('/conversations', auth, async (req, res) => {
    try {
        // Find all messages where the user is either sender or receiver
        const messages = await Message.find({
            $or: [
                { sender: req.user.id },
                { receiver: req.user.id }
            ]
        }).sort({ createdAt: -1 });
        
        // Extract unique conversation partners
        const conversationPartners = new Set();
        const conversations = [];
        
        for (const message of messages) {
            const partnerId = message.sender.toString() === req.user.id ? 
                message.receiver.toString() : message.sender.toString();
            
            if (!conversationPartners.has(partnerId)) {
                conversationPartners.add(partnerId);
                
                // Find the latest message in this conversation
                const latestMessage = await Message.findOne({
                    $or: [
                        { sender: req.user.id, receiver: partnerId },
                        { sender: partnerId, receiver: req.user.id }
                    ]
                })
                .sort({ createdAt: -1 })
                .populate('sender', 'name profilePicture')
                .populate('receiver', 'name profilePicture');
                
                // Count unread messages
                const unreadCount = await Message.countDocuments({
                    sender: partnerId,
                    receiver: req.user.id,
                    read: false
                });
                
                // Get partner info
                const partner = await User.findById(partnerId, 'name email profilePicture');
                
                conversations.push({
                    partner,
                    latestMessage,
                    unreadCount
                });
            }
        }
        
        res.json(conversations);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Server error" });
    }
});

// Get chat history with a specific user
app.get('/messages/:userId', auth, async (req, res) => {
    try {
        const messages = await Message.find({
            $or: [
                { sender: req.user.id, receiver: req.params.userId },
                { sender: req.params.userId, receiver: req.user.id }
            ]
        })
        .sort({ createdAt: 1 })
        .populate('sender', 'name profilePicture')
        .populate('receiver', 'name profilePicture');
        
        // Mark all received messages as read
        await Message.updateMany(
            { sender: req.params.userId, receiver: req.user.id, read: false },
            { $set: { read: true } }
        );
        
        res.json(messages);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Server error" });
    }
});

// Search users
app.get('/users/search', auth, async (req, res) => {
    try {
        const query = req.query.query;
        if (!query) return res.status(400).json({ error: "Search query is required" });
        
        const users = await User.find({
            _id: { $ne: req.user.id }, // Exclude current user
            $or: [
                { name: { $regex: query, $options: 'i' } },
                { email: { $regex: query, $options: 'i' } }
            ]
        }, 'name email profilePicture');
        
        res.json(users);
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: "Server error" });
    }
});

//========================== START SERVER
server.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on port ${PORT}`);
});