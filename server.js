const express = require("express");
const path = require("path");

const app = express();

// Serve everything in project folder
app.use(express.static(path.join(__dirname)));

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "index.html"));
});

const port = 5000;
app.listen(port, () => {
  console.log(`Server running on http://127.0.0.1:${port}`);
});