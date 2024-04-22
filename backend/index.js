// index.js

import express from 'express';
import bodyParser from 'body-parser';
import { nanoid } from 'nanoid';
import cors from 'cors';
import mongoose from 'mongoose';
import validator from 'validator'; // Import the validator library
import { SERVER_URL, MONGODB_URL, SERVER_PORT } from './config.js';

// MongoDB setup
mongoose.connect(MONGODB_URL, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});
const db = mongoose.connection;
db.on('error', console.error.bind(console, 'MongoDB connection error:'));

// Define a schema
const urlSchema = new mongoose.Schema({
  originalUrl: String,
  shortenedId: String,
});

// Define a model
const Url = mongoose.model('Url', urlSchema);

const app = express();
app.use(bodyParser.json());
app.use(cors()); // Enable CORS for all routes

// Endpoint to shorten a URL
app.post('/shorten', async (req, res) => {
  const { originalUrl } = req.body;

  // Check if the URL is in a valid format
  if (!validator.isURL(originalUrl)) { // Use the isURL method from the validator library
    return res.status(400).json({ error: 'Invalid URL format' });
  }

  // Check if the URL already exists in the database
  let url = await Url.findOne({ originalUrl });
  if (url) {
    return res.json({ shortenedUrl: `${SERVER_URL}/${url.shortenedId}` });
  }

  let shortenedId;
  do {
    shortenedId = nanoid(6);
  } while (await Url.exists({ shortenedId }));

  if (!originalUrl.startsWith('http://') && !originalUrl.startsWith('https://')) {
    // If not, prepend "https://" to the URL
    url = new Url({ originalUrl: 'https://' + originalUrl, shortenedId });
  } else {
    url = new Url({ originalUrl, shortenedId });
  }

  try {
    await url.save();
    res.json({ shortenedUrl: `${SERVER_URL}/${shortenedId}` });
  } catch (err) {
    res.status(500).json({ error: 'Internal Server Error' });
  }
});

// Endpoint to redirect shortened URL to original URL
app.get('/:shortenedId', async (req, res) => {
  const { shortenedId } = req.params;
  const url = await Url.findOne({ shortenedId });

  if (url) {
    res.redirect(url.originalUrl);
  } else {
    res.status(404).send('URL not found');
  }
});

// Start the server
const PORT = process.env.PORT || SERVER_PORT; // Use a different port for backend
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
