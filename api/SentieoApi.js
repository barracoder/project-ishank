const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = 3000; // You can choose any port

// Endpoint to return metadata.json
app.get('/notes/:noteId', (req, res) => {
  const metadataPath = path.join(__dirname, 'metadata.json');
  fs.readFile(metadataPath, (err, data) => {
	if (err) {
	  return res.status(404).send('Metadata not found');
	}
	res.type('application/json').send(data);
  });
});

// Endpoint to return a random byte array
let callCount = 0; // Initialize a call counter outside the endpoint

app.get('/notes/:noteId/content', (req, res) => {
  callCount++; // Increment the call counter
  if (callCount % 10 === 0) {
    // Every 10th call, return a 404 error
    return res.status(404).send('Content not found');
  }

  const randomBytes = Buffer.alloc(10); // Change 10 to the desired size of the byte array
  for (let i = 0; i < randomBytes.length; i++) {
    randomBytes[i] = Math.floor(Math.random() * 256); // Random byte
  }
  res.type('application/octet-stream').send(randomBytes);
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});