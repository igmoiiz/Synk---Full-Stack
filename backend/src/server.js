//  HEADERS
const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');
const cors = require('cors');
const PORT = 5000;
const url = "mongodb+srv://khanmoaiz682:332211Asdfghjkl@cluster0.0kcojwd.mongodb.net/Synk";
const app = express();

// MIDDLEWARE
app.use(cors());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

//  DATABASE CONNECTION
mongoose.connect(url).then(() => {
    console.log("Connected to MongoDB");

    //  GET ROUTE
    app.get("/", (req, res) => {
        res.send("Hello World");
    });
 }).catch((error) => { 
    console.error(error);
});


//  RUN THE SERVER
app.listen(PORT, "0.0.0.0", () => { });